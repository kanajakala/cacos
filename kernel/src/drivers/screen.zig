const limine = @import("limine");
const cpu = @import("../core/cpu.zig");
const db = @import("../core/debug.zig");
const stream = @import("../drivers/stream.zig");

//framebuffer
pub export var framebuffer_request: limine.FramebufferRequest = .{};
pub export var base_revision: limine.BaseRevision = .{ .revision = 1 };

///font
pub const Fonts = enum {
    vga,
    psf,
};

const Font = struct {
    /// A Bit Map containing the shape of each character, it must be compatible with
    /// the ASCII Table so we can get the shape using the character itself
    ftype: Fonts,
    data: []const u8,
    width: usize,
    height: usize,
};

//image handling
const Img_Type = enum {
    pbm, //portable bitmap format
    ppm, //portable pixmap (colors)
};

const Image = struct {
    img_type: Img_Type,
    ///A bitmap used to display images
    data: []const u8,
    width: usize,
    height: usize,
};

//pub const font_fallback: Font = loadFont(Fonts.vga, @embedFile("assets/vga8x16.bin"), 8, 16);
const emptyArray: [1]u8 = .{0};
pub const placeholder_font = Font{ .ftype = Fonts.vga, .data = emptyArray[0..], .width = 0, .height = 0 };
pub var font: Font = placeholder_font;

const imgErrs = error{
    invalidFormat,
    unsupportedFormat,
};

const ScreenErrors = error{
    noFrameBuffer,
};

var framebuffers: []*limine.Framebuffer = undefined;
pub var framebuffer: *limine.Framebuffer = undefined;

//variables to help with character placement
pub var col: usize = 0;
pub var row: usize = 0;

pub var height: usize = undefined;
pub var width: usize = undefined;

pub const bg = 0x280804;
pub const text = 0xdddddd;
pub const errorc = 0xff0000;
pub const primary = 0x8dfdcc;
pub const accent = 0xf6aa70;

pub inline fn putpixel(x: usize, y: usize, color: u32) void {
    // Calculate the pixel offset using the framebuffer information we obtained above.
    // We skip `y` scanlines (pitch is provided in bytes) and add `x * 4` to skip `x` pixels forward.
    const pixel_offset = y * framebuffer.pitch + x * 4;

    // Write 0xFFFFFFFF to the provided pixel offset to fill it white.
    @as(*u32, @ptrCast(@alignCast(framebuffer.address + pixel_offset))).* = color;
}

pub fn drawRect(x: usize, y: usize, w: usize, h: usize, color: u32) void {
    //check for owerflow else cut the overflowing part
    const dw: usize = if (w + x < width) w else w - ((x + w) - width);
    const dh: usize = if (h + y < height) h else h - ((y + h) - height);
    //if (x + w > width or y + h > height) db.panic("Rectangle overflow");
    for (0..dw) |dx| {
        for (0..dh) |dy| {
            putpixel(x + dx, y + dy, color);
        }
    }
}

fn copyLine(source: usize, dest: usize) void {
    for (0..width) |i| {
        const source_offset = source * framebuffer.pitch + i * 4;
        const dest_offset = dest * framebuffer.pitch + i * 4;

        // Write 0xFFFFFFFF to the provided pixel offset to fill it white.
        @as(*u32, @ptrCast(@alignCast(framebuffer.address + dest_offset))).* = @as(*u32, @ptrCast(@alignCast(framebuffer.address + source_offset))).*;
    }
}

///scroll by 1 lines
pub fn scroll() void {
    for (font.height..height) |i| {
        copyLine(i, i - font.height);
    }
    gotoLastLine();
    clearLastLine();
}

pub fn loadFont(ftype: Fonts, data: []const u8, fwidth: usize, fheight: usize) Font {
    switch (ftype) {
        Fonts.vga => return Font{
            .ftype = ftype,
            .data = data,
            .width = fwidth,
            .height = fheight,
        },
        Fonts.psf => {
            //PSF VERSION 1 NOT SUPPORTED

            const PSF_Header = struct {
                magic: u32, //magic bytes to identify PSF
                version: u32, //zero
                headersize: u32, //offset of bitmaps in file, 32
                flags: u32, //0 if there's no unicode table
                numglyph: u32, //number of glyphs
                bytesperglyph: u32, //size of each glyph
                height: u32, //height in pixels
                width: u32, //width in pixels
            };

            const header = PSF_Header{
                .magic = data[0],
                .version = data[1],
                .headersize = data[2],
                .flags = data[3],
                .numglyph = data[4],
                .bytesperglyph = data[5],
                .height = data[6],
                .width = data[7],
            };

            const out = Font{
                .ftype = ftype,
                .data = data[header.headersize..],
                .width = fwidth,
                .height = fheight,
            };

            return out;
        },
    }
}

