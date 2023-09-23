pub fn paddingSpecial(message: []const u8, tail: usize) [16]u32 {
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
