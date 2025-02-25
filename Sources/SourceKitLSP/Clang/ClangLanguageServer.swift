//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation
import LSPLogging
import LanguageServerProtocol
import LanguageServerProtocolJSONRPC
import SKCore
import SKSupport

import struct TSCBasic.AbsolutePath

#if os(Windows)
import WinSDK
#endif

extension NSLock {
  /// NOTE: Keep in sync with SwiftPM's 'Sources/Basics/NSLock+Extensions.swift'
  fileprivate func withLock<T>(_ body: () throws -> T) rethrows -> T {
    lock()
    defer { unlock() }
    return try body()
  }
}

/// Gathers data from clangd's stderr pipe. When it has accumulated a full line, writes the the line to the logger.
fileprivate class ClangdStderrLogForwarder {
  private var buffer = Data()

  func handle(_ newData: Data) {
    self.buffer += newData
    while let newlineIndex = self.buffer.firstIndex(of: UInt8(ascii: "\n")) {
      // Output a separate log message for every line in clangd's stderr.
      // The reason why we don't output multiple lines in a single log message is that
      //  a) os_log truncates log messages at about 1000 bytes. The assumption is that a single line is usually less
      //     than 1000 bytes long but if we merge multiple lines into one message, we might easily exceed this limit.
      //  b) It might be confusing why sometimes a single log message contains one line while sometimes it contains
      //     multiple.
      let logger = Logger(subsystem: subsystem, category: "clangd-stderr")
      logger.info("\(String(data: self.buffer[...newlineIndex], encoding: .utf8) ?? "<invalid UTF-8>")")
      buffer = buffer[buffer.index(after: newlineIndex)...]
    }
  }
}

