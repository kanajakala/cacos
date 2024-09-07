const std = @import("std");
const cpu = @import("cpu.zig");
const mem = @import("memory.zig");
const pages = @import("pages.zig");
const screen = @import("screen.zig");
const stream = @import("stream.zig");

pub inline fn printChar(char: u8) void {
    cpu.outb(0xe9, char);
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
    cpu.stop();
}

pub fn numberToStringHex(n: u64, buffer: []u8) []const u8 {
    return std.fmt.bufPrint(buffer, "{X}", .{n}) catch buffer[0..0];
}
pub fn numberToStringDec(n: u64, buffer: []u8) []const u8 {
    return std.fmt.bufPrint(buffer, "{d}", .{n}) catch buffer[0..0];
}

pub fn testMem(value: u8) void {
    var buffer: [20]u8 = undefined;
    const memory: pages.Page = pages.alloc(&pages.pageTable) catch |err| { //on errors
        switch (err) {
            pages.errors.outOfPages => screen.print("Error: out of pages", 0xff0000),
        }
        return;
    };
    screen.print("\nAttempting allocation of 1 page at ", 0xeeeeee);
    screen.print(numberToStringHex(memory.start, &buffer), 0xeeeeee);

    screen.print("\n -> Writing value ", 0x888888);
    screen.print(numberToStringHex(value, &buffer), 0x888888);

    var iterations: usize = 0;
    for (0..memory.end - memory.start) |j| {
        mem.memory_region[memory.start + j] = value;
        iterations = j;
    }
    screen.print("\n -> words written: ", 0x0fbbff);
    screen.print(numberToStringDec(iterations, &buffer), 0xff0000);
    screen.print("\n -> reading word 0: ", 0x00ff00);
    screen.print(numberToStringHex(mem.memory_region[memory.start], &buffer), 0xff0000);
    screen.print("\n -> reading word 8000 (page size): ", 0x00ff00);
    screen.print(numberToStringHex(mem.memory_region[memory.end - 1], &buffer), 0xff0000);
    //screen.print("\n -> freeing memory\n", 0xfb342);
    //pages.free(memory, &pages.pageTable);
}

pub fn printMem() void {
    var buffer: [20]u8 = undefined;
    const length = numberToStringHex(mem.memory_region.len, &buffer);
    screen.print("\nlength of memory: ", 0xeeeeee);
    screen.print(length, 0xffaa32);
    const number_of_pages = numberToStringDec(pages.number_of_pages, &buffer);
    screen.print("\nnumber of pages: ", 0xeeeeee);
    screen.print(number_of_pages, 0xffaa32);
    const page_size = numberToStringDec(pages.page_size, &buffer);
    screen.print("\npage size: ", 0xeeeeee);
    screen.print(page_size, 0xffaa32);
    screen.newLine();
}

pub fn arrayStartsWith(arr: []const u8, str: []const u8) bool {
    if (arr.len < str.len) return false;
    return std.mem.eql(u8, arr[0..str.len], str);
}

pub fn printArray(arr: []const u8) void {
    for (arr) |i| {
        if (i != 0) {
            printChar(i);
        }
    }
}

pub fn charToInt(char: u8) u8 {
    if (char >= 30) {
        return char - '0';
    }
    return 0;
}

//NOT TESTED
pub fn concat(str1: []const u8, str2: []const u8) []const u8 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const result = std.fmt.allocPrint(allocator, "{s} {s}!", .{ str1, str2 }) catch "R";
    defer allocator.free(result);
    return result;
}

pub fn stdinToString(in: [stream.stream_size]u8) []const u8 {
    var out: []const u8 = "";
    for (in) |i| {
        if (i != 0 and i != 0xa) {
            out = concat(out, i);
        }
    }
    return out;
}
