const std = @import("std");
const scr = @import("screen.zig");
const stream = @import("stream.zig");
const kb = @import("keyboard.zig");

const cpu = @import("../cpu/cpu.zig");
const debug = @import("../cpu/debug.zig");

const utils = @import("../apps/utils.zig");
const fractal = @import("../apps/fractal.zig");
const cacfetch = @import("../apps/cacfetch.zig");

const out_color = scr.text;

pub fn print(str: []const u8) void {
    scr.newLine();
    for (str, 0..str.len) |char, i| {
        if (char != 0) {
            stream.stdout[i] = char;
            scr.printChar(char, out_color);
        }
    }
}
pub fn printErr(str: []const u8) void {
    scr.newLine();
    for (str, 0..str.len) |char, i| {
        if (char != 0) {
            stream.stderr[i] = char;
            scr.printChar(char, scr.errorc);
        }
    }
}
fn hashStr(str: []const u8) u32 {
    var hash: u32 = 2166136261;
    for (str) |c| {
        hash = (hash ^ c) *% 16777619;
    }
    return hash;
}

pub fn execute_command() void {
    const hash = hashStr(debug.firstWordOfArray(&stream.stdin));
    const parameter: u64 = debug.numberInArray(&stream.stdin);
    switch (hash) {
        hashStr("info") => utils.info(),
        hashStr("meminfo") => utils.printMem(),
        hashStr("testmem") => utils.testMem(parameter),
        hashStr("fractal") => fractal.draw(parameter),
        hashStr("clear") => scr.clear(),
        hashStr("motd") => scr.printMOTD(),
        hashStr("cacfetch") => cacfetch.run(),
        hashStr("stop") => {
            debug.print("Stopping");
            print("Stopping");
            cpu.stop();
        },
        hashStr("echo") => utils.echo(),
        else => printErr("Unknown Command"),
    }
}

pub fn init() void {
    kb.init();
    stream.newLine();
}
