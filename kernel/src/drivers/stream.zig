const std = @import("std");
const kb = @import("keyboard.zig");
const scr = @import("screen.zig");
const console = @import("console.zig");
const debug = @import("../cpu/debug.zig");

pub const stream_size = 10_000;
pub export var stdin: [stream_size]u8 = .{0} ** stream_size;
pub export var stdout: [stream_size]u8 = .{0} ** stream_size;
pub export var stderr: [stream_size]u8 = .{0} ** stream_size;
pub export var index: usize = undefined;

fn handleLineFeed() void {
    index = 0;
    console.execute_command();
    stdin = .{0} ** stream_size;
    stdout = .{0} ** stream_size;
    scr.newLine();
    scr.print("> ", scr.primary);
}

fn handleBackSpace() void {
    stdin[index] = 0;
    if (index > 0) {
        index -= 1;
    }
    scr.printChar(0x8, scr.text);
}

pub fn init() noreturn {
    var value: u8 = undefined;
    var old_value: u8 = undefined;
    index = 0;
    scr.newLine();
    scr.print("> ", scr.primary);
    while (true) {
        value = kb.listener();
        if (value != old_value and value != 0) {
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
        old_value = value;
    }
}
