const std = @import("std");
const screen = @import("screen.zig");
const cpu = @import("cpu.zig");
const kb = @import("keyboard.zig");
const mem = @import("memory.zig");

export fn _start() callconv(.C) noreturn {
    cpu.print("CaCOS loaded sucessfully\n");

    //initialize screen
    screen.init();

    //init memory
    mem.init();

    //print MOTD
    screen.printMOTD();

    mem.printMem();

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
