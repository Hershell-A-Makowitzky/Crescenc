const std = @import("std");

fn format(input: [4]u8) void {
    for (input) |value| {
        std.debug.print("{x:0^2}", .{value});
    }
    std.debug.print("\n", .{});
}

pub fn main() void {
    // const word: [4]u8 = [_]u8 {0} ** 4;
    const word: [4]u8 = [_]u8 {'a', 'b', 'c', 'd'};
    std.debug.print("{any}", .{word | word});
    format(word);
}
