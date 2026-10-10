// -------------------------------------------------------------------------------
// /qompassai/blaze-ts.nvim/src/root.zig
// Qompass AI Zig binding for the Mojo grammar
// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Qompass AI
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not
// use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
// -------------------------------------------------------------------------------

//! Zig binding for the Mojo tree-sitter grammar.
//!
//! The parser itself is C (src/parser.c + src/scanner.c, built by build.zig
//! into a static library). This module exposes the single symbol every
//! tree-sitter grammar exports: tree_sitter_mojo(), which returns an opaque
//! pointer to the TSLanguage struct for the tree-sitter runtime to consume.

const std = @import("std");

extern fn tree_sitter_mojo() *const anyopaque;

/// The Mojo language object, as an opaque TSLanguage pointer.
pub fn language() *const anyopaque {
    return tree_sitter_mojo();
}

test "language symbol resolves to a non-null pointer" {
    try std.testing.expect(@intFromPtr(language()) != 0);
}
