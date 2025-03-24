const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("root", .{
        .root_source_file = b.path("src/init.zig"),
    });

    const rd = b.dependency("raylib", .{
        .target = target,
        .optimize = optimize,
    });

    mod.addIncludePath(rd.path("src"));
    b.installArtifact(rd.artifact("raylib"));

    const mod_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/init.zig"),
        .target = target,
        .optimize = optimize,
    });
    mod_unit_tests.linkLibrary(rd.artifact("raylib"));
    mod_unit_tests.linkLibC();

    const run_mod_unit_tests = b.addRunArtifact(mod_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_mod_unit_tests.step);
}
