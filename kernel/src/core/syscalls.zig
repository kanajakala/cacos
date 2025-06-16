////This is used for the apps to interface with the kernel
const db = @import("../utils/debug.zig");
const isr = @import("../cpu/isr.zig");
const pic = @import("../cpu/pic.zig");
const mem = @import("../core/memory.zig");

pub const Syscalls = enum(u64) {
    open,
    read,
    write,
    alloc,
    malloc,
    valloc,
    load,
    exec,
};

///trigger a system interrupt using these arguments and returns a value
pub fn syscall(stype: Syscalls, arg0: u64, arg1: u64, arg2: u64) u64 {
    //push the arguments on the stack
    asm volatile (
    //pass the arguments
    //trigger the syscall interrupt
        \\int $34        
        : //no output parameters
        : [syscall] "{r8}" (@intFromEnum(stype)),
          [arg0] "{r9}" (arg0),
          [arg1] "{r10}" (arg1),
          [arg2] "{r11}" (arg2),
    );
    return 0;
}

pub fn dummy() void {
    db.print("\nentering syscall");
    _ = syscall(Syscalls.open, 0xDEDEDEDEDE, 0xABABABAB, 0xCDCDCDCD);
    const value: u64 = asm volatile ("movq %r12, %[ret]"
        : [ret] "=r" (-> u64), // output operand: put result in `result`
    );
    db.printValue(value);
    db.print("\nsyscall done");
}

fn handler(stack_frame: *isr.InterruptStackFrame) callconv(.C) void {
    //Interrupts must end at some point
    defer pic.primary.endInterrupt();

    //return value
    if (stack_frame.r9 == 0xDEDEDEDEDE) {
        asm volatile (
            \\mov $0xCACACACACA, %r12
        );
    }
}

pub fn init() void {
    //enable the syscall interrupt in the pic
    pic.primary.enable(2);

    //set the function used to handle syscalls
    isr.handle(2, handler);

    dummy();
}
