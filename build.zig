const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const quickjs_h = b.addTranslateC(.{
        .root_source_file = b.path("./quickjs.h"),
        .link_libc = true,
        .target = target,
        .optimize = optimize,
    });

    const quickjs = quickjs_h.addModule("quickjs");
    quickjs.sanitize_c = .off;
    quickjs.addCSourceFiles(.{
        .files = &.{
            "cutils.c",
            "libregexp.c",
            "libunicode.c",
            "quickjs.c",
            "xsum.c",
        },
        .flags = &.{
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
        },
        .language = .c,
    });
    quickjs.addCMacro("_GNU_SOURCE", "");
}
