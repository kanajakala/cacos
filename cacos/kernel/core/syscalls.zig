////This is used for the apps to interface with the kernel
const db = @import("../utils/debug.zig");
const isr = @import("../cpu/isr.zig");
const pic = @import("../cpu/pic.zig");
const mem = @import("../core/memory.zig");
const console = @import("../interface/console.zig");

pub const Syscalls = enum(u64) {
    print,
    open,
    read,
    write,
    alloc,
    malloc,
    valloc,
    load,
    exec,
    debug,
};

fn handler(stack_frame: *isr.InterruptStackFrame) callconv(.C) void {
    //Interrupts must end at some point
    defer pic.primary.endInterrupt();

    //the return value will be passed to the caller
    var value: u64 = 0;

    const syscall: Syscalls = @enumFromInt(stack_frame.r8);
    const arg0: u64 = stack_frame.r9;
    const arg1: u64 = stack_frame.r10;
    //const arg2: u64 = stack_frame.r11;

    switch (syscall) {
        .print => {
            //in this context:
            // arg0 -> pointer to a string
            // arg1 -> length of the string
            console.print(@as([*]u8, @ptrFromInt(mem.physicalFromVirtual(arg0)))[0..arg1]) catch {};
        },
        .open => value = 0xbaba,
        .read => value = 0xfafa,
        .write => value = 0xcac,
        .debug => {
            //in this context:
            // arg0 -> pointer to a string
            // arg1 -> length of the string
            db.print(@as([*]u8, @ptrFromInt(mem.physicalFromVirtual(arg0)))[0..arg1]);
        },
        else => value = 0xdada,
    }

    //return value
    asm volatile (
        \\mov %[value], %r12
        : //no output
        : [value] "m" (value),
        : "memory"
    );
}

pub fn init() void {
    //enable the syscall interrupt in the pic
    pic.primary.enable(2);

    //set the function used to handle syscalls
    isr.handle(2, handler);
}
