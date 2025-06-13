///output value at port
pub inline fn outb(port: u16, data: u8) void {
    asm volatile ("outb %[data], %[port]"
        :
        : [data] "{al}" (data),
          [port] "N{dx}" (port),
    );
}

///output character to debug console
pub inline fn printChar(char: u8) void {
    outb(0xe9, char);
}

///print to debug console
pub inline fn print(string: []const u8) void {
    for (string) |char| {
        printChar(char);
    }
}

//entry point
export fn _start() callconv(.C) void {
    //test interrupt, should print the current context
    asm volatile ("int $9");
}
