const dsp = @import("../core/display.zig");
const kb = @import("../drivers/keyboard.zig");
const font = @import("../interface/font.zig");
const fs = @import("../core/ramfs.zig");
const mem = @import("../core/memory.zig");
const elf = @import("../core/elf.zig");
const db = @import("../utils/debug.zig");
const strings = @import("../utils/strings.zig");

//appearance variables
const ratio = 1; // must be a wole number, sets the separation
const border = 20; //the size of the border on the outside of the screen

//colors
pub const text_color: u32 = 0xffeeff;
pub const background: u32 = 0x280800;

var cac_in: fs.Node = undefined;
var cac_err: fs.Node = undefined;
var cac_keys: fs.Node = undefined;

const Cursor = packed struct {
    x: u64,
    y: u64,
    color: u32 = 0xff00ff,
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
        if (self.enabled == 1) try dsp.rect(self.x, self.y, font.w, font.h, self.color);
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

pub fn printChar(char: u8, color: u32) !void {
    try handle_char(char, color);
    try cac_in.append(char);
}

pub fn print(string: []const u8) !void {
    try cac_in.appendSlice(@constCast(string));
    for (string) |char| try printChar(char, text_color);
}

pub fn printColor(string: []const u8,color: u32) !void {
    try cac_in.appendSlice(@constCast(string));
    for (string) |char| try printChar(char, color);
}

pub fn printErr(string: []const u8) !void {
    try cac_err.appendSlice(@constCast(string));
    for (string) |char| try printChar(char, 0xff0000);
}

pub fn handle_char(char: u8, color: u32) !void {
    switch (char) {
        0 => {
            try font.drawChar('?', cursor.x, cursor.y, color);
            try cursor.next();
        },
        '\n' => try newLine(),
        else => {
            try font.drawChar(char, cursor.x, cursor.y, color);
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
                if (cac_in.data.size > 0) try exec(); //execute the command which was typed if there was something typed
                            try prompt();

                //clear the different data streams
                try cac_in.data.clear();
                try cac_err.data.clear();
                try cac_keys.data.clear();

                try cac_in.update();
                try cac_err.update();
                try cac_keys.update();
            },
            else => printChar(key.char, text_color),
        };
    }
    //update cursors position
    try cursor.draw();
}

pub fn prompt() !void {
    try newLine();
    try printColor(" CaCOS", 0x00ff00);
    try printColor("> ", 0x00ffff);
}

pub fn exec() !void {
    //get the name of the process to execute
    const command: []const u8 = try cac_in.data.readSlice(0, cac_in.data.size);
    const name = strings.take(' ', command, strings.Directions.left);
    db.print("\nname of the command: ");
    db.print(name);
    db.print("\ncontent of cac-in: ");
    db.print(command);
    const executable = fs.idFromName(name) catch {
        try printErr("no such file!");
        return;
    };
    elf.load(executable) catch {
        try printErr("the file is not executable");
        return;
    };
}

pub fn init() !void {
    //inittialise required components
    try dsp.init();
    font.init();
    kb.init();

    cac_in = try fs.Node.create("cac_in", fs.Ftype.text, 0);
    cac_err = try fs.Node.create("cac_err", fs.Ftype.text, 0);
    cac_keys = try fs.Node.create("cac_keys", fs.Ftype.text, 0);

    //draw background rectangle
    try dsp.fill(background);

    //load the test elf file
    const motd = try fs.idFromName("motd.elf");
    try elf.load(motd);
    try cac_in.data.clear(); //we need to clear the polluted cac_in
}
