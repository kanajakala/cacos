const cpu = @import("core/cpu.zig");
const idt = @import("core/idt.zig");
const gdt = @import("core/gdt.zig");
const db = @import("core/debug.zig");
const fs = @import("core/fs.zig");
const scheduler = @import("core/scheduler.zig");

const mem = @import("memory/memory.zig");

const scr = @import("drivers/screen.zig");
const kb = @import("drivers/keyboard.zig");
const console = @import("drivers/console.zig");

const apps = @import("apps/init.zig");

export fn _start() callconv(.C) noreturn {
    //db.print("\nStarted CaCOS loading\n");

    scr.init();
    scr.printMOTD();

    gdt.init();
    idt.init();
    mem.init();
    fs.init();

    apps.init();

    console.init();

    //db.print("Loaded Cacos!\n");
    scheduler.init();

    cpu.hang();
}
