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

import Csourcekitd

public struct sourcekitd_keys {
  public let actionname: sourcekitd_uid_t
  public let actionuid: sourcekitd_uid_t
  public let annotated_decl: sourcekitd_uid_t
  public let annotations: sourcekitd_uid_t
  public let argindex: sourcekitd_uid_t
  public let associated_usrs: sourcekitd_uid_t
  public let bodylength: sourcekitd_uid_t
  public let bodyoffset: sourcekitd_uid_t
  public let cancelOnSubsequentRequest: sourcekitd_uid_t
  public let categories: sourcekitd_uid_t
  public let categorizededits: sourcekitd_uid_t
  public let categorizedranges: sourcekitd_uid_t
  public let category: sourcekitd_uid_t
  public let column: sourcekitd_uid_t
  public let compilerargs: sourcekitd_uid_t
  public let context: sourcekitd_uid_t
  public let description: sourcekitd_uid_t
  public let diagnostic_stage: sourcekitd_uid_t
  public let diagnostics: sourcekitd_uid_t
  public let doc_brief: sourcekitd_uid_t
  public let doc_full_as_xml: sourcekitd_uid_t
  public let edits: sourcekitd_uid_t
  public let educational_note_paths: sourcekitd_uid_t
  public let enablesyntaxmap: sourcekitd_uid_t
  public let endcolumn: sourcekitd_uid_t
  public let endline: sourcekitd_uid_t
  public let expression_length: sourcekitd_uid_t
  public let expression_offset: sourcekitd_uid_t
  public let expression_type_list: sourcekitd_uid_t
  public let expression_type: sourcekitd_uid_t
  public let filepath: sourcekitd_uid_t
  public let fixits: sourcekitd_uid_t
  public let groupname: sourcekitd_uid_t
  public let id: sourcekitd_uid_t
  public let includeNonEditableBaseNames: sourcekitd_uid_t
  public let is_system: sourcekitd_uid_t
  public let isDynamic: sourcekitd_uid_t
  public let kind: sourcekitd_uid_t
  public let length: sourcekitd_uid_t
  public let line: sourcekitd_uid_t
  public let locations: sourcekitd_uid_t
  public let modulename: sourcekitd_uid_t
  public let name: sourcekitd_uid_t
  public let namelength: sourcekitd_uid_t
  public let nameoffset: sourcekitd_uid_t
  public let nameType: sourcekitd_uid_t
  public let not_recommended: sourcekitd_uid_t
  public let notification: sourcekitd_uid_t
  public let num_bytes_to_erase: sourcekitd_uid_t
  public let offset: sourcekitd_uid_t
  public let ranges: sourcekitd_uid_t
  public let receivers: sourcekitd_uid_t
  public let refactor_actions: sourcekitd_uid_t
  public let renamelocations: sourcekitd_uid_t
  public let renameRangeBase: sourcekitd_uid_t
  public let renameRangeCallArgColon: sourcekitd_uid_t
  public let renameRangeCallArgCombined: sourcekitd_uid_t
  public let renameRangeCallArgLabel: sourcekitd_uid_t
  public let renameRangeDeclArgLabel: sourcekitd_uid_t
  public let renameRangeKeywordBase: sourcekitd_uid_t
  public let renameRangeNoncollapsibleParam: sourcekitd_uid_t
  public let renameRangeParam: sourcekitd_uid_t
  public let renameRangeSelectorArgLabel: sourcekitd_uid_t
  public let request: sourcekitd_uid_t
  public let results: sourcekitd_uid_t
  public let retrieve_refactor_actions: sourcekitd_uid_t
  public let secondarySymbols: sourcekitd_uid_t
  public let semantic_tokens: sourcekitd_uid_t
  public let severity: sourcekitd_uid_t
  public let sourceEditKindActive: sourcekitd_uid_t
  public let sourceEditKindComment: sourcekitd_uid_t
  public let sourceEditKindInactive: sourcekitd_uid_t
  public let sourceEditKindMismatch: sourcekitd_uid_t
  public let sourceEditKindSelector: sourcekitd_uid_t
  public let sourceEditKindString: sourcekitd_uid_t
  public let sourceEditKindUnknown: sourcekitd_uid_t
  public let sourcefile: sourcekitd_uid_t
  public let sourcetext: sourcekitd_uid_t
  public let substructure: sourcekitd_uid_t
  public let syntactic_only: sourcekitd_uid_t
  public let syntacticRenameCall: sourcekitd_uid_t
  public let syntacticRenameDefinition: sourcekitd_uid_t
  public let syntacticRenameReference: sourcekitd_uid_t
  public let syntacticRenameUnknown: sourcekitd_uid_t
  public let syntaxmap: sourcekitd_uid_t
  public let synthesizedextensions: sourcekitd_uid_t
  public let text: sourcekitd_uid_t
  public let typename: sourcekitd_uid_t
  public let usr: sourcekitd_uid_t
  public let variable_length: sourcekitd_uid_t
  public let variable_offset: sourcekitd_uid_t
  public let variable_type_explicit: sourcekitd_uid_t
  public let variable_type_list: sourcekitd_uid_t
  public let variable_type: sourcekitd_uid_t

