pub inline fn stop() noreturn {
    while (true) {
        asm volatile ("hlt");
    }
}

//print to the console
pub inline fn inb(port: u16) u8 {
    return asm volatile ("inb %[port], %[result]"
        : [result] "={al}" (-> u8),
        : [port] "N{dx}" (port),
    );
}

pub inline fn outb(port: u16, data: u8) void {
    asm volatile ("outb %[data], %[port]"
        :
        : [data] "{al}" (data),
          [port] "N{dx}" (port),
    );
}

pub inline fn getCS() u16 {
    return asm volatile ("mov %cs, %[result]"
        : [result] "=r" (-> u16),
    );
}

pub inline fn lgdt(gdtr: u80) void {
    //Load GDT
    asm volatile (
        \\lgdt %[p]
        :
        : [p] "*p" (&gdtr),
    );
}

pub inline fn lidt(idtr: u80) void {
    asm volatile ("lidt %[p]"
        :
        : [p] "*p" (&idtr),
    );
}
