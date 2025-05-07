const BOOTBOOT = @import("../bootboot.zig").BOOTBOOT;
const pow = @import("std").math.pow;

extern var framebuffer: u8; // linear framebuffer mapped, linked in link.ld
extern var bootboot: BOOTBOOT;

//global variables
//these variables are initialized at runtime
pub var s: u32 = undefined;
pub var w: u32 = undefined;
pub var h: u32 = undefined;
var fb: [*]u32 = undefined;

const errors = error{
    overflow,
};

pub inline fn put(x: usize, y: usize, color: u32) !void {
    //check for overflow
    if (x > w or y > h) return errors.overflow;

    //put the pixel
    fb[((s * y) + x * 4) / @sizeOf(u32)] = color;
}

pub inline fn copyLine(x: usize, y: usize, rw: usize, to_x: usize, to_y: usize) !void {
    //overflow check
    if (x + rw > w or y + 1 > h) return errors.overflow;
    if (to_x + rw > w or to_y + 1 > h) return errors.overflow;

    //we have to copy line by line to the destination
    const source = fb[(x * 4 + (s * y)) / @sizeOf(u32) .. ((x + rw) * 4 + (s * y)) / @sizeOf(u32)];
    const dest = fb[(to_x * 4 + (s * to_y)) / @sizeOf(u32) .. ((to_x + rw) * 4 + (s * to_y)) / @sizeOf(u32)];
    @memcpy(dest, source);
}

pub inline fn copy(x: usize, y: usize, rw: usize, rh: usize, to_x: usize, to_y: usize) !void {
    //overflow check
    if (x + rw > w or y + rh > h) return errors.overflow;
    if (to_x + rw > w or to_y + rh > h) return errors.overflow;

    //we have to copy line by line to the destination
    for (0..rh) |i| {
        try copyLine(x, y + i, rw, to_x, to_y + i);
    }
}

pub fn rect(x: usize, y: usize, rw: usize, rh: usize, color: u32) !void {
    //check for overflow
    if (x + rw > w or y + rh > h) return errors.overflow;

    //fill first line
    for (0..rw) |i| {
        try put(x + i, y, color);
    }
    //copy the line over and over again
    for (0..rh - 1) |i| {
        try copyLine(x, y + i, rw, x, y + i + 1);
    }
}

pub fn init() !void {
    s = bootboot.fb_scanline;
    w = bootboot.fb_width;
    h = bootboot.fb_height;
    fb = @ptrCast(@alignCast(&framebuffer));
}
