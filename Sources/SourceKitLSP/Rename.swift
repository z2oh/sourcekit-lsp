//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import IndexStoreDB
import LSPLogging
import LanguageServerProtocol
import SKSupport
import SourceKitD

// MARK: - Helper types

/// A parsed representation of a name that may be disambiguated by its argument labels.
///
/// ### Examples
///  - `foo(a:b:)`
///  - `foo(_:b:)`
///  - `foo` if no argument labels are specified, eg. for a variable.
fileprivate struct CompoundDeclName {
  /// The parameter of a compound decl name, which can either be the parameter's name or `_` to indicate that the
  /// parameter is unnamed.
  enum Parameter: Equatable {
    case named(String)
    case wildcard

    var stringOrWildcard: String {
      switch self {
      case .named(let str): return str
      case .wildcard: return "_"
      }
    }

    var stringOrEmpty: String {
      switch self {
      case .named(let str): return str
      case .wildcard: return ""
      }
    }
  }

  let baseName: String
  let parameters: [Parameter]

  /// Parse a compound decl name into its base names and parameters.
  init(_ compoundDeclName: String) {
    guard let openParen = compoundDeclName.firstIndex(of: "(") else {
      // We don't have a compound name. Everything is the base name
      self.baseName = compoundDeclName
      self.parameters = []
      return
    }
    self.baseName = String(compoundDeclName[..<openParen])
    let closeParen = compoundDeclName.firstIndex(of: ")") ?? compoundDeclName.endIndex
    let parametersText = compoundDeclName[compoundDeclName.index(after: openParen)..<closeParen]
    // Split by `:` to get the parameter names. Drop the last element so that we don't have a trailing empty element
    // after the last `:`.
    let parameterStrings = parametersText.split(separator: ":", omittingEmptySubsequences: false).dropLast()
    parameters = parameterStrings.map {
      switch $0 {
      case "", "_": return .wildcard
      default: return .named(String($0))
      }
    }
  }
}

/// The kind of range that a `SyntacticRenamePiece` can be.
fileprivate enum SyntacticRenamePieceKind {
  /// The base name of a function or the name of a variable, which can be renamed.
  ///
  /// ### Examples
  /// - `foo` in `func foo(a b: Int)`.
  /// - `foo` in `let foo = 1`
  case baseName

  /// The base name of a function-like declaration that cannot be renamed
  ///
  /// ### Examples
  /// - `init` in `init(a: Int)`
  /// - `subscript` in `subscript(a: Int) -> Int`
  case keywordBaseName

  /// The internal parameter name (aka. second name) inside a function declaration
  ///
  /// ### Examples
  /// - ` b` in `func foo(a b: Int)`
  case parameterName

  /// Same as `parameterName` but cannot be removed if it is the same as the parameter's first name. This only happens
  /// for subscripts where parameters are unnamed by default unless they have both a first and second name.
  ///
  /// ### Examples
  /// The second ` a` in `subscript(a a: Int)`
  case noncollapsibleParameterName

  /// The external argument label of a function parameter
  ///
  /// ### Examples
  /// - `a` in `func foo(a b: Int)`
  /// - `a` in `func foo(a: Int)`
  case declArgumentLabel

  /// The argument label inside a call.
  ///
  /// ### Examples
  /// - `a` in `foo(a: 1)`
  case callArgumentLabel

  /// The colon after an argument label inside a call. This is reported so it can be removed if the parameter becomes
  /// unnamed.
  ///
  /// ### Examples
  /// - `: ` in `foo(a: 1)`
  case callArgumentColon

  /// An empty range that point to the position before an unnamed argument. This is used to insert the argument label
  /// if an unnamed parameter becomes named.
  ///
  /// ### Examples
  /// - An empty range before `1` in `foo(1)`, which could expand to `foo(a: 1)`
  case callArgumentCombined

  /// The argument label in a compound decl name.
  ///
  /// ### Examples
  /// - `a` in `foo(a:)`
  case selectorArgumentLabel

  init?(_ uid: sourcekitd_uid_t, keys: sourcekitd_keys) {
    switch uid {
    case keys.renameRangeBase: self = .baseName
    case keys.renameRangeCallArgColon: self = .callArgumentColon
    case keys.renameRangeCallArgCombined: self = .callArgumentCombined
    case keys.renameRangeCallArgLabel: self = .callArgumentLabel
    case keys.renameRangeDeclArgLabel: self = .declArgumentLabel
    case keys.renameRangeKeywordBase: self = .keywordBaseName
    case keys.renameRangeNoncollapsibleParam: self = .noncollapsibleParameterName
    case keys.renameRangeParam: self = .parameterName
    case keys.renameRangeSelectorArgLabel: self = .selectorArgumentLabel
    default: return nil
    }
  }
}

