const std = @import("std");
const scr = @import("screen.zig");
const stream = @import("stream.zig");
const kb = @import("keyboard.zig");

const cpu = @import("../cpu/cpu.zig");
const debug = @import("../cpu/debug.zig");

const utils = @import("../apps/utils.zig");
const fractal = @import("../apps/fractal.zig");
const cacfetch = @import("../apps/cacfetch.zig");
const snake = @import("../apps/snake.zig");

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

pub fn execute_command() void {
    const hash = debug.hashStr(debug.firstWordOfArray(&stream.stdin));
    const parameter: u64 = debug.numberInArray(&stream.stdin);
    switch (hash) {
        debug.hashStr("info") => utils.info(),
        debug.hashStr("meminfo") => utils.printMem(),
        debug.hashStr("testmem") => utils.testMemStart(parameter),
        debug.hashStr("fractal") => fractal.start(parameter),
        debug.hashStr("clear") => scr.clear(),
        debug.hashStr("motd") => scr.printMOTD(),
        debug.hashStr("cacfetch") => cacfetch.run(),
        debug.hashStr("test") => print("Working fine"),
        debug.hashStr("logo") => scr.printLogo(),
        debug.hashStr("echo") => utils.echo(),
        debug.hashStr("help") => utils.help(),
        debug.hashStr("snake") => snake.start(),
        debug.hashStr("stop") => {
            debug.print("Stopping");
            print("Stopping");
            cpu.stop();
        },
        else => printErr("Unknown Command"),
    }
}

pub fn init() void {
    kb.init();
    stream.newLine();
}
