const std = @import("std");


const Word: type = [4]u8;
const Block: type = [64]u8;

const K1: Word = [_]u8{'\x5A', '\x82', '\x79', '\x99'};
const K2: Word = [_]u8{'\x6E', '\xD9', '\xEB', '\xA1'};
const K3: Word = [_]u8{'\x8F', '\x1B', '\xBC', '\xDC'};
const K4: Word = [_]u8{'\xCA', '\x62', '\xC1', '\xD6'};

fn wand(x: Word, y: Word) Word {
    var result: Word = undefined;
    for (x) |val, i| {
        result[i] = val & y[i];
    }
    return result;
}

fn wor(x: Word, y: Word) Word {
    var result: Word = undefined;
    for (x) |val, i| {
        result[i] = val | y[i];
    }
    return result;
}

fn wxor(x: Word, y: Word) Word {
    var result: Word = undefined;
    for (x) |val, i| {
        result[i] = val ^ y[i];
    }
    return result;
}

fn wnot(x: Word) Word {
    var result: Word = undefined;
    for (x) |val, i| {
        result[i] = ~val;
    }
    return result;
}

fn circular(n: u5, w: Word) Word {
    var tmpA: u64 = undefined;
    var tmpB: u64 = undefined;
    tmpA = std.mem.bytesToValue(u64, &w) << n;
    tmpB = std.mem.bytesToValue(u64, &w) >> (32 - n);

    var result: Word = wor((), (w >> (32 - n)));
    return result;
}

fn f(u: u8, b: Word, c: Word, d: Word) !Word {
    if (u <= 19 ) {
        return wor(wand(b, c), wand(wnot(b), d));
    }
    if (u <= 39) {
        return wxor(b, wxor(c, d));
    }
    if (u <= 59) {
        return wor(wand(b, c), wor(wand(b, d), wand(c, d)));
    }
    if (u <= 79) {
        return wxor(b, wxor(c, d));
    }
    return error.WordError;
}

fn k(u: u8) !Word {
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
    return error.KError;
}

fn padding(block: *Block, message: [] const u8) void {
    var formator: u64 = 0xff << 0x38;
    var comparator: u6 = 56;
    @memcpy(block, @ptrCast([*]const u8, message), message.len);
    for (block) |*value, i| {
        if (i == message.len) {
            value.* = '\x80';
        }
        if ((i > message.len) and (i < 56)) {
            value.* = '\x00';
        }
        if (i >= 56) {
            value.* = @intCast(u8, ((formator & (message.len * 8)) >> comparator));
            formator >>= 8;
            comparator -|= 8;
        }
        if (i % 4 == 0) std.debug.print(" ", .{});
        if (i % 16 == 0) std.debug.print("\n", .{});
        std.debug.print("{x:0^2}", .{value.*});
    }
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

// fn calculate(message: [] const u8) !void {
//     var block: Block = undefined;
//     var bufferA: [5]Word = {
//         [_]u8{ '\x67', '\x45', '\x23', '\x01' };
//         [_]u8{ '\xEF', '\xCD', '\xAB', '\x89' };
//         [_]u8{ '\x98', '\xBA', '\xDC', '\xFE' };
//         [_]u8{ '\x10', '\x32', '\x54', '\x76' };
//         [_]u8{ '\xC3', '\xD2', '\xE1', '\xF0' };
//     };
//     var bufferB: [5]Word = undefined;
//     var temp: Word = undefined;
//     var seq: [80]Word = undefined;

//     padding(&block, message);

//     for (block) |val, i| {
//         seq[i] = val;
//     }

//     for ([_]u8{} ** 64) |_, i| {
//         seq[i + 16] =
//     }
// }

pub fn main() !void {
    const a: Word = [_]u8 {'\x61', '\x62', '\x63', '\x64'};
    const b: Word = [_]u8 {'\x65', '\x66', '\x67', '\x68'};
    const c: Word = [_]u8 {'\x69', '\x70', '\x71', '\x72'};
    const result = try f(42, a, b, c);
    for (result) |val| {
        std.debug.print("{x:0^2} ", .{val});
    }
    std.debug.print("\n", .{});
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
    // check(message);
    var block: Block = undefined;
    padding(&block, message);
    // const msg = try k(40);
    // std.debug.print("\n", .{});
    // for (msg) |val| {
    //     std.debug.print("{X:0^2} ", .{val});
    // }
    const msg = circular(2, a);
    std.debug.print("\n", .{});
    for (msg) |val| {
        std.debug.print("{X:0^2} ", .{val});
    }
    // std.debug.print("{}\n", .{@typeInfo(Block)});
}
