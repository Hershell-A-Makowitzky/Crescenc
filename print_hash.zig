const std = @import("std");
const fp = @import("flags_processor.zig");

pub fn printHash(hash: [5]u32, file: []const u8, flag: fp.FlagsProcessor.Flags) !void {
    const stdout = std.io.getStdOut().writer();
    for (hash) |val| {
        try stdout.print("{x:0>8}", .{val});
    }
    if (flag == fp.FlagsProcessor.Flags.zero) {
        try stdout.print("  {s}\x00", .{file});
        return;
    }
    try stdout.print("  {s}\n", .{file});
}
