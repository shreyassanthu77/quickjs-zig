# QuickJS Zig
[QuickJS ng](https://github.com/quickjs-ng/quickjs) packaged for the [Zig build system](https://ziglang.org/).

> [!NOTE]
> Requires **Zig 0.15.1** or later.

## Installation

Add QuickJS as a dependency to your project:

```bash
zig fetch --save git+https://github.com/shreyassanthu77/quickjs-zig
```

In your `build.zig`:

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Add QuickJS dependency
    const quickjs_dep = b.dependency("quickjs_zig", .{
        .target = target,
        .optimize = optimize,
    });
    const quickjs = quickjs_dep.module("quickjs");

    // Your executable
    const exe = b.addExecutable(.{
        .name = "your-app",
        .root_source_file = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .imports = &.{
                // Add QuickJS module to your executable
                .{ .name = "quickjs", .module = quickjs },
            },
            .target = target,
            .optimize = optimize,
        }),
    });

    // ...
}
```

## Usage

```zig
const std = @import("std");
const qjs = @import("quickjs");

pub fn main() !void {
    const runtime = qjs.JS_NewRuntime() orelse return error.JS_NewRuntime;
    defer qjs.JS_FreeRuntime(runtime);

    const context = qjs.JS_NewContext(runtime) orelse return error.JS_NewContext;
    defer qjs.JS_FreeContext(context);

    // ...
}
```
