const std = @import("std");
const pbuffer = @import("process_buffer.zig");
const fp = @import("flags_processor.zig");
const ph = @import("print_hash.zig");

pub var exit: u8 = 0;

pub fn check(program: [:0]u8, filename: [:0]u8, flags: *fp.FlagsProcessor) !void {
    var shabuffer: [42]u8 = undefined;
    var filebuffer: [255]u8 = undefined;
    var line: usize = 0;
    var formattedFiles: usize = 0;
    var fileWarnings: usize = 0;
    var shaWarnings: usize = 0;
    var seek: u64 = 0;
    const input = std.fs.cwd().openFile(filename, .{}) catch |err| {
        if (exit == 0) {
            exit = 1;
        }
        std.debug.print("ExecuteCheck {s}: {s}: No such file or directory\n", .{ program, filename });
        return err;
    };
    defer {
        if (fileWarnings > 0 and flags.f[8] != fp.FlagsProcessor.Flags.status) {
            if (fileWarnings == 1) {
                std.debug.print("{s}: WARNING: {d} listed file could not be read\n", .{ program, fileWarnings });
            } else {
                std.debug.print("{s}: WARNING: {d} listed files could not be read\n", .{ program, fileWarnings });
            }
        }
        if (shaWarnings > 0) {
            std.debug.print("{s}: WARNING: {d} computed checksum did NOT match\n", .{ program, shaWarnings });
        }
        if (formattedFiles == 0) {
            std.debug.print("{s}: {s}: no properly formatted checksum lines found\n", .{ program, filename });
        }
    }
    defer input.close();
    while (true) {
        line += 1;
        const len = try input.readAll(&shabuffer);
        const pos = try input.getPos();
        if (pos == try input.getEndPos()) {
            break;
        }
        seek += len;
        _ = try input.seekTo(seek);
        var bufferRead = std.mem.tokenizeScalar(u8, &shabuffer, ' ');
        if (bufferRead.peek()) |value| {
            if (value.len != 40 or !(std.mem.eql(u8, " *", shabuffer[40..]) or std.mem.eql(u8, "  ", shabuffer[40..]))) {
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
        _ = try input.readAll(&filebuffer);
        var fileRead = std.mem.tokenizeScalar(u8, &filebuffer, '\n');
        if (fileRead.peek()) |fileToSha| {
            seek += fileToSha.len + 1;
            _ = try input.seekTo(seek);
            const openFileToSha = std.fs.cwd().openFile(fileToSha, .{}) catch {
                if (exit == 0) {
                    exit = 1;
                }
                std.debug.print("{s}: '{s}': No such file or directory\n",  .{program, fileToSha});
                if (flags.f[8] != fp.FlagsProcessor.Flags.status) {
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
                std.debug.print("{s}: OK\n", .{ fileToSha });
            } else if (flags.f[8] != fp.FlagsProcessor.Flags.status) {
                shaWarnings += 1;
                std.debug.print("{s}: FAILED\n", .{ fileToSha });
            }
        }
    }
}
