// /qompassai/blze-ts.nvim/build.zig
// blaze-ts.nvim zig build
// Copyright (C) 2025 Qompass AI, All rights reserved

const std = @import("std");
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zts_pkg = b.dependency("zts", .{ .target = target, .optimize = optimize });

    const lib_mod = b.addModule("blaze_ts", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe_mod = b.addModule("blaze_ts_cli", .{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe_mod.addImport("blaze_ts", lib_mod);
    exe_mod.addImport("zts", zts_pkg.module("zts"));

    const lib = b.addStaticLibrary(.{
        .name = "blaze_ts_nvim",
        .root_module = lib_mod,
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(lib);

    const exe = b.addExecutable(.{
        .name = "blaze_ts_nvim",
        .root_module = exe_mod,
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    if (b.args) |cli_args| run_cmd.addArgs(cli_args);
    const run_step = b.step("run", "Run example CLI");
    run_step.dependOn(&run_cmd.step);

    const wasm_target = b.resolveTargetQuery(.{ .cpu_arch = .wasm32, .os_tag = .freestanding });
    const wasm = b.addSharedLibrary(.{
        .name = "tree-sitter-mojo",
        .root_source_file = .{ .path = "src/parser.c" },
        .target = wasm_target,
        .optimize = optimize,
    });
    wasm.addCSourceFile(.{ .file = .{ .path = "src/parser.c" }, .flags = &[_][]const u8{"-std=c99"} });
    if (std.fs.cwd().openFile("src/scanner.c", .{}) catch null) |f| {
        defer f.close();
        wasm.addCSourceFile(.{ .file = .{ .path = "src/scanner.c" }, .flags = &[_][]const u8{"-std=c99"} });
    }
    wasm.linkLibC();
    b.installArtifact(wasm);

    const lib_tests = b.addTest(.{ .root_module = lib_mod, .target = target, .optimize = optimize });
    const exe_tests = b.addTest(.{ .root_module = exe_mod, .target = target, .optimize = optimize });
    const test_step = b.step("test", "Run all unit tests");
    test_step.dependOn(&b.addRunArtifact(lib_tests).step);
    test_step.dependOn(&b.addRunArtifact(exe_tests).step);
}
