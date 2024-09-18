const limine = @import("limine");
const cpu = @import("../cpu/cpu.zig");
const debug = @import("../cpu/debug.zig");
const stream = @import("../drivers/stream.zig");

//framebuffer
pub export var framebuffer_request: limine.FramebufferRequest = .{};
pub export var base_revision: limine.BaseRevision = .{ .revision = 1 };

//font
const Font = struct {
    /// A Bit Map containing the shape of each character, it must be compatible with
    /// the ASCII Table so we can get the shape using the character itself
    data: []const u8,
    width: u8,
    height: u8,
};

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

const font: Font = .{
    .data = @embedFile("assets/vga8x16.bin"),
    .width = 8,
    .height = 16,
};

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

pub fn putpixel(x: usize, y: usize, color: u32) void {
    // Calculate the pixel offset using the framebuffer information we obtained above.
    // We skip `y` scanlines (pitch is provided in bytes) and add `x * 4` to skip `x` pixels forward.
    const pixel_offset = y * framebuffer.pitch + x * 4;

    // Write 0xFFFFFFFF to the provided pixel offset to fill it white.
    @as(*u32, @ptrCast(@alignCast(framebuffer.address + pixel_offset))).* = color;
}

pub fn drawRect(x: usize, y: usize, w: usize, h: usize, color: u32) void {
    //check for owerflow else cut the overflowing part
    //const dw = if (x + w < width) w + x else w - ((x + w) - width) + x;
    //const dh = if (y + h < height) h + y else h - ((y + h) - height) + y;
    for (0..w) |dx| {
        for (0..h) |dy| {
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

pub fn createImagefromFile(file: []const u8) !Image {
    //If the magic number is invalid we return an errro
    if (file[0] != 'P') return imgErrs.invalidFormat;

    //required to transform numbers to strings
    var buffer: [30]u8 = undefined;

    //the type of the file: 4 => Portable Bitmap Format  6 => Portable Pixmap (colors)
    var img_type: Img_Type = undefined;

    //The height is the first number after a whitespace
    //the first line contains 3 chars (magic number and line feed)
    const im_height = debug.numberInArray(@constCast(file[3..]));

    //debug.print("Height of the image: ");
    debug.print(debug.numberToStringDec(im_height, &buffer));

    //we need to offset by the length of the height string to read the width
    //const w_offset = debug.numberToStringDec(im_height, &buffer).len + 4;

    //TODO actually get  the real value this is currently bad
    const im_width = im_height; //debug.numberInArray(@constCast(file[w_offset..]));
    //debug.print("Width of the image: ");
    //debug.print(debug.numberToStringDec(im_width, &buffer));

    const data_offset = 15; //w_offset + debug.numberToStringDec(im_width, &buffer).len + 9;
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
                if (color != 0) putpixel(x + imx, y + imy, color);
                imx += 1;
            }
        },
    }
}

pub fn drawCharacter(char: u8, fg: u32) void {
    const mask = [8]u8{ 128, 64, 32, 16, 8, 4, 2, 1 };
    const glyph_offset: usize = @as(usize, char) * font.height;
    manageOwerflow(font.width);
    for (0..font.height) |cy| {
        for (0..font.width) |cx| {
            if (font.data[glyph_offset + cy] & mask[cx] != 0) putpixel(cx + col, cy + row, fg);
        }
    }
}

pub fn clearChar() void {
    drawRect(col, row, font.width, font.height, bg);
}

pub fn manageOwerflow(offset: u8) void {
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
            col += font.width;
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
    //col += font.width;
    clearChar();
    drawCharacter('#', 0xf98a13);
    //col -= font.width;
}

pub fn print(string: []const u8, fg: u32) void {
    for (string) |char| {
        printChar(char, fg);
    }
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

pub fn gotoFirstLine() void {
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

pub fn init() void {
    // cpu.print("screen initialized\n");
    const maybe_framebuffer_response = framebuffer_request.response;

    if (maybe_framebuffer_response == null or maybe_framebuffer_response.?.framebuffers().len == 0) {
        debug.panic("framebuffer error");
    }

    const framebuffer_response = maybe_framebuffer_response.?;

    framebuffers = framebuffer_response.framebuffers();
    framebuffer = framebuffers[0];
    height = framebuffer.height;
    width = framebuffer.width;
    const img = createImagefromFile(@embedFile("assets/caclogo.ppm")) catch Image{ .img_type = Img_Type.ppm, .data = "cac", .height = 0, .width = 0 };

    drawImage(12, 12, img);
}
