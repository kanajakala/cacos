///Get value at port
pub inline fn inb(port: u16) u8 {
    return asm volatile ("inb %[port], %[result]"
        : [result] "={al}" (-> u8),
        : [port] "N{dx}" (port),
    );
}

///output value at port
pub inline fn outb(port: u16, data: u8) void {
    asm volatile ("outb %[data], %[port]"
        :
        : [data] "{al}" (data),
          [port] "N{dx}" (port),
    );
}

///Get Code Segment
pub inline fn getCS() u16 {
    return asm volatile ("mov %cs, %[result]"
        : [result] "=r" (-> u16),
    );
}

///Load Global Descriptor Table
pub inline fn lgdt(gdtr: u80) void {
    //Load GDT
    asm volatile (
        \\lgdt %[p]
        :
        : [p] "*p" (&gdtr),
    );
}

///load the Interrupt Descriptor Table
pub inline fn lidt(idtr: u80) void {
    asm volatile ("lidt %[p]"
        :
        : [p] "*p" (&idtr),
    );
}

/// Perform a short I/O delay.
pub inline fn wait() void {
    // port 0x80 was wired to a hex display in the past and
    // is now mostly unused. Writing garbage data to port 0x80
    // allegedly takes long enough to make everything work on most
    // hardware.
    outb(0x80, 0);
}

pub inline fn wait_long() void {
    @setEvalBranchQuota(10_000);
    inline for (0..3000) |_| wait();
}

///wait for interrupt
pub inline fn hang() noreturn {
    while (true) {
        asm volatile ("hlt");
    }
}

pub fn jump(address: u64) void {
    const func: *const fn () callconv(.c) void = @ptrFromInt(address);
    func();
}
