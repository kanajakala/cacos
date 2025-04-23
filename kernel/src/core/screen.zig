const BOOTBOOT = @import("../bootboot.zig").BOOTBOOT;

extern var fb: u8; // linear framebuffer mapped, linked in link.ld
extern var bootboot: BOOTBOOT;

pub fn start() void {
    const s = bootboot.fb_scanline;
    const w = bootboot.fb_width;
    const h = bootboot.fb_height;
    var framebuffer: [*]u32 = @ptrCast(@alignCast(&fb));

    if (s > 0) {
        // cross-hair to see screen dimension detected correctly
        for (0..h) |y| {
            framebuffer[(s * y + w * 2) / @sizeOf(u32)] = 0x00FFFFFF;
        }

        for (0..w) |x| {
            framebuffer[(s * (h / 2) + x * 4) / @sizeOf(u32)] = 0x00FFFFFF;
        }

        // red, green, blue boxes in order
        inline for (0..20) |y| {
            for (0..20) |x| {
                framebuffer[(s * (y + 20) + (x + 20) * 4) / @sizeOf(u32)] = 0x00FF0000;
            }
        }

        inline for (0..20) |y| {
            for (0..20) |x| {
                framebuffer[(s * (y + 20) + (x + 50) * 4) / @sizeOf(u32)] = 0x0000FF00;
            }
        }
        inline for (0..20) |y| {
            for (0..20) |x| {
                framebuffer[(s * (y + 90) + (x + 80) * 4) / @sizeOf(u32)] = 0x00FFFFFF;
            }
        }
    }
}
