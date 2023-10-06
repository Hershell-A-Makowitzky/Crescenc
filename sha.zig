// Reference implementation of SHA1 algorithm according to "https://www.rfc-editor.org/rfc/rfc3174"
// Only for personal purposes

const std = @import("std");
const fp  = @import("flags_processor.zig").FlagsProcessor;
const pb  = @import("process_buffer.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    var options = fp{};
    try fp.processFlags(&options, args);
}