/// A single “piece” that is used for renaming a compound function name.
///
/// See `SyntacticRenamePieceKind` for the different rename pieces that exist.
///
/// ### Example
/// `foo(x: 1)` is represented by three pieces
/// - The base name `foo`
/// - The parameter name `x`
/// - The call argument colon `: `.
fileprivate struct SyntacticRenamePiece {
  /// The range that represents this piece of the name
  let range: Range<Position>

  /// The kind of the rename piece.
  let kind: SyntacticRenamePieceKind

  /// If this piece belongs to a parameter, the index of that parameter (zero-based) or `nil` if this is the base name
  /// piece.
  let parameterIndex: Int?

  /// Create a `SyntacticRenamePiece` from a `sourcekitd` response.
  init?(_ dict: SKDResponseDictionary, in snapshot: DocumentSnapshot, keys: sourcekitd_keys) {
    guard let line: Int = dict[keys.line],
      let column: Int = dict[keys.column],
      let endLine: Int = dict[keys.endline],
      let endColumn: Int = dict[keys.endcolumn],
      let kind: sourcekitd_uid_t = dict[keys.kind]
    else {
      return nil
    }
    guard
      let start = snapshot.positionOf(zeroBasedLine: line - 1, utf8Column: column - 1),
      let end = snapshot.positionOf(zeroBasedLine: endLine - 1, utf8Column: endColumn - 1)
    else {
      return nil
    }
    guard let kind = SyntacticRenamePieceKind(kind, keys: keys) else {
      return nil
    }

    self.range = start..<end
    self.kind = kind
    self.parameterIndex = dict[keys.argindex] as Int?
  }
}

/// The context in which the location to be renamed occurred.
fileprivate enum SyntacticRenameNameContext {
  /// No syntactic rename ranges for the rename location could be found.
  case unmatched

  /// A name could be found at a requested rename location but the name did not match the specified old name.
  case mismatch

  /// The matched ranges are in active source code (ie. source code that is not an inactive `#if` range).
  case activeCode

  /// The matched ranges are in an inactive `#if` region of the source code.
  case inactiveCode

  /// The matched ranges occur inside a string literal.
  case string

  /// The matched ranges occur inside a `#selector` directive.
  case selector

  /// The matched ranges are within a comment.
  case comment

  init?(_ uid: sourcekitd_uid_t, keys: sourcekitd_keys) {
    switch uid {
    case keys.sourceEditKindActive: self = .activeCode
    case keys.sourceEditKindComment: self = .comment
    case keys.sourceEditKindInactive: self = .inactiveCode
    case keys.sourceEditKindMismatch: self = .mismatch
    case keys.sourceEditKindSelector: self = .selector
    case keys.sourceEditKindString: self = .string
    case keys.sourceEditKindUnknown: self = .unmatched
    default: return nil
    }
  }
}

