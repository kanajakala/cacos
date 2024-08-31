const limine = @import("limine");
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
var col: usize = 0;
var row: usize = 0;

pub fn putpixel(x: usize, y: usize, color: u32) void {
    // Calculate the pixel offset using the framebuffer information we obtained above.
    // We skip `y` scanlines (pitch is provided in bytes) and add `x * 4` to skip `x` pixels forward.
    const pixel_offset = y * framebuffer.pitch + x * 4;

    // Write 0xFFFFFFFF to the provided pixel offset to fill it white.
    @as(*u32, @ptrCast(@alignCast(framebuffer.address + pixel_offset))).* = color;
}

pub fn printChar(char: u16, fg: u32, bg: u32) void {
    //see https://wiki.osdev.org/VGA_Fonts#Decoding_of_bitmap_fonts
    var bs_override: bool = false;
    if (char == 0) return;
    if (char == 0x08) {
        bs_override = true;
        if (col - font.width > 0) {
            col -= font.width;
        } else if (row - font.height > 0) {
            row -= font.height;
            col = 0;
        } else {
            row = 0;
            col = 0;
        }
    }

    if (char == '\n' or char == 0x0d) {
        newLine();
    } else if ((col + font.width) < framebuffer.width) {
        const mask = [8]u8{ 1, 2, 4, 8, 16, 32, 64, 128 };
        const glyph_offset: usize = char * font.height;
        for (0..font.width) |cx| {
            for (0..font.height) |cy| {
                if (bs_override) {
                    putpixel((font.width - cx) + col, cy + row, bg);
                } else if (bg == 0x000000) {
                    if (font.data[glyph_offset + cy] & mask[cx] != 0) putpixel((font.width - cx) + col, cy + row, fg);
                } else {
                    const pixel_color = if (font.data[glyph_offset + cy] & mask[cx] != 0) fg else bg;
                    putpixel((font.width - cx) + col, cy + row, pixel_color);
                }
            }
        }
        if (!bs_override) col += font.width;
    } else if ((row + font.height) < framebuffer.height) {
        newLine();
    } else {
        row = 0;
        col = 0;
    }
}

pub fn newLine() void {
    row += font.height;
    col = 0;
}

pub fn print(string: []const u8, fg: u32, bg: u32) void {
    for (string) |char| {
        printChar(char, fg, bg);
    }
}

pub fn printMOTD() void {
    print("\n   .d8888b.            .d8888b.   .d88888b.   .d8888b.  \n", 0xf6aa70, 0x0);
    print("  d88P  Y88b          d88P  Y88b d88P\" \"Y88b d88P  Y88b \n", 0xf6aa70, 0x0);
    print("  888    888          888    888 888     888 Y88b.      \n", 0xf6aa70, 0x0);
    print("  888         8888b.  888        888     888  \"Y888b.   \n", 0xf6aa70, 0x0);
    print("  888            \"88b 888        888     888     \"Y88b. \n", 0xf6aa70, 0x0);
    print("  888    888 .d888888 888    888 888     888       \"888 \n", 0xf6aa70, 0x0);
    print("  Y88b  d88P 888  888 Y88b  d88P Y88b. .d88P Y88b  d88P \n", 0xf6aa70, 0x0);
    print("   \"Y8888P\"  \"Y888888  \"Y8888P\"   \"Y88888P\"   \"Y8888P\"  \n", 0xf6aa70, 0x0);
}
pub fn init() void {
    debug.print("\nscreen initialized");
    const maybe_framebuffer_response = framebuffer_request.response;

    if (maybe_framebuffer_response == null or maybe_framebuffer_response.?.framebuffers().len == 0) {
        debug.print("framebuffer error");
        debug.stop();
    }

    const framebuffer_response = maybe_framebuffer_response.?;

    framebuffers = framebuffer_response.framebuffers();
    framebuffer = framebuffers[0];
}
