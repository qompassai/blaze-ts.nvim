// /qompassai/blaze-ts.nvim/build.zig
const std = @import("std");
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{
        .default_target = .{
            .cpu_arch = .wasm32,
            .os_tag = .wasi,
        },
    });
    const optimize = b.standardOptimizeOption(.{});
    const tree_sitter = b.dependency("tree_sitter", .{
        .target = target,
        .optimize = optimize,
    });
    const ts_mojo = b.dependency("tree_sitter_mojo", .{
        .target = target,
        .optimize = optimize,
    });
    const parser = b.addSharedLibrary(.{
        .name = "mojo",
        .root_source_file = .{ .path = "src/parser.zig" },
        .target = target,
        .optimize = optimize,
    });
    parser.addCSourceFile(.{
        .file = ts_mojo.path("src/parser.c"),
        .flags = &.{"-std=c11"},
    });
    if (fileExists(ts_mojo.path("src/scanner.c"))) {
        parser.addCSourceFile(.{
            .file = ts_mojo.path("src/scanner.c"),
            .flags = &.{"-std=c11"},
        });
    }
    parser.linkLibrary(tree_sitter.artifact("tree-sitter"));
    parser.linkLibC();
    const install_parser = b.addInstallArtifact(parser, .{
        .dest_dir = .{ .override = .{ .custom = "parser" } },
    });
    const exe = b.addExecutable(.{
        .name = "blaze_ts_nvim",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe.linkLibC();
    exe.addModule("tree-sitter", tree_sitter.module("tree-sitter"));
    b.installArtifact(exe);
    const test_step = b.step("test", "Run tests");
    const lib_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = optimize,
    });
    test_step.dependOn(&b.addRunArtifact(lib_tests).step);
    exe.step.dependOn(&install_parser.step);
}
fn fileExists(path: std.Build.LazyPath) bool {
    const file = path.getPath2(.{}, &.{});
    return std.fs.accessAbsolute(file, .{}) catch false;
}
