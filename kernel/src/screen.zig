const limine = @import("limine");
const cpu = @import("cpu.zig");
const debug = @import("debug.zig");

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

const font: Font = .{
    .data = @embedFile("font/vga8x16.bin"),
    .width = 8,
    .height = 16,
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
pub const primary = 0x8ddddc;
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
    const dw = if (x + w < width) w + x else w - ((x + w) - width) + x;
    const dh = if (y + h < height) h + y else h - ((y + h) - height) + y;
    for (0..dw) |dx| {
        for (0..dh) |dy| {
            putpixel(dx, dy, color);
        }
    }
}

pub fn manageOwerflow(offset: u8) void {
    if (col + offset < width) {
        return;
    } else if (row + offset < height) {
        newLine();
        col = 0;
    } else {
        row = 0;
        col = 0;
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

fn handleBackspace() void {
    drawCharacter(0, bg);
    if (col >= font.width) {
        col -= font.width;
    } else if (row >= font.height) {
        row -= font.height;
        col = width - font.width;
    } else {
        row = 0;
        col = 0;
    }
}

pub fn drawCharacter(char: u8, fg: u32) void {
    const mask = [8]u8{ 128, 64, 32, 16, 8, 4, 2, 1 };
    const glyph_offset: usize = @as(usize, char) * font.height;
    manageOwerflow(font.width);
    for (0..font.height) |cy| {
        for (0..font.width) |cx| {
            const pixel_color = if (font.data[glyph_offset + cy] & mask[cx] != 0) fg else bg;
            if (bg != 0x000001 or pixel_color == fg) {
                putpixel(cx + col, cy + row, pixel_color);
            }
        }
    }
}

pub fn newLine() void {
    col = 0;
    if (row <= height) {
        row += font.height;
    } else {
        row = 0;
    }
}

pub fn drawCursor() void {
    //draw one character to the right
    manageOwerflow(2 * font.width);
    //col += font.width;
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
    row = height - 2 * font.height;
}

pub fn printMOTD() void {
    clear();
    print("\n   .d8888b.            .d8888b.   .d88888b.   .d8888b.  \n", 0xf6aa70);
    print("  d88P  Y88b          d88P  Y88b d88P\" \"Y88b d88P  Y88b \n", 0xf6aa70);
    print("  888    888          888    888 888     888 Y88b.      \n", 0xf6aa70);
    print("  888         8888b.  888        888     888  \"Y888b.   \n", 0xf6aa70);
    print("  888            \"88b 888        888     888     \"Y88b. \n", 0xf6aa70);
    print("  888    888 .d888888 888    888 888     888       \"888 \n", 0xf6aa70);
    print("  Y88b  d88P 888  888 Y88b  d88P Y88b. .d88P Y88b  d88P \n", 0xf6aa70);
    print("   \"Y8888P\"  \"Y888888  \"Y8888P\"   \"Y88888P\"   \"Y8888P\"  \n", 0xf6aa70);
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
}
