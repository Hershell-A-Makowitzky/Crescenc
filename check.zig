const std = @import("std");
const pbuffer = @import("process_buffer.zig");
const fp = @import("flags_processor.zig");

pub fn check(shasum: [:0]u8, filename: [:0]u8, file: std.fs.File, flags: *fp.FlagsProcessor) void {
    var shabuffer: [42]u8 = undefined;
    var filebuffer: [1024]u8 = undefined;
    var line: usize = 0;
    while (true) {
        const shasize = file.readAll(&shabuffer) catch {
            std.debug.print("{s}: {s}: no properly formated checksum lines found\n", .{ shasum, filename });
            continue;
        };
        if (shasize == 0) {
            break;
        }
        const filesize = file.readAll(&filebuffer) catch {
            std.debug.print("{s}: {s}: no properly formated checksum lines found\n", .{ shasum, filename });
            continue;
        };
        if (filesize == 0) {
            break;
        }
        line += 1;
        // std.debug.print("{d}\n", .{filesize});
        const sha = shabuffer[0..40];
        const fileToSha = std.mem.trimRight(u8, filebuffer[0..filesize], "\n");
        std.debug.print("SHA:{s} FILE:{s}appendix\n", .{ sha, fileToSha });
        std.debug.print("INDX {?}\n", .{std.mem.indexOfScalar(u8, fileToSha, 0)});
        const openFileToSha = std.fs.cwd().openFile(fileToSha, .{}) catch {
            std.debug.print("AAAAAA{s}: {s}: No such file or directory\n", .{ shasum, fileToSha });
            std.debug.print("BBBBBB{s}: FAILED open or read\n", .{ fileToSha });
            if (flags.f[10] == fp.FlagsProcessor.Flags.warn) {
                std.debug.print("{s}: {s}: {d}: improperly formatted SHA1 checksum line\n", .{ shasum, filename, line});
            }
            continue;
        };
        const result = pbuffer.processBuffer(openFileToSha, fileToSha, flags);
        if (result) |value| {
            const presult: *const[5]u32 = &value;
            if (std.mem.eql(u8, @as(*const[20]u8, @ptrCast(presult)), sha)) {
                std.debug.print("{s}: OK\n", .{ fileToSha });
            } else {
                std.debug.print("{s}: FAILED\n", .{ fileToSha });
            }
        } else |err| {
            std.debug.print("{any}\n", .{err});
            continue;
        }
    }
}
