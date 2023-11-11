const std = @import("std");
const cir = @import("circular.zig");
const bit = @import("bitwise.zig");
const cv = @import("constant_value.zig");

pub fn calculateHash(message: *[16]u32, bufferB: *[5]u32) void {
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
            val.* = cir.circular(1, seq[i - 3] ^ seq[i - 8] ^ seq[i - 14] ^ seq[i - 16]);
        }
    }

    inline for (&bufferA, 0..) |*val, i| {
        val.* = bufferB[i];
    }

    inline for (0..80, 0..) |_, i| {
        temp = cir.circular(5, bufferA[0]) +% bit.bitwise(i, bufferA[1], bufferA[2], bufferA[3]) +% bufferA[4] +% seq[i] +% cv.constantValue(i);
        bufferA[4] = bufferA[3];
        bufferA[3] = bufferA[2];
        bufferA[2] = cir.circular(30, bufferA[1]);
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