  // Code Completion options.
  public let codecomplete_options: sourcekitd_uid_t
  public let codecomplete_sort_byname: sourcekitd_uid_t
  public let codecomplete_filtertext: sourcekitd_uid_t
  public let codecomplete_requestlimit: sourcekitd_uid_t
  public let codecomplete_hideunderscores: sourcekitd_uid_t
  public let codecomplete_hidelowpriority: sourcekitd_uid_t
  public let codecomplete_hidebyname: sourcekitd_uid_t
  public let codecomplete_addinneroperators: sourcekitd_uid_t
  public let codecomplete_callpatternheuristics: sourcekitd_uid_t
  public let codecomplete_showtopnonliteralresults: sourcekitd_uid_t

  public init(api: sourcekitd_functions_t) {
    actionname = api.uid_get_from_cstr("key.actionname")!
    actionuid = api.uid_get_from_cstr("key.actionuid")!
    annotated_decl = api.uid_get_from_cstr("key.annotated_decl")!
    annotations = api.uid_get_from_cstr("key.annotations")!
    argindex = api.uid_get_from_cstr("key.argindex")!
    associated_usrs = api.uid_get_from_cstr("key.associated_usrs")!
    bodylength = api.uid_get_from_cstr("key.bodylength")!
    bodyoffset = api.uid_get_from_cstr("key.bodyoffset")!
    cancelOnSubsequentRequest = api.uid_get_from_cstr("key.cancel_on_subsequent_request")!
    categories = api.uid_get_from_cstr("key.categories")!
    category = api.uid_get_from_cstr("key.category")!
    categorizededits = api.uid_get_from_cstr("key.categorizededits")!
    categorizedranges = api.uid_get_from_cstr("key.categorizedranges")!
    column = api.uid_get_from_cstr("key.column")!
    compilerargs = api.uid_get_from_cstr("key.compilerargs")!
    context = api.uid_get_from_cstr("key.context")!
    description = api.uid_get_from_cstr("key.description")!
    diagnostic_stage = api.uid_get_from_cstr("key.diagnostic_stage")!
    diagnostics = api.uid_get_from_cstr("key.diagnostics")!
    doc_brief = api.uid_get_from_cstr("key.doc.brief")!
    doc_full_as_xml = api.uid_get_from_cstr("key.doc.full_as_xml")!
    edits = api.uid_get_from_cstr("key.edits")!
    educational_note_paths = api.uid_get_from_cstr("key.educational_note_paths")!
    enablesyntaxmap = api.uid_get_from_cstr("key.enablesyntaxmap")!
    endcolumn = api.uid_get_from_cstr("key.endcolumn")!
    endline = api.uid_get_from_cstr("key.endline")!
    expression_length = api.uid_get_from_cstr("key.expression_length")!
    expression_offset = api.uid_get_from_cstr("key.expression_offset")!
    expression_type = api.uid_get_from_cstr("key.expression_type")!
    expression_type_list = api.uid_get_from_cstr("key.expression_type_list")!
    filepath = api.uid_get_from_cstr("key.filepath")!
    fixits = api.uid_get_from_cstr("key.fixits")!
    groupname = api.uid_get_from_cstr("key.groupname")!
    id = api.uid_get_from_cstr("key.id")!
    includeNonEditableBaseNames = api.uid_get_from_cstr("key.include_non_editable_base_names")!
    is_system = api.uid_get_from_cstr("key.is_system")!
    isDynamic = api.uid_get_from_cstr("key.is_dynamic")!
    kind = api.uid_get_from_cstr("key.kind")!
    length = api.uid_get_from_cstr("key.length")!
    line = api.uid_get_from_cstr("key.line")!
    locations = api.uid_get_from_cstr("key.locations")!
    modulename = api.uid_get_from_cstr("key.modulename")!
    name = api.uid_get_from_cstr("key.name")!
    namelength = api.uid_get_from_cstr("key.namelength")!
    nameoffset = api.uid_get_from_cstr("key.nameoffset")!
    nameType = api.uid_get_from_cstr("key.nametype")!
    not_recommended = api.uid_get_from_cstr("key.not_recommended")!
    notification = api.uid_get_from_cstr("key.notification")!
    num_bytes_to_erase = api.uid_get_from_cstr("key.num_bytes_to_erase")!
    offset = api.uid_get_from_cstr("key.offset")!
    ranges = api.uid_get_from_cstr("key.ranges")!
    receivers = api.uid_get_from_cstr("key.receivers")!
    refactor_actions = api.uid_get_from_cstr("key.refactor_actions")!
    renamelocations = api.uid_get_from_cstr("key.renamelocations")!
    renameRangeBase = api.uid_get_from_cstr("source.refactoring.range.kind.basename")!
    renameRangeCallArgColon = api.uid_get_from_cstr("source.refactoring.range.kind.call-argument-colon")!
    renameRangeCallArgCombined = api.uid_get_from_cstr("source.refactoring.range.kind.call-argument-combined")!
    renameRangeCallArgLabel = api.uid_get_from_cstr("source.refactoring.range.kind.call-argument-label")!
    renameRangeDeclArgLabel = api.uid_get_from_cstr("source.refactoring.range.kind.decl-argument-label")!
    renameRangeKeywordBase = api.uid_get_from_cstr("source.refactoring.range.kind.keyword-basename")!
    renameRangeNoncollapsibleParam = api.uid_get_from_cstr("source.refactoring.range.kind.noncollapsible-parameter")!
    renameRangeParam = api.uid_get_from_cstr("source.refactoring.range.kind.parameter-and-whitespace")!
    renameRangeSelectorArgLabel = api.uid_get_from_cstr("source.refactoring.range.kind.selector-argument-label")!
    request = api.uid_get_from_cstr("key.request")!
    results = api.uid_get_from_cstr("key.results")!
    retrieve_refactor_actions = api.uid_get_from_cstr("key.retrieve_refactor_actions")!
    secondarySymbols = api.uid_get_from_cstr("key.secondary_symbols")!
    semantic_tokens = api.uid_get_from_cstr("key.semantic_tokens")!
    severity = api.uid_get_from_cstr("key.severity")!
    sourceEditKindActive = api.uid_get_from_cstr("source.edit.kind.active")!
    sourceEditKindComment = api.uid_get_from_cstr("source.edit.kind.comment")!
    sourceEditKindInactive = api.uid_get_from_cstr("source.edit.kind.inactive")!
    sourceEditKindMismatch = api.uid_get_from_cstr("source.edit.kind.mismatch")!
    sourceEditKindSelector = api.uid_get_from_cstr("source.edit.kind.selector")!
    sourceEditKindString = api.uid_get_from_cstr("source.edit.kind.string")!
    sourceEditKindUnknown = api.uid_get_from_cstr("source.edit.kind.unknown")!
    sourcefile = api.uid_get_from_cstr("key.sourcefile")!
    sourcetext = api.uid_get_from_cstr("key.sourcetext")!
    substructure = api.uid_get_from_cstr("key.substructure")!
    syntactic_only = api.uid_get_from_cstr("key.syntactic_only")!
    syntacticRenameCall = api.uid_get_from_cstr("source.syntacticrename.call")!
    syntacticRenameDefinition = api.uid_get_from_cstr("source.syntacticrename.definition")!
    syntacticRenameReference = api.uid_get_from_cstr("source.syntacticrename.reference")!
    syntacticRenameUnknown = api.uid_get_from_cstr("source.syntacticrename.unknown")!
    syntaxmap = api.uid_get_from_cstr("key.syntaxmap")!
    synthesizedextensions = api.uid_get_from_cstr("key.synthesizedextensions")!
    text = api.uid_get_from_cstr("key.text")!
    typename = api.uid_get_from_cstr("key.typename")!
    usr = api.uid_get_from_cstr("key.usr")!
    variable_length = api.uid_get_from_cstr("key.variable_length")!
    variable_offset = api.uid_get_from_cstr("key.variable_offset")!
    variable_type = api.uid_get_from_cstr("key.variable_type")!
    variable_type_explicit = api.uid_get_from_cstr("key.variable_type_explicit")!
    variable_type_list = api.uid_get_from_cstr("key.variable_type_list")!

    // Code Completion options
    codecomplete_options = api.uid_get_from_cstr("key.codecomplete.options")!
    codecomplete_sort_byname = api.uid_get_from_cstr("key.codecomplete.sort.byname")!
    codecomplete_filtertext = api.uid_get_from_cstr("key.codecomplete.filtertext")!
    codecomplete_requestlimit = api.uid_get_from_cstr("key.codecomplete.requestlimit")!
    codecomplete_hideunderscores = api.uid_get_from_cstr("key.codecomplete.hideunderscores")!
    codecomplete_hidelowpriority = api.uid_get_from_cstr("key.codecomplete.hidelowpriority")!
    codecomplete_hidebyname = api.uid_get_from_cstr("key.codecomplete.hidebyname")!
    codecomplete_addinneroperators = api.uid_get_from_cstr("key.codecomplete.addinneroperators")!
    codecomplete_callpatternheuristics = api.uid_get_from_cstr("key.codecomplete.callpatternheuristics")!
    codecomplete_showtopnonliteralresults = api.uid_get_from_cstr("key.codecomplete.showtopnonliteralresults")!
  }
}

