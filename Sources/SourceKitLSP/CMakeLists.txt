
add_library(SourceKitLSP STATIC
  CapabilityRegistry.swift
  DocumentManager.swift
  IndexStoreDB+MainFilesProvider.swift
  ResponseError+Init.swift
  Rename.swift
  Sequence+AsyncMap.swift
  SourceKitIndexDelegate.swift
  SourceKitLSPCommandMetadata.swift
  SourceKitServer.swift
  SourceKitServer+Options.swift
  TestDiscovery.swift
  ToolchainLanguageServer.swift
  Workspace.swift
)
target_sources(SourceKitLSP PRIVATE
  Clang/ClangLanguageServer.swift)
target_sources(SourceKitLSP PRIVATE
  Swift/CodeCompletion.swift
  Swift/CodeCompletionSession.swift
  Swift/CommentXML.swift
  Swift/CursorInfo.swift
  Swift/Diagnostic.swift
  Swift/DiagnosticReportManager.swift
  Swift/DocumentFormatting.swift
  Swift/DocumentSymbols.swift
  Swift/EditorPlaceholder.swift
  Swift/FoldingRange.swift
  Swift/OpenInterface.swift
  Swift/RelatedIdentifiers.swift
  Swift/SemanticRefactorCommand.swift
  Swift/SemanticRefactoring.swift
  Swift/SemanticTokens.swift
  Swift/SourceKitD+ResponseError.swift
  Swift/SwiftCommand.swift
  Swift/SwiftLanguageServer.swift
  Swift/SymbolInfo.swift
  Swift/SyntaxHighlightingToken.swift
  Swift/SyntaxHighlightingTokenParser.swift
  Swift/SyntaxTreeManager.swift
  Swift/VariableTypeInfo.swift
)
set_target_properties(SourceKitLSP PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_Swift_MODULE_DIRECTORY})
# TODO(compnerd) reduce the exposure here, why is everything PUBLIC-ly linked?
target_link_libraries(SourceKitLSP PUBLIC
  BuildServerProtocol
  LanguageServerProtocol
  LanguageServerProtocolJSONRPC
  LSPLogging
  SKCore
  SKSupport
  SKSwiftPMWorkspace
  SourceKitD
  IndexStoreDB
  SwiftSyntax::SwiftBasicFormat
  SwiftSyntax::SwiftDiagnostics
  SwiftSyntax::SwiftIDEUtils
  SwiftSyntax::SwiftParser
  SwiftSyntax::SwiftParserDiagnostics
  SwiftSyntax::SwiftSyntax)
target_link_libraries(SourceKitLSP PRIVATE
  $<$<NOT:$<PLATFORM_ID:Darwin>>:FoundationXML>)

