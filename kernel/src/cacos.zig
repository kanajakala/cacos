const BOOTBOOT = @import("bootboot.zig").BOOTBOOT;
const dsp = @import("core/display.zig");
const font = @import("core/font.zig");

// imported virtual addresses, see linker script
extern var bootboot: BOOTBOOT; // see bootboot.zig
extern var environment: [4096]u8; // configuration, UTF-8 text key=value pairs

fn init() !void {
    try dsp.init();
    try font.init();
}

//entry point
export fn _start() callconv(.C) noreturn {
    _ = init() catch 0;

    //hang
    while (true) {}
}
