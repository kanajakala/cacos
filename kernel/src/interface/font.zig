const BOOTBOOT = @import("../bootboot.zig").BOOTBOOT;
const dsp = @import("../core/display.zig");

const fontData = @embedFile("../assets/font.psf");

const PsfFont = packed struct {
    magic: u32, // magic bytes to identify PSF
    version: u32, // zero
    headersize: u32, // offset of bitmaps in file, 32
    flags: u32, // 0 if there's no unicode table
    numglyph: u32, // number of glyphs
    bytesperglyph: u32, // size of each glyph
    height: u32, // height in pixels
    width: u32, // width in pixels
};

var font: PsfFont = undefined;

pub var w: usize = undefined;
pub var h: usize = undefined;

pub fn init() !void {
    font = @bitCast(fontData[0..@sizeOf(PsfFont)].*);
    w = font.width;
    h = font.height;
}

///display a character on screen at (x,y)
pub fn drawChar(char: u8, x: usize, y: usize, color: u32) !void {
    @setRuntimeSafety(false);

    const mask = [8]u8{ 128, 64, 32, 16, 8, 4, 2, 1 };

    //the glyph offset to display the right character
    const offset = if (char > 0 and char < font.numglyph) blk: {
        break :blk font.headersize + (char * font.bytesperglyph);
    } else blk: {
        break :blk font.headersize;
    };

    //display the character
    for (0..font.height) |cy| {
        for (0..font.width) |cx| {
            if (fontData[offset + cy] & mask[cx] != 0) try dsp.put(cx + x, cy + y, color);
        }
    }
}

///display a string with line warping
pub fn printString(string: []const u8, dcol: usize, dline: usize, color: u32) !void {
    var line = dline;
    var col = dcol;
    for (string) |char| {
        //check for overflow -> change line
        if ((col + 1) * font.width >= dsp.w) {
            line += 1;
            col = dcol;
        }
        try drawChar(char, col * font.width, line * font.height, color);
        col += 1;
    }
}
