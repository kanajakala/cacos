const db = @import("libs/lib-debug.zig");
const fs = @import("libs/lib-fs.zig");
const console = @import("libs/lib-console.zig");
const mem = @import("libs/lib-memory.zig");

//entry point
export fn _start() callconv(.C) void {
    //print the buffer
    console.print("Another app!");
}
