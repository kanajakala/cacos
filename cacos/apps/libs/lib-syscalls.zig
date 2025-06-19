pub const Syscalls = enum(u64) {
    print,
    open,
    read,
    readBuf,
    write,
    writeBuf,
    alloc,
    malloc,
    valloc,
    free,
    load,
    exec,
    debug,
    debugValue,
};

///trigger a system interrupt using these arguments and returns a value
pub fn syscall(stype: Syscalls, arg0: u64, arg1: u64, arg2: u64, arg3: u64) u64 {
    //push the arguments on the stack
    return asm volatile (
    //pass the arguments
    //trigger the syscall interrupt
        \\int $34        
        : [ret] "={r8}" (-> u64),
        : [syscall] "{r8}" (@intFromEnum(stype)),
          [arg0] "{r9}" (arg0),
          [arg1] "{r10}" (arg1),
          [arg2] "{r11}" (arg2),
          [arg3] "{r12}" (arg3),
    );
    //return asm volatile ("movq %r13, %[ret]"
    //    : [ret] "={r13}" (-> u64), // output operand: put result in `result`
    //);
}
