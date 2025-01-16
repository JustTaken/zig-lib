const Builder = @import("std").Build;

pub fn build(builder: *Builder) void {
    _ = builder.standardTargetOptions(.{});
    _ = builder.standardOptimizeOption(.{});

    _ = builder.addModule("lib", .{
        .root_source_file = builder.path("src/root.zig"),
    });

    const lib_test = builder.addTest(.{
        .root_source_file = builder.path("src/root.zig"),
    });

    const run_test = builder.addRunArtifact(lib_test);
    const test_step = builder.step("test", "Run unit test");

    test_step.dependOn(&run_test.step);
}