/// A set of ranges that, combined, represent which edits need to be made to rename a possibly compound name.
///
/// See `SyntacticRenamePiece` for more details.
fileprivate struct SyntacticRenameName {
  let pieces: [SyntacticRenamePiece]
  let category: SyntacticRenameNameContext

  init?(_ dict: SKDResponseDictionary, in snapshot: DocumentSnapshot, keys: sourcekitd_keys) {
    guard let ranges: SKDResponseArray = dict[keys.ranges] else {
      return nil
    }
    self.pieces = ranges.compactMap { SyntacticRenamePiece($0, in: snapshot, keys: keys) }
    guard let categoryUid: sourcekitd_uid_t = dict[keys.category],
      let category = SyntacticRenameNameContext(categoryUid, keys: keys)
    else {
      return nil
    }
    self.category = category
  }
}

private extension LineTable {
  subscript(range: Range<Position>) -> Substring? {
    guard let start = self.stringIndexOf(line: range.lowerBound.line, utf16Column: range.lowerBound.utf16index),
      let end = self.stringIndexOf(line: range.upperBound.line, utf16Column: range.upperBound.utf16index)
    else {
      return nil
    }
    return self.content[start..<end]
  }
}

private extension DocumentSnapshot {
  init(_ url: URL, language: Language) throws {
    let contents = try String(contentsOf: url)
    self.init(uri: DocumentURI(url), language: language, version: 0, lineTable: LineTable(contents))
  }
}

private extension RenameLocation.Usage {
  init(roles: SymbolRole) {
    if roles.contains(.definition) || roles.contains(.declaration) {
      self = .definition
    } else if roles.contains(.call) {
      self = .call
    } else {
      self = .reference
    }
  }
}

// MARK: - SourceKitServer

extension SourceKitServer {
  func rename(_ request: RenameRequest) async throws -> WorkspaceEdit? {
    let uri = request.textDocument.uri
    guard let workspace = await workspaceForDocument(uri: uri) else {
      throw ResponseError.workspaceNotOpen(uri)
    }
    guard let languageService = workspace.documentService[uri] else {
      return nil
    }

    // Determine the local edits and the USR to rename
    let renameResult = try await languageService.rename(request)
    var changes = renameResult.edits.changes ?? [:]

    if let usr = renameResult.usr, let oldName = renameResult.oldName, let index = workspace.index {
      // If we have a USR + old name, perform an index lookup to find workspace-wide symbols to rename.
      // First, group all occurrences of that USR by the files they occur in.
      var locationsByFile: [URL: [RenameLocation]] = [:]
      let occurrences = index.occurrences(ofUSR: usr, roles: [.declaration, .definition, .reference])
      for occurrence in occurrences {
        let url = URL(fileURLWithPath: occurrence.location.path)
        let renameLocation = RenameLocation(
          line: occurrence.location.line,
          utf8Column: occurrence.location.utf8Column,
          usage: RenameLocation.Usage(roles: occurrence.roles)
        )
        locationsByFile[url, default: []].append(renameLocation)
      }

      // Now, call `editsToRename(locations:in:oldName:newName:)` on the language service to convert these ranges into
      // edits.
      let urisAndEdits =
        await locationsByFile
        .filter { changes[DocumentURI($0.key)] == nil }
        .concurrentMap { (url: URL, renameLocations: [RenameLocation]) -> (DocumentURI, [TextEdit])? in
          let uri = DocumentURI(url)
          // Create a document snapshot to operate on. If the document is open, load it from the document manager,
          // otherwise conjure one from the file on disk. We need the file in memory to perform UTF-8 to UTF-16 column
          // conversions.
          // We should technically infer the language for the from-disk snapshot. But `editsToRename` doesn't care
          // about it, so defaulting to Swift is good enough for now
          // If we fail to get edits for one file, log an error and continue but don't fail rename completely.
          guard
            let snapshot = (try? self.documentManager.latestSnapshot(uri))
              ?? (try? DocumentSnapshot(url, language: .swift))
          else {
            logger.error("Failed to get document snapshot for \(uri.forLogging)")
            return nil
          }
          do {
            let edits = try await languageService.editsToRename(
              locations: renameLocations,
              in: snapshot,
              oldName: oldName,
              newName: request.newName
            )
            return (uri, edits)
          } catch {
            logger.error("Failed to get edits for \(uri.forLogging): \(error.forLogging)")
            return nil
          }
        }.compactMap { $0 }
      for (uri, editsForUri) in urisAndEdits {
        precondition(
          changes[uri] == nil,
          "We should have only computed edits for URIs that didn't have edits from the initial rename request"
        )
        if !editsForUri.isEmpty {
          changes[uri] = editsForUri
        }
      }
    }
    var edits = renameResult.edits
    edits.changes = changes
    return edits
  }