/// A thin wrapper over a connection to a clangd server providing build setting handling.
///
/// In addition, it also intercepts notifications and replies from clangd in order to do things
/// like witholding diagnostics when fallback build settings are being used.
///
/// ``ClangLangaugeServerShim`` conforms to ``MessageHandler`` to receive
/// requests and notifications **from** clangd, not from the editor, and it will
/// forward these requests and notifications to the editor.
actor ClangLanguageServerShim: ToolchainLanguageServer, MessageHandler {
  /// The queue on which all messages that originate from clangd are handled.
  ///
  /// These are requests and notifications sent *from* clangd, not replies from
  /// clangd.
  ///
  /// Since we are blindly forwarding requests from clangd to the editor, we
  /// cannot allow concurrent requests. This should be fine since the number of
  /// requests and notifications sent from clangd to the client is quite small.
  public let clangdMessageHandlingQueue = AsyncQueue<Serial>()

  /// The ``SourceKitServer`` instance that created this `ClangLanguageServerShim`.
  ///
  /// Used to send requests and notifications to the editor.
  private weak var sourceKitServer: SourceKitServer?

  /// The connection to the clangd LSP. `nil` until `startClangdProcesss` has been called.
  var clangd: Connection!

  /// Capabilities of the clangd LSP, if received.
  var capabilities: ServerCapabilities? = nil

  /// Path to the clang binary.
  let clangPath: AbsolutePath?

  /// Path to the `clangd` binary.
  let clangdPath: AbsolutePath

  let clangdOptions: [String]

  /// The current state of the `clangd` language server.
  /// Changing the property automatically notified the state change handlers.
  private var state: LanguageServerState {
    didSet {
      for handler in stateChangeHandlers {
        handler(oldValue, state)
      }
    }
  }

  private var stateChangeHandlers: [(_ oldState: LanguageServerState, _ newState: LanguageServerState) -> Void] = []

  /// The date at which `clangd` was last restarted.
  /// Used to delay restarting in case of a crash loop.
  private var lastClangdRestart: Date?

  /// Whether or not a restart of `clangd` has been scheduled.
  /// Used to make sure we are not restarting `clangd` twice.
  private var clangRestartScheduled = false

  /// The `InitializeRequest` with which `clangd` was originally initialized.
  /// Stored so we can replay the initialization when clangd crashes.
  private var initializeRequest: InitializeRequest?

  /// The workspace this `ClangLanguageServer` was opened for.
  ///
  /// `clangd` doesn't have support for multi-root workspaces, so we need to start a separate `clangd` instance for every workspace root.
  private let workspace: WeakWorkspace

  /// The documents that have been opened and which language they have been
  /// opened with.
  private var openDocuments: [DocumentURI: Language] = [:]

  /// While `clangd` is running, its PID.
  #if os(Windows)
  private var hClangd: HANDLE = INVALID_HANDLE_VALUE
  #else
  private var clangdPid: Int32?
  #endif

  /// Creates a language server for the given client referencing the clang binary specified in `toolchain`.
  /// Returns `nil` if `clangd` can't be found.
  public init?(
    sourceKitServer: SourceKitServer,
    toolchain: Toolchain,
    options: SourceKitServer.Options,
    workspace: Workspace
  ) async throws {
    guard let clangdPath = toolchain.clangd else {
      return nil
    }
    self.clangPath = toolchain.clang
    self.clangdPath = clangdPath
    self.clangdOptions = options.clangdOptions
    self.workspace = WeakWorkspace(workspace)
    self.state = .connected
    self.sourceKitServer = sourceKitServer
    try startClangdProcess()
  }

  private func buildSettings(for document: DocumentURI) async -> ClangBuildSettings? {
    guard let workspace = workspace.value, let language = openDocuments[document] else {
      return nil
    }
    guard
      let settings = await workspace.buildSystemManager.buildSettingsInferredFromMainFile(
        for: document,
        language: language
      )
    else {
      return nil
    }
    return ClangBuildSettings(settings, clangPath: clangdPath)
  }

  nonisolated func canHandle(workspace: Workspace) -> Bool {
    // We launch different clangd instance for each workspace because clangd doesn't have multi-root workspace support.
    return workspace === self.workspace.value
  }

  func addStateChangeHandler(handler: @escaping (LanguageServerState, LanguageServerState) -> Void) {
    self.stateChangeHandlers.append(handler)
  }

  /// Called after the `clangd` process exits.
  ///
  /// Restarts `clangd` if it has crashed.
  ///
  /// - Parameter terminationStatus: The exit code of `clangd`.
  private func handleClangdTermination(terminationStatus: Int32) {
    #if os(Windows)
    self.hClangd = INVALID_HANDLE_VALUE
    #else
    self.clangdPid = nil
    #endif
    if terminationStatus != 0 {
      self.state = .connectionInterrupted
      self.restartClangd()
    }
  }

  /// Start the `clangd` process, either on creation of the `ClangLanguageServerShim` or after `clangd` has crashed.
  private func startClangdProcess() throws {
    // Since we are starting a new clangd process, reset the list of open document
    openDocuments = [:]

    let usToClangd: Pipe = Pipe()
    let clangdToUs: Pipe = Pipe()

    let connectionToClangd = JSONRPCConnection(
      name: "clangd",
      protocol: MessageRegistry.lspProtocol,
      inFD: clangdToUs.fileHandleForReading,
      outFD: usToClangd.fileHandleForWriting
    )
    self.clangd = connectionToClangd

    connectionToClangd.start(receiveHandler: self) {
      // FIXME: keep the pipes alive until we close the connection. This
      // should be fixed systemically.
      withExtendedLifetime((usToClangd, clangdToUs)) {}
    }

    let process = Foundation.Process()
    process.executableURL = clangdPath.asURL
    process.arguments =
      [
        "-compile_args_from=lsp",  // Provide compiler args programmatically.
        "-background-index=false",  // Disable clangd indexing, we use the build
        "-index=false",  // system index store instead.
      ] + clangdOptions

    process.standardOutput = clangdToUs
    process.standardInput = usToClangd
    let logForwarder = ClangdStderrLogForwarder()
    let stderrHandler = Pipe()
    stderrHandler.fileHandleForReading.readabilityHandler = { fileHandle in
      let newData = fileHandle.availableData
      if newData.count == 0 {
        stderrHandler.fileHandleForReading.readabilityHandler = nil
      } else {
        logForwarder.handle(newData)
      }
    }
    process.standardError = stderrHandler
    process.terminationHandler = { [weak self] process in
      logger.log(
        level: process.terminationReason == .exit ? .default : .error,
        "clangd exited: \(String(reflecting: process.terminationReason)) \(process.terminationStatus)"
      )
      connectionToClangd.close()
      guard let self = self else { return }
      Task {
        await self.handleClangdTermination(terminationStatus: process.terminationStatus)
      }
    }
    try process.run()
    #if os(Windows)
    self.hClangd = process.processHandle
    #else
    self.clangdPid = process.processIdentifier
    #endif
  }

  /// Restart `clangd` after it has crashed.
  /// Delays restarting of `clangd` in case there is a crash loop.
  private func restartClangd() {
    precondition(self.state == .connectionInterrupted)

    precondition(self.clangRestartScheduled == false)
    self.clangRestartScheduled = true

    guard let initializeRequest = self.initializeRequest else {
      logger.error("clangd crashed before it was sent an InitializeRequest.")
      return
    }

    let restartDelay: Int
    if let lastClangdRestart = self.lastClangdRestart, Date().timeIntervalSince(lastClangdRestart) < 30 {
      logger.log("clangd has already been restarted in the last 30 seconds. Delaying another restart by 10 seconds.")
      restartDelay = 10
    } else {
      restartDelay = 0
    }
    self.lastClangdRestart = Date()

    Task {
      try await Task.sleep(nanoseconds: UInt64(restartDelay) * 1_000_000_000)
      self.clangRestartScheduled = false
      do {
        try self.startClangdProcess()
        // FIXME: We assume that clangd will return the same capabilities after restarting.
        // Theoretically they could have changed and we would need to inform SourceKitServer about them.
        // But since SourceKitServer more or less ignores them right now anyway, this should be fine for now.
        _ = try await self.initialize(initializeRequest)
        self.clientInitialized(InitializedNotification())
        if let sourceKitServer {
          await sourceKitServer.reopenDocuments(for: self)
        } else {
          logger.fault("Cannot reopen documents because SourceKitServer is no longer alive")
        }
        self.state = .connected
      } catch {
        logger.fault("Failed to restart clangd after a crash.")
      }
    }
  }

  /// Handler for notifications received **from** clangd, ie. **clangd** is
  /// sending a notification that's intended for the editor.
  ///
  /// We should either handle it ourselves or forward it to the editor.
  nonisolated func handle(_ params: some NotificationType, from clientID: ObjectIdentifier) {
    logger.info(
      """
      Received notification from clangd:
      \(params.forLogging)
      """
    )
    clangdMessageHandlingQueue.async {
      switch params {
      case let publishDiags as PublishDiagnosticsNotification:
        await self.publishDiagnostics(publishDiags)
      default:
        // We don't know how to handle any other notifications and ignore them.
        logger.error("Ignoring unknown notification \(type(of: params))")
        break
      }
    }
  }

  /// Handler for requests received **from** clangd, ie. **clangd** is
  /// sending a notification that's intended for the editor.
  ///
  /// We should either handle it ourselves or forward it to the client.
  nonisolated func handle<R: RequestType>(
    _ params: R,
    id: RequestID,
    from clientID: ObjectIdentifier,
    reply: @escaping (LSPResult<R.Response>) -> Void
  ) {
    logger.info(
      """
      Received request from clangd:
      \(params.forLogging)
      """
    )
    clangdMessageHandlingQueue.async {
      guard let sourceKitServer = await self.sourceKitServer else {
        // `SourceKitServer` has been destructed. We are tearing down the language
        // server. Nothing left to do.
        reply(.failure(.unknown("Connection to the editor closed")))
        return
      }

      do {
        let result = try await sourceKitServer.sendRequestToClient(params)
        reply(.success(result))
      } catch {
        reply(.failure(ResponseError(error)))
      }
    }
  }

  /// Forward the given request to `clangd`.
  ///
  /// This method calls `readyToHandleNextRequest` once the request has been
  /// transmitted to `clangd` and another request can be safely transmitted to
  /// `clangd` while guaranteeing ordering.
  ///
  /// The response of the request is  returned asynchronously as the return value.
  func forwardRequestToClangd<R: RequestType>(_ request: R) async throws -> R.Response {
    return try await clangd.send(request)
  }

  func _crash() {
    // Since `clangd` doesn't have a method to crash it, kill it.
    #if os(Windows)
    if self.hClangd != INVALID_HANDLE_VALUE {
      // FIXME(compnerd) this is a bad idea - we can potentially deadlock the
      // process if a kobject is a pending state.  Unfortunately, the
      // `OpenProcess(PROCESS_TERMINATE, ...)`, `CreateRemoteThread`,
      // `ExitProcess` dance, while safer, can also indefinitely hang as
      // `CreateRemoteThread` may not be serviced depending on the state of
      // the process.  This just attempts to terminate the process, risking a
      // deadlock and resource leaks.
      _ = TerminateProcess(self.hClangd, 0)
    }
    #else
    if let pid = self.clangdPid {
      kill(pid, SIGKILL)
    }
    #endif
  }
}

