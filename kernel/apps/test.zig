const lib = @import("libs/caclib.zig");

//entry point
export fn _start() callconv(.C) void {
    //test interrupt, should print the current context
    lib.debug("\nHello from binary!!");
}