  func prepareRename(
    _ request: PrepareRenameRequest,
    workspace: Workspace,
    languageService: ToolchainLanguageServer
  ) async throws -> PrepareRenameResponse? {
    try await languageService.prepareRename(request)
  }
}

// MARK: - Swift

extension SwiftLanguageServer {
  /// From a list of rename locations compute the list of `SyntacticRenameName`s that define which ranges need to be
  /// edited to rename a compound decl name.
  ///
  /// - Parameters:
  ///   - renameLocations: The locations to rename
  ///   - oldName: The compound decl name that the declaration had before the rename. Used to verify that the rename
  ///     locations match that name. Eg. `myFunc(argLabel:otherLabel:)` or `myVar`
  ///   - snapshot: A `DocumentSnapshot` containing the contents of the file for which to compute the rename ranges.
  private func getSyntacticRenameRanges(
    renameLocations: [RenameLocation],
    oldName: String,
    in snapshot: DocumentSnapshot
  ) async throws -> [SyntacticRenameName] {
    let locations = sourcekitd.array(
      renameLocations.map { renameLocation in
        sourcekitd.dictionary([
          keys.line: renameLocation.line,
          keys.column: renameLocation.utf8Column,
          keys.nameType: renameLocation.usage.uid(keys: keys),
        ])
      }
    )
    let renameLocation = sourcekitd.dictionary([
      keys.locations: locations,
      keys.name: oldName,
    ])

    let skreq = sourcekitd.dictionary([
      keys.request: requests.find_syntactic_rename_ranges,
      keys.sourcefile: snapshot.uri.pseudoPath,
      // find-syntactic-rename-ranges is a syntactic sourcekitd request that doesn't use the in-memory file snapshot.
      // We need to send the source text again.
      keys.sourcetext: snapshot.text,
      keys.renamelocations: [renameLocation],
    ])

    let syntacticRenameRangesResponse = try await sourcekitd.send(skreq, fileContents: snapshot.text)
    guard let categorizedRanges: SKDResponseArray = syntacticRenameRangesResponse[keys.categorizedranges] else {
      throw ResponseError.internalError("sourcekitd did not return categorized ranges")
    }

    return categorizedRanges.compactMap { SyntacticRenameName($0, in: snapshot, keys: keys) }
  }

  public func rename(_ request: RenameRequest) async throws -> (edits: WorkspaceEdit, usr: String?, oldName: String?) {
    let snapshot = try self.documentManager.latestSnapshot(request.textDocument.uri)

    let relatedIdentifiersResponse = try await self.relatedIdentifiers(
      at: request.position,
      in: snapshot,
      includeNonEditableBaseNames: true
    )
    guard let oldName = relatedIdentifiersResponse.name else {
      throw ResponseError.unknown("Running sourcekit-lsp with a version of sourcekitd that does not support rename")
    }

    try Task.checkCancellation()

    let renameLocations = relatedIdentifiersResponse.relatedIdentifiers.compactMap {
      (relatedIdentifier) -> RenameLocation? in
      let position = relatedIdentifier.range.lowerBound
      guard let utf8Column = snapshot.lineTable.utf8ColumnAt(line: position.line, utf16Column: position.utf16index)
      else {
        logger.fault("Unable to find UTF-8 column for \(position.line):\(position.utf16index)")
        return nil
      }
      return RenameLocation(line: position.line + 1, utf8Column: utf8Column + 1, usage: relatedIdentifier.usage)
    }

    try Task.checkCancellation()

    let edits = try await editsToRename(
      locations: renameLocations,
      in: snapshot,
      oldName: oldName,
      newName: request.newName
    )

    try Task.checkCancellation()

    let usr =
      (try? await self.symbolInfo(SymbolInfoRequest(textDocument: request.textDocument, position: request.position)))?
      .only?.usr

    return (edits: WorkspaceEdit(changes: [snapshot.uri: edits]), usr: usr, oldName: oldName)
  }