// MARK: - LanguageServer

extension ClangLanguageServerShim {

  /// Intercept clangd's `PublishDiagnosticsNotification` to withold it if we're using fallback
  /// build settings.
  func publishDiagnostics(_ notification: PublishDiagnosticsNotification) async {
    // Technically, the publish diagnostics notification could still originate
    // from when we opened the file with fallback build settings and we could
    // have received real build settings since, which haven't been acknowledged
    // by clangd yet.
    //
    // Since there is no way to tell which build settings clangd used to generate
    // the diagnostics, there's no good way to resolve this race. For now, this
    // should be good enough since the time in which the race may occur is pretty
    // short and we expect clangd to send us new diagnostics with the updated
    // non-fallback settings very shortly after, which will override the
    // incorrect result, making it very temporary.
    let buildSettings = await self.buildSettings(for: notification.uri)
    guard let sourceKitServer else {
      logger.fault("Cannot publish diagnostics because SourceKitServer has been destroyed")
      return
    }
    if buildSettings?.isFallback ?? true {
      // Fallback: send empty publish notification instead.
      await sourceKitServer.sendNotificationToClient(
        PublishDiagnosticsNotification(
          uri: notification.uri,
          version: notification.version,
          diagnostics: []
        )
      )
    } else {
      await sourceKitServer.sendNotificationToClient(notification)
    }
  }

}

