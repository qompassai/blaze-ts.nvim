// -------------------------------------------------------------------------------
// /qompassai/blaze-ts.nvim/src/grammar.js
// Qompass AI Mojo grammar definition for tree-sitter
// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Qompass AI
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not
// use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
// -------------------------------------------------------------------------------

const PREC = {
  lambda: -2,
  typed_parameter: -1,
  conditional: -1,
  parenthesized_expression: 1,
  parenthesized_list_splat: 1,
  or: 10,
  and: 11,
  not: 12,
  compare: 13,
  bitwise_or: 14,
  bitwise_and: 15,
  xor: 16,
  shift: 17,
  plus: 18,
  times: 19,
  unary: 20,
  power: 21,
  call: 22,
};

const SEMICOLON = ';';
const SELF = 'self';
export default grammar({
  name: 'mojo',

  extras: ($) => [
    $.comment,
    /[\s\f\uFEFF\u2060\u200B]|\r?\n/,
    $.line_continuation,
  ],

  conflicts: ($) => [
    [$.parameter_list, $.subscript],
    [$.primary_expression, $.pattern],
    [$.primary_expression, $.list_splat_pattern],
    [$.tuple, $.tuple_pattern],
    [$.list, $.list_pattern],
    [$.with_item, $._collection_elements],
    [$.named_expression, $.as_pattern],
    [$.print_statement, $.primary_expression],
    [$.type_alias_statement, $.primary_expression],
    [$.match_statement, $.primary_expression],
    [$.transfer_expression, $.binary_operator],
    [$.transfer_expression, $.binary_operator, $.unary_operator],
    [$.transfer_expression, $.binary_operator, $.await],
    [$.list_splat_pattern, $.keyword_separator],
    [$._error_type, $.dotted_name],
    [$.function_type],
    [$.parameters, $.tuple_pattern],
    [$.parameter, $.pattern],
    [$._ref_convention, $.argument_convention],
    [$.untyped_convention_parameter, $._convention_type],
    [$.typed_splat_parameter, $.list_splat_pattern],
    [$.typed_splat_parameter, $.dictionary_splat_pattern],
    [$.typed_splat_parameter, $.constrained_type],
    [$.self_parameter],
    [$.self_parameter, $.constrained_type],
    [$.primary_expression, $.concatenated_string],
    [$._effect_specifier],
    [$._effect_specifier, $._fn_type_effect],
    [$._error_type, $.dotted_name, $.generic_type],
    [$.primary_expression, $.dotted_type_parameter],
    [$.comparison_pattern, $.as_pattern],
    [$.primary_expression, $.type],
    [$.type, $._return_type],
    [$.list_splat_pattern, $.primary_expression, $.type],
    [$.splat_type, $.generic_type],
    [$.slice, $.keyword_argument],
    [$.parameter, $.function_type_parameters],
    [$.primary_expression, $.keyword_argument],
    [$.untyped_convention_parameter, $._fn_convention_type],
    [$.brace_literal, $._collection_elements],
    [$.list_splat_pattern, $.type],
    [$.generic_type_expression],
    [$.where_clause, $.concatenated_string],
    [$.parenthesized_function_type, $.type],
    [$.where_clause],
    [$.dotted_type_parameter, $._fn_convention_type],
  ],

  supertypes: ($) => [
    $._simple_statement,
    $._compound_statement,
    $.expression,
    $.primary_expression,
    $.pattern,
    $.parameter,
  ],

  externals: ($) => [
    $._newline,
    $._indent,
    $._dedent,
    $.string_start,
    $._string_content,
    $.escape_interpolation,
    $.string_end,

    $.comment,

    ']',
    ')',
    '}',
    'except',
  ],

  inline: ($) => [
    $._simple_statement,
    $._compound_statement,
    $._suite,
    $._expressions,
    $._left_hand_side,
    $.keyword_identifier,
  ],

  word: ($) => $.identifier,

  rules: {
    module: ($) => repeat($._statement),

    _statement: ($) => choice($._simple_statements, $._compound_statement),

    _simple_statements: ($) =>
      seq(
        sep1($._simple_statement, SEMICOLON),
        optional(SEMICOLON),
        $._newline,
      ),

    _simple_statement: ($) =>
      choice(
        $.future_import_statement,
        $.import_statement,
        $.import_from_statement,
        $.decorated_import,
        $.print_statement,
        $.assert_statement,
        $.expression_statement,
        $.return_statement,
        $.delete_statement,
        $.raise_statement,
        $.pass_statement,
        $.break_statement,
        $.continue_statement,
        $.global_statement,
        $.nonlocal_statement,
        $.exec_statement,
        $.type_alias_statement,
        $.comptime_declaration,
        $.comptime_assert_statement,
        $.ref_declaration,
      ),

    import_statement: ($) => seq('import', $._import_list),

    import_prefix: (_) => repeat1('.'),

    relative_import: ($) => seq($.import_prefix, optional($.dotted_name)),

    future_import_statement: ($) =>
      seq(
        'from',
        '__future__',
        'import',
        choice($._import_list, seq('(', $._import_list, ')')),
      ),

    import_from_statement: ($) =>
      seq(
        'from',
        field('module_name', choice($.relative_import, $.dotted_name)),
        'import',
        choice(
          $.wildcard_import,
          $._import_list,
          seq('(', $._import_list, ')'),
        ),
      ),

    _import_list: ($) =>
      seq(
        commaSep1(field('name', choice($.dotted_name, $.aliased_import))),
        optional(','),
      ),

    aliased_import: ($) =>
      seq(field('name', $.dotted_name), 'as', field('alias', $.identifier)),

    wildcard_import: (_) => '*',

    print_statement: ($) =>
      choice(
        prec(
          1,
          seq(
            'print',
            $.chevron,
            repeat(seq(',', field('argument', $.expression))),
            optional(','),
          ),
        ),
        prec(
          -3,
          prec.dynamic(
            -1,
            seq(
              'print',
              commaSep1(field('argument', $.expression)),
              optional(','),
            ),
          ),
        ),
      ),

    chevron: ($) => seq('>>', $.expression),

    assert_statement: ($) => seq('assert', commaSep1($.expression)),

    expression_statement: ($) =>
      choice(
        $.expression,
        seq(commaSep1($.expression), optional(',')),
        $.assignment,
        $.augmented_assignment,
        $.yield,
      ),

    named_expression: ($) =>
      seq(
        field('name', $._named_expression_lhs),
        ':=',
        field('value', $.expression),
      ),

    _named_expression_lhs: ($) => choice($.identifier, $.keyword_identifier),

    return_statement: ($) => seq('return', optional($._expressions)),

    delete_statement: ($) => seq('del', $._expressions),

    _expressions: ($) => choice($.expression, $.expression_list),

    raise_statement: ($) =>
      seq(
        'raise',
        optional($._expressions),
        optional(seq('from', field('cause', $.expression))),
      ),

    pass_statement: (_) => prec.left('pass'),
    break_statement: (_) => prec.left('break'),
    continue_statement: (_) => prec.left('continue'),

    _compound_statement: ($) =>
      choice(
        $.if_statement,
        $.if_case_statement,
        $.for_statement,
        $.while_statement,
        $.while_case_statement,
        $.mlir_region_statement,
        $.try_statement,
        $.with_statement,
        $.function_definition,
        $.class_definition,
        $.trait_definition,
        $.decorated_definition,
        $.match_statement,
        $.comptime_if_statement,
        $.comptime_for_statement,
        $.comptime_match_statement,
        $.decorated_field,
        $.extension_definition,
      ),

    // `__extension List:` — adds methods to an existing type (Mojo 1.2+).
    extension_definition: ($) =>
      prec(
        1,
        seq(
          '__extension',
          field('type', choice($.identifier, $.generic_type, $.member_type)),
          ':',
          field('body', $._suite),
        ),
      ),

    if_statement: ($) =>
      seq(
        'if',
        field('condition', $.expression),
        ':',
        field('consequence', $._suite),
        repeat(field('alternative', choice($.elif_clause, $.elif_case_clause))),
        optional(field('alternative', $.else_clause)),
      ),

    elif_clause: ($) =>
      seq(
        'elif',
        field('condition', $.expression),
        ':',
        field('consequence', $._suite),
      ),

    // `if case .Some(x) = value:` — pattern-matching conditional (Mojo 1.2+).
    if_case_statement: ($) =>
      seq(
        'if',
        'case',
        field('pattern', $.case_pattern),
        '=',
        field('value', $.expression),
        ':',
        field('consequence', $._suite),
        repeat(field('alternative', choice($.elif_clause, $.elif_case_clause))),
        optional(field('alternative', $.else_clause)),
      ),

    // `while case .Some(x) = value:` — pattern-matching loop (Mojo 1.2+).
    while_case_statement: ($) =>
      seq(
        'while',
        'case',
        field('pattern', $.case_pattern),
        '=',
        field('value', $.expression),
        ':',
        field('body', $._suite),
        optional(field('alternative', $.else_clause)),
      ),

    // `__mlir_region name(params):` — a named MLIR region block.
    mlir_region_statement: ($) =>
      seq(
        '__mlir_region',
        field('name', $.identifier),
        field('parameters', optional($.parameters)),
        ':',
        field('body', $._suite),
      ),

    elif_case_clause: ($) =>
      seq(
        'elif',
        'case',
        field('pattern', $.case_pattern),
        '=',
        field('value', $.expression),
        ':',
        field('consequence', $._suite),
      ),

    else_clause: ($) => seq('else', ':', field('body', $._suite)),

    match_statement: ($) =>
      seq(
        'match',
        commaSep1(field('subject', $.expression)),
        optional(','),
        ':',
        field('body', alias($._match_block, $.block)),
      ),

    _match_block: ($) =>
      choice(
        seq($._indent, repeat(field('alternative', $.case_clause)), $._dedent),
        $._newline,
      ),

    case_clause: ($) =>
      seq(
        'case',
        commaSep1($.case_pattern),
        optional(','),
        optional(field('guard', $.if_clause)),
        ':',
        field('consequence', $._suite),
      ),

    for_statement: ($) =>
      seq(
        optional('async'),
        'for',
        // Loop-variable conventions: `for var item in ...`, `for ref x in ...`.
        optional($.argument_convention),
        field('left', $._left_hand_side),
        'in',
        field('right', $._expressions),
        ':',
        field('body', $._suite),
        field('alternative', optional($.else_clause)),
      ),

    while_statement: ($) =>
      seq(
        'while',
        field('condition', $.expression),
        ':',
        field('body', $._suite),
        optional(field('alternative', $.else_clause)),
      ),

    try_statement: ($) =>
      seq(
        'try',
        ':',
        field('body', $._suite),
        choice(
          seq(
            repeat1($.except_clause),
            optional($.else_clause),
            optional($.finally_clause),
          ),
          seq(
            repeat1($.except_group_clause),
            optional($.else_clause),
            optional($.finally_clause),
          ),
          $.finally_clause,
        ),
      ),

    except_clause: ($) =>
      seq(
        'except',
        optional(
          seq($.expression, optional(seq(choice('as', ','), $.expression))),
        ),
        ':',
        $._suite,
      ),

    except_group_clause: ($) =>
      seq(
        'except*',
        seq($.expression, optional(seq('as', $.expression))),
        ':',
        $._suite,
      ),

    finally_clause: ($) => seq('finally', ':', $._suite),

    with_statement: ($) =>
      seq(
        optional('async'),
        'with',
        $.with_clause,
        ':',
        field('body', $._suite),
      ),

    with_clause: ($) =>
      choice(
        seq(commaSep1($.with_item), optional(',')),
        seq('(', commaSep1($.with_item), optional(','), ')'),
      ),

    with_item: ($) => prec.dynamic(1, seq(field('value', $.expression))),

    function_definition: ($) =>
      seq(
        // `__async def` is the MLIR-era spelling of an async definition.
        optional(choice('async', '__async')),
        choice('def', 'fn'),
        optional(
          seq(
            '[',
            field('name', $.identifier),
            field('type_parameters', optional($.type_parameter)),
            field('parameters', $.parameters),
            ']',
          ),
        ),
        field('name', $.identifier),
        field('type_parameters', optional($.type_parameter)),
        field('parameters', $.parameters),
        optional(field('abi', $.abi_specifier)),
        // Effect specifiers (raises / capturing / escaping) are
        // whitespace-separated. Whitespace is an extra in this grammar,
        // so an explicit separator token could never match here; the
        // specifiers are also independent of the return annotation,
        // since `fn f() raises:` carries no arrow.
        optional(seq($._effect_specifier, repeat($._effect_specifier))),
        optional(field('captures', $.capture_list)),
        optional(
          seq(
            '->',
            optional($._ref_convention),
            field('return_type', alias($._return_type, $.type)),
          ),
        ),
        optional(field('where_clause', $.where_clause)),
        ':',
        field('body', $._suite),
      ),

    parameters: ($) => seq('(', optional($._parameters), ')'),

    lambda_parameters: ($) => $._parameters,

    list_splat: ($) => seq('*', $.expression),

    dictionary_splat: ($) => seq('**', $.expression),

    global_statement: ($) => seq('global', commaSep1($.identifier)),

    nonlocal_statement: ($) => seq('nonlocal', commaSep1($.identifier)),

    exec_statement: ($) =>
      seq(
        'exec',
        field('code', choice($.string, $.identifier)),
        optional(seq('in', commaSep1($.expression))),
      ),

    type_alias_statement: ($) =>
      prec.dynamic(1, seq('type', $.type, '=', $.type)),


    comptime_declaration: ($) =>
      prec(
        1,
        seq(
          'comptime',
          commaSep1(field('name', choice($.identifier, $.backtick_name))),
          field('parameters', optional($.type_parameter)),
          // Either a definition (`= value`, annotation optional) or an
          // associated-type requirement in a trait (`: Trait`, no value).
          // A bare `comptime X` with neither is invalid.
          choice(
            seq(
              optional(seq(':', field('type', $._comptime_type))),
              optional(field('where_clause', $.where_clause)),
              '=',
              field(
                'value',
                choice(
                  $.expression,
                  $.function_type,
                  $.tuple_type,
                  // A parenthesized function type: `comptime F = (def(...) thin)`.
                  alias(seq('(', $.function_type, ')'), $.parenthesized_type),
                ),
              ),
            ),
            seq(
              ':',
              field('type', $._comptime_type),
              optional(field('where_clause', $.where_clause)),
            ),
          ),
        ),
      ),

    comptime_for_statement: ($) => seq('comptime', $.for_statement),

    // The type in a comptime annotation: every nominal/composed type form,
    // but never a bare expression or a function type — neither is observed
    // as a comptime annotation, and admitting them forks the optional
    // segments that follow (where clause, value) against every expression
    // continuation.
    // The annotation of a comptime declaration is an ordinary type.
    // (A hand-rolled fork of the type forms lived here; it shredded
    // member-generic annotations like `A.b[k=v]` into fragments that
    // carried no ERROR node — a silent misparse. Delegating to $.type
    // restores the (type ...) wrapper in these trees.)
    _comptime_type: ($) => prec(1, $.type),

    abi_specifier: ($) => seq('abi', '(', $.string, ')'),

    _effect_specifier: ($) =>
      choice(
        prec.dynamic(2, seq('raises', optional(field('error_type', $._error_type)))),
        'capturing',
        'escaping',
      ),

    // Error types exclude constrained_type: in `raises A:` the colon ends the
    // signature; it never starts a `type : type` constraint.
    _error_type: ($) => prec.dynamic(1, choice($.identifier, $.generic_type, $.dotted_name)),

    capture_convention: ($) => choice('imm', 'mut', 'ref', 'var'),

    capture_entry: ($) =>
      choice(
        seq(
          $.capture_convention,
          optional(field('name', $.identifier)),
          optional('^'),
        ),
        seq(field('name', $.identifier), optional('^')),
      ),

    capture_list: ($) =>
      seq('{', optional(commaSep1($.capture_entry)), optional(','), '}'),

    where_clause: ($) =>
      // Clauses may chain: `where A where B:`.
      seq(
        repeat1(
          seq(
            'where',
            field('condition', $.expression),
            // `where (cond) else "message":` — a compile-time requirement
            // with a diagnostic message (Mojo 1.2+); the message may be a
            // parenthesized (concatenated) string.
            optional(
              seq(
                'else',
                field(
                  'message',
                  choice(
                    $.string,
                    $.concatenated_string,
                    seq('(', choice($.string, $.concatenated_string), ')'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),

    conformance_clause: ($) =>
      seq(
        field('trait', $.identifier),
        'where',
        field('condition', $.expression),
        // `Trait where cond else ("message")` in a conformance list.
        optional(
          seq(
            'else',
            field(
              'message',
              choice(
                $.string,
                $.concatenated_string,
                seq('(', choice($.string, $.concatenated_string), ')'),
              ),
            ),
          ),
        ),
      ),

    comptime_assert_statement: ($) => seq('comptime', $.assert_statement),

    ref_declaration: ($) =>
      seq('ref', field('name', $.identifier), '=', field('value', $.expression)),

    comptime_if_statement: ($) =>
      seq('comptime', choice($.if_statement, $.if_case_statement)),

    comptime_match_statement: ($) => seq('comptime', $.match_statement),

    class_definition: ($) =>
      seq(
        choice('class', 'struct'),
        field('name', $.identifier),
        field('type_parameters', optional($.type_parameter)),
        field('superclasses', optional(alias($.superclass_list, $.argument_list))),
        field('where_clause', optional($.where_clause)),
        ':',
        field('body', $._suite),
      ),

    // A struct/trait conformance list; entries may be function types:
    // `struct S(ImplicitlyCopyable, def() -> None):`.
    superclass_list: ($) =>
      seq(
        '(',
        commaSep1(choice($.expression, $.function_type, $.conformance_clause)),
        optional(','),
        ')',
      ),
    type_parameter: ($) =>
      seq(
        '[',
        // The bracket list may be empty: `Tuple[]`, `def f[]()`,
        // `-> _CString[]`.
        optional(
          commaSep1(
            choice(
              // A lone name in brackets is a type (`List[Int]`); the type
              // reading wins over the expression reading by dynamic prec.
              prec.dynamic(1, $.type),
              // Parametric values are comptime expressions generally:
              // `SIMD[dtype, width * 4]`, `ViewType[fn[type_of(t).L]]`.
              // $.type precedes it so trait compositions (`A & def()`)
              // keep their type reading.
              $.expression,
              $.parametric_default,
              '//',
              '/',
              '*',
            ),
          ),
        ),
        optional(','),
        ']',
      ),

    parametric_default: ($) =>
      seq(field('parameter', $.type), '=', field('value', $.expression)),

    trait_definition: ($) =>
      seq(
        'trait',
        field('name', $.identifier),
        field('supertraits', optional($.trait_list)),
        ':',
        field('body', seq($._indent, $.block)),
      ),

    trait_list: ($) =>
      seq(
        '(',
        // Supertraits may be member or generic types, or conformance
        // clauses: `trait T(std.traits.Movable, A where conforms_to(B))`.
        optional(commaSep1(choice($.type, $.conformance_clause))),
        optional(','),
        ')',
      ),

    parenthesized_list_splat: ($) =>
      prec(
        PREC.parenthesized_list_splat,
        seq(
          '(',
          choice(
            alias($.parenthesized_list_splat, $.parenthesized_expression),
            $.list_splat,
          ),
          ')',
        ),
      ),

    argument_list: ($) =>
      seq(
        '(',
        optional(
          commaSep1(
            choice(
              $.expression,
              $.list_splat,
              $.dictionary_splat,
              alias($.parenthesized_list_splat, $.parenthesized_expression),
              $.keyword_argument,
              $.conformance_clause,
              // A ref argument: `SMemArray[...](ref smem.field)`.
              seq('ref', $.expression),
            ),
          ),
        ),
        optional(','),
        ')',
      ),

    parameter_list: ($) =>
      seq(
        '[',
        optional(
          commaSep1(
            choice(
              seq(optional('inferred'), $.expression),
              $.list_splat,
              $.dictionary_splat,
              alias($.parenthesized_list_splat, $.parenthesized_expression),
              $.keyword_argument,
              // Function types as generic arguments:
              // `_get_dylib_function[def(...) thin -> Result]`.
              $.function_type,
            ),
          ),
        ),
        optional(','),
        ']',
      ),

    decorated_definition: ($) =>
      seq(
        repeat1($.decorator),
        field(
          'definition',
          choice(
            $.class_definition,
            $.function_definition,
            $.trait_definition,
            $.comptime_declaration,
          ),
        ),
      ),

    // Decorated import: `@__doc_inline` on an import statement.
    decorated_import: ($) =>
      seq(
        repeat1($.decorator),
        choice($.import_statement, $.import_from_statement),
      ),

    // Decorated struct field: `@__allow_legacy_any_origin_fields` on a
    // `var` declaration inside a struct body.
    decorated_field: ($) =>
      seq(
        repeat1($.decorator),
        'var',
        field('name', $.identifier),
        ':',
        field('type', $.type),
        optional(seq('=', field('value', $.expression))),
        $._newline,
      ),

    decorator: ($) => seq('@', $.expression, $._newline),

    _suite: ($) =>
      choice(
        alias($._simple_statements, $.block),
        seq($._indent, $.block),
        alias($._newline, $.block),
      ),

    block: ($) => seq(repeat($._statement), $._dedent),

    expression_list: ($) =>
      prec.right(
        seq(
          $.expression,
          choice(',', seq(repeat1(seq(',', $.expression)), optional(','))),
        ),
      ),

    dotted_name: ($) => prec(1, sep1($.identifier, '.')),

    case_pattern: ($) =>
      prec(
        1,
        choice(
          alias($._as_pattern, $.as_pattern),
          $.keyword_pattern,
          $._simple_pattern,
        ),
      ),

    // Comparison pattern: `case == SCHED_MASK:` — the subject is compared
    // against the expression (Mojo 1.2+).
    comparison_pattern: ($) =>
      seq(choice('==', '!=', '<', '<=', '>', '>='), $.expression),

    // Leading-dot shorthand pattern: `case .bool:`, `.Some(x)` — the enum
    // type is inferred from the matched subject (Mojo 1.2+).
    dot_pattern: ($) =>
      seq(
        '.',
        $.identifier,
        optional(
          seq(
            '(',
            optional(seq(commaSep1($.case_pattern), optional(','))),
            ')',
          ),
        ),
      ),

    _simple_pattern: ($) =>
      prec(
        1,
        choice(
          $.dot_pattern,
          $.comparison_pattern,
          // A bare identifier in pattern position binds (captures); only a
          // dotted path is a value pattern. Must precede $.dotted_name,
          // whose single-segment form would otherwise swallow captures.
          prec(2, $.identifier),
          // An explicit owning binding: `case .Some(var nn)`.
          prec(2, seq('var', $.identifier)),
          // A reference binding: `case .Some(ref fd_out)`.
          prec(2, seq('ref', $.identifier)),
          $.class_pattern,
          $.splat_pattern,
          $.union_pattern,
          alias($._list_pattern, $.list_pattern),
          alias($._tuple_pattern, $.tuple_pattern),
          $.dict_pattern,
          $.string,
          $.concatenated_string,
          $.true,
          $.false,
          $.none,
          seq(optional('-'), choice($.integer, $.float)),
          $.complex_pattern,
          $.dotted_name,
          '_',
        ),
      ),

    _as_pattern: ($) => seq($.case_pattern, 'as', $.identifier),

    union_pattern: ($) =>
      prec.right(
        seq($._simple_pattern, repeat1(prec.left(seq('|', $._simple_pattern)))),
      ),

    _list_pattern: ($) =>
      seq('[', optional(seq(commaSep1($.case_pattern), optional(','))), ']'),

    _tuple_pattern: ($) =>
      seq('(', optional(seq(commaSep1($.case_pattern), optional(','))), ')'),

    dict_pattern: ($) =>
      seq(
        '{',
        optional(
          seq(
            commaSep1(choice($._key_value_pattern, $.splat_pattern)),
            optional(','),
          ),
        ),
        '}',
      ),

    _key_value_pattern: ($) =>
      seq(field('key', $._simple_pattern), ':', field('value', $.case_pattern)),

    keyword_pattern: ($) => seq($.identifier, '=', $._simple_pattern),

    splat_pattern: ($) =>
      prec(1, seq(choice('*', '**'), choice($.identifier, '_'))),

    class_pattern: ($) =>
      seq(
        $.dotted_name,
        '(',
        optional(seq(commaSep1($.case_pattern), optional(','))),
        ')',
      ),

    complex_pattern: ($) =>
      prec(
        1,
        seq(
          optional('-'),
          choice($.integer, $.float),
          choice('+', '-'),
          choice($.integer, $.float),
        ),
      ),

    // Patterns

    _parameters: ($) => seq(commaSep1($.parameter), optional(',')),

    _patterns: ($) => seq(commaSep1($.pattern), optional(',')),

    parameter: ($) =>
      choice(
        $.self_parameter,
        $.untyped_convention_parameter,
        $.identifier,
        $.typed_parameter,
        $.default_parameter,
        $.typed_default_parameter,
        $.list_splat_pattern,
        $.typed_splat_parameter,
        $.tuple_pattern,
        $.keyword_separator,
        $.positional_separator,
        $.dictionary_splat_pattern,
      ),

    pattern: ($) =>
      choice(
        $.identifier,
        $.keyword_identifier,
        $.backtick_name,
        $.subscript,
        $.attribute,
        $.list_splat_pattern,
        $.tuple_pattern,
        $.list_pattern,
      ),

    // Demoted: where the assignment's own `var` prefix reading also
    // exists (statement start), it wins; mid-list this is the only
    // reading, so `_, var r = ...` still declares.
    var_pattern: ($) => prec(-1, seq('var', field('name', $.identifier))),

    // A ref-binding element in a destructuring list:
    // `count, ref chars = get_pair()`.
    ref_pattern: ($) => prec(-1, seq('ref', field('name', $.identifier))),

    tuple_pattern: ($) => seq('(', optional($._patterns), ')'),

    list_pattern: ($) => seq('[', optional($._patterns), ']'),

    _ref_convention: ($) =>
      seq('ref', '[', commaSep1($.expression), optional(','), ']'),
    argument_convention: ($) =>
      choice(
        'borrowed',
        'deinit',
        // `imm` is the 1.1 spelling of the default convention
        // (`imm self`); `read` is its legacy alias.
        'imm',
        'inout',
        'owned',
        'out',
        'read',
        'mut',
        'ref',
        'var',
        $._ref_convention,
      ),

    untyped_convention_parameter: ($) =>
      seq($.argument_convention, field('name', $.identifier)),

    // Function-type parameter lists only (def(var T)): a convention applied
    // to a bare type. Kept out of $.parameter — in signatures the same text
    // is a typed_parameter (name before the colon), and this rule's type
    // would swallow it as a constrained_type.
    convention_parameter: ($) =>
      prec.dynamic(1, seq($.argument_convention, field('type', $._convention_type))),

    // The type in a convention parameter (def(var T)) excludes
    // constrained_type: in `var s: String` the colon belongs to a
    // typed_parameter (s is the name), never to a `type : type` form.
    _convention_type: ($) =>
      choice($.identifier, $.generic_type, $.member_type),

    self_parameter: ($) =>
      seq(
        optional($.argument_convention),
        SELF,
        optional(seq(':', field('type', $.type))),
      ),

    typed_parameter: ($) =>
      prec(
        PREC.typed_parameter,
        seq(
          choice(
            seq(optional($.argument_convention), $.identifier),
            $.list_splat_pattern,
            $.dictionary_splat_pattern,
          ),
          ':',
          field('type', $.type),
          optional(field('where_clause', $.where_clause)),
        ),
      ),

    default_parameter: ($) =>
      seq(
        field('name', choice($.identifier, $.tuple_pattern)),
        '=',
        field('value', $.expression),
      ),

    typed_default_parameter: ($) =>
      prec(
        PREC.typed_parameter,
        seq(
          optional($.argument_convention),
          field('name', $.identifier),
          ':',
          field('type', $.type),
          '=',
          field('value', $.expression),
          optional(field('where_clause', $.where_clause)),
        ),
      ),

    typed_splat_parameter: ($) =>
      seq(
        // `var *args: *Self.Ts` carries a convention before the splat.
        optional($.argument_convention),
        choice('*', '**'),
        field('name', $.identifier),
        ':',
        field('type', $.type),
        optional(seq('=', field('value', $.expression))),
      ),

    list_splat_pattern: ($) =>
      seq(
        '*',
        choice($.identifier, $.keyword_identifier, $.subscript, $.attribute),
      ),

    dictionary_splat_pattern: ($) =>
      seq(
        '**',
        choice($.identifier, $.keyword_identifier, $.subscript, $.attribute),
      ),

    as_pattern: ($) =>
      prec.left(
        seq(
          $.expression,
          'as',
          field('alias', alias($.expression, $.as_pattern_target)),
        ),
      ),

    _expression_within_for_in_clause: ($) =>
      choice($.expression, alias($.lambda_within_for_in_clause, $.lambda)),

    expression: ($) =>
      choice(
        $.comparison_operator,
        $.not_operator,
        $.boolean_operator,
        $.lambda,
        $.primary_expression,
        $.conditional_expression,
        $.named_expression,
        $.as_pattern,
      ),

    primary_expression: ($) =>
      choice(
        $.await,
        $.binary_operator,
        $.identifier,
        $.keyword_identifier,
        // Backtick-quoted name as a value: `` `nvvm.grid_constant` ``,
        // `` var `6bit` = ... `` (names that are not plain identifiers).
        $.backtick_name,
        $.string,
        $.concatenated_string,
        $.integer,
        $.float,
        $.true,
        $.false,
        $.none,
        $.unary_operator,
        $.attribute,
        choice(prec.dynamic(-1, $.subscript), prec.dynamic(1, $.call)),
        $.list,
        $.list_comprehension,
        $.dictionary,
        $.dictionary_comprehension,
        $.set,
        $.set_comprehension,
        $.tuple,
        $.parenthesized_expression,
        // A parenthesized function type as a value operand:
        // `A & (def[...] (...) -> T)` in a comptime trait composition.
        $.parenthesized_function_type,
        $.generator_expression,
        $.ellipsis,
        $.transfer_expression,
        $.implicit_member_expression,
        $.brace_literal,
        $.mlir_op,
        $.mlir_attr,
        alias($.list_splat_pattern, $.list_splat),
        $.mlir_type,
      ),

    not_operator: ($) =>
      prec(PREC.not, seq('not', field('argument', $.expression))),

    boolean_operator: ($) =>
      choice(
        prec.left(
          PREC.and,
          seq(
            field('left', $.expression),
            field('operator', 'and'),
            field('right', $.expression),
          ),
        ),
        prec.left(
          PREC.or,
          seq(
            field('left', $.expression),
            field('operator', 'or'),
            field('right', $.expression),
          ),
        ),
      ),

    binary_operator: $ => {
      const table = [
        [prec.left, '+', PREC.plus],
        [prec.left, '-', PREC.plus],
        [prec.left, '*', PREC.times],
        [prec.left, '@', PREC.times],
        [prec.left, '/', PREC.times],
        [prec.left, '%', PREC.times],
        [prec.left, '//', PREC.times],
        [prec.right, '**', PREC.power],
        [prec.left, '|', PREC.bitwise_or],
        [prec.left, '&', PREC.bitwise_and],
        [prec.left, '^', PREC.xor],
        [prec.left, '<<', PREC.shift],
        [prec.left, '>>', PREC.shift],
      ];

      return choice(
        ...table.map(([fn, operator, precedence]) =>
          fn(
            precedence,
            seq(
              field('left', $.primary_expression),
              field('operator', operator),
              field('right', $.primary_expression),
            ),
          ),
        ),
      );
    },
    unary_operator: ($) =>
      prec(
        PREC.unary,
        seq(
          field('operator', choice('+', '-', '~')),
          field('argument', $.primary_expression),
        ),
      ),

    _not_in: (_) => seq('not', 'in'),

    _is_not: (_) => seq('is', 'not'),

    comparison_operator: ($) =>
      prec.left(
        PREC.compare,
        seq(
          $.primary_expression,
          repeat1(
            seq(
              field(
                'operators',
                choice(
                  '<',
                  '<=',
                  '==',
                  '!=',
                  '>=',
                  '>',
                  '<>',
                  'in',
                  alias($._not_in, 'not in'),
                  'is',
                  alias($._is_not, 'is not'),
                ),
              ),
              $.primary_expression,
            ),
          ),
        ),
      ),

    lambda: ($) =>
      prec(
        PREC.lambda,
        seq(
          'lambda',
          field('type_parameters', optional($.type_parameter)),
          field(
            'parameters',
            optional(choice($.parameters, $.lambda_parameters)),
          ),
          optional(field('captures', $.capture_list)),
          optional(seq($._effect_specifier, repeat($._effect_specifier))),
          optional(seq('->', field('return_type', alias($._return_type, $.type)))),
          ':',
          field('body', $.expression),
        ),
      ),

    lambda_within_for_in_clause: ($) =>
      seq(
        'lambda',
        field('parameters', optional($.lambda_parameters)),
        ':',
        field('body', $._expression_within_for_in_clause),
      ),

    assignment: ($) =>
      seq(
        optional(choice('var', 'let', 'alias', '__disable_del')),
        field('left', $._left_hand_side),
        choice(
          seq('=', field('right', $._right_hand_side)),
          seq(':', field('type', $.type)),
          seq(
            ':',
            field('type', $.type),
            '=',
            field('right', $._right_hand_side),
          ),
        ),
      ),

    augmented_assignment: ($) =>
      seq(
        field('left', $._left_hand_side),
        field(
          'operator',
          choice(
            '+=',
            '-=',
            '*=',
            '/=',
            '@=',
            '//=',
            '%=',
            '**=',
            '>>=',
            '<<=',
            '&=',
            '^=',
            '|=',
          ),
        ),
        field('right', $._right_hand_side),
      ),

    _left_hand_side: ($) =>
      choice(
        $.pattern,
        $.pattern_list,
        // Assignment through a ref-returning call: `p[].right() = q`,
        // `get_ref() = v`.
        $.call,
      ),

    pattern_list: ($) =>
      seq(
        // Elements may declare mid-list: `_, var r = udivmod(...)`,
        // `count, ref chars = ...` (var/ref patterns are prec(-1), so a
        // statement-initial keyword still reads as the assignment's
        // own prefix/convention).
        choice($.pattern, $.var_pattern, $.ref_pattern),
        choice(
          ',',
          seq(
            repeat1(seq(',', choice($.pattern, $.var_pattern, $.ref_pattern))),
            optional(','),
          ),
        ),
      ),

    _right_hand_side: ($) =>
      choice(
        $.expression,
        $.expression_list,
        $.assignment,
        $.augmented_assignment,
        $.pattern_list,
        $.yield,
      ),

    yield: ($) =>
      prec.right(
        seq(
          'yield',
          choice(seq('from', $.expression), optional($._expressions)),
        ),
      ),

    attribute: ($) =>
      prec(
        PREC.call,
        seq(
          field('object', $.primary_expression),
          '.',
          choice(
            field('attribute', $.identifier),
            seq($.string_start, $.string_content, $.string_end),
          ),
        ),
      ),

    subscript: ($) =>
      prec(
        PREC.call,
        seq(
          field('value', $.primary_expression),
          '[',
          optional(
            commaSep1(
              field(
                'subscript',
                choice(
                  $.expression,
                  $.slice,
                  $.keyword_argument,
                  alias($.slice_keyword_argument, $.keyword_argument),
                  // Type-only entries appear when the brackets are a
                  // generic type's: `Variant[Bool, def() capturing -> Path]`
                  // reaches the parser through the subscript reading in
                  // value position (comptime values keep subscript shape).
                  $.function_type,
                ),
              ),
            ),
          ),
          optional(','),
          ']',
        ),
      ),

    slice: ($) =>
      seq(
        optional(choice($.expression, $.keyword_argument)),
        ':',
        optional($.expression),
        optional(seq(':', optional($.expression))),
      ),

    ellipsis: (_) => '...',

    call: ($) =>
      prec(
        PREC.call,
        seq(
          field('function', $.primary_expression),
          optional($.parameter_list),
          field('arguments', choice($.generator_expression, $.argument_list)),
        ),
      ),

    parenthesized_type: ($) => seq('(', $.type, ')'),

    // A parenthesized function type in value position (a single named
    // child so primary_expression's supertype constraint holds).
    parenthesized_function_type: ($) => seq('(', $.function_type, ')'),

    // Tuple of types: `(def(...) -> None, def(...) -> Int)` — used for
    // comptime type tuples (plugin hook signatures).
    // Elements are restricted to function-bearing forms: the tuple's only
    // observed use is a comptime value listing fn-type signatures, and
    // admitting every $.type forks each parenthesized expression in value
    // position against a type reading of its first element.
    tuple_type: ($) =>
      seq(
        '(',
        // The first element anchors the tuple as a function type: without
        // the anchor, a type reading forks against every parenthesized
        // expression in value position.
        $.function_type,
        ',',
        commaSep1($._tuple_type_element),
        optional(','),
        ')',
      ),

    _tuple_type_element: ($) =>
      choice(
        $.function_type,
        $.intersection_type,
        $.union_type,
        $.constrained_type,
        $.parenthesized_type,
        $.tuple_type,
      ),

    type: ($) =>
      choice(
        // No raw $.expression route: in type position the expression
        // reading captures `A & B` as a bitwise-and (silently wrong trees
        // for trait intersections, fatal for fn-type operands). Every
        // legitimate type form has a dedicated rule below.
        $.identifier,
        // Keyword names as types/parameters: `P[type: AnyType]`.
        $.keyword_identifier,
        // `None` as a type keeps its literal node: `-> None`.
        $.none,
        $.splat_type,
        $.generic_type,
        $.generic_type_expression,
        alias($.type_call, $.generic_type_expression),
        $.union_type,
        $.intersection_type,
        $.constrained_type,
        $.member_type,
        $.function_type,
        $.mlir_type,
        $.parenthesized_type,
        $.generator_type_application,
        $.conditional_type,
      ),

    // A type-level function applied to a type argument written after its
    // brackets: `__generator_type[Idx: Int] Trait`.
    generator_type_application: ($) =>
      prec(PREC.call, seq($.generic_type, $.type)),

    // A type-level conditional: `A if type_of(x).flag else B` in type
    // position (parameter/return annotations, comptime types).
    conditional_type: ($) =>
      prec.right(
        -1,
        seq(
          field('consequence', $.type),
          'if',
          field('condition', $.expression),
          'else',
          field('alternative', $.type),
        ),
      ),

    // The `type_of(x)` builtin producing a type. Spelled literally:
    // a general identifier-headed type call in bracket entries
    // completes over the same span as a call expression and its
    // completion culls the expression stack (`SIMD[f() * 2]` dies).
    // Restricted to `type_of`, no competing stack arises for ordinary
    // calls, while `type_of(...)` keeps its type reading in type
    // position and as a member base (`type_of(x).T`).
    type_call: ($) => prec(PREC.call, seq('type_of', $.argument_list)),

    // Comptime type expressions: a generic type called or subscripted to
    // produce another type — `TypeList[...]()[id]`, `List[Int]()`. In type
    // position the expression stack does not survive a generic type's
    // brackets, so the chain gets its own rule.
    generic_type_expression: ($) =>
      prec(
        PREC.call,
        choice(
          // Generic head with call/subscript continuations:
          // `TypeList[...]()[id]`, `List[Int]()`.
          seq(
            $.generic_type,
            repeat1(
              choice(
                $.argument_list,
                seq(
                  '[',
                  optional(
                    commaSep1(
                      choice($.expression, $.slice, $.keyword_argument),
                    ),
                  ),
                  optional(','),
                  ']',
                ),
              ),
            ),
          ),
          // A plain or member name CALLED to produce a type:
          // `type_of(x)`, `Self.make_type()`. The head alone may not take
          // a subscript continuation — `A[0]` there is a plain subscript
          // expression, and admitting it forks every subscript in value
          // position against a type reading.
          seq($.member_type, $.argument_list),
          // A member type subscripted by types, with further call or
          // subscript continuations: `Self.Ts[i]`,
          // `*TypeList.splat[Trait=T, rank, Scalar[d]]()`.
          seq(
            $.member_type,
            $.type_parameter,
            repeat(choice($.argument_list, $.type_parameter)),
          ),
        ),
      ),

    // Trait composition in type position: `ImplicitlyCopyable & def(...)`.
    intersection_type: ($) =>
      prec.dynamic(1, prec.left(seq($.type, '&', $.type))),

    function_type: ($) =>
      prec.dynamic(
        2,
        seq(
          optional('thin'),
          choice('def', 'fn'),
          field('type_parameters', optional($.type_parameter)),
          field('parameters', $.function_type_parameters),
          // `thin` and the ABI specifier appear in either order:
          // `def(...) thin abi("C")`, `def(...) abi("C") thin`.
          optional(
            choice(
              seq('thin', optional(field('abi', $.abi_specifier))),
              seq(field('abi', $.abi_specifier), optional('thin')),
            ),
          ),
          optional(seq($._fn_type_effect, repeat($._fn_type_effect))),
          optional(seq('->', field('return_type', alias($._return_type, $.type)))),
          optional(field('where_clause', $.where_clause)),
        ),
      ),

    function_type_parameters: ($) =>
      seq(
        '(',
        optional(
          seq(
            commaSep1(
              choice(
                alias($.fn_bare_convention_parameter, $.convention_parameter),
                alias($.fn_typed_convention_parameter, $.typed_parameter),
                // Direct entry (not only via $.parameter): with a leading
                // convention the shared-parameter path loses the splat
                // continuation in this list (`def(var **kwargs: T)`).
                $.typed_splat_parameter,
                $.parameter,
                $.call,
                // Bare type parameters: `def(SIMD[dtype, width])` — a
                // generic type with no parameter name.
                $.generic_type,
                // `def(Self.T)` — a dotted type with no parameter name.
                // Flat identifier chain: $.member_type's recursive $.type
                // base poisons the parameter states here.
                $.dotted_type_parameter,
                // A bare MLIR type entry: `def(__mlir_type.`!kgen.ptr`)`.
                $.mlir_type,
                // A bare function type entry (nested signatures):
                // `def(def(Int16) thin raises -> None) thin -> Result`.
                $.function_type,
              ),
            ),
            optional(','),
          ),
        ),
        ')',
      ),

    dotted_type_parameter: ($) =>
      seq(
        $.identifier,
        repeat1(choice(seq('.', $.identifier), $.type_parameter)),
      ),

    // A convention + typed parameter inside a function type:
    // `def(mut writer: W)`. Distinct from $.typed_parameter (whose -1
    // precedence loses the colon shift against the bare-convention
    // readings in this list); aliased so the tree shape is identical.
    fn_typed_convention_parameter: ($) =>
      prec(
        1,
        seq(
          $.argument_convention,
          field('name', $.identifier),
          ':',
          field('type', $.type),
          optional(seq('=', field('value', $.expression))),
        ),
      ),

    // A bare convention + type parameter inside a function type:
    // `def(var T)`. Distinct from $.convention_parameter, whose shared
    // states kill the convention splats in this list; aliased so the
    // tree shape is identical. Its type slot excludes the member_type
    // route, whose $.type base would grab `**k` as a splat type and
    // strand the typed splat's colon.
    fn_bare_convention_parameter: ($) =>
      prec.dynamic(
        1,
        seq($.argument_convention, field('type', $._fn_convention_type)),
      ),

    _fn_convention_type: ($) =>
      choice(
        $.identifier,
        $.generic_type,
        alias(
          seq(
            choice($.identifier, $.generic_type),
            repeat1(seq('.', $.identifier)),
          ),
          $.member_type,
        ),
        // A dotted chain with a bracket segment:
        // `var IterableType.IteratorType[origin].Element`.
        $.dotted_type_parameter,
      ),

    // Return types: every $.type form except a constraint. A constraint
    // in return position (`-> Int32: Int32(i)`) would read the colon as
    // its own and the body call as its second type. Aliased to $.type at
    // the use sites so tree shapes are unchanged.
    _return_type: ($) =>
      choice(
        $.identifier,
        $.keyword_identifier,
        $.none,
        $.splat_type,
        $.generic_type,
        $.generic_type_expression,
        alias($.type_call, $.generic_type_expression),
        $.union_type,
        $.intersection_type,
        $.member_type,
        $.function_type,
        $.mlir_type,
        $.parenthesized_type,
        $.generator_type_application,
      ),

    _fn_type_effect: ($) =>
      choice(
        $._effect_specifier,
        // Bare `capturing` with no capture list: `def(...) capturing`.
        'capturing',
        seq(
          'capturing',
          '[',
          commaSep1(choice('_', $.capture_entry)),
          optional(','),
          ']',
        ),
      ),
    splat_type: ($) =>
      prec(
        1,
        seq(
          choice('*', '**'),
          choice(
            $.identifier,
            $.member_type,
            $.generic_type,
            $.generic_type_expression,
          ),
        ),
      ),
    generic_type: ($) => prec(1, seq($.identifier, $.type_parameter)),
    union_type: ($) => prec.left(seq($.type, '|', $.type)),
    constrained_type: ($) => prec.right(seq($.type, ':', $.type)),
    member_type: ($) => seq($.type, '.', $.identifier),

    brace_literal: ($) =>
      seq(
        '{',
        commaSep1(
          choice(
            seq(field('name', $.identifier), '=', field('value', $.expression)),
            // A bare positional entry: `return {ctx, name = value}`.
            $.expression,
          ),
        ),
        optional(','),
        '}',
      ),

    implicit_member_expression: ($) =>
      prec(PREC.call, seq('.', field('name', $.identifier))),

    transfer_expression: ($) =>
      prec(PREC.call, seq(field('value', $.primary_expression), '^')),

    // Backtick-quoted name: LLVM metadata keys and MLIR names —
    // `@__llvm_metadata(`nvvm.minctasm`=...)`.
        backtick_name: (_) => token(prec(1, seq('`', /[^`\n]+/, '`'))),

    keyword_argument: ($) =>
      seq(
        field('name', choice($.identifier, $.keyword_identifier, $.backtick_name)),
        '=',
        // A function type can be a keyword value in MLIR parameter
        // brackets: `__mlir_op.x[_type=def(A) thin -> None](...)`, as
        // can an MLIR type: `_type=__mlir_type.`vector<4 x bf16>``.
        field('value', choice($.expression, $.function_type, $.mlir_type)),
      ),

    // A subscript keyword argument whose value is a slice:
    // `self[byte = : self.byte_length() - suffix.byte_length()]`.
    slice_keyword_argument: ($) =>
      seq(
        field('name', choice($.identifier, $.keyword_identifier, $.backtick_name)),
        '=',
        field('value', $.slice),
      ),

    // Literals

    mlir_op: ($) => seq('__mlir_op', '.', $._mlir_literal),

    mlir_attr: ($) =>
      choice(
        seq('__mlir_attr', '.', $._mlir_literal),
        seq('__mlir_attr', '.', $.identifier),
        seq(
          '__mlir_attr',
          '[',
          commaSep1(choice($._mlir_literal, $.expression)),
          optional(','),
          ']',
        ),
      ),

    _mlir_literal: ($) => token(seq('`', /[^`]*/, '`')),

    mlir_type: ($) =>
      // Dynamic precedence over member_type / attribute readings of the
      // dotted form: `__mlir_type.index` is an MLIR type, not a member.
      prec.dynamic(
        1,
        seq(
          '__mlir_type',
        choice(
          seq('.', $.identifier),
          seq('.`', $._mlir_type, '`'),
          seq(
            '[',
            commaSep1(
              choice(
                $._mlir_literal,
                seq('`', $._mlir_type, '`'),
                $.expression,
              ),
            ),
            optional(','),
            ']',
          ),
          ),
        ),
      ),

    _mlir_type: ($) =>
      prec.left(
        seq(
          optional('>'),
          choice(
            $._mlir_type_def,
            seq(
              '(',
              repeat(seq($._mlir_type_def, optional(','))),
              ')',
              '->',
              $._mlir_type_def,
            ),
          ),
          optional(
            choice(
              seq(
                '<',
                // Dimensioned forms: `vector<4 x bf16>`, `vector<8 x i8>`
                // — size segments joined by `x`, element type last.
                seq($._mlir_type, repeat(seq('x', $._mlir_type))),
                '>',
              ),
              '<',
            ),
          ),
        ),
      ),
    _mlir_type_def: ($) =>
      prec.left(
        seq(
          optional(':'),
          choice(
            seq('!', sep1(alias($.identifier, $.type), '.')),
            alias($.identifier, $.type),
            // Integer arguments: `!llvm.ptr<8>` (address space).
            $.integer,
          ),
        ),
      ),

    list: ($) => seq('[', optional($._collection_elements), ']'),

    set: ($) => seq('{', $._collection_elements, '}'),

    tuple: ($) => seq('(', optional($._collection_elements), ')'),

    dictionary: ($) =>
      seq(
        '{',
        optional(commaSep1(choice($.pair, $.dictionary_splat))),
        optional(','),
        '}',
      ),

    pair: ($) =>
      seq(field('key', $.expression), ':', field('value', $.expression)),

    list_comprehension: ($) =>
      seq('[', field('body', $.expression), $._comprehension_clauses, ']'),

    dictionary_comprehension: ($) =>
      seq('{', field('body', $.pair), $._comprehension_clauses, '}'),

    set_comprehension: ($) =>
      seq('{', field('body', $.expression), $._comprehension_clauses, '}'),

    generator_expression: ($) =>
      seq('(', field('body', $.expression), $._comprehension_clauses, ')'),

    _comprehension_clauses: ($) =>
      seq($.for_in_clause, repeat(choice($.for_in_clause, $.if_clause))),

    parenthesized_expression: ($) =>
      prec(
        PREC.parenthesized_expression,
        seq('(', choice($.expression, $.yield), ')'),
      ),

    _collection_elements: ($) =>
      seq(
        commaSep1(
          choice(
            $.expression,
            $.yield,
            $.list_splat,
            $.parenthesized_list_splat,
          ),
        ),
        optional(','),
      ),

    for_in_clause: ($) =>
      prec.left(
        seq(
          optional('async'),
          'for',
          field('left', $._left_hand_side),
          'in',
          field('right', commaSep1($._expression_within_for_in_clause)),
          optional(','),
        ),
      ),

    if_clause: ($) => seq('if', $.expression),

    conditional_expression: ($) =>
      prec.right(
        PREC.conditional,
        seq($.expression, 'if', $.expression, 'else', $.expression),
      ),

    concatenated_string: ($) => prec.left(seq($.string, repeat1($.string))),

    string: ($) =>
      seq(
        $.string_start,
        repeat(choice($.interpolation, $.string_content)),
        $.string_end,
      ),

    string_content: ($) =>
      prec.right(
        repeat1(
          choice(
            $.escape_interpolation,
            $.escape_sequence,
            $._not_escape_sequence,
            $._string_content,
          ),
        ),
      ),

    interpolation: ($) =>
      seq(
        '{',
        field('expression', $._f_expression),
        optional('='),
        optional(field('type_conversion', $.type_conversion)),
        optional(field('format_specifier', $.format_specifier)),
        '}',
      ),

    _f_expression: ($) =>
      choice($.expression, $.expression_list, $.pattern_list, $.yield),

    escape_sequence: (_) =>
      token.immediate(
        prec(
          1,
          seq(
            '\\',
            choice(
              /u[a-fA-F\d]{4}/,
              /U[a-fA-F\d]{8}/,
              /x[a-fA-F\d]{2}/,
              /\d{1,3}/,
              /\r?\n/,
              /['"abfrntv\\]/,
              /N\{[^}]+\}/,
            ),
          ),
        ),
      ),

    _not_escape_sequence: (_) => token.immediate('\\'),

    format_specifier: ($) =>
      seq(
        ':',
        repeat(
          choice(
            token(prec(1, /[^{}\n]+/)),
            alias($.interpolation, $.format_expression),
          ),
        ),
      ),

    type_conversion: (_) => /![a-z]/,

    integer: (_) =>
      token(
        choice(
          seq(choice('0x', '0X'), repeat1(/_?[A-Fa-f0-9]+/), optional(/[Ll]/)),
          seq(choice('0o', '0O'), repeat1(/_?[0-7]+/), optional(/[Ll]/)),
          seq(choice('0b', '0B'), repeat1(/_?[0-1]+/), optional(/[Ll]/)),
          seq(
            repeat1(/[0-9]+_?/),
            choice(
              optional(/[Ll]/), // long numbers
              optional(/[jJ]/), // complex numbers
            ),
          ),
        ),
      ),

    float: (_) => {
      const digits = repeat1(/[0-9]+_?/);
      const exponent = seq(/[eE][\+-]?/, digits);

      return token(
        seq(
          choice(
            seq(digits, '.', optional(digits), optional(exponent)),
            seq(optional(digits), '.', digits, optional(exponent)),
            seq(digits, exponent),
          ),
          optional(/[jJ]/),
        ),
      );
    },

    identifier: (_) => /[_\p{XID_Start}][_\p{XID_Continue}]*/,

    keyword_identifier: ($) =>
      choice(
        prec(
          -3,
          alias(choice('print', 'exec', 'async', 'await'), $.identifier),
        ),
        alias(choice('type', 'match'), $.identifier),
      ),

    true: (_) => 'True',
    false: (_) => 'False',
    none: (_) => 'None',

    await: ($) =>
      prec(PREC.unary, seq(choice('await', '__await'), $.primary_expression)),

    comment: (_) => token(seq('#', /.*/)),

    line_continuation: (_) =>
      token(seq('\\', choice(seq(optional('\r'), '\n'), '\0'))),

    positional_separator: (_) => '/',
    keyword_separator: (_) => '*',
  },
});


/**
 * Creates a rule to match one or more of the rules separated by a comma
 *
 * @param {RuleOrLiteral} rule
 *
 * @returns {SeqRule}
 */
function commaSep1(rule) {
  return sep1(rule, ',');
}

/**
 * Creates a rule to match one or more occurrences of `rule` separated by `sep`
 *
 * @param {RuleOrLiteral} rule
 *
 * @param {RuleOrLiteral} separator
 *
 * @returns {SeqRule}
 */
function sep1(rule, separator) {
  return seq(rule, repeat(seq(separator, rule)));
}