  /// Return the edit that needs to be performed for the given syntactic rename piece to rename it from
  /// `oldParameter` to `newParameter`.
  /// Returns `nil` if no edit needs to be performed.
  private func textEdit(
    for piece: SyntacticRenamePiece,
    in snapshot: DocumentSnapshot,
    oldParameter: CompoundDeclName.Parameter,
    newParameter: CompoundDeclName.Parameter
  ) -> TextEdit? {
    switch piece.kind {
    case .parameterName:
      if newParameter == .wildcard, piece.range.isEmpty, case .named(let oldParameterName) = oldParameter {
        // We are changing a named parameter to an unnamed one. If the parameter didn't have an internal parameter
        // name, we need to transfer the previously external parameter name to be the internal one.
        // E.g. `func foo(a: Int)` becomes `func foo(_ a: Int)`.
        return TextEdit(range: piece.range, newText: " " + oldParameterName)
      }
      if let original = snapshot.lineTable[piece.range],
        case .named(let newParameterLabel) = newParameter,
        newParameterLabel.trimmingCharacters(in: .whitespaces) == original.trimmingCharacters(in: .whitespaces)
      {
        // We are changing the external parameter name to be the same one as the internal parameter name. The
        // internal name is thus no longer needed. Drop it.
        // Eg. an old declaration `func foo(_ a: Int)` becomes `func foo(a: Int)` when renaming the parameter to `a`
        return TextEdit(range: piece.range, newText: "")
      }
      // In all other cases, don't touch the internal parameter name. It's not part of the public API.
      return nil
    case .noncollapsibleParameterName:
      // Noncollapsible parameter names should never be renamed because they are the same as `parameterName` but
      // never fall into one of the two categories above.
      return nil
    case .declArgumentLabel:
      if piece.range.isEmpty {
        // If we are inserting a new external argument label where there wasn't one before, add a space after it to
        // separate it from the internal name.
        // E.g. `subscript(a: Int)` becomes `subscript(a a: Int)`.
        return TextEdit(range: piece.range, newText: newParameter.stringOrWildcard + " ")
      }
      // Otherwise, just update the name.
      return TextEdit(range: piece.range, newText: newParameter.stringOrWildcard)
    case .callArgumentLabel:
      // Argument labels of calls are just updated.
      return TextEdit(range: piece.range, newText: newParameter.stringOrEmpty)
    case .callArgumentColon:
      if case .wildcard = newParameter {
        // If the parameter becomes unnamed, remove the colon after the argument name.
        return TextEdit(range: piece.range, newText: "")
      }
      return nil
    case .callArgumentCombined:
      if case .named(let newParameterName) = newParameter {
        // If an unnamed parameter becomes named, insert the new name and a colon.
        return TextEdit(range: piece.range, newText: newParameterName + ": ")
      }
      return nil
    case .selectorArgumentLabel:
      return TextEdit(range: piece.range, newText: newParameter.stringOrWildcard)
    case .baseName, .keywordBaseName:
      preconditionFailure("Handled above")
    }
  }

