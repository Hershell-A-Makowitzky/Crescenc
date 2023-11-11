const std = @import("std");
const fp  = @import("flags_processor.zig");
const ch  = @import("calculate_hash.zig");
const pes = @import("padding_end_special.zig");
const ph  = @import("print_hash.zig");
const ps  = @import("padding_short.zig");
const psl = @import("padding_special.zig");
const pe  = @import("padding_end.zig");

pub fn processBuffer(file: std.fs.File, name: []const u8, flags: *fp.FlagsProcessor) ![5]u32 {
    const ssize: usize = 4096;
    var buffer: [ssize]u8 = undefined;
    var size = if (file.handle == std.os.STDIN_FILENO) try file.readAll(&buffer) else try file.read(&buffer);
    var index: usize = 0;
    var strlen: usize = 0;
    var bufferB: [5]u32 = [_]u32{
        0x67452301,
        0xEFCDAB89,
        0x98BADCFE,
        0x10325476,
        0xC3D2E1F0,
    };
    _ = name;
    _ = flags;
    // std.debug.print("{}\n", .{size});
    while (true) {
        if (index + 64 <= size) {
            // std.debug.print("In loop {} {}\n", .{index, index + 64});
            // var rest = padding(buffer[index..(index + 64)]);
            // TODO: optimize without calling padding (cast [64]u8 to [5]u32)
            var input: [16]u32 = undefined;
            var pointer: *[64]u8 = @ptrCast(&input);
            inline for (0..64, 0..) |_, i| {
                pointer[i] = buffer[index + i];
            }
            ch.calculateHash(&input, &bufferB);
            index += 64;
            strlen += 64;
            // std.debug.print("Strlen in loop {}\n", .{strlen});
        } else {
            if (size == ssize) {
                // std.debug.print("turn\n", .{});
                strlen += size - index;
                index = 0;
                size = try file.read(&buffer);
            } else {
                index = size - index;
                // std.debug.print("Index in break {}\n", .{index});
                strlen += index;
                // std.debug.print("Strlen {}\n", .{strlen});
                // std.debug.print("Index in main {}\n", .{index});
                switch (index) {
                    0 => {
                        var rest = pes.paddingEndSpecial(strlen);
                        ch.calculateHash(&rest, &bufferB);
                        // try ph.printHash(bufferB, name, flags);
                    },
                    1...55 => {
                        // strlen += index;
                        var rest = ps.paddingShort(buffer[(size - index)..size], strlen, index);
                        ch.calculateHash(&rest, &bufferB);
                        // try ph.printHash(bufferB, name, flags);
                    },
                    56...63 => {
                        // strlen += index;
                        var rest = psl.paddingSpecial(buffer[(size - index)..size], index);
                        _ = ch.calculateHash(&rest, &bufferB);
                        rest = pe.paddingEnd(strlen);
                        ch.calculateHash(&rest, &bufferB);
                        // try ph.printHash(bufferB, name, flags);
                    },
                    else => {},
                }
                break;
            }
        }
    }
    return bufferB;
}