pub fn createImagefromFile(file: []const u8) !Image {
    //If the magic number is invalid we return an error
    if (file[0] != 'P') return imgErrs.invalidFormat;

    //the type of the file: 4 => Portable Bitmap Format  6 => Portable Pixmap (colors)
    var img_type: Img_Type = undefined;

    //The height is the first number after a whitespace
    //the first line contains 3 chars (magic number and line feed)
    const im_height = db.numberInArray(@constCast(file[3..]));

    //db.print("Height of the image: ");
    //db.print(db.numberToStringDec(im_height, &buffer));

    //we need to offset by the length of the height string to read the width
    //const w_offset = db.numberToStringDec(im_height, &buffer).len + 4;

    //TODO actually get  the real value this is currently bad
    const im_width = im_height; //db.numberInArray(@constCast(file[w_offset..]));
    //db.print("Width of the image: ");
    //db.print(db.numberToStringDec(im_width, &buffer));

    const data_offset = 15; //w_offset + db.numberToStringDec(im_width, &buffer).len + 9;
    const data = file[data_offset..];

    switch (file[1]) {
        //4 indicates the PBM format
        '4' => {
            img_type = Img_Type.pbm;

            return Image{ .img_type = img_type, .data = data, .height = im_height, .width = im_width };
        },
        '6' => {
            img_type = Img_Type.ppm;
            return Image{ .img_type = img_type, .data = data, .height = im_height, .width = im_width };
        },

        else => return imgErrs.unsupportedFormat,
    }
}

pub fn drawImage(x: usize, y: usize, img: Image) void {
    switch (img.img_type) {
        Img_Type.pbm => {
            //TODO: fix this
            const mask = [8]u8{ 128, 64, 32, 16, 8, 4, 2, 1 };
            for (0..img.data.len) |d| {
                //data is defined in bytes but we need to access individual bits
                for (0..8) |i| {
                    if (img.data[d] & mask[i] == 0) {
                        const pixel_x = x + @mod((d * 8 + i), img.width);
                        const pixel_y = y + (d * 8 + i) / img.width;
                        putpixel(pixel_x, pixel_y, 0xffffff);
                    }
                }
            }
        },
        Img_Type.ppm => {
            var imx: usize = 0;
            var imy: usize = 0;
            var d: usize = 0;
            while (d <= img.data.len - 3) : (d += 3) {
                //check for overflows
                if (imx + 1 > img.width) {
                    imx = 0;
                    imy += 1;
                }
                //we read data as a byte triplet
                //one byte per color channel
                //we want color as 32 bit so we have to shift the colors
                //eg we read red: 0xff but the hex for red is 0xff0000 and to more bytes for some reason
                const red = @as(u24, img.data[d]) << 16;
                const green = @as(u24, img.data[d + 1]) << 8;
                const blue = @as(u24, img.data[d + 2]);
                const color: u32 = (red + green + blue);
                //we consider pure black as transparent for esthetical reasons
                if (color >= 0x11111) putpixel(x + imx, y + imy, color);
                imx += 1;
            }
        },
    }
}

pub fn printImage(img: Image) void {
    drawImage(col, row, img);
    //set cursor position after the image
    col = 0;
    row += img.height;
}

pub fn skipChar(n: usize) void {
    col += font.width * n;
}

pub fn gotoChar(n: usize) void {
    gotoStart();
    //check for overflow
    if (n >= (height / font.height) * (width / font.width)) {
        //find how many lines we need to scroll:
        const scrollLines = (height / font.height) - (n / width);

        for (font.height..height) |i| {
            copyLine(i, i - font.height * scrollLines);
        }
    }
    col = @mod(n, width / font.width) * font.width;
    row = (n / (width / font.width)) * font.height;
}

