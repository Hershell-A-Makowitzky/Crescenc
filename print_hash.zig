const std = @import("std");
const fp  = @import("flags_processor.zig");

pub fn printHash(hash: [5]u32, file: []const u8, flags: *fp.FlagsProcessor) !void {
    const stdout = std.io.getStdOut().writer();
    if (flags.f[3] == fp.FlagsProcessor.Flags.tag) {
        try stdout.print("SHA1 ({s}) = ", .{file});
        for (hash) |val| {
            try stdout.print("{x:0>8}", .{val});
        }
        if (flags.f[5] == fp.FlagsProcessor.Flags.zero) {
            try stdout.print("\x00", .{});
            return;
        }
        return;
    }
    if (flags.f[1] == fp.FlagsProcessor.Flags.binary) {
        for (hash) |val| {
            try stdout.print("{x:0>8}", .{val});
        }
        if (flags.f[5] == fp.FlagsProcessor.Flags.zero) {
            try stdout.print(" *{s}\x00", .{file});
            return;
        }
        try stdout.print("  {s}\n", .{file});
        return;
    }
    for (hash) |val| {
        try stdout.print("{x:0>8}", .{val});
    }
    if (flags.f[5] == fp.FlagsProcessor.Flags.zero) {
        try stdout.print("  {s}\x00", .{file});
        return;
    } else {
        try stdout.print("  {s}\n", .{file});
    }
}
