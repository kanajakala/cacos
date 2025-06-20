const dsp = @import("../core/display.zig");
const kb = @import("../drivers/keyboard.zig");
const font = @import("../interface/font.zig");
const fs = @import("../core/ramfs.zig");
const mem = @import("../core/memory.zig");
const elf = @import("../core/elf.zig");
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
const ratio = 1; // must be a wole number, sets the separation
const border = 20; //the size of the border on the outside of the screen

//colors
const text_color: u32 = 0xffffff;
const background: u32 = 0x280800;

var stream: fs.Node = undefined;

const Cursor = struct {
    x: u64,
    y: u64,
    enabled: u1 = 1,

    pub fn next(self: *Cursor) !void {
        if (self.x + font.w >= dsp.w / ratio - border) {
            try newLine();
        }
        self.x += font.w;
    }

    pub fn previous(self: *Cursor) !void {
        if (self.x - font.w <= border) {
            if (self.y - font.h <= border) return;
            self.y -= font.h;
            self.x = dsp.w / ratio + border;
            return;
        }
        self.x -= font.w;
    }

    pub fn draw(self: Cursor) !void {
        if (self.enabled == 1) try dsp.rect(self.x, self.y, font.w, font.h, 0xff00ff);
    }

    pub fn remove(self: *Cursor) !void {
        try erase(self.x, self.y);
    }
};

var cursor: Cursor = Cursor{ .x = border, .y = border };

pub fn erase(x: usize, y: usize) !void {
    try dsp.rect(x, y, font.w, font.h, background);
}

pub fn scroll() !void {
    try dsp.copyChunk(dsp.w * font.h, dsp.w * dsp.h - (2 * dsp.w * font.h), 0);
    cursor.x = border;
    dsp.rect(border, dsp.h - font.h - border, dsp.w - 2 * border, font.h, background) catch {};
}

pub fn newLine() !void {
    if (cursor.y + font.h + border >= dsp.h - border) {
        return scroll();
    }
    cursor.y += font.h;
    cursor.x = border;
    //try cursor.draw();
}

pub fn printChar(char: u8) !void {
    try handle_char(char);
    try stream.append(char);
}

pub fn print(string: []const u8) !void {
    for (string) |char| try printChar(char);
}

pub fn handle_char(char: u8) !void {
    switch (char) {
        0 => {
            try font.drawChar('?', cursor.x, cursor.y, text_color);
            try cursor.next();
        },
        '\n' => try newLine(),
        else => {
            try font.drawChar(char, cursor.x, cursor.y, text_color);
            try cursor.next();
        },
    }
}

pub fn handle(key: kb.KeyEvent) !void {
    //remove the cursor
    try cursor.remove();
    //handle logic
    if (key.state == kb.KeyEvent.State.pressed) {
        try switch (key.code) {
            kb.KeyEvent.Code.enter => {
                try newLine();
                try stream.data.clear();
                try stream.update();
            },
            else => printChar(key.char),
        };
    }
    //update cursors position
    try cursor.draw();
}

pub fn init() !void {
    //inittialise required components
    try dsp.init();
    font.init();
    kb.init();
    stream = try fs.Node.create("stream", fs.Ftype.text, 0);

    //draw background rectangle
    try dsp.fill(background);

    //load the test elf file
    const motd = try fs.idFromName("motd.elf");
    try elf.load(motd);
}
