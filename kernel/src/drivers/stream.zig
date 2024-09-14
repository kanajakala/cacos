const std = @import("std");
const kb = @import("keyboard.zig");
const scr = @import("screen.zig");
const console = @import("console.zig");
const debug = @import("../cpu/debug.zig");

pub const stream_size = 10_000;
pub export var stdin: [stream_size]u8 = .{0} ** stream_size;
pub export var stdout: [stream_size]u8 = .{0} ** stream_size;
pub export var stderr: [stream_size]u8 = .{0} ** stream_size;
pub var index: usize = 0;

pub const prefix: []const u8 = " > ";

pub fn newLine() void {
    scr.newLine();
    scr.print(prefix, scr.primary);
}

fn flush() void {
    stdin = .{0} ** stream_size;
    stdout = .{0} ** stream_size;
}

fn handleLineFeed() void {
    //print new line and flush the streams when done handling
    defer newLine();
    defer flush();

    //we need to delete the cursor on the old line before jumping to the new one
    scr.handleBackspace();

    index = 0;

    //if array is empty we do nothing
    if (debug.sum(&stdin) == 0) {
        return;
    }
    //else we execute the command
    console.execute_command();
}

fn handleBackSpace() void {
    stdin[index] = 0;
    if (index > 0) {
        index -= 1;
    }
    scr.printChar(0x8, scr.text);
}

pub fn handleKey(key: kb.KeyEvent) void {
    const value = kb.keyEventToChar(key);
    if (key.state == kb.KeyEvent.State.pressed and value != 0) {
        if (index >= stream_size) index = 0;
        switch (value) {
            0xa => handleLineFeed(),
            0x8 => handleBackSpace(),
            else => {
                stdin[index] = value;
                index += 1;
                scr.printChar(value, scr.text);
            },
        }
        scr.drawCursor();
    }
}
