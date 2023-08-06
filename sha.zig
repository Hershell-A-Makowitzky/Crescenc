const std = @import("std");

const K1: u32 = 0x5A827999;
const K2: u32 = 0x6ED9EBA1;
const K3: u32 = 0x8F1BBCDC;
const K4: u32 = 0xCA62C1D6;

var bufferB: [5]u32 = [_]u32{
    0x67452301,
    0xEFCDAB89,
    0x98BADCFE,
    0x10325476,
    0xC3D2E1F0,
};

var lenght: u32 = 0;

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

fn messageToBLock(message: []const u8) [16]u32 {
    var block: [16]u32 = undefined;
    const p_padded: *[64]u8 = @as(*[64]u8, @ptrCast(&block));
    for (0..64, 0..) |_, i| {
        p_padded[i] = message[i];
    }
    return block;
}

fn calculateHash(message: *[16]u32) [5]u32 {
    // var block: [16]u32 = messageToBLock(message);
    // var block: *[16]u32 = @ptrCast(&message);
    var bufferA: [5]u32 = undefined;
    var temp: u32 = undefined;
    var seq: [80]u32 = undefined;

    // printPadded(message);

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

fn printHash(hash: [5]u32) void {
    for (hash) |val| {
        std.debug.print("{x:0>8}", .{val});
    }
    // std.debug.print("\n", .{});
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

fn splitMessage(message: []const u8) !void {
    var start: usize = 0;
    var stop: usize = 64;
    var length = message.len;
    var tail = length;
    if (length >= 56) {
        while (tail > 64) {
            // if (tail == 63) {
            //     var rest = padding(message[start..stop]);
            //     // std.debug.print("{s}\n", .{message[start..stop]});
            //     const result = calculateHash(&rest);
            //     printPadded(rest);
            //     printHash(result);
            //     return;
            // }
            var rest = padding(message[start..stop]);
            // std.debug.print("{s}\n", .{message[start..stop]});
            _ = calculateHash(&rest);
            // printPadded(rest);
            start = stop;
            stop += 64;
            tail -= 64;
        }
        // if (tail == 63) {
        //     var rest = padding(message[start..stop]);
        //     // std.debug.print("{s}\n", .{message[start..stop]});
        //     const result = calculateHash(&rest);
        //     printPadded(rest);
        //     printHash(result);
        //     return;
        // }
        // if (tail % 64 == 0) {
        //     stop = tail;
        //     std.debug.print("KVA", .{});
        //     var rest = paddingSpecial(message[start..stop], tail);
        //     printPadded(rest);
        //     _ = calculateHash(&rest);

        //     rest = paddingEndSpecial(length);
        //     printPadded(rest);
        //     const result = calculateHash(&rest);
        //     printHash(result);
        //     return;
        // }
        if (tail >= 56 and tail < 64) {
            // std.debug.print("56 and 64\n", .{});
            stop = tail;
            var rest = paddingSpecial(message[start..stop], tail);
            // printPadded(rest);
            _ = calculateHash(&rest);
            rest = paddingEnd(length);
            // printPadded(rest);
            const result = calculateHash(&rest);
            printHash(result);
            return;
            // printHash(result);
        } else if (tail == 64) {
            // std.debug.print("64\n", .{});
            stop = tail;
            var rest = padding(message[start..stop]);
            // printPadded(rest);
            _ = calculateHash(&rest);
            rest = paddingEndSpecial(length);
            // printPadded(rest);
            const result = calculateHash(&rest);
            printHash(result);
            return;
        }
        // std.debug.print("rest\n", .{});
        var rest = paddingShort(message[start..stop], length, tail);
        // printPadded(rest);
        const result = calculateHash(&rest);
        printHash(result);
        return;
    }

    var rest = paddingShort(message, length, length);
    // std.debug.print("IN SHORT\n", .{});
    // printPadded(rest);
    const result = calculateHash(&rest);
    printHash(result);
    // const rest: usize = start + length;
    // std.debug.print("{s}\n", .{message[start..rest]});
    // const result = calculateHash(message[start..rest]);
    // printHash(res&ult);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    // if (args.len != 2) {
    //     std.debug.print("Usage '{s}' <string>\n", .{args[0]});
    //     std.process.exit(1);
    // }
    // const message = args[1];
    if (args.len == 1 or std.mem.eql(u8, args[1], "-")) {
        // std.debug.print("{}\n", .{args.len});
        // std.debug.print("{}\n", .{std.mem.eql(u8, message, "-")});
        // std.debug.print("ARGS: {s}\n", .{message});
        const stdin = std.io.getStdIn();
        var buffer: [64]u8 = undefined;
        var index = try stdin.read(&buffer);
        var strlen: usize = undefined;
        while (index == 64) {
            // std.debug.print("In while loop\n", .{});
            strlen += index;
            var rest = padding(buffer[0..index]);
            // printPadded(rest);
            _ = calculateHash(&rest);
            index = try stdin.read(&buffer);
        }
        switch (index) {
            0 => {
                // std.debug.print("Out of while loop\n", .{});
                var rest = paddingEndSpecial(strlen);
                // printPadded(rest);
                const result = calculateHash(&rest);
                printHash(result);
            },
            1...55 => {
                // std.debug.print("In lower 56\n", .{});
                strlen += index;
                var rest = paddingShort(buffer[0..index], strlen, index);
                // printPadded(rest);
                const result = calculateHash(&rest);
                printHash(result);
            },
            56...63 => {
                // std.debug.print("In between 56 and 64\n", .{});
                // std.debug.print("56 and 64\n", .{});
                strlen += index;
                var rest = paddingSpecial(buffer[0..index], index);
                // printPadded(rest);
                _ = calculateHash(&rest);
                rest = paddingEnd(strlen);
                // printPadded(rest);
                const result = calculateHash(&rest);
                printHash(result);
            },
            else => {}
        }
        // if (index == 0) {
        //     std.debug.print("Out of while loop\n", .{});
        //     var rest = paddingEndSpecial(strlen);
        //     printPadded(rest);
        //     const result = calculateHash(&rest);
        //     printHash(result);
        // }
        // if (index < 56) {
        //     std.debug.print("In lower 56\n", .{});
        //     var rest = paddingSpecial(buffer[0..index], index);
        //     const result = calculateHash(&rest);
        //     printHash(result);
        // }
        // if (index >= 56 and index < 64) {
        //     std.debug.print("In between 56 and 64\n", .{});
        //     // std.debug.print("56 and 64\n", .{});
        //     var rest = paddingSpecial(buffer[0..index], index);
        //     // printPadded(rest);
        //     _ = calculateHash(&rest);
        //     rest = paddingEnd(strlen);
        //     // printPadded(rest);
        //     const result = calculateHash(&rest);
        //     printHash(result);
        // }
        std.debug.print("  -\n", .{});
    } else {
        std.debug.print("IN ELSE BRANCH\n", .{});
    }
    // std.debug.print("{s}\n", .{message});
    // const result = try calculateHash(message);
    // printHash(result);
}
