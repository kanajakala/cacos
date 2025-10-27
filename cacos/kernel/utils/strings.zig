const std = @import("std");
const db = @import("../utils/debug.zig");

const errors = error{
    stringCharNotFound,
};

///returns the index at which the element can be found starting from the left
pub fn find_right(char: u8, string: []const u8) !usize {
    var index: usize = 0;
    for (0..string.len) |i| {
        if (string[i] == char) {
            return index;
        }
        index += 1;
    }
    return errors.stringCharNotFound;
}

///returns the index at which the element can be found starting from the right
pub fn find_left(char: u8, string: []const u8) !usize {
    var index: usize = string.len;
    for (0..string.len) |i| {
        if (string[string.len - i] == char) {
            return index;
        }
        index -= 1;
    }
    return errors.stringCharNotFound;
}
pub const Directions = enum {
    left,
    right,
};

///returns the piece of the string in a direction until we hit the cut_char starting from the right inclusive
pub fn take_left(cut_char: u8, string: []const u8) []const u8 {
    const index: usize = find_left(cut_char, string) catch string.len;
    return string[index..string.len];
}

///returns the piece of the string in a direction until we hit the cut_char inclusive
pub fn take_right(cut_char: u8, string: []const u8) []const u8 {
    const index: usize = find_right(cut_char, string) catch 0;
    return string[0..index];
}


///remove a piece of the string until we hit cut_char
pub fn cut_right(cut_char: u8, string: []const u8) []const u8 {
    const index: usize = find_right(cut_char, string) catch 0;
    return string[index..string.len];
}

///remove a piece of the string until we hit cut_char
pub fn cut_left(cut_char: u8, string: []const u8) []const u8 {
    const index: usize = find_left(cut_char, string) catch string.len;
    return string[0..index];
}

///counts aa characters occurences in a string
pub fn count(char: u8, string: []const u8) usize {
    var counter: usize = 0;
    for (string) |test_char| {
        if (test_char == char) counter += 1;
    }
    return counter;
}

///strip a string from a character on the left and right
pub fn strip(char: u8, string: []const u8) []const u8 {
    //handle special cases
    if (isEmpty(string)) return string;

    var start: usize = 0;
    var end: usize = string.len - 1;
    //we start by the left side
    while (string[start] == char and start < string.len) : (start += 1) {db.print("\n   STRING: stripping start");}
    while (string[end] == char and end > 0) : (end -= 1) {db.print("\n   STRING: stripping end");}
    return string[start..end + 1];
}

///returns wether two strings are equal
pub fn equal(string1: []const u8, string2: []const u8) bool {
    return std.mem.eql(u8, string1, string2);
}

pub fn isEmpty(string: []const u8) bool {
    return equal(string, "");
}
