// Reference implementation of SHA1 algorithm according to "https://www.rfc-editor.org/rfc/rfc3174"
// Only for studying purposes
// compilation: "zig build-exe -OReleaseFast -fstrip --name hersha sha.zig"

const std = @import("std");

const K1: u32 = 0x5A827999;
const K2: u32 = 0x6ED9EBA1;
const K3: u32 = 0x8F1BBCDC;
const K4: u32 = 0xCA62C1D6;

const Flags = enum {
    binary,
    check,
    tag,
    text,
    zero,
    ingnoreMissing,
    quiet,
    status,
    strict,
    warn,
    help,
    version
};

var bufferB: [5]u32 = [_]u32{
    0x67452301,
    0xEFCDAB89,
    0x98BADCFE,
    0x10325476,
    0xC3D2E1F0,
};

fn circular(n: u5, w: u32) u32 {
    return (w << n) | (w >> ((31 - n) + 1));
}

fn f(u: usize, b: u32, c: u32, d: u32) u32 {
    if (u <= 19) {
        return (b & c) | ((~b) & d);
    }
    if (u <= 39) {
        return b ^ c ^ d;
    }
    if (u <= 59) {
        return (b & c) | (b & d) | (c & d);
    }
    return b ^ c ^ d;
}

fn k(u: usize) u32 {
    if (u <= 19) {
        return K1;
    }
    if (u <= 39) {
        return K2;
    }
    if (u <= 59) {
        return K3;
    }
    return K4;
}

fn paddingShort(message: []const u8, length: usize, tail: usize) [16]u32 {
    var innerLength = length;
    var p_length: *[8]u8 = @as(*[8]u8, @ptrCast(&innerLength));
    var padded: [16]u32 = undefined;
    const p_padded: *[64]u8 = @as(*[64]u8, @ptrCast(&padded));
    for (0..56, 0..) |_, i| {
        if (i < tail) {
            p_padded[i] = message[i];
            continue;
        }
        if (i == tail) {
            p_padded[i] = '\x80';
            continue;
        }
        p_padded[i] = '\x00';
    }

    innerLength *= 8;
    for (0..8, 0..) |_, i| {
        p_padded[56 + i] = p_length[7 - i];
    }
    return padded;
}

fn padding(message: []const u8) [16]u32 {
    var padded: [16]u32 = undefined;
    const p_padded: *[64]u8 = @as(*[64]u8, @ptrCast(&padded));
    for (0..64, 0..) |_, i| {
        p_padded[i] = message[i];
    }
    return padded;
}
fn paddingSpecial(message: []const u8, tail: usize) [16]u32 {
    var padded: [16]u32 = undefined;
    const p_padded: *[64]u8 = @as(*[64]u8, @ptrCast(&padded));
    for (0..64, 0..) |_, i| {
        if (i < tail) {
            p_padded[i] = message[i];
            continue;
        }
        if (i == tail) {
            p_padded[i] = '\x80';
            continue;
        }
        p_padded[i] = '\x00';
    }
    return padded;
}

fn paddingEnd(length: usize) [16]u32 {
    var innerLength = length;
    var p_length: *[8]u8 = @as(*[8]u8, @ptrCast(&innerLength));
    var padded: [16]u32 = undefined;
    const p_padded: *[64]u8 = @as(*[64]u8, @ptrCast(&padded));
    for (0..56, 0..) |_, i| {
        p_padded[i] = '\x00';
    }

    innerLength *= 8;
    for (0..8, 0..) |_, i| {
        p_padded[56 + i] = p_length[7 - i];
    }
    return padded;
}