public struct sourcekitd_requests {
  public let crash_exit: sourcekitd_uid_t
  public let editor_open: sourcekitd_uid_t
  public let editor_open_interface: sourcekitd_uid_t
  public let editor_close: sourcekitd_uid_t
  public let editor_replacetext: sourcekitd_uid_t
  public let codecomplete: sourcekitd_uid_t
  public let codecomplete_open: sourcekitd_uid_t
  public let codecomplete_update: sourcekitd_uid_t
  public let codecomplete_close: sourcekitd_uid_t
  public let cursorinfo: sourcekitd_uid_t
  public let diagnostics: sourcekitd_uid_t
  public let semantic_tokens: sourcekitd_uid_t
  public let expression_type: sourcekitd_uid_t
  public let find_usr: sourcekitd_uid_t
  public let variable_type: sourcekitd_uid_t
  public let relatedidents: sourcekitd_uid_t
  public let semantic_refactoring: sourcekitd_uid_t
  public let find_syntactic_rename_ranges: sourcekitd_uid_t

  public init(api: sourcekitd_functions_t) {
    crash_exit = api.uid_get_from_cstr("source.request.crash_exit")!
    editor_open = api.uid_get_from_cstr("source.request.editor.open")!
    editor_open_interface = api.uid_get_from_cstr("source.request.editor.open.interface")!
    editor_close = api.uid_get_from_cstr("source.request.editor.close")!
    editor_replacetext = api.uid_get_from_cstr("source.request.editor.replacetext")!
    codecomplete = api.uid_get_from_cstr("source.request.codecomplete")!
    codecomplete_open = api.uid_get_from_cstr("source.request.codecomplete.open")!
    codecomplete_update = api.uid_get_from_cstr("source.request.codecomplete.update")!
    codecomplete_close = api.uid_get_from_cstr("source.request.codecomplete.close")!
    cursorinfo = api.uid_get_from_cstr("source.request.cursorinfo")!
    diagnostics = api.uid_get_from_cstr("source.request.diagnostics")!
    semantic_tokens = api.uid_get_from_cstr("source.request.semantic_tokens")!
    expression_type = api.uid_get_from_cstr("source.request.expression.type")!
    find_usr = api.uid_get_from_cstr("source.request.editor.find_usr")!
    variable_type = api.uid_get_from_cstr("source.request.variable.type")!
    relatedidents = api.uid_get_from_cstr("source.request.relatedidents")!
    semantic_refactoring = api.uid_get_from_cstr("source.request.semantic.refactoring")!
    find_syntactic_rename_ranges = api.uid_get_from_cstr("source.request.find-syntactic-rename-ranges")!
  }
}

