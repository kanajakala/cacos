const screen = @import("screen.zig");
const debug = @import("debug.zig");
const std = @import("std");
const stream = @import("stream.zig");

const fractal = @import("apps/fractal.zig");

const out_color = screen.text;

fn info() void {
    screen.print("\nCaCOS developped by kanjakala", out_color);
}

pub fn execute_command() void {
    if (debug.arrayStartsWith(&stream.stdin, "info")) {
        info();
    } else if (debug.arrayStartsWith(&stream.stdin, "memory")) {
        debug.printMem();
    } else if (debug.arrayStartsWith(&stream.stdin, "test memory")) {
        debug.testMem(@truncate(stream.stdin[12]));
    } else if (debug.arrayStartsWith(&stream.stdin, "fractal")) {
        fractal.draw(@truncate(stream.stdin[8] - '0'));
    } else if (debug.arrayStartsWith(&stream.stdin, "clear")) {
        screen.clear();
    } else {
        screen.print("\nNot a valid command", out_color);
    }
}
