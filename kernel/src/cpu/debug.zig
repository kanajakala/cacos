const std = @import("std");
const cpu = @import("cpu.zig");
const mem = @import("../memory/memory.zig");
const pages = @import("../memory/pages.zig");
const scr = @import("../drivers/screen.zig");
const stream = @import("../drivers/stream.zig");

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
    var memory: pages.Page = pages.alloc(&pages.pageTable) catch |err| { //on errors
        switch (err) {
            pages.errors.outOfPages => scr.print("Error: out of pages", scr.errorc),
        }
        return;
    };
    var temp: pages.Page = undefined;
    for (0..value) |i| {
        _ = i;
        temp = pages.alloc(&pages.pageTable) catch |err| { //on errors
            switch (err) {
                pages.errors.outOfPages => scr.print("Error: out of pages", scr.errorc),
            }
            return;
        };
    }
    memory.end = temp.end;
    scr.print("\nAttempting allocation of ", scr.text);
    scr.print(numberToStringDec(value, &buffer), scr.errorc);
    scr.print(" pages at ", scr.text);
    scr.print(numberToStringHex(memory.start, &buffer), scr.text);

    scr.print("\n -> Writing value ", 0x888888);
    scr.print(numberToStringHex(value, &buffer), 0x888888);

    var iterations: usize = 0;
    for (0..memory.end - memory.start) |j| {
        mem.memory_region[memory.start + j] = value;
        iterations = j;
    }
    scr.print("\n -> words written: ", 0x0fbbff);
    scr.print(numberToStringDec(iterations, &buffer), scr.errorc);
    scr.print("\n -> reading word 0: ", 0x00ff00);
    scr.print(numberToStringHex(mem.memory_region[memory.start], &buffer), scr.errorc);
    scr.print("\n -> reading last word: ", 0x00ff00);
    scr.print(numberToStringHex(mem.memory_region[memory.end - 1], &buffer), scr.errorc);
    //scr.print("\n -> freeing memory\n", 0xfb342);
    //pages.free(memory, &pages.pageTable);
}

pub fn printMem() void {
    var buffer: [20]u8 = undefined;
    const length = numberToStringDec(mem.memory_region.len / 1_000_000, &buffer);
    scr.print("\nsize of memory: ", scr.text);
    scr.print(length, scr.errorc);
    const number_of_pages = numberToStringDec(pages.number_of_pages, &buffer);
    scr.print("\nnumber of pages: ", scr.text);
    scr.print(number_of_pages, scr.errorc);
    const page_size = numberToStringDec(pages.page_size, &buffer);
    scr.print("\npage size: ", scr.text);
    scr.print(page_size, scr.errorc);
    const free_pages = numberToStringDec(pages.getFreePages(&pages.pageTable), &buffer);
    scr.print("\nnumber of free pages: ", scr.text);
    scr.print(free_pages, scr.errorc);
    const free_mem = numberToStringDec(pages.getFreePages(&pages.pageTable) * pages.page_size / 1_000_000, &buffer);
    scr.print("\nfree memory: ", scr.text);
    scr.print(free_mem, scr.errorc);
    scr.newLine();
}

pub fn arrayStartsWith(arr: []const u8, str: []const u8) bool {
    if (arr.len < str.len) return false;
    return std.mem.eql(u8, arr[0..str.len], str);
}

pub fn printArrayDB(arr: []const u8) void {
    for (arr) |i| {
        if (i != 0) {
            printChar(i);
        }
    }
}

pub fn printArray(arr: []const u8, color: u32) void {
    for (arr) |i| {
        if (i != 0) {
            scr.printChar(i, color);
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
