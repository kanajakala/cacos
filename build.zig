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
    //const limine_raw = b.dependency("limine_raw", .{});
    const target: std.Build.ResolvedTarget = b.resolveTargetQuery(.{
        .cpu_arch = kernel_config.arch,
        .os_tag = .freestanding,
        .abi = .none,
        .cpu_features_add = feature_mod.add,
        .cpu_features_sub = feature_mod.sub,
    });

    const kernel_optimize = b.standardOptimizeOption(.{});

    //build steps

    //Compile the kernel to an elf file
    const kernel = b.addExecutable(.{
        .name = "cacos.elf",
        .root_source_file = b.path("kernel/src/cacos.zig"),
        .target = target,
        .optimize = kernel_optimize,
        .code_model = .kernel,
        .pic = true,
        .strip = true,
    });

    kernel.setLinkerScript(b.path("kernel/link.ld"));

    //step to build the kernel
    const compile_step = b.step("compile", "Build the kernel");
    compile_step.dependOn(&b.addInstallArtifact(kernel, .{
        .dest_dir = .{
            .override = .{ .custom = "../kernel/img/src/initrd" },
        },
    }).step);

    //Compile all apps to elf files
    var apps_dir = std.fs.cwd().openDir(
        "kernel/apps",
        .{ .iterate = true },
    ) catch |err| {
        std.debug.print("Failed to open apps directory: {}\n", .{err});
        return;
    };
    defer apps_dir.close();

    const compile_apps_step = b.step("compile-apps", "Build the apps");
    compile_apps_step.dependOn(compile_step);

    var iterator = apps_dir.iterate();
    while (iterator.next() catch null) |entry| {
        if (entry.kind == .file and std.mem.endsWith(u8, entry.name, ".zig")) {
            const app_name = entry.name[0 .. entry.name.len - 4]; // Remove .zig extension
            const app_path = b.fmt("kernel/apps/{s}", .{entry.name});

            const app = b.addExecutable(.{
                .name = b.fmt("{s}.elf", .{app_name}),
                .root_source_file = b.path(app_path),
                .target = target,
                .optimize = kernel_optimize,
                .code_model = .small,
                //.pic = true,
                .strip = true,
            });

            compile_apps_step.dependOn(&b.addInstallArtifact(app, .{
                .dest_dir = .{
                    .override = .{ .custom = "../kernel/img/src/initrd/bin" },
                },
            }).step);
        }
    }

    //generate an image using mkbootimg, a bootboot utility
    const gen_cmd = b.addSystemCommand(&.{ "bash", "scripts/image.sh" });
    gen_cmd.step.dependOn(compile_apps_step);
    const gen_step = b.step("image", "Generate the cacos image");
    gen_step.dependOn(&gen_cmd.step);

    //run the kernel in quemu
    const run_command = b.addSystemCommand(&.{
        "qemu-system-x86_64",
        "-s", //enable debugging
        "-drive", //the file to run
        "format=raw,file=kernel/img/cacos.img",
        "-m", //the amount of ram
        "16G",
        "-debugcon", //send debug console output to stdio
        "stdio",
        "--no-reboot", //don't reboot, usefull for debugging
        "-D", //enable logs
        ".cache/logs",
        "-d",
        "int",
        //"-icount", //slow machine down
        //"0,align=on", //by a factor 10
    });
    run_command.step.dependOn(gen_step);

    const run = b.step("run", "Run Cacos");
    run.dependOn(&run_command.step);

    //extras

    //build the mkbootimg utility
    const setup_cmd = b.addSystemCommand(&.{ "bash", "scripts/setup_mkbootimg.sh" });
    const setup_step = b.step("setup", "Download and build the mkbootimg utility");
    setup_step.dependOn(&setup_cmd.step);

    //clean the directory
    const clean_cmd = b.addSystemCommand(&.{
        "rm",
        "-f",
        "-r",
        "cacos.bin",
        "zig-cache",
        "zig-out",
    });
    const clean_step = b.step("clean", "Remove all generated files");
    clean_step.dependOn(&clean_cmd.step);
}
