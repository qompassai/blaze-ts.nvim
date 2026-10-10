; -------------------------------------------------------------------------------
; /qompassai/blaze-ts.nvim/runtime/queries/mojo/locals.scm
; Qompass AI Tree-sitter locals query for Mojo
; SPDX-License-Identifier: Apache-2.0
; Copyright (c) 2026 Qompass AI
;
; Licensed under the Apache License, Version 2.0 (the "License"); you may not
; use this file except in compliance with the License. You may obtain a copy
; of the License at http://www.apache.org/licenses/LICENSE-2.0
; -------------------------------------------------------------------------------

; Locals for the Mojo grammar (nvim-treesitter locals query).
; Node and field names verified against src/node-types.json.

; Scopes

[
  (module)
  (function_definition)
  (class_definition)
  (trait_definition)
  (lambda)
] @local.scope

; Definitions

(function_definition
  name: (identifier) @local.definition.function)

(class_definition
  name: (identifier) @local.definition.type)

(trait_definition
  name: (identifier) @local.definition.type)

(parameters
  (identifier) @local.definition.parameter)

(typed_parameter
  (identifier) @local.definition.parameter)

(default_parameter
  name: (identifier) @local.definition.parameter)

(typed_default_parameter
  name: (identifier) @local.definition.parameter)

(assignment
  left: (identifier) @local.definition.var)

(assignment
  left: (pattern_list
    (identifier) @local.definition.var))

(for_statement
  left: (identifier) @local.definition.var)

(named_expression
  name: (identifier) @local.definition.var)

(aliased_import
  alias: (identifier) @local.definition.import)

; References

(identifier) @local.reference