  public func editsToRename(
    locations renameLocations: [RenameLocation],
    in snapshot: DocumentSnapshot,
    oldName oldNameString: String,
    newName newNameString: String
  ) async throws -> [TextEdit] {
    let compoundRenameRanges = try await getSyntacticRenameRanges(
      renameLocations: renameLocations,
      oldName: oldNameString,
      in: snapshot
    )
    let oldName = CompoundDeclName(oldNameString)
    let newName = CompoundDeclName(newNameString)

    try Task.checkCancellation()

    return compoundRenameRanges.flatMap { (compoundRenameRange) -> [TextEdit] in
      switch compoundRenameRange.category {
      case .unmatched, .mismatch:
        // The location didn't match. Don't rename it
        return []
      case .activeCode, .inactiveCode, .selector:
        // Occurrences in active code and selectors should always be renamed.
        // Inactive code is currently never returned by sourcekitd.
        break
      case .string, .comment:
        // We currently never get any results in strings or comments because the related identifiers request doesn't
        // provide any locations inside strings or comments. We would need to have a textual index to find these
        // locations.
        return []
      }
      return compoundRenameRange.pieces.compactMap { (piece) -> TextEdit? in
        if piece.kind == .baseName {
          return TextEdit(range: piece.range, newText: newName.baseName)
        } else if piece.kind == .keywordBaseName {
          // Keyword base names can't be renamed
          return nil
        }

        guard let parameterIndex = piece.parameterIndex,
          parameterIndex < newName.parameters.count,
          parameterIndex < oldName.parameters.count
        else {
          // Be lenient and just keep the old parameter names if the new name doesn't specify them, eg. if we are
          // renaming `func foo(a: Int, b: Int)` and the user specified `bar(x:)` as the new name.
          return nil
        }

        return self.textEdit(
          for: piece,
          in: snapshot,
          oldParameter: oldName.parameters[parameterIndex],
          newParameter: newName.parameters[parameterIndex]
        )
      }
    }
  }

  public func prepareRename(_ request: PrepareRenameRequest) async throws -> PrepareRenameResponse? {
    let snapshot = try self.documentManager.latestSnapshot(request.textDocument.uri)

    let response = try await self.relatedIdentifiers(
      at: request.position,
      in: snapshot,
      includeNonEditableBaseNames: true
    )
    guard let name = response.name else {
      throw ResponseError.unknown("Running sourcekit-lsp with a version of sourcekitd that does not support rename")
    }
    guard let range = response.relatedIdentifiers.first(where: { $0.range.contains(request.position) })?.range
    else {
      return nil
    }
    return PrepareRenameResponse(
      range: range,
      placeholder: name
    )
  }
}

// MARK: - Clang

extension ClangLanguageServerShim {
  func rename(_ renameRequest: RenameRequest) async throws -> (edits: WorkspaceEdit, usr: String?, oldName: String?) {
    async let edits = forwardRequestToClangd(renameRequest)
    let symbolInfoRequest = SymbolInfoRequest(
      textDocument: renameRequest.textDocument,
      position: renameRequest.position
    )
    let symbolDetail = try await forwardRequestToClangd(symbolInfoRequest).only
    return (try await edits ?? WorkspaceEdit(), symbolDetail?.usr, symbolDetail?.name)
  }

  func editsToRename(
    locations renameLocations: [RenameLocation],
    in snapshot: DocumentSnapshot,
    oldName: String,
    newName: String
  ) async throws -> [TextEdit] {
    let positions = [
      snapshot.uri: renameLocations.compactMap {
        snapshot.positionOf(zeroBasedLine: $0.line - 1, utf8Column: $0.utf8Column - 1)
      }
    ]
    let request = IndexedRenameRequest(
      textDocument: TextDocumentIdentifier(snapshot.uri),
      oldName: oldName,
      newName: newName,
      positions: positions
    )
    do {
      let edits = try await forwardRequestToClangd(request)
      return edits?.changes?[snapshot.uri] ?? []
    } catch {
      logger.error("Failed to get indexed rename edits: \(error.forLogging)")
      return []
    }
  }

  public func prepareRename(_ request: PrepareRenameRequest) async throws -> PrepareRenameResponse? {
    return nil
  }
}