pub fn drawCharacter(char: u8, fg: u32) void {
    switch (font.ftype) {
        Fonts.vga => {
            const mask = [8]u8{ 128, 64, 32, 16, 8, 4, 2, 1 };
            const glyph_offset: usize = @as(usize, char) * font.height;
            manageOwerflow(font.width);
            for (0..font.height) |cy| {
                for (0..font.width) |cx| {
                    if (font.data[glyph_offset + cy] & mask[cx] != 0) putpixel(cx + col, cy + row, fg);
                }
            }
        },
        Fonts.psf => {
            const mask_1 = [8]u8{ 128, 64, 32, 16, 8, 4, 2, 1 };
            const mask_2 = [8]u8{ 128, 64, 32, 16, 8, 4, 2, 1 };
            const glyph_offset: usize = @as(usize, char) * font.height;
            manageOwerflow(font.width);
            for (0..font.height) |cy| {
                for (0..font.width) |cx| {
                    if (font.data[glyph_offset + cy] & mask_1[cx / 2] != 0 and font.data[glyph_offset + cy + 1] & mask_2[cx / 2] != 0) putpixel(cx + col, cy + row, fg);
                }
            }
        },
    }
}

pub fn clearChar() void {
    drawRect(col, row, font.width, font.height, bg);
}

pub fn manageOwerflow(offset: usize) void {
    if (col + offset < width) {
        return;
    } else if (row + font.height <= height) {
        newLine();
        col = 0;
    } else {
        scroll();
    }
}

pub fn printChar(char: u8, fg: u32) void {
    switch (char) {
        0 => return,
        0x08 => handleBackspace(),
        '\n' => {
            drawCharacter(0, bg);
            newLine();
        },
        else => {
            drawCharacter(char, fg);
            skipChar(1);
        },
    }
}

pub fn handleBackspace() void {
    clearChar();
    //we can go back one char if we don't erase the prefix
    if (col >= (stream.prefix.len + 1) * font.width) {
        col -= font.width;
    }
}

pub fn newLine() void {
    col = 0;
    if (row + 2 * font.height <= height) {
        row += font.height;
    } else {
        scroll();
    }
}

pub fn drawCursor() void {
    //draw one character to the right
    manageOwerflow(2 * font.width);
    //skipChar(1);
    clearChar();
    drawCharacter('#', 0xf98a13);
    //col -= font.width;
}

pub fn print(string: []const u8, fg: u32) void {
    for (string) |char| {
        printChar(char, fg);
    }
}

pub fn printCenter(string: []const u8, fg: u32) void {
    col = (width / 2) - (string.len / 2) * font.width;
    print(string, fg);
}

pub fn clear() void {
    drawRect(0, 0, width, height, bg);
    col = 0;
    row = 0;
}

pub fn gotoLastLine() void {
    col = 0;
    row = height - font.height;
}

pub fn gotoCenter() void {
    row = height / 2;
}

pub fn gotoStart() void {
    col = 0;
    row = 0;
}

pub fn clearLastLine() void {
    drawRect(0, height - font.height, width, font.height, bg);
}

pub fn printMOTD() void {
    clear();
    print("\n   .d8888b.            .d8888b.   .d88888b.   .d8888b.  \n", accent);
    print("  d88P  Y88b          d88P  Y88b d88P\" \"Y88b d88P  Y88b \n", accent);
    print("  888    888          888    888 888     888 Y88b.      \n", accent);
    print("  888         8888b.  888        888     888  \"Y888b.   \n", accent);
    print("  888            \"88b 888        888     888     \"Y88b. \n", accent);
    print("  888    888 .d888888 888    888 888     888       \"888 \n", accent);
    print("  Y88b  d88P 888  888 Y88b  d88P Y88b. .d88P Y88b  d88P \n", accent);
    print("   \"Y8888P\"  \"Y888888  \"Y8888P\"   \"Y88888P\"   \"Y8888P\"  \n", accent);
}

pub fn printLogo() void {
    const img = createImagefromFile(@embedFile("assets/caclogo.ppm")) catch Image{ .img_type = Img_Type.ppm, .data = "cac", .height = 0, .width = 0 };

    printImage(img);
}

pub fn init() void {
    const maybe_framebuffer_response = framebuffer_request.response;

    if (maybe_framebuffer_response == null or maybe_framebuffer_response.?.framebuffers().len == 0) {
        db.panic("framebuffer error");
    }

    const framebuffer_response = maybe_framebuffer_response.?;

    font = loadFont(Fonts.psf, @embedFile("assets/font.psf"), 16, 32);
    db.print("\nLoaded font!\n");

    framebuffers = framebuffer_response.framebuffers();
    framebuffer = framebuffers[0];
    height = framebuffer.height;
    width = framebuffer.width;
}
