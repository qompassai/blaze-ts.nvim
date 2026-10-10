// -------------------------------------------------------------------------------
// /qompassai/blaze-ts.nvim/build.zig
// Qompass AI Zig build script
// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Qompass AI
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not
// use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
// -------------------------------------------------------------------------------

const std = @import("std");

/// Build the Mojo tree-sitter parser as a static library from its C sources,
/// and test the Zig binding that exposes the language symbol.
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const parser_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    parser_mod.addCSourceFiles(.{
        .files = &.{ "src/parser.c", "src/scanner.c" },
        .flags = &.{"-std=c11"},
    });
    parser_mod.addIncludePath(b.path("src"));

    const lib = b.addLibrary(.{
        .name = "tree-sitter-mojo",
        .linkage = .static,
        .root_module = parser_mod,
    });
    b.installArtifact(lib);

    const binding_mod = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    binding_mod.linkLibrary(lib);

    const binding_tests = b.addTest(.{ .root_module = binding_mod });
    const run_binding_tests = b.addRunArtifact(binding_tests);
    b.step("test", "Run the Zig binding test").dependOn(&run_binding_tests.step);
}
