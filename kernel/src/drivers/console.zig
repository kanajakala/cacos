const std = @import("std");
const scr = @import("screen.zig");
const stream = @import("stream.zig");

const debug = @import("../cpu/debug.zig");
const fractal = @import("../apps/fractal.zig");
const cacfetch = @import("../apps/cacfetch.zig");

const out_color = scr.text;

fn info() void {
    scr.print("\nCaCOS developped by kanjakala", out_color);
}

pub fn execute_command() void {
    if (debug.arrayStartsWith(&stream.stdin, "info")) {
        info();
    } else if (debug.arrayStartsWith(&stream.stdin, "memory")) {
        debug.printMem();
    } else if (debug.arrayStartsWith(&stream.stdin, "test memory")) {
        debug.testMem(debug.charToInt(stream.stdin[12]));
    } else if (debug.arrayStartsWith(&stream.stdin, "fractal")) {
        fractal.draw(debug.charToInt(stream.stdin[8]));
    } else if (debug.arrayStartsWith(&stream.stdin, "clear")) {
        scr.clear();
    } else if (debug.arrayStartsWith(&stream.stdin, "motd")) {
        scr.printMOTD();
    } else if (debug.arrayStartsWith(&stream.stdin, "cacfetch")) {
        cacfetch.run();
    } else {
        scr.print("\nNot a valid command", out_color);
    }
}
