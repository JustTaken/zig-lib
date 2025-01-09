const Builder = @import("std").Build;

pub fn build(builder: *Builder) void {
    _ = builder.standardTargetOptions(.{});
    _ = builder.standardOptimizeOption(.{});

    _ = builder.addModule("lib", .{
        .root_source_file = builder.path("src/root.zig"),
    });
}
