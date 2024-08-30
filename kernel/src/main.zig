//print to the console
inline fn inb(port: u16) u8 {
    return asm volatile ("inb %[port], %[result]"
        : [result] "={al}" (-> u8),
        : [port] "N{dx}" (port),
    );
}

inline fn outb(port: u16, data: u8) void {
    asm volatile ("outb %[data], %[port]"
        :
        : [data] "{al}" (data),
          [port] "N{dx}" (port),
    );
}

inline fn dprint(comptime string: [:0]const u8) void {
    inline for (string) |char| {
        outb(0xe9, char);
    }
}

export fn _start() callconv(.C) noreturn {
    dprint("CaCOS loaded sucessfully");
    while (true) {}
}
