const dsp = @import("../core/display.zig");
const kb = @import("../drivers/keyboard.zig");
const font = @import("../interface/font.zig");
const fs = @import("../core/ramfs.zig");
const mem = @import("../core/memory.zig");
const db = @import("../utils/debug.zig");

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
const border = 20; //the size of the border on the outside of the screen

//colors
const text_color: u32 = 0xffffff;
const background: u32 = 0x280800;

const Coords = struct {
    x: u64,
    y: u64,
};

var cursor: Coords = Coords{ .x = border, .y = border };

pub fn scroll() !void {
    try dsp.copyChunk(dsp.w * font.h, dsp.w * dsp.h - (2 * dsp.w * font.h), 0);
    //db.print("\nbut this works???");
    cursor.x = border;
    dsp.rect(border, dsp.h - font.h - border, dsp.w - 2 * border, font.h, background) catch {};
}

pub fn newLine() !void {
    if (cursor.y + font.h + border >= dsp.h - border) {
        return scroll();
    }
    cursor.y += font.h;
    cursor.x = border;
}

fn handleSpecial(key: kb.KeyEvent) !void {
    try switch (key.code) {
        kb.KeyEvent.Code.enter => newLine(),
        else => {},
    };
}

pub fn print(char: u8) !void {
    try font.drawChar(char, cursor.x, cursor.y, text_color);
    cursor.x += font.w;
    if (cursor.x >= dsp.w / ratio - border) {
        try newLine();
    }
}

pub fn handle(key: kb.KeyEvent) !void {
    if (key.state == kb.KeyEvent.State.pressed) {
        if (key.char == 0) {
            try handleSpecial(key);
        }
        try print(key.char);
    }
}

pub fn init() !void {
    db.print("\nstatring console");
    try dsp.init();
    db.print("\nstatring console");
    font.init();
    db.print("\nstatring console");
    kb.init();
    db.print("\nstatred keyboard");

    //draw background rectangle
    try dsp.fill(background);
    db.print("\ndone filling screen");
    //print the motd
    db.printErr("\ndebugging Node inside console");
    const root = try fs.open(0);
    //const data = "The data will be different ?";
    //try root.data.appendSlice(@constCast(data[0..]));
    //db.printErr("\nDebugging root at console time");
    db.debugNode(root);
    // for (0..motd.data.size) |i| {
    //     try print(try motd.data.read(i));
    //     db.printChar(try motd.data.read(i));
    // }
    //  db.print("done printing motd, in theory");
}
