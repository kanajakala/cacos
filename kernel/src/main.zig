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
    text_width: u8,
    text_height: u8,
};

const font: Font = .{
    .data = @embedFile("font/vga8x16.bin"),
    .text_width = 8,
    .text_height = 16,
};

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

inline fn putpixel(framebuffer: *limine.Framebuffer, x: usize, y: usize, color: u32) void {
    // Calculate the pixel offset using the framebuffer information we obtained above.
    // We skip `i` scanlines (pitch is provided in bytes) and add `i * 4` to skip `i` pixels forward.
    const pixel_offset = y * framebuffer.pitch + x * 4;

    // Write 0xFFFFFFFF to the provided pixel offset to fill it white.
    @as(*u32, @ptrCast(@alignCast(framebuffer.address + pixel_offset))).* = color;
}

//inline fn drawChar(framebuffer: *limine.Framebuffer, char: u16, x: usize, y: usize, fg: u32, bg: u32) void {
//const mask = [8]u8{ 1, 2, 4, 8, 16, 32, 64, 128 };
//const glyph_offset: usize = char * font.text_height;
//var cy: u8 = 0;
//while (cy < font.text_height) : (cy += 1) {
//    var cx: u8 = 0;
//    while (cx < font.text_width) : (cx += 1) {
//        //const pixel_color = if (font.data[glyph_offset + cy] & mask[cx] != 0) fg else bg;
//        const pixel_color = 0xFFFFFF;
//        putpixel(framebuffer, @as(u8, cx) + x, @as(u8, cy) + y - 12, pixel_color);
//    }
//}
//}

inline fn loopTest() void {
    var i: usize = 0;
    var t: usize = 0;
    while (i < 1000) : (i += 1) {
        t += 10;
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

        const framebuffer = framebuffer_response.framebuffers()[0];
        // Get the first framebuffer's information.
        putpixel(framebuffer, 0, 0, 0xFFFFFFFF);
        //drawChar(framebuffer, 'X', 0, 0, @intCast(0xFFFFFF), @intCast(0x000000));
        loopTest();
    }
    while (true) {}
}
