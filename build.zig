const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const options = try getCompileOptions(b, target);
    defer b.allocator.free(options.c_flags);
    defer b.allocator.free(options.defines);

    const sources = try getQuickJsSources(b);
    defer b.allocator.free(sources);

    const lib_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    lib_mod.addCSourceFiles(.{
        .files = sources,
        .flags = options.c_flags,
        .language = .c,
    });
    for (options.defines) |define| {
        lib_mod.c_macros.append(
            b.allocator,
            b.fmt("-D{s}", .{define}),
        ) catch @panic("OOM");
    }

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "quickjs",
        .root_module = lib_mod,
    });
    const os = target.result.os.tag;
    lib.stack_size = switch (os) {
        .wasi => 2097152,
        else => 8388608,
    };

    lib.installHeadersDirectory(b.path("."), ".", .{});
    b.installArtifact(lib);

    // TODO: run tests
    // const lib_unit_tests = b.addTest(.{
    //     .root_module = lib_mod,
    // });
    // const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    //
    // const test_step = b.step("test", "Run unit tests");
    // test_step.dependOn(&run_lib_unit_tests.step);
}

pub fn getCompileOptions(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
) !struct {
    c_flags: []const []const u8,
    defines: []const []const u8,
} {
    const os = target.result.os.tag;

    var flags = std.ArrayList([]const u8).init(b.allocator);
    var defines = std.ArrayList([]const u8).init(b.allocator);

    try flags.appendSlice(&.{
        "-std=c11",
        "-Wall",
        "-Wextra",
        "-Werror",
        "-Wformat=2",
        "-Wno-implicit-fallthrough",
        "-Wno-sign-compare",
        "-Wno-missing-field-initializers",
        "-Wno-unused-parameter",
        "-Wno-unused-function",
        "-Wno-unused-but-set-variable",
        "-Wno-unused-result",
        // "-Wno-stringop-truncation",
        "-Wno-array-bounds",
        "-funsigned-char",
        "-Wno-unsafe-buffer-usage",
        "-Wno-sign-conversion",
        "-Wno-nonportable-system-include-path",
        "-Wno-implicit-int-conversion",
        "-Wno-shorten-64-to-32",
        "-Wno-reserved-macro-identifier",
        "-Wno-reserved-identifier",
        "-Wdeprecated-declarations",
    });

    try defines.appendSlice(&.{
        "_GNU_SOURCE",
    });

    switch (os) {
        .windows => {
            try defines.appendSlice(&.{
                "WIN32_LEAN_AND_MEAN",
            });
        },
        .wasi => {
            try defines.appendSlice(&.{
                "_WASI_EMULATED_PROCESS_CLOCKS",
                "_WASI_EMULATED_SIGNAL",
            });
            try flags.appendSlice(&.{
                "-lwasi-emulated-process-clocks",
                "-lwasi-emulated-signal",
            });
        },
        else => {},
    }

    return .{
        .c_flags = try flags.toOwnedSlice(),
        .defines = try defines.toOwnedSlice(),
    };
}

pub fn getQuickJsSources(b: *std.Build) ![]const []const u8 {
    const build_qjs_libc = b.option(bool, "qlibc", "Build standard library modules as part of the library") orelse false;

    var sources = std.ArrayList([]const u8).init(b.allocator);
    try sources.appendSlice(&.{
        "cutils.c",
        "libbf.c",
        "libregexp.c",
        "libunicode.c",
        "quickjs.c",
    });
    if (build_qjs_libc) {
        try sources.append("quickjs-libc.c");
    }

    return sources.toOwnedSlice();
}
