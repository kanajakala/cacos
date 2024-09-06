const screen = @import("screen.zig");
const debug = @import("debug.zig");
const kb = @import("keyboard.zig");
const mem = @import("memory.zig");
const stream = @import("stream.zig");

export fn _start() callconv(.C) noreturn {
    debug.print("CaCOS loaded sucessfully\n");

    //initialize screen
    screen.init();

    //init memory
    mem.init();

    //print MOTD
    screen.printMOTD();

    //keyboard handling
    kb.restartKeyboard();
    stream.init(&stream.stdin);
}
