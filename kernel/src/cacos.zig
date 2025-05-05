const dsp = @import("core/display.zig");
const ramfs = @import("core/ramfs.zig");
const font = @import("core/font.zig");
const gdt = @import("cpu/gdt.zig");
const idt = @import("cpu/idt.zig");
const db = @import("utils/debug.zig");

// imported virtual addresses, see linker script
extern var environment: [4096]u8; // configuration, UTF-8 text key=value pairs

fn init() !void {
    try gdt.init();
    try idt.init();
    try dsp.init();
    try font.init();
    try ramfs.init();
}

//entry point
export fn _start() callconv(.C) noreturn {
    _ = init() catch |err| {
        //on error, print it
        db.printerr(@errorName(err));
    };

    //hang
    while (true) {}
}
