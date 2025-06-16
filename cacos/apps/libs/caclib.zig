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

pub fn print(string: []const u8) void {
    _ = syscall(Syscalls.print, @intFromPtr(string.ptr), string.len, 0);
}

pub fn debug(string: []const u8) void {
    _ = syscall(Syscalls.debug, @intFromPtr(string.ptr), string.len, 0);
}
