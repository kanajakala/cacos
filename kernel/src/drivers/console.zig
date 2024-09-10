const std = @import("std");
const scr = @import("screen.zig");
const stream = @import("stream.zig");

const cpu = @import("../cpu/cpu.zig");
const debug = @import("../cpu/debug.zig");

const fractal = @import("../apps/fractal.zig");
const cacfetch = @import("../apps/cacfetch.zig");

const out_color = scr.text;

fn info() void {
    scr.print("\nCaCOS developped by kanjakala", out_color);
}

fn echo(in: *[stream.stream_size]u8, out: *[stream.stream_size]u8) void {
    const offset = "echo ".len;
    //Copy stdin to stdout
    for (offset..stream.stream_size) |i| {
        out[i] = in[i];
    }
    //print array
    scr.newLine();
    debug.printArray(out[offset..], scr.primary);
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
    } else if (debug.arrayStartsWith(&stream.stdin, "stop")) {
        debug.print("Stopping");
        scr.print("Stopping", scr.primary);
        cpu.stop();
    } else if (debug.arrayStartsWith(&stream.stdin, "echo")) {
        echo(&stream.stdin, &stream.stdout);
    } else {
        scr.print("\nNot a valid command", out_color);
    }
}
