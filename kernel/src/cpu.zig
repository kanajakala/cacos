const std = @import("std");

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

pub inline fn printChar(char: u8) void {
    outb(0xe9, char);
}

pub fn print(string: []const u8) void {
    for (string) |char| {
        printChar(char);
    }
}

pub fn panic(string: []const u8) void {
    for (string) |char| {
        printChar(char);
    }
    stop();
}

pub fn numberToString(n: u64, buffer: []u8) []const u8 {
    return std.fmt.bufPrint(buffer, "{x}", .{n}) catch buffer[0..0];
}
