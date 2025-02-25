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

import LSPLogging
import LSPTestSupport
import LanguageServerProtocol
import SKTestSupport
import SourceKitLSP
import XCTest

final class FormattingTests: XCTestCase {
  func testFormatting() async throws {
    let testClient = try await TestSourceKitLSPClient()
    let uri = DocumentURI.for(.swift)

    let positions = testClient.openDocument(
      """
      struct S {
      1️⃣var foo: 2️⃣ 3️⃣Int
      4️⃣var bar: Int
      }5️⃣
      """,
      uri: uri
    )

    let response = try await testClient.send(
      DocumentFormattingRequest(
        textDocument: TextDocumentIdentifier(uri),
        options: FormattingOptions(tabSize: 3, insertSpaces: true)
      )
    )

    let edits = try XCTUnwrap(response)
    XCTAssertEqual(
      edits,
      [
        TextEdit(range: positions["2️⃣"]..<positions["3️⃣"], newText: ""),
        TextEdit(range: Range(positions["1️⃣"]), newText: "   "),
        TextEdit(range: Range(positions["4️⃣"]), newText: "   "),
        TextEdit(range: Range(positions["5️⃣"]), newText: "\n"),
      ]
    )
  }

  func testFormattingNoEdits() async throws {
    let testClient = try await TestSourceKitLSPClient()
    let uri = DocumentURI.for(.swift)

    testClient.openDocument(
      """
      struct S {
        var foo: Int
      }

      """,
      uri: uri
    )

    let response = try await testClient.send(
      DocumentFormattingRequest(
        textDocument: TextDocumentIdentifier(uri),
        options: FormattingOptions(tabSize: 2, insertSpaces: true)
      )
    )

    let edits = try XCTUnwrap(response)
    XCTAssertEqual(edits.count, 0)
  }

  func testConfigFileOnDisk() async throws {
    // We pick up an invalid swift-format configuration file and thus don't set the user-provided options.
    let ws = try await MultiFileTestWorkspace(files: [
      ".swift-format": """
      {
        "version": 1,
        "indentation": {
          "spaces": 1
        }
      }
      """,
      "test.swift": """
      struct Root {
      1️⃣var bar = 123
      }

      """,
    ])
    let (uri, positions) = try ws.openDocument("test.swift")

    let response = try await ws.testClient.send(
      DocumentFormattingRequest(
        textDocument: TextDocumentIdentifier(uri),
        options: FormattingOptions(tabSize: 2, insertSpaces: true)
      )
    )
    XCTAssertEqual(
      response,
      [
        TextEdit(range: Range(positions["1️⃣"]), newText: " ")
      ]
    )
  }

  func testConfigFileInParentDirectory() async throws {
    // We pick up an invalid swift-format configuration file and thus don't set the user-provided options.
    let ws = try await MultiFileTestWorkspace(files: [
      ".swift-format": """
      {
        "version": 1,
        "indentation": {
          "spaces": 1
        }
      }
      """,
      "sub/test.swift": """
      struct Root {
      1️⃣var bar = 123
      }

      """,
    ])
    let (uri, positions) = try ws.openDocument("test.swift")

    let response = try await ws.testClient.send(
      DocumentFormattingRequest(
        textDocument: TextDocumentIdentifier(uri),
        options: FormattingOptions(tabSize: 2, insertSpaces: true)
      )
    )
    XCTAssertEqual(
      response,
      [
        TextEdit(range: Range(positions["1️⃣"]), newText: " ")
      ]
    )
  }

  func testConfigFileInNestedDirectory() async throws {
    // We pick up an invalid swift-format configuration file and thus don't set the user-provided options.
    let ws = try await MultiFileTestWorkspace(files: [
      ".swift-format": """
      {
        "version": 1,
        "indentation": {
          "spaces": 1
        }
      },
      """,
      "sub/.swift-format": """
      {
        "version": 1,
        "indentation": {
          "spaces": 3
        }
      }
      """,
      "sub/test.swift": """
      struct Root {
      1️⃣var bar = 123
      }

      """,
    ])
    let (uri, positions) = try ws.openDocument("test.swift")

    let response = try await ws.testClient.send(
      DocumentFormattingRequest(
        textDocument: TextDocumentIdentifier(uri),
        options: FormattingOptions(tabSize: 2, insertSpaces: true)
      )
    )
    XCTAssertEqual(
      response,
      [
        TextEdit(range: Range(positions["1️⃣"]), newText: "   ")
      ]
    )
  }

  func testInvalidConfigurationFile() async throws {
    // We pick up an invalid swift-format configuration file and thus don't set the user-provided options.
    // The swift-format default is 2 spaces.
    let ws = try await MultiFileTestWorkspace(files: [
      ".swift-format": "",
      "test.swift": """
      struct Root {
      1️⃣var bar = 123
      }

      """,
    ])
    let (uri, _) = try ws.openDocument("test.swift")

    await assertThrowsError(
      try await ws.testClient.send(
        DocumentFormattingRequest(
          textDocument: TextDocumentIdentifier(uri),
          options: FormattingOptions(tabSize: 3, insertSpaces: true)
        )
      )
    )
  }
}
