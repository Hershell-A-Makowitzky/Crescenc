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

fn f0(b: Word, c: Word, d: Word) Word {
    return wor(wand(b, c), wand(wnot(b), d));
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

pub fn main() void {
    // const a: Word = [_]u8 {'\x61', '\x62', '\x63', '\x64'};
    // const b: Word = [_]u8 {'\x65', '\x66', '\x67', '\x68'};
    // const c: Word = [_]u8 {'\x69', '\x70', '\x71', '\x72'};
    // const result = f0(a, b, c);
    // for (result) |val| {
    //     std.debug.print("{x:0^2} ", .{val});
    // }
    const message = "Hello, World!";
    // check(message);
    var block: Block = undefined;
    padding(&block, message);
    // std.debug.print("{}\n", .{@typeInfo(Block)});
}
