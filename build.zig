const std = @import("std");

const kernel_config = .{
    .arch = std.Target.Cpu.Arch.x86_64,
};

const FeatureMod = struct {
    add: std.Target.Cpu.Feature.Set = std.Target.Cpu.Feature.Set.empty,
    sub: std.Target.Cpu.Feature.Set = std.Target.Cpu.Feature.Set.empty,
};

fn getFeatureMod(comptime arch: std.Target.Cpu.Arch) FeatureMod {
    var mod: FeatureMod = .{};

    switch (arch) {
        .x86_64 => {
            const Features = std.Target.x86.Feature;

            mod.add.addFeature(@intFromEnum(Features.soft_float));
            mod.sub.addFeature(@intFromEnum(Features.mmx));
            mod.sub.addFeature(@intFromEnum(Features.sse));
            mod.sub.addFeature(@intFromEnum(Features.sse2));
            mod.sub.addFeature(@intFromEnum(Features.avx));
            mod.sub.addFeature(@intFromEnum(Features.avx2));
        },
        else => @compileError("Unimplemented architecture"),
    }

    return mod;
}

pub fn build(b: *std.Build) void {
    const feature_mod = getFeatureMod(kernel_config.arch);
    const limine = b.dependency("limine", .{});
    //const limine_raw = b.dependency("limine_raw", .{});
    const target: std.Build.ResolvedTarget = b.resolveTargetQuery(.{
        .cpu_arch = kernel_config.arch,
        .os_tag = .freestanding,
        .abi = .none,
        .cpu_features_add = feature_mod.add,
        .cpu_features_sub = feature_mod.sub,
    });

    const kernel_optimize = b.standardOptimizeOption(.{});

    const kernel = b.addExecutable(.{
        .name = "kernel",
        .root_source_file = b.path("kernel/src/main.zig"),
        .target = target,
        .optimize = kernel_optimize,
        .code_model = .kernel,
        .pic = true,
    });

    //kernel.pie = false;
    kernel.root_module.addImport("limine", limine.module("limine"));
    kernel.setLinkerScriptPath(b.path("kernel/linker.ld"));

    const app_cmd = b.addSystemCommand(&.{ "bash", "scripts/apps.sh" });
    const app_step = b.step("app", "Assemble all asm apps");
    app_step.dependOn(&app_cmd.step);

    const kernel_step = b.step("kernel", "Build the kernel");
    kernel_step.dependOn(&app_cmd.step);
    kernel_step.dependOn(&b.addInstallArtifact(kernel, .{
        .dest_dir = .{ .override = .prefix },
    }).step);

    const limine_cmd = b.addSystemCommand(&.{ "bash", "scripts/limine.sh" });
    const limine_step = b.step("limine", "Download and build limine bootloader");
    limine_step.dependOn(&limine_cmd.step);

    const iso_cmd = b.addSystemCommand(&.{ "bash", "scripts/iso.sh" });
    iso_cmd.step.dependOn(limine_step);
    iso_cmd.step.dependOn(kernel_step);
    const iso_step = b.step("iso", "Build an iso file");
    iso_step.dependOn(&iso_cmd.step);

    const run_iso_cmd = b.addSystemCommand(&.{ "bash", "scripts/run_iso.sh" });
    run_iso_cmd.step.dependOn(iso_step);
    const run_iso_step = b.step("run-iso", "Run ISO file in emulator");
    run_iso_step.dependOn(&run_iso_cmd.step);

    const clean_cmd = b.addSystemCommand(&.{
        "rm",
        "-f",
        "cacos.iso",
        "-r",
        "zig-cache",
        "zig-out",
    });
    const clean_step = b.step("clean", "Remove all generated files");
    clean_step.dependOn(&clean_cmd.step);
}
