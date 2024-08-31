const std = @import("std");
const screen = @import("screen.zig");
const debug = @import("debug.zig");

export fn _start() callconv(.C) noreturn {
    debug.print("CaCOS loaded sucessfully");

    //initialize screen
    screen.init();

    //print MOTD
    screen.printMOTD();

    while (true) {}
}
