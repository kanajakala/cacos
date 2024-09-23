const std = @import("std");
const cpu = @import("cpu.zig");
const mem = @import("../memory/memory.zig");
const pages = @import("../memory/pages.zig");
const scr = @import("../drivers/screen.zig");
const console = @import("../drivers/console.zig");
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

pub fn hashStr(str: []const u8) u32 {
    var hash: u32 = 2166136261;
    for (str) |c| {
        hash = (hash ^ c) *% 16777619;
    }
    return hash;
}

pub fn hashNumber(n: usize) u32 {
    var hash: u32 = 2166136261;
    for (0..n) |i| {
        hash = @truncate((hash ^ i) *% 16723 * n);
    }
    return hash;
}

//non persistent buffer
pub fn ntsHexFast(n: u64) []const u8 {
    var buffer: [100]u8 = undefined;
    return std.fmt.bufPrint(&buffer, "{X}", .{n}) catch buffer[0..0];
}
pub fn ntsDecFast(n: u64) []const u8 {
    var buffer: [100]u8 = undefined;
    return std.fmt.bufPrint(&buffer, "{d}", .{n}) catch buffer[0..0];
}

//persistent buffer
pub fn numberToStringHex(n: u64, buffer: []u8) []const u8 {
    return std.fmt.bufPrint(buffer, "{X}", .{n}) catch buffer[0..0];
}
pub fn numberToStringDec(n: u64, buffer: []u8) []const u8 {
    return std.fmt.bufPrint(buffer, "{d}", .{n}) catch buffer[0..0];
}

pub fn stringToNumber(str: []const u8) u64 {
    var tot: u64 = 0;
    for (0..str.len) |i| {
        if (str[str.len - i - 1] < '0' or str[i] > '9') return 1;
        tot += (str[str.len - i - 1] - '0') * std.math.pow(u64, 10, i);
    }
    return tot;
}

pub fn arrayStartsWith(arr: []u8, str: []const u8) bool {
    if (arr.len < str.len) return false;
    return std.mem.eql(u8, arr[0..str.len], str);
}

pub fn sum(arr: []u8) usize {
    var out: usize = 0;
    for (arr) |i| {
        out += i;
    }
    return out;
}

pub fn printArray(arr: []u8) void {
    print(".{ ");
    for (arr) |i| {
        if (i != 0) {
            printChar(' ');
            printChar(i);
            printChar(',');
        }
    }
    printChar('}');
}

pub fn printMem(arr: []u8) void {
    print("< ");
    var buffer: [2]u8 = undefined;
    for (arr) |i| {
        printChar(' ');
        print(numberToStringHex(i, &buffer));
        printChar(',');
    }
    print(" >\n");
}

pub fn shiftMem(page: pages.Page, direction: usize, comptime clip: usize) void {
    var temp: [clip]u8 = undefined;
    @memcpy(&temp, mem.memory_region[page.start .. page.start + clip]);
    for (temp, page.start..page.start + clip) |word, i| {
        mem.memory_region[i + direction] = word;
    }
}

const arrayErrors = error{
    elementNotInArray,
};

pub fn elementInArray(comptime T: type, element: T, arr: []T, skip: usize) !usize {
    var i: usize = 0;
    while (i < arr.len / skip - skip) : (i += skip) {
        if (arr[i] == element) {
            return i;
        }
    } else return arrayErrors.elementNotInArray;
}

pub fn charToInt(char: u8) u8 {
    if (char >= 30) {
        return char - '0';
    }
    return 0;
}

pub fn firstWordOfArray(arr: []u8) []const u8 {
    for (arr, 0..arr.len) |element, i| {
        if (element == ' ' or element == 0) {
            return arr[0..i];
        }
    }
    return "No first word";
}

//Find the first number in an array,
//the number must be delimited by spaces
pub fn numberInArray(arr: []u8) u64 {
    var index1: usize = 0;
    var index2: usize = 0;
    for (0..arr.len - 2) |i| {
        //if the current char is a space and the next one is a digit
        if (arr[i] == ' ' and arr[i + 1] >= '0' and arr[i + 1] <= '9') {
            index1 = i + 1;
            printChar(arr[i + 1]);
        }
        //if the current char is a digit and the next one is a space we know the
        //number has ended
        if ((arr[i + 1] == ' ' or arr[i + 1] == 0) and arr[i] >= '0' and arr[i] <= '9') {
            index2 = i + 1;
            return stringToNumber(arr[index1..index2]);
        }
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
