; -------------------------------------------------------------------------------
; /qompassai/blaze-ts.nvim/runtime/queries/mojo/highlights.scm
; Qompass AI Tree-sitter highlights query for Mojo
; SPDX-License-Identifier: Apache-2.0
; Copyright (c) 2026 Qompass AI
;
; Licensed under the Apache License, Version 2.0 (the "License"); you may not
; use this file except in compliance with the License. You may obtain a copy
; of the License at http://www.apache.org/licenses/LICENSE-2.0
; -------------------------------------------------------------------------------

; Highlights for the Mojo grammar.
;
; Written against this grammar's actual node inventory (src/node-types.json).
; Structure follows the tree-sitter-python highlights query, whose grammar
; this one adapts, with Mojo-specific additions (fn/struct/trait, raises,
; argument conventions, builtin type names).

; Identifier naming conventions

(identifier) @variable

((identifier) @constructor
  (#match? @constructor "^[A-Z]"))

((identifier) @constant
  (#match? @constant "^[A-Z][A-Z_]*$"))

; Function calls

(decorator) @attribute

(call
  function: (attribute
    attribute: (identifier) @function.method.call))

(call
  function: (identifier) @function.call)

; Builtin functions

((call
  function: (identifier) @function.builtin)
  (#match?
    @function.builtin
    "^(abs|bool|debug_assert|enumerate|float|hash|int|len|max|min|print|range|repr|reversed|sorted|static_assert|str|sum|type|zip)$"))

; Function definitions

(function_definition
  name: (identifier) @function)

(attribute
  attribute: (identifier) @variable.member)

; Types

(type
  (identifier) @type)

(generic_type
  (identifier) @type)

(class_definition
  name: (identifier) @type)

(trait_definition
  name: (identifier) @type)

((type
  (identifier) @type.builtin)
  (#match?
    @type.builtin
    "^(Bool|Int|UInt|Int8|UInt8|Int16|UInt16|Int32|UInt32|Int64|UInt64|Int128|UInt128|Float16|Float32|Float64|SIMD|DType|String|StringSlice|List|Dict|Object|Self|UnsafePointer|OwnedPointer|ArcPointer|Pointer|VariadicList|VariadicPack)$"))

(mlir_type) @type.builtin

; Parameters

(parameters
  (identifier) @variable.parameter)

(parameters
  (typed_parameter
    (identifier) @variable.parameter))

(parameters
  (default_parameter
    name: (identifier) @variable.parameter))

(parameters
  (typed_default_parameter
    name: (identifier) @variable.parameter))

(self_parameter
  "self" @variable.parameter.builtin)

(argument_convention) @keyword.modifier

(keyword_argument
  name: (identifier) @variable.parameter)

; Literals

[
  (none)
  (true)
  (false)
] @constant.builtin

(integer) @number

(float) @number.float

(comment) @comment

(string) @string

(escape_sequence) @string.escape

(interpolation
  "{" @punctuation.special
  "}" @punctuation.special)

; Operators

[
  "-"
  "-="
  "!="
  "*"
  "**"
  "**="
  "*="
  "/"
  "//"
  "//="
  "/="
  "&"
  "&="
  "%"
  "%="
  "^"
  "^="
  "+"
  "->"
  "+="
  "<"
  "<<"
  "<<="
  "<="
  "<>"
  "="
  ":="
  "=="
  ">"
  ">="
  ">>"
  ">>="
  "|"
  "|="
  "~"
  "@="
  "and"
  "in"
  "is"
  "not"
  "or"
] @operator

; Punctuation

[
  "("
  ")"
  "["
  "]"
  "{"
  "}"
] @punctuation.bracket

[
  ","
  "."
  ":"
  ";"
] @punctuation.delimiter

; Keywords

[
  "as"
  "assert"
  "async"
  "await"
  "break"
  "class"
  "continue"
  "def"
  "del"
  "elif"
  "else"
  "except"
  "exec"
  "finally"
  "fn"
  "for"
  "from"
  "global"
  "if"
  "import"
  "lambda"
  "let"
  "nonlocal"
  "pass"
  "print"
  "raise"
  "raises"
  "return"
  "struct"
  "trait"
  "try"
  "var"
  "alias"
  "while"
  "with"
  "yield"
  "match"
  "case"
] @keyword
