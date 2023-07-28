const std = @import("std");

const K1: u32 = 0x5A827999;
const K2: u32 = 0x6ED9EBA1;
const K3: u32 = 0x8F1BBCDC;
const K4: u32 = 0xCA62C1D6;

fn circular(n: u5, w: u32) u32 {
    return (w << n) | (w >> ((31 - n) + 1));
}

fn f(u: usize, b: u32, c: u32, d: u32) !u32 {
    if (u <= 19 ) {
        return (b & c) | ((~b) & d);
    }
    if (u <= 39) {
        return b ^ c ^ d;
    }
    if (u <= 59) {
        return (b & c) | (b & d) | (c & d);
    }
    if (u <= 79) {
        return b ^ c ^ d;
    }
    return error.WordError;
}

fn k(u: usize) !u32 {
    if (u <= 19) {
        return K1;
    }
    if (u <= 39) {
        return K2;
    }
    if (u <= 59) {
        return K3;
    }
    if (u <= 79) {
        return K4;
    }
    return error.WordError;
}

fn padding(message: [] const u8) [16]u32 {
        var length: u64 = message.len;
        const p_length: *[8]u8 = @ptrCast(*[8]u8, &length);
        var padded: [16]u32 = undefined;
        const p_padded: *[64]u8 = @ptrCast(*[64]u8, &padded);
        for ([_]u8{0}**56) |_, i| {
            if (i < length) {
                p_padded[i] = message[i];
                continue;
            }
            if (i == length) {
                p_padded[i] = '\x80';
                continue;
            }
            p_padded[i] = '\x00';
        }

        length *= 8;
        for ([_]u8{0}**8) |_, i| {
            p_padded[56 + i] = p_length[7 - i];
        }
        return padded;
}

test "k" {
    const k1 = try k(1);
    const k2 = try k(21);
    const k3 = try k(41);
    const k4 = try k(61);
    std.debug.assert(std.mem.eql(u8, &K1, &k1));
    std.debug.assert(std.mem.eql(u8, &K2, &k2));
    std.debug.assert(std.mem.eql(u8, &K3, &k3));
    std.debug.assert(std.mem.eql(u8, &K4, &k4));
}

fn calculateHash(message: [] const u8) ![5]u32 {
    var block: [16]u32 = padding(message);
    var bufferA: [5]u32 = undefined;
    var bufferB: [5]u32 = [_]u32{
        0x67452301,
        0xEFCDAB89,
        0x98BADCFE,
        0x10325476,
        0xC3D2E1F0,
    };
    var temp: u32 = undefined;
    var seq: [80]u32 = undefined;

    for (seq) |*val, i| {
        if (i < 16) {
            val.* = std.mem.nativeToBig(u32, block[i]);
        } else {
            val.* = circular(1, seq[i - 3] ^ seq[i - 8] ^ seq[i - 14] ^ seq[i - 16]);
        }
    }

    for (bufferA) |*val, i| {
        val.* = bufferB[i];
    }

    for ([_]u8{0} ** 80) |_, i| {
        temp = circular(5, bufferA[0]) +% try f(i, bufferA[1], bufferA[2], bufferA[3]) +% bufferA[4] +% seq[i] +% try k(i);
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

fn printHash(hash: [5]u32) void {
    for (hash) |val| {
        std.debug.print("{x:0^8}", .{val});
    }
    std.debug.print("\n", .{});
}

fn splitMessage(message: [] const u8) !void {
    var start: usize = 0;
    var stop: usize = 64;
    var length = message.len;
    while (length > 64) {
        // std.debug.print("{s}\n", .{message[start..stop]});
        const result = try calculateHash(message[start..stop]);
        printHash(result);
        start = stop;
        stop += 64;
        length -= 64;
    }
    const rest: usize = start + length;
    // std.debug.print("{s}\n", .{message[start..rest]});
    const result = try calculateHash(message[start..rest]);
    printHash(result);

}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    if (args.len != 2) {
        std.debug.print("Usage '{s}' <string>\n", .{args[0]});
        std.process.exit(1);
    }
    const message = args[1];
    // const result = try calculateHash(message);
    // printHash(result);
    _ = try splitMessage(message);
}
