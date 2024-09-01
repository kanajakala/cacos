const std = @import("std");
const screen = @import("screen.zig");
const debug = @import("debug.zig");
const kb = @import("keyboard.zig");

export fn _start() callconv(.C) noreturn {
    debug.print("CaCOS loaded sucessfully");

    //initialize screen
    screen.init();

    //print MOTD
    screen.printMOTD();

    kb.restartKeyboard();

    var value: u8 = undefined;
    var old_value: u8 = undefined;
    while (true) {
        value = kb.listener();
        if (value != old_value) {
            screen.printChar(value, 0xfffffff, 0);
            screen.drawCursor();
            old_value = value;
        }
    }
}
