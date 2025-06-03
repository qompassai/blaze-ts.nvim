// /qompassai/blaze-ts.nvim/src/parser.zig
// ----------------------------------------------
// Copyright (C) 2025 Qompass AI, All rights reserved
const ts = @import("tree-sitter");
export fn tree_sitter_mojo() callconv(.C) *ts.Language {
    return @import("tree_sitter_mojo");
}
