// Reference implementation of SHA1 algorithm according to "https://www.rfc-editor.org/rfc/rfc3174"
// Only for studying purposes
// compilation: "zig build-exe -OReleaseFast -fstrip --name hersha sha.zig"

const std = @import("std");

const K1: u32 = 0x5A827999;
const K2: u32 = 0x6ED9EBA1;
const K3: u32 = 0x8F1BBCDC;
const K4: u32 = 0xCA62C1D6;



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

fn calculateHash(message: *[16]u32, bufferB: *[5]u32) void {
    var bufferA: [5]u32 = undefined;
    var temp: u32 = undefined;
    var seq: [80]u32 = undefined;


    inline for (&seq, 0..) |*val, i| {
        if (i < 16) {
            // var valuePointer: *[4]u8 = @ptrCast(val);
            // for (0..4, 0..) |_, j| {
            //     valuePointer[i] = message[j];
            // }
            val.* = std.mem.nativeToBig(u32, message[i]);
        } else {
            val.* = circular(1, seq[i - 3] ^ seq[i - 8] ^ seq[i - 14] ^ seq[i - 16]);
        }
    }

    inline for (&bufferA, 0..) |*val, i| {
        val.* = bufferB[i];
    }

    inline for (0..80, 0..) |_, i| {
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

    //return bufferB;
}

const FlagsProcessor = struct {
    pub const Flags = enum {
        none,
        std,
        binary,
        check,
        tag,
        text,
        zero,
        ignoreMissing,
        quiet,
        status,
        strict,
        warn,
        help,
        version
    };
    f: [11]FlagsProcessor.Flags = [_]FlagsProcessor.Flags{FlagsProcessor.Flags.none} ** 11,
    pub fn processFlags(self: *FlagsProcessor, options: [][:0]u8) !void {
        if (options.len == 1) {
            try processBuffer(std.io.getStdIn(), "-", self.f[0]);
            return;
        }
        for (options[1..]) |val| {
            if ((std.mem.eql(u8, "-", options[1]) or std.mem.eql(u8, "--", options[1])) and options.len == 2) {
                self.f[0] = FlagsProcessor.Flags.std;
                try processBuffer(std.io.getStdIn(), "-", self.f[0]);
                break;
            }
            if (std.mem.eql(u8, "-", val) or std.mem.eql(u8, "--", val)) {
                continue;
            }
            if (std.mem.eql(u8, "-b", val)
                    or std.mem.eql(u8, "--b", val)
                    or std.mem.eql(u8, "--bi", val)
                    or std.mem.eql(u8, "--bin", val)
                    or std.mem.eql(u8, "--bina", val)
                    or std.mem.eql(u8, "--binar", val)
                    or std.mem.eql(u8, "--binary", val)) {
                if (self.f[4] == FlagsProcessor.Flags.text) {
                    self.f[1] = FlagsProcessor.Flags.binary;
                    self.f[4] = FlagsProcessor.Flags.none;
                } else {
                    self.f[1] = FlagsProcessor.Flags.binary;
                }
                continue;
            }
            if (std.mem.eql(u8, "-c", val)
                    or std.mem.eql(u8, "--c", val)
                    or std.mem.eql(u8, "--ch", val)
                    or std.mem.eql(u8, "--che", val)
                    or std.mem.eql(u8, "--chec", val)
                    or std.mem.eql(u8, "--check", val)) {
                self.f[2] = FlagsProcessor.Flags.check;
                continue;
            }
            if (std.mem.eql(u8, "--t", val)) {
                std.debug.print("{s}: option '--t' is ambiguous; possibilities: '--tag' '--text'\nTry '{s} --help' for more information.\n", .{options[0], options[0]});
                std.process.exit(1);
            }
            if (std.mem.eql(u8, "--ta", val)
                    or std.mem.eql(u8, "--tag", val)) {
                self.f[3] = FlagsProcessor.Flags.tag;
                continue;
            }
            if (std.mem.eql(u8, "-t", val)
                    or std.mem.eql(u8, "--te", val)
                    or std.mem.eql(u8, "--tex", val)
                    or std.mem.eql(u8, "--text", val)) {
                if (self.f[1] == FlagsProcessor.Flags.binary) {
                    self.f[4] = FlagsProcessor.Flags.text;
                    self.f[1] = FlagsProcessor.Flags.none;
                } else {
                    self.f[4] = FlagsProcessor.Flags.text;
                }
                continue;
            }
            if (std.mem.eql(u8, "-z", val)
                    or std.mem.eql(u8, "--z", val)
                    or std.mem.eql(u8, "--ze", val)
                    or std.mem.eql(u8, "--zer", val)
                    or std.mem.eql(u8, "--zero", val)) {
                self.f[5] = FlagsProcessor.Flags.zero;
                continue;
            }
            if (std.mem.eql(u8, "--i", val)
                    or std.mem.eql(u8, "--ig", val)
                    or std.mem.eql(u8, "--ign", val)
                    or std.mem.eql(u8, "--igno", val)
                    or std.mem.eql(u8, "--ignor", val)
                    or std.mem.eql(u8, "--ignore", val)
                    or std.mem.eql(u8, "--ignore-", val)
                    or std.mem.eql(u8, "--ignore-m", val)
                    or std.mem.eql(u8, "--ignore-mi", val)
                    or std.mem.eql(u8, "--ignore-mis", val)
                    or std.mem.eql(u8, "--ignore-miss", val)
                    or std.mem.eql(u8, "--ignore-missi", val)
                    or std.mem.eql(u8, "--ignore-missin", val)
                    or std.mem.eql(u8, "--ignore-missing", val)) {
                self.f[6] = FlagsProcessor.Flags.ignoreMissing;
                continue;
            }
            if (std.mem.eql(u8, "--q", val)
                    or std.mem.eql(u8, "--qu", val)
                    or std.mem.eql(u8, "--qui", val)
                    or std.mem.eql(u8, "--quie", val)
                    or std.mem.eql(u8, "--quiet", val)) {
                self.f[7] = FlagsProcessor.Flags.quiet;
                continue;
            }
            if (std.mem.eql(u8, "--s", val)
                    or std.mem.eql(u8, "--st", val)
                    or std.mem.eql(u8, "--sta", val)
                    or std.mem.eql(u8, "--stat", val)
                    or std.mem.eql(u8, "--statu", val)
                    or std.mem.eql(u8, "--status", val)) {
                self.f[8] = FlagsProcessor.Flags.status;
                continue;
            }
            if (std.mem.eql(u8, "--s", val)
                    or std.mem.eql(u8, "--st", val)
                    or std.mem.eql(u8, "--str", val)
                    or std.mem.eql(u8, "--stri", val)
                    or std.mem.eql(u8, "--stric", val)
                    or std.mem.eql(u8, "--strict", val)) {
                self.f[9] = FlagsProcessor.Flags.strict;
                continue;
            }
            if (std.mem.eql(u8, "-w", val)
                    or std.mem.eql(u8, "--w", val)
                    or std.mem.eql(u8, "--wa", val)
                    or std.mem.eql(u8, "--war", val)
                    or std.mem.eql(u8, "--warn", val)) {
                self.f[10] = FlagsProcessor.Flags.warn;
                continue;
            }
            if (std.mem.eql(u8, "--h", val)
                    or std.mem.eql(u8, "--he", val)
                    or std.mem.eql(u8, "--hel", val)
                    or std.mem.eql(u8, "--help", val)) {
                // TODO: print help
                std.debug.print("HELP", .{});
                std.process.exit(0);
            }
            if (std.mem.eql(u8, "--v", val)
                    or std.mem.eql(u8, "--ve", val)
                    or std.mem.eql(u8, "--ver", val)
                    or std.mem.eql(u8, "--vers", val)
                    or std.mem.eql(u8, "--versi", val)
                    or std.mem.eql(u8, "--versio", val)
                    or std.mem.eql(u8, "--version", val)) {
                // TODO: print version
                std.debug.print("VERSION", .{});
                std.process.exit(0);
            }
            if (std.mem.startsWith(u8, val, "--") and val.len > 2) {
                // std.debug.print("{s}\n", .{val});
                std.debug.print("{s}: invalid option -- '{s}'\nTry '{s} --help' for more information.\n", .{options[0], val[1..], options[0]});
                std.os.exit(1);
            }
            if (std.mem.startsWith(u8, val, "-") and val.len > 1) {
                std.debug.print("{s}\n", .{val});
                std.debug.print("{s}: invalid option -- '{c}'\nTry '{s} --help' for more information.\n", .{options[0], val[1], options[0]});
                std.os.exit(1);
            }
        }
        self.checkForOptionsError(options[0]);
        for (options[1..]) |val| {
            if (!std.mem.startsWith(u8, val, "-")) {
                const input = std.fs.cwd().openFile(val, .{}) catch {
                    std.debug.print("{s}: {s}: No such file or directory\n", .{options[0], val});
                    continue;
                };
                try processBuffer(input, val, self.f[0]);
            }
        }
    }
    pub fn checkForOptionsError(self: *FlagsProcessor, name: [:0]u8) void {
        for (self.f) |val| {
            std.debug.print("{any}\n", .{val});
        }
        if (self.f[1] == FlagsProcessor.Flags.binary and self.f[2] == FlagsProcessor.Flags.check) {
            std.debug.print("The --binary and --text options are meaningless when verifying checksums\n", .{});
            std.debug.print("Try '{s} --help' for more information.\n", .{name});
        }
        if (self.f[4] == FlagsProcessor.Flags.text and self.f[2] == FlagsProcessor.Flags.check) {
            std.debug.print("The --binary and --text options are meaningless when verifying checksums\n", .{});
            std.debug.print("Try '{s} --help' for more information.\n", .{name});
        }
        if (self.f[5] == FlagsProcessor.Flags.zero and self.f[2] == FlagsProcessor.Flags.check) {
            std.debug.print("The --zero options is not supported when verifying checksums\n", .{});
            std.debug.print("Try '{s} --help' for more information.\n", .{name});
        }
        if (self.f[3] == FlagsProcessor.Flags.tag and self.f[2] == FlagsProcessor.Flags.check) {
            std.debug.print("The --tag option is meaningless when verifying checksums\n", .{});
            std.debug.print("Try '{s} --help' for more information.\n", .{name});
        }
        if (self.f[3] == FlagsProcessor.Flags.tag and self.f[2] == FlagsProcessor.Flags.check) {
            self.f[1] = FlagsProcessor.Flags.none;
            self.f[4] = FlagsProcessor.Flags.none;
        }
        if (self.f[6] == FlagsProcessor.Flags.ignoreMissing and self.f[2] == FlagsProcessor.Flags.none) {
            std.debug.print("The --ignore-missing option is meaningful only when verifying checksums\n", .{});
            std.debug.print("Try '{s} --help' for more information.\n", .{name});
        }
        if (self.f[7] == FlagsProcessor.Flags.ignoreMissing and self.f[2] == FlagsProcessor.Flags.none) {
            std.debug.print("The --quiet option is meaningful only when verifying checksums\n", .{});
            std.debug.print("Try '{s} --help' for more information.\n", .{name});
        }
        if (self.f[8] == FlagsProcessor.Flags.ignoreMissing and self.f[2] == FlagsProcessor.Flags.none) {
            std.debug.print("The --status option is meaningful only when verifying checksums\n", .{});
            std.debug.print("Try '{s} --help' for more information.\n", .{name});
        }
        if (self.f[9] == FlagsProcessor.Flags.ignoreMissing and self.f[2] == FlagsProcessor.Flags.none) {
            std.debug.print("The --strict option is meaningful only when verifying checksums\n", .{});
            std.debug.print("Try '{s} --help' for more information.\n", .{name});
        }
        if (self.f[10] == FlagsProcessor.Flags.ignoreMissing and self.f[2] == FlagsProcessor.Flags.none) {
            std.debug.print("The --warn option is meaningful only when verifying checksums\n", .{});
            std.debug.print("Try '{s} --help' for more information.\n", .{name});
        }
    }
        // binary 1
        // check 2
        // tag 3
        // text 4
        // zero  5
        // ignoreMissing 6
        // quiet 7
        // status 8
        // strict 9
        // warn 10
        // help 11
        // version 12
};

fn printHash(hash: [5]u32, file: []const u8, flag: FlagsProcessor.Flags) !void {
    const stdout = std.io.getStdOut().writer();
    for (hash) |val| {
        try stdout.print("{x:0>8}", .{val});
    }
    if (flag == FlagsProcessor.Flags.zero) {
        try stdout.print("  {s}\x00", .{file});
        return;
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

fn processBuffer(file: std.fs.File, name: []const u8, flag: FlagsProcessor.Flags) !void {
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
            calculateHash(&input, &bufferB);
            index += 64;
            strlen += 64;
            // std.debug.print("Strlen in loop {}\n", .{strlen});
        } else {
            if (size == ssize) {
                // std.debug.print("turn\n", .{});
                // strlen += size - index;
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
                        var rest = paddingEndSpecial(strlen);
                        calculateHash(&rest, &bufferB);
                        try printHash(bufferB, name, flag);
                    },
                    1...55 => {
                        // strlen += index;
                        var rest = paddingShort(buffer[(size - index)..size], strlen, index);
                        calculateHash(&rest, &bufferB);
                        try printHash(bufferB, name, flag);
                    },
                    56...63 => {
                        // strlen += index;
                        var rest = paddingSpecial(buffer[(size - index)..size], index);
                        _ = calculateHash(&rest, &bufferB);
                        rest = paddingEnd(strlen);
                        calculateHash(&rest, &bufferB);
                        try printHash(bufferB, name, flag);
                    },
                    else => {}
                }
                break;
            }
        }
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    // try handleOptions(args);
    var options = FlagsProcessor{};
    try FlagsProcessor.processFlags(&options, args);
    // for (options.f) |val| {
    //     std.debug.print("{any}\n", .{val});
    // }
}
