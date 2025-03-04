const std = @import("std");
const scr = @import("screen.zig");
const stream = @import("stream.zig");
const kb = @import("keyboard.zig");

const cpu = @import("../core/cpu.zig");
const db = @import("../core/debug.zig");
const fs = @import("../core/fs.zig");

const utils = @import("../apps/utils.zig");
const fractal = @import("../apps/fractal.zig");
const cacfetch = @import("../apps/cacfetch.zig");
const snake = @import("../apps/snake.zig");
const editor = @import("../apps/editor.zig");
const dancing_man = @import("../apps/dancing_man.zig");

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
pub fn printColor(str: []const u8, color: u24) void {
    scr.newLine();
    for (str, 0..str.len) |char, i| {
        if (char != 0) {
            stream.stdout[i] = char;
            scr.printChar(char, color);
        }
    }
}
pub fn printColorf(str: []const u8, color: u24) void {
    for (str, 0..str.len) |char, i| {
        if (char != 0) {
            stream.stdout[i] = char;
            scr.printChar(char, color);
        }
    }
}
pub fn printf(str: []const u8) void {
    for (str, 0..str.len) |char, i| {
        if (char != 0) {
            stream.stdout[i] = char;
            scr.printChar(char, out_color);
        }
    }
}
pub fn printInfo(str: []const u8) void {
    scr.newLine();
    for (str, 0..str.len) |char, i| {
        if (char != 0) {
            stream.stdout[i] = char;
            scr.printChar(char, scr.primary);
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
    const hash = db.hashStr(db.firstWordOfArray(&stream.stdin));
    const parameter: u64 = db.numberInArray(&stream.stdin);
    switch (hash) {
        db.hashStr("info") => utils.info(),
        db.hashStr("meminfo") => utils.printMem(),
        db.hashStr("testmem") => utils.testMemStart(parameter),
        db.hashStr("fractal") => fractal.start(parameter),
        db.hashStr("clear") => scr.clear(),
        db.hashStr("motd") => scr.printMOTD(),
        db.hashStr("cacfetch") => cacfetch.run(),
        db.hashStr("test") => print("Working fine"),
        db.hashStr("logo") => scr.printLogo(),
        db.hashStr("echo") => utils.echo(),
        db.hashStr("help") => utils.help(),
        db.hashStr("snake") => snake.start(),
        db.hashStr("ls") => utils.ls(),
        db.hashStr("touch") => utils.touch(),
        db.hashStr("mkdir") => utils.mkdir(),
        db.hashStr("cd") => utils.cd(),
        db.hashStr("mv") => utils.mv(),
        db.hashStr("cp") => utils.cp(),
        db.hashStr("rm") => utils.rm(),
        db.hashStr("pwd") => utils.pwd(),
        db.hashStr("tree") => utils.tree(fs.current_dir),
        db.hashStr("write") => utils.write(),
        db.hashStr("read") => utils.read(),
        db.hashStr("readhex") => utils.readhex(),
        db.hashStr("append") => utils.append(),
        db.hashStr("stat") => utils.stat(),
        db.hashStr("editor") => editor.start(),
        db.hashStr("display") => utils.display(),
        db.hashStr("dance") => dancing_man.start(),
        db.hashStr("run") => utils.run(),
        db.hashStr("stop") => {
            db.print("Stopping");
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
