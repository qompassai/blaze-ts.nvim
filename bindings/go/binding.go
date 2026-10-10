// -------------------------------------------------------------------------------
// /qompassai/blaze-ts.nvim/bindings/go/binding.go
// Qompass AI Go binding for the Mojo grammar
// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Qompass AI
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not
// use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
// -------------------------------------------------------------------------------

package tree_sitter_mojo

// #cgo CFLAGS: -std=c11 -fPIC
// #include "../../src/parser.c"
// #if __has_include("../../src/scanner.c")
// #include "../../src/scanner.c"
// #endif
import "C"

import "unsafe"

// Get the tree-sitter Language for this grammar.
func Language() unsafe.Pointer {
	return unsafe.Pointer(C.tree_sitter_mojo())
}
