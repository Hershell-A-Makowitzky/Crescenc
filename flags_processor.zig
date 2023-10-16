const std     = @import("std");
const pbuffer = @import("process_buffer.zig");
const ch = @import("check.zig");
const ph = @import("print_hash.zig");

pub const FlagsProcessor = struct {
    pub const Flags = enum { none, std, binary, check, tag, text, zero, ignoreMissing, quiet, status, strict, warn, help, version };
    f: [11]FlagsProcessor.Flags = [_]FlagsProcessor.Flags{FlagsProcessor.Flags.none} ** 11,
    pub fn processFlags(self: *FlagsProcessor, program: [:0]u8, options: [][:0]u8) !void {
        if (options.len == 1) {
            _ = try pbuffer.processBuffer(std.io.getStdIn(), "-", self);
            return;
        }
        for (options[1..], 0..) |val, idx| {
            if ((std.mem.eql(u8, "-", options[1]) or std.mem.eql(u8, "--", options[1])) and options.len == 2) {
                self.f[0] = FlagsProcessor.Flags.std;
                _ = try pbuffer.processBuffer(std.io.getStdIn(), "-", self);
                break;
            }
            if (std.mem.eql(u8, "-", val)) {
                self.f[1] = FlagsProcessor.Flags.std;
                continue;
            }
            if (std.mem.eql(u8, "--", val)) {
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
                self.f[7] = FlagsProcessor.Flags.quiet;
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
                continue;
            }
            if (std.mem.eql(u8, "--h", val) or std.mem.eql(u8, "--he", val) or std.mem.eql(u8, "--hel", val) or std.mem.eql(u8, "--help", val)) {
                // TODO: print help
                std.debug.print("HELP", .{});
                std.process.exit(0);
            }
            if (std.mem.eql(u8, "--v", val) or std.mem.eql(u8, "--ve", val) or std.mem.eql(u8, "--ver", val) or std.mem.eql(u8, "--vers", val) or std.mem.eql(u8, "--versi", val) or std.mem.eql(u8, "--versio", val) or std.mem.eql(u8, "--version", val)) {
                // TODO: print version
                std.debug.print("VERSION", .{});
                std.process.exit(0);
            }
            if (std.mem.startsWith(u8, val, "--") and val.len > 2) {
                // std.debug.print("{s}\n", .{val});
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
        for (options[1..]) |val| {
            if (!std.mem.startsWith(u8, val, "-")) {
                const input = std.fs.cwd().openFile(val, .{}) catch {
                    std.debug.print("{s}: {s}: No such file or directory\n", .{ program, val });
                    continue;
                };
                defer input.close();
                _ = try pbuffer.processBuffer(input, val, self);
            }
        }
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
        for (options[1..]) |value| {
            // std.debug.print("{s}\n", .{value});
            if (std.mem.eql(u8, value, "--")) {
                continue;
            }
            if (std.mem.eql(u8, value, "-")) {
                // std.debug.print("in --\n", .{});
                const result = try pbuffer.processBuffer(std.io.getStdIn(), "-", self);
                try ph.printHash(result, value, self);
                continue;
            }
            const file = std.fs.cwd().openFile(value, .{}) catch {
                std.debug.print("defaultCheck {s}: {s}: No such file or directory\n", .{ name, value });
                continue;
            };
            defer file.close();
            // std.debug.print("Precess buffer\n", .{});
            const result = try pbuffer.processBuffer(file, value, self);
            try ph.printHash(result, value, self);
        }
    }

    // pub fn executeCheck(self: *FlagsProcessor, options: [][:0]u8) !void {
    //     for (options[1..]) |value| {
    //         if (std.mem.eql(u8, value, "--")) {
    //             continue;
    //         }
    //         if (std.mem.eql(u8, value, "-")) {
    //             std.debug.print("in --\n", .{});
    //             _ = try pbuffer.processBuffer(std.io.getStdIn(), "-", self);
    //             continue;
    //         }
    //         const file = std.fs.cwd().openFile(value, .{}) catch {
    //             std.debug.print("checkAfterDoubleDash {s}: {s}: No such file or directory\n", .{ program, value });
    //             continue;
    //         };
    //         defer file.close();
    //         _ = try pbuffer.processBuffer(file, value, self);
    //     }

    // }
    pub fn executeCheck(self: *FlagsProcessor, program: [:0]u8, options: [][:0]u8) !void {
        // for (options) |option| {
        //     std.debug.print("{s}\n", .{option});
        // }

        // for (self.f) |flag| {
        //     std.debug.print("{any}\n", .{flag});
        // }
        // std.debug.print("{any}\n", .{self.f[2] == FlagsProcessor.Flags.check and self.f[1] == FlagsProcessor.Flags.std});
        // if (self.f[2] == FlagsProcessor.Flags.check) {
        //     std.debug.print("Checking empty\n", .{});
        //     ch.check(program, @constCast("standard input"[0..]), std.io.getStdIn(), self);
        // }
        if (self.f[2] == FlagsProcessor.Flags.check) { //or self.f[9] == FlagsProcessor.Flags.strict or self.f[6] == FlagsProcessor.Flags.ignoreMissing or self.f[7] == FlagsProcessor.Flags.quiet or self.f[8] == FlagsProcessor.Flags.status or self.f[10] == FlagsProcessor.Flags.warn)) {
            for (options[1..], 0..) |option, index| {
                // std.debug.print("{d} {s}\n", .{index, option});
                if (std.mem.eql(u8, option, "--")) {
                    try defaultCheck(self, program, options[index..]);
                    return;
                }
                if (std.mem.startsWith(u8, option, "-")) {
                    // std.debug.print("Whooo...\n", .{});
                    continue;
                }
                // const input = std.fs.cwd().openFile(option, .{}) catch {
                //     std.debug.print("ExecuteCheck {s}: {s}: No such file or directory\n", .{ program, option });
                //     continue;
                // };
                // defer input.close();
                // std.debug.print("FILE {?}\n", .{input});
                try ch.check(program, option, self);
            }
            // const input = std.fs.cwd().openFile(option, .{}) catch {
            //     std.debug.print("{s}: {s}: No such file or directory\n", .{ program, option });
            //     continue;
            // };
            // try pbuffer.processBuffer(input, option, self);
            // std.debug.print("Reading stdin...", .{});
        } else {
            try self.defaultCheck(program, options);
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
