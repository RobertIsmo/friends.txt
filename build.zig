const std = @import("std");

const targets: []const std.Target.Query = &.{
    .{ .cpu_arch = .x86_64, .os_tag = .macos },
    .{ .cpu_arch = .aarch64, .os_tag = .macos },
    .{ .cpu_arch = .aarch64, .os_tag = .linux },
    .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .musl },
};

pub fn build(b: *std.Build) !void {
    const release = b.option(bool, "release", "Do a release build.") orelse false;

    b.addSearchPrefix(".");
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const main_file_path = "src/main.zig";

    if (release) {
        const version = b.option(
            []const u8,
            "version",
            "application version string",
        ) orelse unreachable;
        const options = b.addOptions();
        options.addOption([]const u8, "version", version);

        const gen = b.addSystemCommand(&.{
            "sh", "-c",
            \\mkdir -p "$DESTDIR/bin/release" &&
            \\sed "s/{VERSION}/$VERSION/" install.sh.in > "$DESTDIR/bin/release/install.sh"
        });
        gen.setEnvironmentVariable("VERSION", version);
        gen.setEnvironmentVariable("DESTDIR", b.install_prefix);

        b.getInstallStep().dependOn(&gen.step);

        for (targets) |t| {
            const exe = b.addExecutable(.{
                .name = "friends",
                .root_source_file = b.path(main_file_path),
                .target = b.resolveTargetQuery(t),
                .optimize = .ReleaseSmall,
            });

            exe.root_module.addOptions("config", options);

            const triple = try t.zigTriple(b.allocator);
            const dest_path = try std.mem.concat(
                b.allocator,
                u8,
                &[_][]const u8{ "/bin/release/", version, "/", triple },
            );

            const target_output = b.addInstallArtifact(exe, .{
                .dest_dir = .{
                    .override = .{
                        .custom = dest_path,
                    },
                },
            });

            b.getInstallStep().dependOn(&target_output.step);
        }
    } else {
        const options = b.addOptions();
        options.addOption([]const u8, "version", "Development");

        const exe = b.addExecutable(.{
            .name = "friends",
            .root_source_file = b.path(main_file_path),
            .target = target,
            .optimize = optimize,
        });

        exe.root_module.addOptions("config", options);

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
}
