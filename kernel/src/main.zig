const idt = @import("cpu/idt.zig");
const gdt = @import("cpu/gdt.zig");
const debug = @import("cpu/debug.zig");

const stream = @import("drivers/stream.zig");
const mem = @import("memory/memory.zig");

const scr = @import("drivers/screen.zig");
const kb = @import("drivers/keyboard.zig");

export fn _start() callconv(.C) noreturn {
    debug.print("Starting CaCOS loading\n");

    scr.init();
    scr.printMOTD();

    gdt.init();
    idt.init();
    mem.init();

    //keyboard handling
    kb.restartKeyboard();
    stream.init(&stream.stdin);
    debug.print("Loaded Cacos!\n");
}
