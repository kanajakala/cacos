const db = @import("libs/lib-debug.zig");
const fs = @import("libs/lib-fs.zig");
const dsp = @import("libs/lib-display.zig");

//entry point
export fn _start() callconv(.C) void {
    //test interrupt, should print the current context
    db.print("\nHello from binary!!");
    const node = fs.open("motd.txt");
    db.debugValue(node.size, 0);
    for (0..node.size) |i| {
        const data: u8 = node.read(i);
        db.debugValue(data, 2);
    }
}
