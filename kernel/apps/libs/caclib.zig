pub const Syscalls = enum(u64) {
    open, //0
    read, //1
    write, //2
    alloc, //3
    malloc, //4
    valloc, //5
    load, //6
    exec, //7
    debug, //8
};

///trigger a system interrupt using these arguments and returns a value
fn syscall(stype: Syscalls, arg0: u64, arg1: u64, arg2: u64) u64 {
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
    return asm volatile ("movq %r12, %[ret]"
        : [ret] "=r" (-> u64), // output operand: put result in `result`
    );
}

pub fn dummy() void {
    _ = syscall(Syscalls.open, 0xDEDEDEDEDE, 0xABABABAB, 0xCDCDCDCD);
}

pub fn debug(string: []const u8) void {
    _ = syscall(Syscalls.debug, @intFromPtr(string.ptr), string.len, 0);
}
