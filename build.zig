const std = @import("std");

pub fn build(b: *std.Build) void {
    b.addSearchPrefix(".");
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const main_file_path = "src/main.zig";

    const exe = b.addExecutable(.{
        .name = "friends",
        .root_source_file = b.path(main_file_path),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(exe);

    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_exe.step);

    const unit_tests = b.addTest(.{
        .root_source_file = b.path(main_file_path),
        .target = target,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
