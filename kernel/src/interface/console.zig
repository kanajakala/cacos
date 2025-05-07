const dsp = @import("../core/display.zig");
const kb = @import("../drivers/keyboard.zig");
const font = @import("../core/font.zig");

//the console is split into two parts:
//-> one for the commands
//-> one for the outputs
// ╭console─────────────────────────────────────╮
// │                 │                          │
// │ > command       │ > Output of command 0!   │
// │ > command2      │ > ERROR: no argument     │
// │                 │                          │
// │                 │                          │
// │                 │                          │
// │                 │                          │
// │                 │                          │
// │                 │                          │
// │                 │                          │
// │                 │                          │
// ╰────────────────────────────────────────────╯

//appearance variables
const ratio = 3; // must be a wole number, sets the separation
const border_out = 20; //the size of the border on the outside of the screen

//colors
const text_color: u32 = 0xffffff;
const background: u32 = 0x280800;

const Coords = struct {
    x: u64,
    y: u64,
};

var cursor: Coords = Coords{ .x = border_out, .y = border_out };

pub fn handle(key: kb.KeyEvent) void {
    if (key.state == kb.KeyEvent.State.pressed and key.char != 0) {
        font.drawChar(key.char, cursor.x, cursor.y, 0xffffff) catch {
            return;
        };
        cursor.x += font.w;
        if (cursor.x >= dsp.w / ratio - border_out) {
            cursor.y += font.h;
            cursor.x = border_out;
        }
    }
}

pub fn init() !void {
    kb.init();
    try dsp.init();
    try font.init();

    //draw background rectangle
    try dsp.rect(0, 0, dsp.w, dsp.h, 0x280800);
}
