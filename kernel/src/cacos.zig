const BOOTBOOT = @import("bootboot.zig").BOOTBOOT;
const scr = @import("core/screen.zig");

// imported virtual addresses, see linker script
extern var bootboot: BOOTBOOT; // see bootboot.zig
extern var environment: [4096]u8; // configuration, UTF-8 text key=value pairs

//entry point
export fn _start() callconv(.C) noreturn {
    //hang
    scr.start();
    while (true) {}
}
