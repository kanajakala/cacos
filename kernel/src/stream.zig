const kb = @import("keyboard.zig");
const screen = @import("screen.zig");
const debug = @import("debug.zig");
const std = @import("std");
const console = @import("console.zig");

pub const stream_size = 10_000;
pub export var stdin: [stream_size]u8 = .{0} ** stream_size;
pub export var index: usize = undefined;

fn handleLineFeed() void {
    index = 0;
    console.execute_command();
    stdin = .{0} ** stream_size;
    screen.newLine();
    screen.print("> ", screen.primary);
}
fn handleBackSpace() void {
    stdin[index] = 0;
    if (index > 0) {
        index -= 1;
    }
    screen.printChar(0x8, screen.text);
}
pub fn init(in: *[stream_size]u8) noreturn {
    var value: u8 = undefined;
    var old_value: u8 = undefined;
    index = 0;
    while (true) {
        value = kb.listener();
        if (value != old_value and value != 0) {
            if (index >= stream_size) index = 0;
            switch (value) {
                0xa => handleLineFeed(),
                0x8 => handleBackSpace(),
                else => {
                    in[index] = value;
                    index += 1;
                    screen.printChar(value, screen.text);
                },
            }
            screen.drawCursor();
        }
        old_value = value;
    }
}

//Better version but much slower

//pub fn init(in: *[stream_size]u8) noreturn {
//    var state: kb.KeyEvent.State = .released;
//    index = 0;
//    while (true) {
//        const event = kb.map(kb.getScanCode());
//        if (event.state == .pressed and state == .released) {
//            const value: u8 = kb.keyEventToChar(event);
//            if (index >= stream_size) index = 0;
//            switch (value) {
//                0xa => handleLineFeed(),
//                0x8 => handleBackSpace(),
//                else => {
//                    in[index] = value;
//                    index += 1;
//                    screen.printChar(value, screen.text);
//                },
//            }
//            screen.drawCursor();
//        }
//        state = event.state;
//    }
//}
