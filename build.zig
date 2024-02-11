const std = @import("std");
const LazyPath = std.Build.LazyPath;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const chan = b.addModule("chan", .{ .root_source_file = LazyPath.relative("src/chan.zig") });
    const chan_dep = b.dependency("chan", .{});

    chan.addIncludePath(chan_dep.path("src"));
    chan.addCSourceFile(.{ .file = chan_dep.path("src/chan.c"), .flags = &.{} });
    chan.addCSourceFile(.{ .file = chan_dep.path("src/queue.c"), .flags = &.{} });

    // Tests
    const example = b.addExecutable(.{
        .name = "example",
        .root_source_file = LazyPath.relative("example.zig"),
        .target = target,
        .optimize = optimize,
    });

    example.root_module.addImport("chan", chan);

    const example_run_artifact = b.addRunArtifact(example);
    b.step("run", "Run the example").dependOn(&example_run_artifact.step);
}
