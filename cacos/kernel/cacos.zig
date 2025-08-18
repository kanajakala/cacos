const console = @import("interface/console.zig");
const ramfs = @import("core/ramfs.zig");
const syscalls = @import("core/syscalls.zig");
const gdt = @import("cpu/gdt.zig");
const isr = @import("cpu/isr.zig");
const time = @import("cpu/time.zig");
const db = @import("utils/debug.zig");
const initrd = @import("utils/initrd.zig");

// imported virtual addresses, see linker script
extern var environment: [4096]u8; // configuration, UTF-8 text key=value pairs

fn init() !void {
    try gdt.init();
    try isr.init();
    try time.init();
    try ramfs.init();
    try initrd.unpack();
    syscalls.init();
    try console.init();
}

//entry point
export fn _start() noreturn {
    _ = init() catch |err| {
        //on error, print it
        db.printErr(@errorName(err));
    };

    //hang
    while (true) {}
}
