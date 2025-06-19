const BOOTBOOT = @import("../bootboot.zig").BOOTBOOT;
const db = @import("../utils/debug.zig");

extern var framebuffer: u8; // linear framebuffer mapped, linked in link.ld
extern var bootboot: BOOTBOOT;

//global variables
//these variables are initialized at runtime
pub var s: u32 = undefined;
pub var w: u32 = undefined;
pub var h: u32 = undefined;
var fb: [*]u32 = undefined;

const errors = error{
    framebuffer_overflow,
};

pub inline fn put(x: usize, y: usize, color: u32) !void {
    //check for framebuffer_overflow
    if (x > w or y > h) return errors.framebuffer_overflow;

    //put the pixel
    fb[((s * y) + x * 4) / @sizeOf(u32)] = color;
}

pub inline fn copyChunk(start: usize, width: usize, where: usize) !void {
    //framebuffer_overflow check
    if (start + width > w * h * 16) return errors.framebuffer_overflow;

    @memcpy(fb[where..(where + width)], fb[start..(start + width)]);
}
// pub fn scroll() !void {
//     try dsp.copyChunk(dsp.w * font.h, dsp.w * dsp.h - 2 * dsp.w * font.h, 0);
//     cursor.x = border;
//     dsp.rect(border, dsp.h - font.h - border, dsp.w - 2 * border, font.h, background) catch {};
// }

pub inline fn copyLine(x: usize, y: usize, rw: usize, to_x: usize, to_y: usize) !void {
    //framebuffer_overflow check
    if (x + rw > w or y + 1 > h) return errors.framebuffer_overflow;
    if (to_x + rw > w or to_y + 1 > h) return errors.framebuffer_overflow;

    const source = fb[(x * 4 + (s * y)) / @sizeOf(u32) .. ((x + rw) * 4 + (s * y)) / @sizeOf(u32)];
    const dest = fb[(to_x * 4 + (s * to_y)) / @sizeOf(u32) .. ((to_x + rw) * 4 + (s * to_y)) / @sizeOf(u32)];
    @memcpy(dest, source);
}

pub inline fn copy(x: usize, y: usize, rw: usize, rh: usize, to_x: usize, to_y: usize) !void {
    //framebuffer_overflow check
    if (x + rw > w or y + rh > h) return errors.framebuffer_overflow;
    if (to_x + rw > w or to_y + rh > h) return errors.framebuffer_overflow;

    //we have to copy line by line to the destination
    for (0..rh) |i| {
        try copyLine(x, y + i, rw, to_x, to_y + i);
    }
}

pub inline fn rect(x: usize, y: usize, rw: usize, rh: usize, color: u32) !void {
    //check for framebuffer_overflow
    if (x + rw > w * 4 or y + rh > h * 4) return errors.framebuffer_overflow;

    //fill first line
    for (0..rw) |i| {
        try put(x + i, y, color);
    }
    //copy the line over and over again
    for (0..rh - 1) |i| {
        try copyLine(x, y + i, rw, x, y + i + 1);
    }
}

pub inline fn fill(color: u32) !void {
    try rect(0, 0, w, h, color);
}

pub fn init() !void {
    s = bootboot.fb_scanline;
    w = bootboot.fb_width;
    h = bootboot.fb_height;
    fb = @ptrCast(@alignCast(&framebuffer));
}
