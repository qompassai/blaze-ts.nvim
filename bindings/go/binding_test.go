// -------------------------------------------------------------------------------
// /qompassai/blaze-ts.nvim/bindings/go/binding_test.go
// Qompass AI Go binding test
// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Qompass AI
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not
// use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
// -------------------------------------------------------------------------------

package tree_sitter_mojo_test

import (
	"testing"

	tree_sitter_mojo "github.com/qompassai/blaze-ts.nvim/bindings/go"
	tree_sitter "github.com/tree-sitter/go-tree-sitter"
)

func TestCanLoadGrammar(t *testing.T) {
	language := tree_sitter.NewLanguage(tree_sitter_mojo.Language())
	if language == nil {
		t.Errorf("Error loading Mojo grammar")
	}
}
