const std = @import("std");
const limine = @import("limine");

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

var framebuffer: *limine.Framebuffer = undefined;

//variables to help with character placement
var col: usize = 0;
var row: usize = 0;

inline fn stop() noreturn {
    while (true) {
        asm volatile ("hlt");
    }
}

//print to the console
inline fn inb(port: u16) u8 {
    return asm volatile ("inb %[port], %[result]"
        : [result] "={al}" (-> u8),
        : [port] "N{dx}" (port),
    );
}

inline fn outb(port: u16, data: u8) void {
    asm volatile ("outb %[data], %[port]"
        :
        : [data] "{al}" (data),
          [port] "N{dx}" (port),
    );
}

inline fn dprint(comptime string: [:0]const u8) void {
    inline for (string) |char| {
        outb(0xe9, char);
    }
}

fn putpixel(x: usize, y: usize, color: u32) void {
    // Calculate the pixel offset using the framebuffer information we obtained above.
    // We skip `y` scanlines (pitch is provided in bytes) and add `x * 4` to skip `x` pixels forward.
    const pixel_offset = y * framebuffer.pitch + x * 4;

    // Write 0xFFFFFFFF to the provided pixel offset to fill it white.
    @as(*u32, @ptrCast(@alignCast(framebuffer.address + pixel_offset))).* = color;
}

fn printChar(char: u16, fg: u32, bg: u32) void {
    //see https://wiki.osdev.org/VGA_Fonts#Decoding_of_bitmap_fonts
    const mask = [8]u8{ 1, 2, 4, 8, 16, 32, 64, 128 };
    const glyph_offset: usize = char * font.height;
    if (char == '\n') {
        newLine();
    } else if ((col + font.width) < framebuffer.width) {
        for (0..font.width) |cx| {
            for (0..font.height) |cy| {
                if (bg == 0x000000) {
                    if (font.data[glyph_offset + cy] & mask[cx] != 0) putpixel((font.width - cx) + col, cy + row, fg);
                } else {
                    const pixel_color = if (font.data[glyph_offset + cy] & mask[cx] != 0) fg else bg;
                    putpixel((font.width - cx) + col, cy + row, pixel_color);
                }
            }
        }
        col += font.width;
    } else if ((row + font.height) < framebuffer.height) {
        newLine();
    } else {
        row = 0;
        col = 0;
    }
}

fn newLine() void {
    row += font.height;
    col = 0;
}

fn print(string: [:0]const u8, fg: u32, bg: u32) void {
    for (string) |char| {
        printChar(char, fg, bg);
    }
}

export fn _start() callconv(.C) noreturn {
    dprint("CaCOS loaded sucessfully");
    if (!base_revision.is_supported()) {
        dprint("base revision not supported");
        stop();
    }
    // Ensure we got a framebuffer.
    if (framebuffer_request.response) |framebuffer_response| {
        if (framebuffer_response.framebuffer_count < 1) {
            dprint("No framebuffer");
            stop();
        }

        framebuffer = framebuffer_response.framebuffers()[0];
    }
    // Get the first framebuffer's information.
    putpixel(0, 0, 0xFFFFFFFF);
    print(" .d8888b.            .d8888b.   .d88888b.   .d8888b.  \n", 0xf6aa70, 0x0);
    print("d88P  Y88b          d88P  Y88b d88P\" \"Y88b d88P  Y88b \n", 0xf6aa70, 0x0);
    print("888    888          888    888 888     888 Y88b.      \n", 0xf6aa70, 0x0);
    print("888         8888b.  888        888     888  \"Y888b.   \n", 0xf6aa70, 0x0);
    print("888            \"88b 888        888     888     \"Y88b. \n", 0xf6aa70, 0x0);
    print("888    888 .d888888 888    888 888     888       \"888 \n", 0xf6aa70, 0x0);
    print("Y88b  d88P 888  888 Y88b  d88P Y88b. .d88P Y88b  d88P \n", 0xf6aa70, 0x0);
    print(" \"Y8888P\"  \"Y888888  \"Y8888P\"   \"Y88888P\"   \"Y8888P\"  \n", 0xf6aa70, 0x0);

    print("Welocome to CaCOS\n", @intCast(0xFFFFFF), @intCast(0x000000));

    while (true) {}
}
