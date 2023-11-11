const std = @import("std");
const pbuffer = @import("process_buffer.zig");
const fp = @import("flags_processor.zig");
const ph = @import("print_hash.zig");

pub var exit: u8 = 0;

pub fn check(programm: [:0]u8, filename: [:0]u8, flags: *fp.FlagsProcessor) !void {
    _ = programm;
    const program = "sha1sum";
    var shabuffer: [42]u8 = undefined;
    var filebuffer: [255]u8 = undefined;
    var line: usize = 0;
    var attemptsMade: usize = 0;
    var formattedFiles: usize = 0;
    var improperlyFormattedFiles: usize = 0;
    var fileWarnings: usize = 0;
    var shaWarnings: usize = 0;
    var verifiedFiles: usize = 0;
    const input = std.fs.cwd().openFile(filename, .{}) catch |err| {
        if (exit == 0) {
            exit = 1;
        }
        std.debug.print("{s}: {s}: No such file or directory\n", .{ program, filename });
        return err;
    };
    defer {
        if (improperlyFormattedFiles > 0 and flags.f[8] != fp.FlagsProcessor.Flags.status and attemptsMade > 0) {
            if (improperlyFormattedFiles == 1) {
                std.debug.print("{s}: WARNING: {d} line are improperly formatted\n", .{ program, improperlyFormattedFiles });
            } else {
                std.debug.print("{s}: WARNING: {d} lines are improperly formatted\n", .{ program, improperlyFormattedFiles });
            }
        }
        if (fileWarnings > 0 and flags.f[8] != fp.FlagsProcessor.Flags.status and flags.f[6] != fp.FlagsProcessor.Flags.ignoreMissing) {
            if (fileWarnings == 1) {
                std.debug.print("{s}: WARNING: {d} listed file could not be read\n", .{ program, fileWarnings });
            } else {
                std.debug.print("{s}: WARNING: {d} listed files could not be read\n", .{ program, fileWarnings });
            }
        }
        if (shaWarnings > 0 and flags.f[8] != fp.FlagsProcessor.Flags.status) {
            std.debug.print("{s}: WARNING: {d} computed checksum did NOT match\n", .{ program, shaWarnings });
        }
        if (formattedFiles == 0 and flags.f[8] != fp.FlagsProcessor.Flags.status) {
            std.debug.print("{s}: {s}: no properly formatted checksum lines found\n", .{ program, filename });
        }
        if (verifiedFiles == 0 and flags.f[6] == fp.FlagsProcessor.Flags.ignoreMissing) {
            std.debug.print("{s}: {s}: no file was verified\n", .{ program, filename });
        }
        if (flags.f[9] == fp.FlagsProcessor.Flags.strict) {
            exit = 0;
        }
    }
    defer input.close();
    while (true) {
        line += 1;
        var len = try input.readAll(&shabuffer);
        if (len == 0) {
            break;
        }
        var bufferRead = std.mem.tokenizeScalar(u8, &shabuffer, ' ');
        if (bufferRead.peek()) |value| {
            if (value.len != 40 or !(std.mem.eql(u8, " *", shabuffer[40..]) or std.mem.eql(u8, "  ", shabuffer[40..]))) {
                improperlyFormattedFiles += 1;
                _ = try input.reader().skipUntilDelimiterOrEof('\n');
                if (exit == 0) {
                    exit = 1;
                }
                if (flags.f[10] == fp.FlagsProcessor.Flags.warn and flags.f[8] != fp.FlagsProcessor.Flags.status) {
                    std.debug.print("{s}: {s}: {d}: improperly formatted SHA1 checksum line\n", .{ program, filename, line});
                }
                continue;
            }
        }
        formattedFiles += 1;
        const sha = shabuffer[0..40];
        len = try input.readAll(&filebuffer);
        if (len == 0) {
            break;
        }
        var fileRead = std.mem.tokenizeScalar(u8, &filebuffer, '\n');
        if (fileRead.peek()) |fileToSha| {
            try input.seekBy(-(@as(i64, @intCast(len)) - @as(i64, @intCast(fileToSha.len))-1));
            const openFileToSha = std.fs.cwd().openFile(fileToSha, .{}) catch {
                if (exit == 0) {
                    exit = 1;
                }
                if (flags.f[6] != fp.FlagsProcessor.Flags.ignoreMissing) {
                    std.debug.print("{s}: {s}: No such file or directory\n",  .{program, fileToSha});
                }
                if (flags.f[8] != fp.FlagsProcessor.Flags.status and flags.f[6] != fp.FlagsProcessor.Flags.ignoreMissing) {
                    std.debug.print("{s}: FAILED open or read\n", .{ fileToSha });
                }
                fileWarnings += 1;
                continue;
            };
            defer openFileToSha.close();
            var result = try pbuffer.processBuffer(openFileToSha, fileToSha, flags);
            for (&result) |*val| {
                val.* = std.mem.bigToNative(u32, val.*);
            }
            var cmp: [20]u8 = undefined;
            const h1 = try std.fmt.hexToBytes(&cmp, sha);
            var ptr: *const[20]u8 = @as(*const[20]u8, @ptrCast(&result));
            const h2 = std.fmt.fmtSliceHexLower(ptr[0..20]);

            if (std.mem.eql(u8, h1, h2.data) and flags.f[8] != fp.FlagsProcessor.Flags.status) {
                if (flags.f[7] != fp.FlagsProcessor.Flags.quiet) {
                    std.debug.print("{s}: OK\n", .{ fileToSha });
                }
                attemptsMade += 1;
                verifiedFiles += 1;
            } else if (flags.f[8] != fp.FlagsProcessor.Flags.status) {
                attemptsMade += 1;
                shaWarnings += 1;
                std.debug.print("{s}: FAILED\n", .{ fileToSha });
            }
        }
    }
}
