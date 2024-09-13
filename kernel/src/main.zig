const cpu = @import("cpu/cpu.zig");
const idt = @import("cpu/idt.zig");
const gdt = @import("cpu/gdt.zig");
const debug = @import("cpu/debug.zig");

const mem = @import("memory/memory.zig");

const scr = @import("drivers/screen.zig");
const kb = @import("drivers/keyboard.zig");
const console = @import("drivers/console.zig");

export fn _start() callconv(.C) noreturn {
    debug.print("Started CaCOS loading");

    scr.init();
    scr.printMOTD();

    gdt.init();
    idt.init();
    mem.init();

    console.init();
    debug.print("Loaded Cacos!");
    cpu.hang();
    asm volatile ("int $33");
}