public struct sourcekitd_values {
  public let notification_documentupdate: sourcekitd_uid_t
  public let notification_sema_enabled: sourcekitd_uid_t
  public let diag_error: sourcekitd_uid_t
  public let diag_warning: sourcekitd_uid_t
  public let diag_note: sourcekitd_uid_t
  public let diag_category_deprecation: sourcekitd_uid_t
  public let diag_category_no_usage: sourcekitd_uid_t
  public let diag_stage_parse: sourcekitd_uid_t
  public let diag_stage_sema: sourcekitd_uid_t

  // MARK: Symbol Kinds

  public let decl_function_free: sourcekitd_uid_t
  public let ref_function_free: sourcekitd_uid_t
  public let decl_function_method_instance: sourcekitd_uid_t
  public let ref_function_method_instance: sourcekitd_uid_t
  public let decl_function_method_static: sourcekitd_uid_t
  public let ref_function_method_static: sourcekitd_uid_t
  public let decl_function_method_class: sourcekitd_uid_t
  public let ref_function_method_class: sourcekitd_uid_t
  public let decl_function_accessor_getter: sourcekitd_uid_t
  public let ref_function_accessor_getter: sourcekitd_uid_t
  public let decl_function_accessor_setter: sourcekitd_uid_t
  public let ref_function_accessor_setter: sourcekitd_uid_t
  public let decl_function_accessor_willset: sourcekitd_uid_t
  public let ref_function_accessor_willset: sourcekitd_uid_t
  public let decl_function_accessor_didset: sourcekitd_uid_t
  public let ref_function_accessor_didset: sourcekitd_uid_t
  public let decl_function_accessor_address: sourcekitd_uid_t
  public let ref_function_accessor_address: sourcekitd_uid_t
  public let decl_function_accessor_mutableaddress: sourcekitd_uid_t
  public let ref_function_accessor_mutableaddress: sourcekitd_uid_t
  public let decl_function_accessor_read: sourcekitd_uid_t
  public let ref_function_accessor_read: sourcekitd_uid_t
  public let decl_function_accessor_modify: sourcekitd_uid_t
  public let ref_function_accessor_modify: sourcekitd_uid_t
  public let decl_function_constructor: sourcekitd_uid_t
  public let ref_function_constructor: sourcekitd_uid_t
  public let decl_function_destructor: sourcekitd_uid_t
  public let ref_function_destructor: sourcekitd_uid_t
  public let decl_function_operator_prefix: sourcekitd_uid_t
  public let decl_function_operator_postfix: sourcekitd_uid_t
  public let decl_function_operator_infix: sourcekitd_uid_t
  public let ref_function_operator_prefix: sourcekitd_uid_t
  public let ref_function_operator_postfix: sourcekitd_uid_t
  public let ref_function_operator_infix: sourcekitd_uid_t
  public let decl_precedencegroup: sourcekitd_uid_t
  public let ref_precedencegroup: sourcekitd_uid_t
  public let decl_function_subscript: sourcekitd_uid_t
  public let ref_function_subscript: sourcekitd_uid_t
  public let decl_var_global: sourcekitd_uid_t
  public let ref_var_global: sourcekitd_uid_t
  public let decl_var_instance: sourcekitd_uid_t
  public let ref_var_instance: sourcekitd_uid_t
  public let decl_var_static: sourcekitd_uid_t
  public let ref_var_static: sourcekitd_uid_t
  public let decl_var_class: sourcekitd_uid_t
  public let ref_var_class: sourcekitd_uid_t
  public let decl_var_local: sourcekitd_uid_t
  public let ref_var_local: sourcekitd_uid_t
  public let decl_var_parameter: sourcekitd_uid_t
  public let decl_module: sourcekitd_uid_t
  public let decl_actor: sourcekitd_uid_t
  public let decl_class: sourcekitd_uid_t
  public let ref_actor: sourcekitd_uid_t
  public let ref_class: sourcekitd_uid_t
  public let decl_struct: sourcekitd_uid_t
  public let ref_struct: sourcekitd_uid_t
  public let decl_enum: sourcekitd_uid_t
  public let ref_enum: sourcekitd_uid_t
  public let decl_enumcase: sourcekitd_uid_t
  public let decl_enumelement: sourcekitd_uid_t
  public let ref_enumelement: sourcekitd_uid_t
  public let decl_protocol: sourcekitd_uid_t
  public let ref_protocol: sourcekitd_uid_t
  public let decl_extension: sourcekitd_uid_t
  public let decl_extension_struct: sourcekitd_uid_t
  public let decl_extension_class: sourcekitd_uid_t
  public let decl_extension_enum: sourcekitd_uid_t
  public let decl_extension_protocol: sourcekitd_uid_t
  public let decl_associatedtype: sourcekitd_uid_t
  public let ref_associatedtype: sourcekitd_uid_t
  public let decl_typealias: sourcekitd_uid_t
  public let ref_typealias: sourcekitd_uid_t
  public let decl_generic_type_param: sourcekitd_uid_t
  public let ref_generic_type_param: sourcekitd_uid_t
  public let ref_module: sourcekitd_uid_t
  public let syntaxtype_attribute_builtin: sourcekitd_uid_t
  public let syntaxtype_comment: sourcekitd_uid_t
  public let syntaxtype_comment_marker: sourcekitd_uid_t
  public let syntaxtype_comment_url: sourcekitd_uid_t
  public let syntaxtype_doccomment: sourcekitd_uid_t
  public let syntaxtype_doccomment_field: sourcekitd_uid_t
  public let syntaxtype_keyword: sourcekitd_uid_t
  public let syntaxtype_operator: sourcekitd_uid_t
  public let syntaxtype_number: sourcekitd_uid_t
  public let syntaxtype_string: sourcekitd_uid_t
  public let syntaxtype_string_interpolation_anchor: sourcekitd_uid_t
  public let syntaxtype_type_identifier: sourcekitd_uid_t
  public let syntaxtype_identifier: sourcekitd_uid_t
  public let expr_object_literal: sourcekitd_uid_t
  public let expr_call: sourcekitd_uid_t

