const std = @import("std");

const errors = error{
    stringCharNotFound,
};

///returns the index at which the element can be found
pub fn find(char: u8, string: []const u8) !usize {
    var index: usize = 0;
    for (0..string.len) |i| {
        if (string[i] == char) {
            return index;
        }
        index += 1;
    }
    return errors.stringCharNotFound;
}

pub const Directions = enum {
    left,
    right,
};

///returns the piece of the string in a direction until we hit the cut_char
pub fn take(cut_char: u8, string: []const u8, direction: Directions) []const u8 {
    switch (direction) {
        Directions.left => {
            const index: usize = find(cut_char, string) catch string.len;
            return string[0..index];
        },
        Directions.right => {
            const index: usize = find(cut_char, string) catch 0;
            //handle special cases
            if (index + 1 == string.len) return "";
            if (index == 0) return string;
            return string[index + 1 .. string.len];
        },
    }
}

///remove a piece of the string until we hit cut_char
pub fn cut(cut_char: u8, string: []const u8, direction: Directions) []const u8 {
    switch (direction) {
        Directions.left => {
            const index: usize = find(cut_char, string) catch string.len;
            return string[index..string.len];
        },
        Directions.right => {
            const index: usize = find(cut_char, string) catch 0;
            return string[0..index];
        },
    }
}

///returns wether two strings are equal
pub fn equal(string1: []const u8, string2: []const u8) bool {
    return std.mem.eql(u8, string1, string2);
}

pub fn isEmpty(string: []const u8) bool {
    return equal(string, "");
}
