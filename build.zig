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
        .root_source_file = LazyPath.relative("src/test.zig"),
        .target = target,
        .optimize = optimize,
    });

    example.root_module.addImport("chan", chan);

    // const tests = b.addTest(.{ .root_source_file = LazyPath.relative("src/test.zig") });
    // tests.addIncludePath(chan_dep.path("src"));
    // tests.addCSourceFile(.{ .file = chan_dep.path("src/chan.c"), .flags = &.{} });
    // tests.addCSourceFile(.{ .file = chan_dep.path("src/queue.c"), .flags = &.{} });

    const run_tests = b.addRunArtifact(example);

    b.step("test", "Run tests").dependOn(&run_tests.step);
}