  public let kind_keyword: sourcekitd_uid_t

  public init(api: sourcekitd_functions_t) {
    notification_documentupdate = api.uid_get_from_cstr("source.notification.editor.documentupdate")!
    notification_sema_enabled = api.uid_get_from_cstr("source.notification.sema_enabled")!
    diag_error = api.uid_get_from_cstr("source.diagnostic.severity.error")!
    diag_warning = api.uid_get_from_cstr("source.diagnostic.severity.warning")!
    diag_note = api.uid_get_from_cstr("source.diagnostic.severity.note")!
    diag_category_deprecation = api.uid_get_from_cstr("source.diagnostic.category.deprecation")!
    diag_category_no_usage = api.uid_get_from_cstr("source.diagnostic.category.no_usage")!
    diag_stage_parse = api.uid_get_from_cstr("source.diagnostic.stage.swift.parse")!
    diag_stage_sema = api.uid_get_from_cstr("source.diagnostic.stage.swift.sema")!

    // MARK: Symbol Kinds

    decl_function_free = api.uid_get_from_cstr("source.lang.swift.decl.function.free")!
    ref_function_free = api.uid_get_from_cstr("source.lang.swift.ref.function.free")!
    decl_function_method_instance = api.uid_get_from_cstr("source.lang.swift.decl.function.method.instance")!
    ref_function_method_instance = api.uid_get_from_cstr("source.lang.swift.ref.function.method.instance")!
    decl_function_method_static = api.uid_get_from_cstr("source.lang.swift.decl.function.method.static")!
    ref_function_method_static = api.uid_get_from_cstr("source.lang.swift.ref.function.method.static")!
    decl_function_method_class = api.uid_get_from_cstr("source.lang.swift.decl.function.method.class")!
    ref_function_method_class = api.uid_get_from_cstr("source.lang.swift.ref.function.method.class")!
    decl_function_accessor_getter = api.uid_get_from_cstr("source.lang.swift.decl.function.accessor.getter")!
    ref_function_accessor_getter = api.uid_get_from_cstr("source.lang.swift.ref.function.accessor.getter")!
    decl_function_accessor_setter = api.uid_get_from_cstr("source.lang.swift.decl.function.accessor.setter")!
    ref_function_accessor_setter = api.uid_get_from_cstr("source.lang.swift.ref.function.accessor.setter")!
    decl_function_accessor_willset = api.uid_get_from_cstr("source.lang.swift.decl.function.accessor.willset")!
    ref_function_accessor_willset = api.uid_get_from_cstr("source.lang.swift.ref.function.accessor.willset")!
    decl_function_accessor_didset = api.uid_get_from_cstr("source.lang.swift.decl.function.accessor.didset")!
    ref_function_accessor_didset = api.uid_get_from_cstr("source.lang.swift.ref.function.accessor.didset")!
    decl_function_accessor_address = api.uid_get_from_cstr("source.lang.swift.decl.function.accessor.address")!
    ref_function_accessor_address = api.uid_get_from_cstr("source.lang.swift.ref.function.accessor.address")!
    decl_function_accessor_mutableaddress = api.uid_get_from_cstr(
      "source.lang.swift.decl.function.accessor.mutableaddress"
    )!
    ref_function_accessor_mutableaddress = api.uid_get_from_cstr(
      "source.lang.swift.ref.function.accessor.mutableaddress"
    )!
    decl_function_accessor_read = api.uid_get_from_cstr("source.lang.swift.decl.function.accessor.read")!
    ref_function_accessor_read = api.uid_get_from_cstr("source.lang.swift.ref.function.accessor.read")!
    decl_function_accessor_modify = api.uid_get_from_cstr("source.lang.swift.decl.function.accessor.modify")!
    ref_function_accessor_modify = api.uid_get_from_cstr("source.lang.swift.ref.function.accessor.modify")!
    decl_function_constructor = api.uid_get_from_cstr("source.lang.swift.decl.function.constructor")!
    ref_function_constructor = api.uid_get_from_cstr("source.lang.swift.ref.function.constructor")!
    decl_function_destructor = api.uid_get_from_cstr("source.lang.swift.decl.function.destructor")!
    ref_function_destructor = api.uid_get_from_cstr("source.lang.swift.ref.function.destructor")!
    decl_function_operator_prefix = api.uid_get_from_cstr("source.lang.swift.decl.function.operator.prefix")!
    decl_function_operator_postfix = api.uid_get_from_cstr("source.lang.swift.decl.function.operator.postfix")!
    decl_function_operator_infix = api.uid_get_from_cstr("source.lang.swift.decl.function.operator.infix")!
    ref_function_operator_prefix = api.uid_get_from_cstr("source.lang.swift.ref.function.operator.prefix")!
    ref_function_operator_postfix = api.uid_get_from_cstr("source.lang.swift.ref.function.operator.postfix")!
    ref_function_operator_infix = api.uid_get_from_cstr("source.lang.swift.ref.function.operator.infix")!
    decl_precedencegroup = api.uid_get_from_cstr("source.lang.swift.decl.precedencegroup")!
    ref_precedencegroup = api.uid_get_from_cstr("source.lang.swift.ref.precedencegroup")!
    decl_function_subscript = api.uid_get_from_cstr("source.lang.swift.decl.function.subscript")!
    ref_function_subscript = api.uid_get_from_cstr("source.lang.swift.ref.function.subscript")!
    decl_var_global = api.uid_get_from_cstr("source.lang.swift.decl.var.global")!
    ref_var_global = api.uid_get_from_cstr("source.lang.swift.ref.var.global")!
    decl_var_instance = api.uid_get_from_cstr("source.lang.swift.decl.var.instance")!
    ref_var_instance = api.uid_get_from_cstr("source.lang.swift.ref.var.instance")!
    decl_var_static = api.uid_get_from_cstr("source.lang.swift.decl.var.static")!
    ref_var_static = api.uid_get_from_cstr("source.lang.swift.ref.var.static")!
    decl_var_class = api.uid_get_from_cstr("source.lang.swift.decl.var.class")!
    ref_var_class = api.uid_get_from_cstr("source.lang.swift.ref.var.class")!
    decl_var_local = api.uid_get_from_cstr("source.lang.swift.decl.var.local")!
    ref_var_local = api.uid_get_from_cstr("source.lang.swift.ref.var.local")!
    decl_var_parameter = api.uid_get_from_cstr("source.lang.swift.decl.var.parameter")!
    decl_module = api.uid_get_from_cstr("source.lang.swift.decl.module")!
    decl_actor = api.uid_get_from_cstr("source.lang.swift.decl.actor")!
    ref_actor = api.uid_get_from_cstr("source.lang.swift.ref.actor")!
    decl_class = api.uid_get_from_cstr("source.lang.swift.decl.class")!
    ref_class = api.uid_get_from_cstr("source.lang.swift.ref.class")!
    decl_struct = api.uid_get_from_cstr("source.lang.swift.decl.struct")!
    ref_struct = api.uid_get_from_cstr("source.lang.swift.ref.struct")!
    decl_enum = api.uid_get_from_cstr("source.lang.swift.decl.enum")!
    ref_enum = api.uid_get_from_cstr("source.lang.swift.ref.enum")!
    decl_enumcase = api.uid_get_from_cstr("source.lang.swift.decl.enumcase")!
    decl_enumelement = api.uid_get_from_cstr("source.lang.swift.decl.enumelement")!
    ref_enumelement = api.uid_get_from_cstr("source.lang.swift.ref.enumelement")!
    decl_protocol = api.uid_get_from_cstr("source.lang.swift.decl.protocol")!
    ref_protocol = api.uid_get_from_cstr("source.lang.swift.ref.protocol")!
    decl_extension = api.uid_get_from_cstr("source.lang.swift.decl.extension")!
    decl_extension_struct = api.uid_get_from_cstr("source.lang.swift.decl.extension.struct")!
    decl_extension_class = api.uid_get_from_cstr("source.lang.swift.decl.extension.class")!
    decl_extension_enum = api.uid_get_from_cstr("source.lang.swift.decl.extension.enum")!
    decl_extension_protocol = api.uid_get_from_cstr("source.lang.swift.decl.extension.protocol")!
    decl_associatedtype = api.uid_get_from_cstr("source.lang.swift.decl.associatedtype")!
    ref_associatedtype = api.uid_get_from_cstr("source.lang.swift.ref.associatedtype")!
    decl_typealias = api.uid_get_from_cstr("source.lang.swift.decl.typealias")!
    ref_typealias = api.uid_get_from_cstr("source.lang.swift.ref.typealias")!
    decl_generic_type_param = api.uid_get_from_cstr("source.lang.swift.decl.generic_type_param")!
    ref_generic_type_param = api.uid_get_from_cstr("source.lang.swift.ref.generic_type_param")!
    ref_module = api.uid_get_from_cstr("source.lang.swift.ref.module")!
    syntaxtype_attribute_builtin = api.uid_get_from_cstr("source.lang.swift.syntaxtype.attribute.builtin")!
    syntaxtype_comment = api.uid_get_from_cstr("source.lang.swift.syntaxtype.comment")!
    syntaxtype_comment_marker = api.uid_get_from_cstr("source.lang.swift.syntaxtype.comment.mark")!
    syntaxtype_comment_url = api.uid_get_from_cstr("source.lang.swift.syntaxtype.comment.url")!
    syntaxtype_doccomment = api.uid_get_from_cstr("source.lang.swift.syntaxtype.doccomment")!
    syntaxtype_doccomment_field = api.uid_get_from_cstr("source.lang.swift.syntaxtype.doccomment.field")!
    syntaxtype_keyword = api.uid_get_from_cstr("source.lang.swift.syntaxtype.keyword")!
    syntaxtype_operator = api.uid_get_from_cstr("source.lang.swift.syntaxtype.operator")!
    syntaxtype_number = api.uid_get_from_cstr("source.lang.swift.syntaxtype.number")!
    syntaxtype_string = api.uid_get_from_cstr("source.lang.swift.syntaxtype.string")!
    syntaxtype_string_interpolation_anchor = api.uid_get_from_cstr(
      "source.lang.swift.syntaxtype.string_interpolation_anchor"
    )!
    syntaxtype_type_identifier = api.uid_get_from_cstr("source.lang.swift.syntaxtype.typeidentifier")!
    syntaxtype_identifier = api.uid_get_from_cstr("source.lang.swift.syntaxtype.identifier")!
    expr_object_literal = api.uid_get_from_cstr("source.lang.swift.expr.object_literal")!
    expr_call = api.uid_get_from_cstr("source.lang.swift.expr.call")!

    kind_keyword = api.uid_get_from_cstr("source.lang.swift.keyword")!
  }
}
