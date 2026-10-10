; -------------------------------------------------------------------------------
; /qompassai/blaze-ts.nvim/runtime/queries/mojo/indents.scm
; Qompass AI Tree-sitter indents query for Mojo
; SPDX-License-Identifier: Apache-2.0
; Copyright (c) 2026 Qompass AI
;
; Licensed under the Apache License, Version 2.0 (the "License"); you may not
; use this file except in compliance with the License. You may obtain a copy
; of the License at http://www.apache.org/licenses/LICENSE-2.0
; -------------------------------------------------------------------------------

; Indents for the Mojo grammar (nvim-treesitter indent query).
; Node names verified against src/node-types.json. The grammar's external
; _indent/_dedent tokens are not named nodes, so indentation is driven by
; the block-bearing statements themselves.

[
  (block)
  (function_definition)
  (class_definition)
  (trait_definition)
  (if_statement)
  (for_statement)
  (while_statement)
  (try_statement)
  (with_statement)
  (match_statement)
  (case_clause)
  (argument_list)
  (parameters)
  (parenthesized_expression)
  (list)
  (tuple)
  (dictionary)
  (set)
] @indent.begin

[
  ")"
  "]"
  "}"
] @indent.end

[
  (elif_clause)
  (else_clause)
  (except_clause)
  (except_group_clause)
  (finally_clause)
] @indent.branch

(ERROR) @indent.begin
