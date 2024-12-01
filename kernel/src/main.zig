const cpu = @import("core/cpu.zig");
const idt = @import("core/idt.zig");
const gdt = @import("core/gdt.zig");
const db = @import("core/debug.zig");
const fs = @import("core/fs.zig");
const scheduler = @import("core/scheduler.zig");

const mem = @import("memory/memory.zig");
const pages = @import("memory/pages.zig");

const scr = @import("drivers/screen.zig");
const kb = @import("drivers/keyboard.zig");
const console = @import("drivers/console.zig");

const apps = @import("apps/init.zig");

const files: []const u8 = @embedFile("cacos.fs");

//load all files into the filesystem
pub fn loadFiles() void {}

export fn _start() callconv(.C) noreturn {
    //db.print("\nStarted CaCOS loading\n");

    scr.init();
    scr.printMOTD();

    gdt.init();
    idt.init();

    mem.init();
    pages.init();

    fs.init();
    loadFiles();

    apps.init();

    console.init();

    //db.print("Loaded Cacos!\n");
    scheduler.init();

    cpu.hang();
}
