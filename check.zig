const std = @import("std");
const pbuffer = @import("process_buffer.zig");
const fp = @import("flags_processor.zig");
const ph = @import("print_hash.zig");

pub fn check(program: [:0]u8, filename: [:0]u8, flags: *fp.FlagsProcessor) !void {
    // std.debug.print("IN Check\n", .{});
    var shabuffer: [42]u8 = undefined;
    var filebuffer: [1024]u8 = undefined;
    var line: usize = 0;
    const input = std.fs.cwd().openFile(filename, .{}) catch |err| {
        std.debug.print("ExecuteCheck {s}: {s}: No such file or directory\n", .{ program, filename });
        return err;
    };
    defer input.close();
    // defer std.debug.print("DEFER\n", .{});
    while (true) {
        _ = try input.readAll(&shabuffer);
        var bufferRead = std.mem.tokenizeScalar(u8, &shabuffer, ' ');
        if (bufferRead.peek()) |value| {
            if (value.len != 40) {
                std.debug.print("{s}: {s}: no properly formated checksum lines found\n", .{ program, filename });
                break;
            }
        } else {
            std.debug.print("{s}: {s}: no properly formated checksum lines found\n", .{ program, filename });
            break;
        }
        // std.debug.print("Shabuffer {s}\n", .{shabuffer});
        // if (shasize != 40) {
        //     std.debug.print("{s}: {s}: no properly formated checksum lines found\n", .{ program, filename });
        //     for (&shabuffer) |*val| {
        //         val.* = '\x00';
        //     }
        //     continue;
        // }
        // if (shasize == 0) {
        //     // std.debug.print("Shasize 0\n", .{});
        //     break;
        // }
        const filesize = try input.readAll(&filebuffer);
        // std.debug.print("Filebuffer {s}\n", .{filebuffer});
        if (filesize == 0) {
            // std.debug.print("Filesize 0\n", .{});
            break;
        }
        line += 1;
        // std.debug.print("DEBUG {s}$\n", .{shabuffer[40..42]});
        // std.debug.print("TRUE {any}\n", .{!(std.mem.eql(u8, " *", shabuffer[40..42]) or std.mem.eql(u8, "  ", shabuffer[40..42]))});
        if (!(std.mem.eql(u8, " *", shabuffer[40..]) or std.mem.eql(u8, "  ", shabuffer[40..]))) {
            std.debug.print("{s}: {s}: no properly formated checksum lines found\n", .{ program, filename });
            continue;
        }
        const sha = shabuffer[0..40];
        const fileToSha = std.mem.trimRight(u8, filebuffer[0..filesize], "\n");
        // std.debug.print("SHA:{s} FILE:{s}appendix\n", .{ sha, fileToSha });
        // std.debug.print("INDX {?}\n", .{std.mem.indexOfScalar(u8, fileToSha, 0)});
        const openFileToSha = std.fs.cwd().openFile(fileToSha, .{}) catch {
            std.debug.print("{s}: {s}: no properly formated checksum lines found\n", .{ program, filename });
            // std.debug.print("AAAAAA{s}: {s}: No such file or directory\n", .{ shasum, fileToSha });
            // std.debug.print("BBBBBB{s}: FAILED open or read\n", .{ fileToSha });
            if (flags.f[10] == fp.FlagsProcessor.Flags.warn) {
                std.debug.print("{s}: {s}: {d}: improperly formatted SHA1 checksum line\n", .{ program, filename, line});
            }
            continue;
        };
        defer openFileToSha.close();
        // std.debug.print("FileToSha {s}\n", .{fileToSha});
        var result = try pbuffer.processBuffer(openFileToSha, fileToSha, flags);
        for (&result) |*val| {
            val.* = std.mem.bigToNative(u32, val.*);
        }
        var cmp: [20]u8 = undefined;
        const h1 = try std.fmt.hexToBytes(&cmp, sha);
        // var index: u8 = 0;
        // var ii: u8 = 2;
        var ptr: *const[20]u8 = @as(*const[20]u8, @ptrCast(&result));
        // const h1 = std.fmt.bytesToHex(ptr[0..1], std.fmt.Case.lower);
        const h2 = std.fmt.fmtSliceHexLower(ptr[0..20]);

        // std.debug.print("{any}\n", .{h1});
        // for (h1) |val| {
        //     std.debug.print("{d}", .{val});
        // }
        // std.debug.print("{any}\n", .{std.mem.eql(u8, h1, h2.data)});
        // std.debug.print("{any}\n", .{@typeInfo(h1)});
        // const h1 = std.fmt.bytesToHex(ptr[0..4], std.fmt.Case.lower);
        // for (h1) |v| {
        //     std.debug.print("{x}", .{v});
        // }
        // std.debug.print("sha {d}\n", .{h1});
        // std.debug.print("val {d}\n", .{val});
        // for (result) |value| {
        //     var ptr: *const[4]u8 = @as(*const[4]u8, @ptrCast(&value));
        //     for (ptr) |val| {
        //         const h1 = std.fmt.bytesToHex(val, std.fmt.Case.lower);
        //         std.debug.print("sha {d}\n", .{h1});
        //         std.debug.print("val {d}\n", .{val});
        //         // std.debug.print("{b}\n", .{h1 == val});
        //         index = ii;
        //         ii += 2;
        //     }
        //     std.debug.print("\n", .{});
        // }
        // std.debug.print("\n{x:0>8}\n", .{result[0]});
        // var buffer: [20]u8 = undefined;
        // if (result) |value| {
        // try ph.printHash(result, fileToSha, flags);
        // std.debug.print("{s}\n", .{sha});
        // std.debug.print("About to start\n", .{});
        // try ph.printHash(result, fileToSha, flags);
        // std.debug.print("Compare {c} {c}\n", .{cmp[3], sha[3]});
        if (std.mem.eql(u8, h1, h2.data)) {
            std.debug.print("{s}: OK\n", .{ fileToSha });
        } else {
            std.debug.print("{s}: FAILED\n", .{ fileToSha });
        }
        // } else |err| {
            // std.debug.print("{any}\n", .{err});
            // continue;
        // }
    }
}