fn paddingEndSpecial(length: usize) [16]u32 {
    var innerLength = length;
    var p_length: *[8]u8 = @as(*[8]u8, @ptrCast(&innerLength));
    var padded: [16]u32 = undefined;
    const p_padded: *[64]u8 = @as(*[64]u8, @ptrCast(&padded));
    for (0..56, 0..) |_, i| {
        if (i == 0) {
            p_padded[i] = '\x80';
            continue;
        }
        p_padded[i] = '\x00';
    }

    innerLength *= 8;
    for (0..8, 0..) |_, i| {
        p_padded[56 + i] = p_length[7 - i];
    }
    return padded;
}

fn calculateHash(message: *[16]u32) [5]u32 {
    var bufferA: [5]u32 = undefined;
    var temp: u32 = undefined;
    var seq: [80]u32 = undefined;


    for (&seq, 0..) |*val, i| {
        if (i < 16) {
            val.* = std.mem.nativeToBig(u32, message[i]);
        } else {
            val.* = circular(1, seq[i - 3] ^ seq[i - 8] ^ seq[i - 14] ^ seq[i - 16]);
        }
    }

    for (&bufferA, 0..) |*val, i| {
        val.* = bufferB[i];
    }

    for (0..80, 0..) |_, i| {
        temp = circular(5, bufferA[0]) +% f(i, bufferA[1], bufferA[2], bufferA[3]) +% bufferA[4] +% seq[i] +% k(i);
        bufferA[4] = bufferA[3];
        bufferA[3] = bufferA[2];
        bufferA[2] = circular(30, bufferA[1]);
        bufferA[1] = bufferA[0];
        bufferA[0] = temp;
    }

    bufferB[0] +%= bufferA[0];
    bufferB[1] +%= bufferA[1];
    bufferB[2] +%= bufferA[2];
    bufferB[3] +%= bufferA[3];
    bufferB[4] +%= bufferA[4];

    return bufferB;
}

fn printHash(hash: [5]u32, file: []const u8) !void {
    const stdout = std.io.getStdOut().writer();
    for (hash) |val| {
        try stdout.print("{x:0>8}", .{val});
    }
    try stdout.print("  {s}\n", .{file});
}

fn printPadded(block: [16]u32) void {
    for (block, 0..) |value, i| {
        if (i % 4 == 0) {
            std.debug.print("\n", .{});
        }
        std.debug.print("{x:0>8} ", .{std.mem.nativeToBig(u32, value)});
    }
    std.debug.print("\n\n", .{});
}

fn processBuffer(file: std.fs.File, name: []const u8) !void {
    var buffer: [64]u8 = undefined;
    var index = try file.read(&buffer);
    var strlen: usize = undefined;
    while (index == 64) {
        strlen += index;
        var rest = padding(buffer[0..index]);
        _ = calculateHash(&rest);
        index = try file.read(&buffer);
    }
    switch (index) {
        0 => {
            var rest = paddingEndSpecial(strlen);
            const result = calculateHash(&rest);
            try printHash(result, name);
        },
        1...55 => {
            strlen += index;
            var rest = paddingShort(buffer[0..index], strlen, index);
            const result = calculateHash(&rest);
            try printHash(result, name);
        },
        56...63 => {
            strlen += index;
            var rest = paddingSpecial(buffer[0..index], index);
            _ = calculateHash(&rest);
            rest = paddingEnd(strlen);
            const result = calculateHash(&rest);
            try printHash(result, name);
        },
        else => {}
    }
}

// fn processOptions(args: []const [:0]u8) void {

// }

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    // const stdout = std.io.getStdOut().writer();
    if (args.len == 1 or std.mem.eql(u8, args[1], "-")) {
        const stdin = std.io.getStdIn();
        defer stdin.close();
        try processBuffer(stdin, "-");
        // try stdout.print("  -\n", .{});
    } else {
        for (args[1..]) |arg| {
            const file = std.fs.cwd().openFile(arg, .{}) catch {
                std.debug.print("hersha: {s}: No such file or directory\n", .{arg});
                continue;
            };
            defer file.close();
            try processBuffer(file, arg);
            // try stdout.print("  {s}\n", .{arg});
        }
    }
}
