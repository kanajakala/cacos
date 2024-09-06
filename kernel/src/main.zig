const std = @import("std");
const screen = @import("screen.zig");
const debug = @import("debug.zig");
const kb = @import("keyboard.zig");
const mem = @import("memory.zig");

export fn _start() callconv(.C) noreturn {
    debug.print("CaCOS loaded sucessfully\n");

    //initialize screen
    screen.init();

    //init memory
    mem.init();

    //print MOTD
    screen.printMOTD();

    debug.printMem();
    debug.testMem(0xff);
    debug.testMem(0xbb);

    kb.restartKeyboard();

    var value: u8 = undefined;
    var old_value: u8 = undefined;
    while (true) {
        value = kb.listener();
        if (value != old_value) {
            screen.printChar(value, 0xfffffff);
            screen.drawCursor();
            old_value = value;
        }
    }
}
