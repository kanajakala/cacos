const idt = @import("cpu/idt.zig");
const gdt = @import("cpu/gdt.zig");
const debug = @import("cpu/debug.zig");

const stream = @import("drivers/stream.zig");
const mem = @import("memory/memory.zig");

const scr = @import("drivers/screen.zig");
const kb = @import("drivers/keyboard.zig");

export fn _start() callconv(.C) noreturn {
    debug.print("Starting CaCOS loading\n");

    gdt.init();
    //idt.init();
    //initialize scr
    scr.init();

    //init memory
    mem.init();

    //print MOTD
    scr.printMOTD();

    //keyboard handling
    kb.restartKeyboard();
    stream.init(&stream.stdin);
    debug.print("Loaded Cacos!\n");
}
