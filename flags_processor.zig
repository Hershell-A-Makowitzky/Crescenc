const std     = @import("std");
const pbuffer = @import("process_buffer.zig");
const ch = @import("check.zig");
const ph = @import("print_hash.zig");
const h = @import("help.zig");
const v = @import("version.zig");

pub const FlagsProcessor = struct {
    pub const Flags = enum { none, std, binary, check, tag, text, zero, ignoreMissing, quiet, status, strict, warn, help, version };
    f: [11]FlagsProcessor.Flags = [_]FlagsProcessor.Flags{FlagsProcessor.Flags.none} ** 11,
    pub fn processFlags(self: *FlagsProcessor, program: [:0]u8, options: [][:0]u8) !void {
        for (options[1..], 0..) |val, idx| {
            if ((std.mem.eql(u8, "-", options[1]) or std.mem.eql(u8, "--", options[1])) and options.len == 2) {
                break;
            }
            if (std.mem.eql(u8, "-", val)) {
                continue;
            }
            if (std.mem.eql(u8, "--", val)) {
                self.f[0] = FlagsProcessor.Flags.std;
                self.checkForOptionsError(program);
                try self.executeCheck(program, options[idx..]);
                return;
            }
            if (std.mem.eql(u8, "-b", val) or std.mem.eql(u8, "--b", val) or std.mem.eql(u8, "--bi", val) or std.mem.eql(u8, "--bin", val) or std.mem.eql(u8, "--bina", val) or std.mem.eql(u8, "--binar", val) or std.mem.eql(u8, "--binary", val)) {
                if (self.f[4] == FlagsProcessor.Flags.text) {
                    self.f[1] = FlagsProcessor.Flags.binary;
                    self.f[4] = FlagsProcessor.Flags.none;
                } else {
                    self.f[1] = FlagsProcessor.Flags.binary;
                }
                continue;
            }
            if (std.mem.eql(u8, "-c", val) or std.mem.eql(u8, "--c", val) or std.mem.eql(u8, "--ch", val) or std.mem.eql(u8, "--che", val) or std.mem.eql(u8, "--chec", val) or std.mem.eql(u8, "--check", val)) {
                self.f[2] = FlagsProcessor.Flags.check;
                continue;
            }
            if (std.mem.eql(u8, "--t", val)) {
                std.debug.print("{s}: option '--t' is ambiguous; possibilities: '--tag' '--text'\nTry '{s} --help' for more information.\n", .{ program, program });
                std.process.exit(1);
            }
            if (std.mem.eql(u8, "--ta", val) or std.mem.eql(u8, "--tag", val)) {
                self.f[3] = FlagsProcessor.Flags.tag;
                continue;
            }
            if (std.mem.eql(u8, "-t", val) or std.mem.eql(u8, "--te", val) or std.mem.eql(u8, "--tex", val) or std.mem.eql(u8, "--text", val)) {
                if (self.f[1] == FlagsProcessor.Flags.binary) {
                    self.f[4] = FlagsProcessor.Flags.text;
                    self.f[1] = FlagsProcessor.Flags.none;
                } else {
                    self.f[4] = FlagsProcessor.Flags.text;
                }
                continue;
            }
            if (std.mem.eql(u8, "-z", val) or std.mem.eql(u8, "--z", val) or std.mem.eql(u8, "--ze", val) or std.mem.eql(u8, "--zer", val) or std.mem.eql(u8, "--zero", val)) {
                self.f[5] = FlagsProcessor.Flags.zero;
                continue;
            }
            if (std.mem.eql(u8, "--i", val) or std.mem.eql(u8, "--ig", val) or std.mem.eql(u8, "--ign", val) or std.mem.eql(u8, "--igno", val) or std.mem.eql(u8, "--ignor", val) or std.mem.eql(u8, "--ignore", val) or std.mem.eql(u8, "--ignore-", val) or std.mem.eql(u8, "--ignore-m", val) or std.mem.eql(u8, "--ignore-mi", val) or std.mem.eql(u8, "--ignore-mis", val) or std.mem.eql(u8, "--ignore-miss", val) or std.mem.eql(u8, "--ignore-missi", val) or std.mem.eql(u8, "--ignore-missin", val) or std.mem.eql(u8, "--ignore-missing", val)) {
                self.f[6] = FlagsProcessor.Flags.ignoreMissing;
                continue;
            }
            if (std.mem.eql(u8, "--q", val) or std.mem.eql(u8, "--qu", val) or std.mem.eql(u8, "--qui", val) or std.mem.eql(u8, "--quie", val) or std.mem.eql(u8, "--quiet", val)) {
                if (self.f[10] == FlagsProcessor.Flags.warn) {
                    self.f[7] = FlagsProcessor.Flags.none;
                } else {
                    self.f[7] = FlagsProcessor.Flags.quiet;
                }
                continue;
            }
            if (std.mem.eql(u8, "--s", val) or std.mem.eql(u8, "--st", val) or std.mem.eql(u8, "--sta", val) or std.mem.eql(u8, "--stat", val) or std.mem.eql(u8, "--statu", val) or std.mem.eql(u8, "--status", val)) {
                self.f[8] = FlagsProcessor.Flags.status;
                continue;
            }
            if (std.mem.eql(u8, "--s", val) or std.mem.eql(u8, "--st", val) or std.mem.eql(u8, "--str", val) or std.mem.eql(u8, "--stri", val) or std.mem.eql(u8, "--stric", val) or std.mem.eql(u8, "--strict", val)) {
                self.f[9] = FlagsProcessor.Flags.strict;
                continue;
            }
            if (std.mem.eql(u8, "-w", val) or std.mem.eql(u8, "--w", val) or std.mem.eql(u8, "--wa", val) or std.mem.eql(u8, "--war", val) or std.mem.eql(u8, "--warn", val)) {
                self.f[10] = FlagsProcessor.Flags.warn;
                self.f[7] = FlagsProcessor.Flags.none;

                continue;
            }
            if (std.mem.eql(u8, "--h", val) or std.mem.eql(u8, "--he", val) or std.mem.eql(u8, "--hel", val) or std.mem.eql(u8, "--help", val)) {
                std.debug.print("{s}\n", .{h.help});
                std.process.exit(0);
            }
            if (std.mem.eql(u8, "--v", val) or std.mem.eql(u8, "--ve", val) or std.mem.eql(u8, "--ver", val) or std.mem.eql(u8, "--vers", val) or std.mem.eql(u8, "--versi", val) or std.mem.eql(u8, "--versio", val) or std.mem.eql(u8, "--version", val)) {
                std.debug.print("{s}\n", .{v.version});
                std.process.exit(0);
            }
            if (std.mem.startsWith(u8, val, "--") and val.len > 2) {
                std.debug.print("{s}: invalid option -- '{s}'\nTry '{s} --help' for more information.\n", .{ program, val[1..], program });
                std.os.exit(1);
            }
            if (std.mem.startsWith(u8, val, "-") and val.len > 1) {
                for (val[1..]) |item| {
                    std.debug.print("{c}\n", .{item});
                    switch (item) {
                        'b' => self.f[1] = FlagsProcessor.Flags.binary,
                        'c' => self.f[2] = FlagsProcessor.Flags.check,
                        't' => self.f[4] = FlagsProcessor.Flags.text,
                        'z' => self.f[5] = FlagsProcessor.Flags.zero,
                        'w' => self.f[10] = FlagsProcessor.Flags.warn,
                        else => {
                            std.debug.print("{s}: invalid option -- '{c}'\nTry '{s} --help' for more information.\n", .{ program, item, program });
                            std.os.exit(1);
                        }
                    }
                }
                continue;
            }
            if (std.mem.startsWith(u8, val, "-") and val.len > 1) {
                std.debug.print("{s}: invalid option -- '{c}'\nTry '{s} --help' for more information.\n", .{ program, val[1], program });
                std.os.exit(1);
            }
        }
        self.checkForOptionsError(program);
        try self.executeCheck(program, options[0..]);
    }
    pub fn checkAfterDoubleDash(self: *FlagsProcessor, name: [:0]u8, input: [][:0]u8) !void {
        for (input) |value| {
            if (std.mem.eql(u8, value, "-")) {
                std.debug.print("in --\n", .{});
                _ = try pbuffer.processBuffer(std.io.getStdIn(), "-", self);
                continue;
            }
            const file = std.fs.cwd().openFile(value, .{}) catch {
                std.debug.print("checkAfterDoubleDash {s}: {s}: No such file or directory\n", .{ name, value });
                continue;
            };
            defer file.close();
            _ = try pbuffer.processBuffer(file, value, self);
        }
    }
    pub fn checkForOptionsError(self: *FlagsProcessor, name: [:0]u8) void {
        if (self.f[1] == FlagsProcessor.Flags.binary and self.f[2] == FlagsProcessor.Flags.check) {
            std.debug.print("The --binary and --text options are meaningless when verifying checksums\n", .{});
            std.debug.print("Try '{s} --help' for more information.\n", .{name});
            std.process.exit(1);
        }
        if (self.f[4] == FlagsProcessor.Flags.text and self.f[2] == FlagsProcessor.Flags.check) {
            std.debug.print("The --binary and --text options are meaningless when verifying checksums\n", .{});
            std.debug.print("Try '{s} --help' for more information.\n", .{name});
            std.process.exit(1);
        }
        if (self.f[5] == FlagsProcessor.Flags.zero and self.f[2] == FlagsProcessor.Flags.check) {
            std.debug.print("The --zero options is not supported when verifying checksums\n", .{});
            std.debug.print("Try '{s} --help' for more information.\n", .{name});
            std.process.exit(1);
        }
        if (self.f[3] == FlagsProcessor.Flags.tag and self.f[2] == FlagsProcessor.Flags.check) {
            std.debug.print("The --tag option is meaningless when verifying checksums\n", .{});
            std.debug.print("Try '{s} --help' for more information.\n", .{name});
            std.process.exit(1);
        }
        if (self.f[3] == FlagsProcessor.Flags.tag and self.f[2] == FlagsProcessor.Flags.check) {
            self.f[1] = FlagsProcessor.Flags.none;
            self.f[4] = FlagsProcessor.Flags.none;
        }
        if (self.f[6] == FlagsProcessor.Flags.ignoreMissing and self.f[2] == FlagsProcessor.Flags.none) {
            std.debug.print("The --ignore-missing option is meaningful only when verifying checksums\n", .{});
            std.debug.print("Try '{s} --help' for more information.\n", .{name});
            std.process.exit(1);
        }
        if (self.f[7] == FlagsProcessor.Flags.quiet and self.f[2] == FlagsProcessor.Flags.none) {
            std.debug.print("The --quiet option is meaningful only when verifying checksums\n", .{});
            std.debug.print("Try '{s} --help' for more information.\n", .{name});
            std.process.exit(1);
        }
        if (self.f[8] == FlagsProcessor.Flags.status and self.f[2] == FlagsProcessor.Flags.none) {
            std.debug.print("The --status option is meaningful only when verifying checksums\n", .{});
            std.debug.print("Try '{s} --help' for more information.\n", .{name});
            std.process.exit(1);
        }
        if (self.f[9] == FlagsProcessor.Flags.strict and self.f[2] == FlagsProcessor.Flags.none) {
            std.debug.print("The --strict option is meaningful only when verifying checksums\n", .{});
            std.debug.print("Try '{s} --help' for more information.\n", .{name});
            std.process.exit(1);
        }
        if (self.f[10] == FlagsProcessor.Flags.warn and self.f[2] == FlagsProcessor.Flags.none) {
            std.debug.print("The --warn option is meaningful only when verifying checksums\n", .{});
            std.debug.print("Try '{s} --help' for more information.\n", .{name});
            std.process.exit(1);
        }
    }

    pub fn defaultCheck(self: *FlagsProcessor, name: [:0]u8, options: [][:0]u8) !void {
        if (self.f[0] == FlagsProcessor.Flags.none) {
            const result = try pbuffer.processBuffer(std.io.getStdIn(), "-", self);
            try ph.printHash(result, "-", self);
            return;
        }
        if (self.f[0] == FlagsProcessor.Flags.std) {
            for (options[1..]) |value| {
                if (std.mem.eql(u8, value, "--")) {
                    continue;
                }
                const file = std.fs.cwd().openFile(value, .{}) catch {
                    std.debug.print("{s}: {s}: No such file or directory\n", .{ name, value });
                    continue;
                };
                defer file.close();
                const result = try pbuffer.processBuffer(file, value, self);
                try ph.printHash(result, value, self);
            }
        } else {
            for (options[1..]) |value| {
                if (std.mem.eql(u8, value, "-")) {
                    const result = try pbuffer.processBuffer(std.io.getStdIn(), "-", self);
                    try ph.printHash(result, value, self);
                    continue;
                }
                const file = std.fs.cwd().openFile(value, .{}) catch {
                    std.debug.print("{s}: {s}: No such file or directory\n", .{ name, value });
                    continue;
                };
                defer file.close();
                const result = try pbuffer.processBuffer(file, value, self);
                try ph.printHash(result, value, self);
            }
        }
    }
    pub fn executeCheck(self: *FlagsProcessor, program: [:0]u8, options: [][:0]u8) !void {
        if (self.f[2] == FlagsProcessor.Flags.check) {
            for (options[1..], 0..) |option, index| {
                if (std.mem.eql(u8, option, "--")) {
                    try defaultCheck(self, program, options[index..]);
                    return;
                }
                if (std.mem.startsWith(u8, option, "-")) {
                    continue;
                }
                _ = ch.check(program, option, self) catch {
                    continue;
                };
            }
        } else {
            try self.defaultCheck(program, options);
        }
    }
};
