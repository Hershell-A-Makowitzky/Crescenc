const std = @import("std");

pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "hersha",
        .root_source_file = std.Build.FileSource{ .path = "sha.zig"},
        .single_threaded = true,
        .use_llvm = true,
        .optimize = .ReleaseFast,
        .target = .{}
    });
    exe.strip = true;
    b.installArtifact(exe);
}