// MARK: - ToolchainLanguageServer

extension ClangLanguageServerShim {

  func initialize(_ initialize: InitializeRequest) async throws -> InitializeResult {
    // Store the initialize request so we can replay it in case clangd crashes
    self.initializeRequest = initialize

    let result = try await clangd.send(initialize)
    self.capabilities = result.capabilities
    return result
  }

  public func clientInitialized(_ initialized: InitializedNotification) {
    clangd.send(initialized)
  }

  public func shutdown() async {
    await withCheckedContinuation { continuation in
      _ = clangd.send(ShutdownRequest()) { _ in
        Task {
          self.clangd.send(ExitNotification())
          continuation.resume()
        }
      }
    }
  }

  // MARK: - Text synchronization

  public func openDocument(_ note: DidOpenTextDocumentNotification) async {
    openDocuments[note.textDocument.uri] = note.textDocument.language
    // Send clangd the build settings for the new file. We need to do this before
    // sending the open notification, so that the initial diagnostics already
    // have build settings.
    await documentUpdatedBuildSettings(note.textDocument.uri)
    clangd.send(note)
  }

  public func closeDocument(_ note: DidCloseTextDocumentNotification) {
    openDocuments[note.textDocument.uri] = nil
    clangd.send(note)
  }

  public func changeDocument(_ note: DidChangeTextDocumentNotification) {
    clangd.send(note)
  }

  public func willSaveDocument(_ note: WillSaveTextDocumentNotification) {

  }

  public func didSaveDocument(_ note: DidSaveTextDocumentNotification) {
    clangd.send(note)
  }

  // MARK: - Build System Integration

  public func documentUpdatedBuildSettings(_ uri: DocumentURI) async {
    guard let url = uri.fileURL else {
      // FIXME: The clang workspace can probably be reworked to support non-file URIs.
      logger.error("Received updated build settings for non-file URI '\(uri.forLogging)'. Ignoring the update.")
      return
    }
    let clangBuildSettings = await self.buildSettings(for: uri)
    // FIXME: (logging) Log only the `-something` flags with paths redacted if private mode is enabled
    logger.info("settings for \(uri.forLogging): \(clangBuildSettings?.compilerArgs.description ?? "nil")")

    // The compile command changed, send over the new one.
    // FIXME: what should we do if we no longer have valid build settings?
    if let compileCommand = clangBuildSettings?.compileCommand,
      let pathString = (try? AbsolutePath(validating: url.path))?.pathString
    {
      let note = DidChangeConfigurationNotification(
        settings: .clangd(
          ClangWorkspaceSettings(
            compilationDatabaseChanges: [pathString: compileCommand])
        )
      )
      clangd.send(note)
    }
  }

  public func documentDependenciesUpdated(_ uri: DocumentURI) {
    // In order to tell clangd to reload an AST, we send it an empty `didChangeTextDocument`
    // with `forceRebuild` set in case any missing header files have been added.
    // This works well for us as the moment since clangd ignores the document version.
    let note = DidChangeTextDocumentNotification(
      textDocument: VersionedTextDocumentIdentifier(uri, version: 0),
      contentChanges: [],
      forceRebuild: true
    )
    clangd.send(note)
  }

  // MARK: - Text Document

  /// Returns true if the `ToolchainLanguageServer` will take ownership of the request.
  public func definition(_ req: DefinitionRequest) async throws -> LocationsOrLocationLinksResponse? {
    // We handle it to provide jump-to-header support for #import/#include.
    return try await self.forwardRequestToClangd(req)
  }

  public func declaration(_ req: DeclarationRequest) async throws -> LocationsOrLocationLinksResponse? {
    return try await forwardRequestToClangd(req)
  }

