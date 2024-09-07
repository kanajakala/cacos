const screen = @import("../screen.zig");
const debug = @import("../debug.zig");

pub fn draw(precision: u8) void {
    screen.drawRect(0, 0, screen.width, screen.height, 0);
    screen.gotoLastLine();
    for (0..screen.height) |y| {
        for (0..screen.width) |x| {
            const cx: f32 = @as(f32, @floatFromInt(x)) - @as(f32, @floatFromInt(screen.width)) / 2.0;
            const cy: f32 = @as(f32, @floatFromInt(y)) - @as(f32, @floatFromInt(screen.height)) / 2.0;
            const dx: f32 = cx / 400.0 - 0.8;
            const dy: f32 = cy / 400.0;

            var a: f32 = dx;
            var b: f32 = dy;
            for (0..precision * 10) |t| {
                const d: f32 = (a * a) - (b * b) + dx;
                b = 2 * (a * b) + dy;
                a = d;
                if (d > 200) {
                    screen.putpixel(x, y, @truncate(t * 12));
                }
            }
        }
    }
}
