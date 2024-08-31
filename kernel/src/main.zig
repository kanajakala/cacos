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
        value = kb.getScanCode();
        if (value != 250 and value != old_value) {
            //debug.print(str);
            screen.printChar(value, 0xfffffff, 0);
            old_value = value;
        }
    }
}
