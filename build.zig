const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "tree-sitter-mojo",
        .target = target,
        .optimize = optimize,
    });

    exe.addCSourceFile("src/parser.c", &[_][]const u8{});
    const scanner_path = "src/scanner.c";
    const scanner_file = std.fs.cwd().openFile(scanner_path, .{ .mode = .read_only }) catch null;
    const scanner_exists = scanner_file != null;

    if (scanner_exists) {
        exe.addCSourceFile(scanner_path, &[_][]const u8{});
    }

    exe.linkLibC();
    exe.linkSystemLibrary("c");
    exe.install();
}
