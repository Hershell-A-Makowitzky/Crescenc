// Reference implementation of SHA1 algorithm according to "https://www.rfc-editor.org/rfc/rfc3174"
// Only for studying purposes
// compilation: "zig build-exe -OReleaseFast -fstrip --name hersha sha.zig"

const std = @import("std");
const fp = @import("flagsProcessor.zig").FlagsProcessor;
const pb = @import("processBuffer.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    var options = fp{};
    try fp.processFlags(&options, args);
}