  func completion(_ req: CompletionRequest) async throws -> CompletionList {
    return try await forwardRequestToClangd(req)
  }

  func hover(_ req: HoverRequest) async throws -> HoverResponse? {
    return try await forwardRequestToClangd(req)
  }

  func symbolInfo(_ req: SymbolInfoRequest) async throws -> [SymbolDetails] {
    return try await forwardRequestToClangd(req)
  }

  func documentSymbolHighlight(_ req: DocumentHighlightRequest) async throws -> [DocumentHighlight]? {
    return try await forwardRequestToClangd(req)
  }

  func documentSymbol(_ req: DocumentSymbolRequest) async throws -> DocumentSymbolResponse? {
    return try await forwardRequestToClangd(req)
  }

  func documentColor(_ req: DocumentColorRequest) async throws -> [ColorInformation] {
    guard self.capabilities?.colorProvider?.isSupported ?? false else {
      return []
    }
    return try await forwardRequestToClangd(req)
  }

  func documentSemanticTokens(_ req: DocumentSemanticTokensRequest) async throws -> DocumentSemanticTokensResponse? {
    return try await forwardRequestToClangd(req)
  }

  func documentSemanticTokensDelta(
    _ req: DocumentSemanticTokensDeltaRequest
  ) async throws -> DocumentSemanticTokensDeltaResponse? {
    return try await forwardRequestToClangd(req)
  }

  func documentSemanticTokensRange(
    _ req: DocumentSemanticTokensRangeRequest
  ) async throws -> DocumentSemanticTokensResponse? {
    return try await forwardRequestToClangd(req)
  }

  func colorPresentation(_ req: ColorPresentationRequest) async throws -> [ColorPresentation] {
    guard self.capabilities?.colorProvider?.isSupported ?? false else {
      return []
    }
    return try await forwardRequestToClangd(req)
  }

  func documentFormatting(_ req: DocumentFormattingRequest) async throws -> [TextEdit]? {
    return try await forwardRequestToClangd(req)
  }

  func codeAction(_ req: CodeActionRequest) async throws -> CodeActionRequestResponse? {
    return try await forwardRequestToClangd(req)
  }

  func inlayHint(_ req: InlayHintRequest) async throws -> [InlayHint] {
    return try await forwardRequestToClangd(req)
  }

  func documentDiagnostic(_ req: DocumentDiagnosticsRequest) async throws -> DocumentDiagnosticReport {
    return try await forwardRequestToClangd(req)
  }

  func foldingRange(_ req: FoldingRangeRequest) async throws -> [FoldingRange]? {
    guard self.capabilities?.foldingRangeProvider?.isSupported ?? false else {
      return nil
    }
    return try await forwardRequestToClangd(req)
  }

  func openInterface(_ request: OpenInterfaceRequest) async throws -> InterfaceDetails? {
    throw ResponseError.unknown("unsupported method")
  }

  // MARK: - Other

  func executeCommand(_ req: ExecuteCommandRequest) async throws -> LSPAny? {
    return try await forwardRequestToClangd(req)
  }
}

/// Clang build settings derived from a `FileBuildSettingsChange`.
private struct ClangBuildSettings: Equatable {
  /// The compiler arguments, including the program name, argv[0].
  public let compilerArgs: [String]

  /// The working directory for the invocation.
  public let workingDirectory: String

  /// Whether the compiler arguments are considered fallback - we withhold diagnostics for
  /// fallback arguments and represent the file state differently.
  public let isFallback: Bool

  public init(_ settings: FileBuildSettings, clangPath: AbsolutePath?) {
    var arguments = [clangPath?.pathString ?? "clang"] + settings.compilerArguments
    if arguments.contains("-fmodules") {
      // Clangd is not built with support for the 'obj' format.
      arguments.append(contentsOf: [
        "-Xclang", "-fmodule-format=raw",
      ])
    }
    if let workingDirectory = settings.workingDirectory {
      // FIXME: this is a workaround for clangd not respecting the compilation
      // database's "directory" field for relative -fmodules-cache-path.
      // rdar://63984913
      arguments.append(contentsOf: [
        "-working-directory", workingDirectory,
      ])
    }

    self.compilerArgs = arguments
    self.workingDirectory = settings.workingDirectory ?? ""
    self.isFallback = settings.isFallback
  }

  public var compileCommand: ClangCompileCommand {
    return ClangCompileCommand(
      compilationCommand: self.compilerArgs,
      workingDirectory: self.workingDirectory
    )
  }
}
