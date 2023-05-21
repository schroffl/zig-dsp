const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("dsp", .{
        .source_file = .{ .path = "src/index.zig" },
    });

    const bench_exe = b.addExecutable(.{
        .name = "bench",
        .root_source_file = .{ .path = "src/bench.zig" },
        .optimize = optimize,
        .target = target,
    });

    bench_exe.addModule(
        "bench",
        b.createModule(.{
            .source_file = .{ .path = "libs/zig-bench/bench.zig" },
        }),
    );

    const run_bench = b.addRunArtifact(bench_exe);
    const bench_step = b.step("bench", "Run the benchmarks");
    bench_step.dependOn(&run_bench.step);

    const tests = b.addTest(.{
        .root_source_file = .{ .path = "src/index.zig" },
        .optimize = optimize,
        .target = target,
    });

    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run the tests");
    test_step.dependOn(&run_tests.step);

    b.installArtifact(bench_exe);
    b.installArtifact(tests);
}
