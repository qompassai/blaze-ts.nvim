// qompassai/blaze-ts.nvim/src/main.zig
// Main Zig Module for blaze-ts.nvim
// Copyright (C) 2025 Qompass AI, All rights reserved

const std = @import("std");
const lib = @import("blaze_ts_nvim_lib");
pub fn main() !void {
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
    std.debug.print("Run `zig build test` to run the tests.\n", .{});
}
test "ArrayList: append and pop" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit();
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
test "lib.add: basic addition" {
    try std.testing.expectEqual(@as(i32, 150), lib.add(100, 50));
}
test "fuzz: input should not match 'canyoufindme'" {
    const FuzzTarget = struct {
        fn run(input: []const u8) !void {
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.FuzzTarget.run(FuzzTarget.run);
}
        .testWithSeed(1234);
}
