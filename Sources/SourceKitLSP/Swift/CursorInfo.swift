//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import LanguageServerProtocol
import SourceKitD

/// Detailed information about a symbol under the cursor.
///
/// Wraps the information returned by sourcekitd's `cursor_info` request, such as symbol name, USR,
/// and declaration location. This is intended to only do lightweight processing of the data to make
/// it easier to use from Swift. Any expensive processing, such as parsing the XML strings, is
/// handled elsewhere.
struct CursorInfo {

  /// Information common between CursorInfo and SymbolDetails from the `symbolInfo` request, such as
  /// name and USR.
  var symbolInfo: SymbolDetails

  /// The annotated declaration XML string.
  var annotatedDeclaration: String?

  /// The documentation comment XML string. The schema is at
  /// https://github.com/apple/swift/blob/main/bindings/xml/comment-xml-schema.rng
  var documentationXML: String?

  /// The refactor actions available at this position.
  var refactorActions: [SemanticRefactorCommand]? = nil

  init(
    _ symbolInfo: SymbolDetails,
    annotatedDeclaration: String?,
    documentationXML: String?
  ) {
    self.symbolInfo = symbolInfo
    self.annotatedDeclaration = annotatedDeclaration
    self.documentationXML = documentationXML
  }

  init?(
    _ dict: SKDResponseDictionary,
    sourcekitd: some SourceKitD
  ) {
    let keys = sourcekitd.keys
    guard let kind: sourcekitd_uid_t = dict[keys.kind] else {
      // Nothing to report.
      return nil
    }

    var location: Location? = nil
    if let filepath: String = dict[keys.filepath],
      let line: Int = dict[keys.line],
      let column: Int = dict[keys.column]
    {
      let position = Position(
        line: line - 1,
        // FIXME: we need to convert the utf8/utf16 column, which may require reading the file!
        utf16index: column - 1
      )
      location = Location(uri: DocumentURI(URL(fileURLWithPath: filepath)), range: Range(position))
    }

    self.init(
      SymbolDetails(
        name: dict[keys.name],
        containerName: nil,
        usr: dict[keys.usr],
        bestLocalDeclaration: location,
        kind: kind.asSymbolKind(sourcekitd.values),
        isDynamic: dict[keys.isDynamic] ?? false,
        receiverUsrs: dict[keys.receivers]?.compactMap { $0[keys.usr] as String? } ?? []
      ),
      annotatedDeclaration: dict[keys.annotated_decl],
      documentationXML: dict[keys.doc_full_as_xml]
    )
  }
}

/// An error from a cursor info request.
enum CursorInfoError: Error, Equatable {
  /// The given range is not valid in the document snapshot.
  case invalidRange(Range<Position>)

  /// The underlying sourcekitd request failed with the given error.
  case responseError(ResponseError)
}

extension CursorInfoError: CustomStringConvertible {
  var description: String {
    switch self {
    case .invalidRange(let range):
      return "invalid range \(range)"
    case .responseError(let error):
      return "\(error)"
    }
  }
}

extension SwiftLanguageServer {

  /// Provides detailed information about a symbol under the cursor, if any.
  ///
  /// Wraps the information returned by sourcekitd's `cursor_info` request, such as symbol name,
  /// USR, and declaration location. This request does minimal processing of the result.
  ///
  /// - Parameters:
  ///   - url: Document URL in which to perform the request. Must be an open document.
  ///   - range: The position range within the document to lookup the symbol at.
  ///   - completion: Completion block to asynchronously receive the CursorInfo, or error.
  func cursorInfo(
    _ uri: DocumentURI,
    _ range: Range<Position>,
    additionalParameters appendAdditionalParameters: ((SKDRequestDictionary) -> Void)? = nil
  ) async throws -> (cursorInfo: [CursorInfo], refactorActions: [SemanticRefactorCommand]) {
    let snapshot = try documentManager.latestSnapshot(uri)

    guard let offsetRange = snapshot.utf8OffsetRange(of: range) else {
      throw CursorInfoError.invalidRange(range)
    }

    let keys = self.keys

    let skreq = sourcekitd.dictionary([
      keys.request: requests.cursorinfo,
      keys.cancelOnSubsequentRequest: 0,
      keys.offset: offsetRange.lowerBound,
      keys.length: offsetRange.upperBound != offsetRange.lowerBound ? offsetRange.count : nil,
      keys.sourcefile: snapshot.uri.pseudoPath,
      keys.compilerargs: await self.buildSettings(for: uri)?.compilerArgs as [SKDValue]?,
    ])

    appendAdditionalParameters?(skreq)

    let dict = try await self.sourcekitd.send(skreq, fileContents: snapshot.text)

    var cursorInfoResults: [CursorInfo] = []
    if let cursorInfo = CursorInfo(dict, sourcekitd: sourcekitd) {
      cursorInfoResults.append(cursorInfo)
    }
    cursorInfoResults += dict[keys.secondarySymbols]?.compactMap { CursorInfo($0, sourcekitd: sourcekitd) } ?? []
    let refactorActions =
      [SemanticRefactorCommand](
        array: dict[keys.refactor_actions],
        range: range,
        textDocument: TextDocumentIdentifier(uri),
        keys,
        self.sourcekitd.api
      ) ?? []
    return (cursorInfoResults, refactorActions)
  }
}
