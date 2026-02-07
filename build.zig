const std = @import("std");
const raylib = @import("raylib");
pub const raylib_build = raylib;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("root", .{
        .root_source_file = b.path("src/init.zig"),
        .target = target,
        .optimize = optimize,
    });

    const defaults: raylib.Options = .{};
    const rd = b.dependency("raylib", .{
        .target = target,
        .optimize = optimize,
        .platform = b.option(raylib.PlatformBackend, "platform", "Choose the platform backedn for desktop target") orelse defaults.platform,
        .raudio = b.option(bool, "raudio", "Compile with audio support") orelse defaults.raudio,
        .rmodels = b.option(bool, "rmodels", "Compile with models support") orelse defaults.rmodels,
        .rtext = b.option(bool, "rtext", "Compile with text support") orelse defaults.rtext,
        .rtextures = b.option(bool, "rtextures", "Compile with textures support") orelse defaults.rtextures,
        .rshapes = b.option(bool, "rshapes", "Compile with shapes support") orelse defaults.rshapes,
        .shared = b.option(bool, "shared", "Compile as shared library") orelse defaults.shared,
        .linux_display_backend = b.option(raylib.LinuxDisplayBackend, "linux_display_backend", "Linux display backend to use") orelse defaults.linux_display_backend,
        .opengl_version = b.option(raylib.OpenglVersion, "opengl_version", "OpenGL version to use") orelse defaults.opengl_version,
        .config = b.option([]const u8, "config", "Compile with custom define macros overriding config.h") orelse &.{},
        .android_ndk = b.option([]const u8, "android_ndk", "specify path to android ndk") orelse b.graph.environ_map.get("ANDROID_NDK_HOME") orelse "",
        .android_api_version = b.option([]const u8, "android_api_version", "specify target android API level") orelse defaults.android_api_version,
    });
    b.installArtifact(rd.artifact("raylib"));

    const raylib_tc = b.addTranslateC(.{
        .root_source_file = b.addWriteFile("include.h",
            \\#include "raylib.h"
            \\#include "raymath.h"
            \\#include "rlgl.h"
        ).getDirectory().path(b, "include.h"),
        .optimize = optimize,
        .target = target,
    });
    raylib_tc.addIncludePath(rd.path("src"));
    mod.addImport("c", raylib_tc.createModule());

    mod.addIncludePath(rd.path("src"));
    mod.linkLibrary(rd.artifact("raylib"));
    b.addNamedLazyPath("raylib-root", rd.path("."));

    const test_options = b.addOptions();
    test_options.addOption(bool, "check_raylib_decls", b.option(bool, "check_raylib_decls", "Compile error if we are missing some raylib decls") orelse false);
    mod.addOptions("test_options", test_options);

    const mod_unit_tests = b.addTest(.{
        .root_module = mod,
        .use_lld = false,
    });

    const run_mod_unit_tests = b.addRunArtifact(mod_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_mod_unit_tests.step);
}
