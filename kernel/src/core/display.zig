const BOOTBOOT = @import("../bootboot.zig").BOOTBOOT;

extern var framebuffer: u8; // linear framebuffer mapped, linked in link.ld
extern var bootboot: BOOTBOOT;

//global variables
pub var s: u32 = undefined;
pub var w: u32 = undefined;
pub var h: u32 = undefined;
var fb: [*]u32 = undefined;

//these variables are initialized at runtime
pub fn init() !void {
    s = bootboot.fb_scanline;
    w = bootboot.fb_width;
    h = bootboot.fb_height;
    fb = @ptrCast(@alignCast(&framebuffer));

    //remove later...
    try rect(0, 0, w, h, 0x280800);
}

const errors = error{
    overflow,
};

pub fn put(x: usize, y: usize, color: u32) !void {

    //check for overflow
    if (x > w or y > h) return errors.overflow;

    //put the pixel
    fb[((s * y) + x * 4) / @sizeOf(u32)] = color;
}

pub fn rect(x: usize, y: usize, rw: usize, rh: usize, color: u32) !void {
    //check for overflow
    if (x + rw > w or y + rh > h) return errors.overflow;

    //naive implementation
    for (0..rw) |i| {
        for (0..rh) |j| {
            try put(x + i, y + j, color);
        }
    }

    //TODO: use memcpy to accelerate fill
    //...
}
