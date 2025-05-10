const cpu = @import("../cpu/cpu.zig");
const std = @import("std");

///output character to debug console
pub inline fn printChar(char: u8) void {
    cpu.outb(0xe9, char);
}

///print to debug console
pub inline fn print(string: []const u8) void {
    for (string) |char| {
        printChar(char);
    }
}

///print errors to console to debug console
pub inline fn printErr(string: []const u8) void {
    //color output in yellow
    print("\u{001b}[31m");
    print(string);
    print("\u{001B}[0m");
}

pub inline fn panic(string: []const u8) void {
    //color output in red
    print("\u{001b}[34m");
    print(string);
    print("\u{001B}[0m");
    cpu.hang();
}

pub fn printValue(n: u128) void {
    var buffer: [32]u8 = undefined;
    print(std.fmt.bufPrint(&buffer, "{X}", .{n}) catch buffer[0..0]);
}

pub fn printValueDec(n: u128) void {
    var buffer: [32]u8 = undefined;
    print(std.fmt.bufPrint(&buffer, "{d}", .{n}) catch buffer[0..0]);
}

pub fn debug(string: []const u8, value: usize, mode: u1) void {
    switch (mode) {
        0 => {
            print("\n");
            print(string);
            print(": ");
            printValue(value);
        },
        1 => {
            print("\n");
            print(string);
            print(": ");
            printValueDec(value);
        },
    }
}

pub fn debugPage(page: []u8, format: u1) void {
    print("\n----debugging page------\n");
    print("informations about the page:\n");
    debug(" -> length of the page", page.len, 1);
    debug(" -> address of the page", @intFromPtr(@as(*[4096]u8, @alignCast(@ptrCast(page)))), 0);
    print("\ncontent of the page in hexadecimal\n");
    for (0..64) |i| {
        for (0..64) |j| {
            const value = page[i * 64 + j];
            if (format == 0) {
                if (value < 0xf) { //usefull for formating
                    print("0");
                    printValue(value);
                } else {
                    printValue(value);
                }
            } else {
                printChar(value);
            }
            print(" ");
        }
        print("\n");
    }
}
