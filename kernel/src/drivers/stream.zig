const std = @import("std");
const kb = @import("keyboard.zig");
const scr = @import("screen.zig");
const console = @import("console.zig");
const db = @import("../core/debug.zig");
const scheduler = @import("../core/scheduler.zig");
const cpu = @import("../core/cpu.zig");

pub const stream_size = 8000;
pub var stdin: [stream_size]u8 = .{0} ** stream_size;
pub var stdout: [stream_size]u8 = .{0} ** stream_size;
pub var stderr: [stream_size]u8 = .{0} ** stream_size;
pub var index: usize = 0;
pub var current_key: kb.KeyEvent = undefined;
pub var current_modifier: kb.KeyEvent.Code = undefined;

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
    current_key = kb.empty_key;
}

fn handleLineFeed() void {

    //we need to delete the cursor on the old line before jumping to the new one
    scr.clearChar();

    //if array is empty we do nothing
    if (db.sum(&stdin) == 0) {
        return;
    }
    //else we execute the command
    _ = console.execute_command();
    //print new line and flush the streams when done handling
    newLine();
    flush();
}

fn handleBackSpace() void {
    stdin[index] = 0;
    if (index > 0) {
        index -= 1;
    }
    scr.printChar(0x8, scr.text);
}

pub fn append(value: u8) void {
    if (index >= stream_size) index = 0;
    stdin[index] = value;
    index += 1;
}

pub fn handleKey(key: kb.KeyEvent) void {
    const value = kb.keyEventToChar(key.code);
    const codes = kb.KeyEvent.Code;
    if (key.state == kb.KeyEvent.State.pressed and value != 0) {
        //overflow check
        if (index >= stream_size) index = 0;

        current_key = key;

        //Shortcut handling
        if (kb.control) {
            switch (key.code) {
                codes.key_l => scr.clear(),
                codes.key_c => {
                    scheduler.stopAll();
                    captured = false;
                    flush();
                },
                else => {
                    current_modifier = key.code;
                    //this lines is used to debug which key is pressed
                    //db.printChar(kb.keyEventToChar(key.code));
                },
            }
        } else {
            //regular key handling
            current_modifier = codes.unknown;
            switch (key.code) {
                codes.enter => if (!captured) handleLineFeed(),
                codes.backspace => if (!captured) handleBackSpace(),
                else => {
                    append(value);
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
