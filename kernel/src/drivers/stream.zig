const std = @import("std");
const kb = @import("keyboard.zig");
const scr = @import("screen.zig");
const console = @import("console.zig");
const debug = @import("../cpu/debug.zig");
const scheduler = @import("../cpu/scheduler.zig");
const cpu = @import("../cpu/cpu.zig");

pub const stream_size = 10_000;
pub export var stdin: [stream_size]u8 = .{0} ** stream_size;
pub export var stdout: [stream_size]u8 = .{0} ** stream_size;
pub export var stderr: [stream_size]u8 = .{0} ** stream_size;
pub var index: usize = 0;

pub const prefix: []const u8 = " > ";
pub var captured: bool = false;

pub fn newLine() void {
    scr.newLine();
    scr.print(prefix, scr.primary);
}

pub fn flush() void {
    index = 0;
    stdin = .{0} ** stream_size;
    stdout = .{0} ** stream_size;
}

fn handleLineFeed() void {

    //print new line and flush the streams when done handling
    defer newLine();
    defer flush();

    //we need to delete the cursor on the old line before jumping to the new one
    scr.clearChar();

    //if array is empty we do nothing
    if (debug.sum(&stdin) == 0) {
        return;
    }
    //else we execute the command
    _ = console.execute_command();
}

fn handleBackSpace() void {
    stdin[index] = 0;
    if (index > 0) {
        index -= 1;
    }
    scr.printChar(0x8, scr.text);
}

pub fn handleKey(key: kb.KeyEvent) void {
    const value = kb.keyEventToChar(key.code);
    const codes = kb.KeyEvent.Code;
    if (key.state == kb.KeyEvent.State.pressed and value != 0) {
        //overflow check
        if (index >= stream_size) index = 0;

        //Shortcut handling
        if (kb.control) {
            switch (key.code) {
                codes.key_l => scr.clear(),
                codes.key_c => {
                    scheduler.stopAll();
                    captured = false;
                },
                else => return,
            }
        } else {
            //regular key handling
            switch (key.code) {
                codes.enter => handleLineFeed(),
                codes.backspace => handleBackSpace(),
                else => {
                    stdin[index] = value;
                    index += 1;
                    if (!captured) {
                        scr.clearChar();
                        scr.printChar(value, scr.text);
                    }
                },
            }
        }
        if (!captured) scr.drawCursor();
    }
}
