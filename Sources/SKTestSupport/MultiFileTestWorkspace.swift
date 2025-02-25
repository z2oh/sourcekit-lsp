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

import Foundation
import LanguageServerProtocol
import SKCore

/// The location of a test file within test workspace.
public struct RelativeFileLocation: Hashable, ExpressibleByStringLiteral {
  /// The subdirectories in which the file is located.
  public let directories: [String]

  /// The file's name.
  public let fileName: String

  public init(directories: [String] = [], _ fileName: String) {
    self.directories = directories
    self.fileName = fileName
  }

  public init(stringLiteral value: String) {
    let components = value.components(separatedBy: "/")
    self.init(directories: components.dropLast(), components.last!)
  }
}

/// A workspace that writes multiple files to disk and opens a `TestSourceKitLSPClient` client with a workspace pointing
/// to a temporary directory containing those files.
///
/// The temporary files will be deleted when the `TestSourceKitLSPClient` is destructed.
public class MultiFileTestWorkspace {
  /// Information necessary to open a file in the LSP server by its filename.
  private struct FileData {
    /// The URI at which the file is stored on disk.
    let uri: DocumentURI

    /// The contents of the file including location markers.
    let markedText: String
  }

  public let testClient: TestSourceKitLSPClient

  /// Information necessary to open a file in the LSP server by its filename.
  private let fileData: [String: FileData]

  enum Error: Swift.Error {
    /// No file with the given filename is known to the `SwiftPMTestWorkspace`.
    case fileNotFound
  }

  /// The directory in which the temporary files are being placed.
  public let scratchDirectory: URL

  /// Writes the specified files to a temporary directory on disk and creates a `TestSourceKitLSPClient` for that
  /// temporary directory.
  ///
  /// The file contents can contain location markers, which are returned when opening a document using
  /// ``openDocument(_:)``.
  ///
  /// File contents can also contain `$TEST_DIR`, which gets replaced by the temporary directory.
  public init(
    files: [RelativeFileLocation: String],
    workspaces: (URL) -> [WorkspaceFolder] = { [WorkspaceFolder(uri: DocumentURI($0))] },
    testName: String = #function
  ) async throws {
    scratchDirectory = try testScratchDir(testName: testName)
    try FileManager.default.createDirectory(at: scratchDirectory, withIntermediateDirectories: true)

    var fileData: [String: FileData] = [:]
    for (fileLocation, markedText) in files {
      let markedText = markedText.replacingOccurrences(of: "$TEST_DIR", with: scratchDirectory.path)
      var fileURL = scratchDirectory
      for directory in fileLocation.directories {
        fileURL = fileURL.appendingPathComponent(directory)
      }
      fileURL = fileURL.appendingPathComponent(fileLocation.fileName)
      try FileManager.default.createDirectory(
        at: fileURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
      )
      try extractMarkers(markedText).textWithoutMarkers.write(to: fileURL, atomically: false, encoding: .utf8)

      if fileData[fileLocation.fileName] != nil {
        // If we already have a file with this name, remove its data. That way we can't reference any of the two
        // conflicting documents and will throw when trying to open them, instead of non-deterministically picking one.
        fileData[fileLocation.fileName] = nil
      } else {
        fileData[fileLocation.fileName] = FileData(
          uri: DocumentURI(fileURL),
          markedText: markedText
        )
      }
    }
    self.fileData = fileData

    self.testClient = try await TestSourceKitLSPClient(
      workspaceFolders: workspaces(scratchDirectory),
      cleanUp: { [scratchDirectory] in
        if cleanScratchDirectories {
          try? FileManager.default.removeItem(at: scratchDirectory)
        }
      }
    )
  }

  /// Opens the document with the given file name in the SourceKit-LSP server.
  ///
  /// - Returns: The URI for the opened document and the positions of the location markers.
  public func openDocument(_ fileName: String, language: Language? = nil) throws -> (
    uri: DocumentURI, positions: DocumentPositions
  ) {
    guard let fileData = self.fileData[fileName] else {
      throw Error.fileNotFound
    }
    let positions = testClient.openDocument(fileData.markedText, uri: fileData.uri, language: language)
    return (fileData.uri, positions)
  }

  /// Returns the URI of the file with the given name.
  public func uri(for fileName: String) throws -> DocumentURI {
    guard let fileData = self.fileData[fileName] else {
      throw Error.fileNotFound
    }
    return fileData.uri
  }

  /// Returns the position of the given marker in the given file.
  public func position(of marker: String, in fileName: String) throws -> Position {
    guard let fileData = self.fileData[fileName] else {
      throw Error.fileNotFound
    }
    return DocumentPositions(markedText: fileData.markedText)[marker]
  }
}
