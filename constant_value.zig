pub fn constantValue(u: usize) u32 {
    if (u <= 19) {
        return 0x5A827999;
    }
    if (u <= 39) {
        return 0x6ED9EBA1;
    }
    if (u <= 59) {
        return 0x8F1BBCDC;
    }
    return 0xCA62C1D6;
}
