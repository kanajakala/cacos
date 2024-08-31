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

pub inline fn print(comptime string: []const u8) void {
    inline for (string) |char| {
        outb(0xe9, char);
    }
}

pub fn charToString(char: u8) [:0]const u8 {
    var buf: [256]u8 = undefined;
    const str = try std.fmt.bufPrint(&buf, "{}", .{char});
    return str;
}
