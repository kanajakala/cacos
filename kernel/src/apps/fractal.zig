const scr = @import("../drivers/screen.zig");
const console = @import("../drivers/console.zig");
const debug = @import("../cpu/debug.zig");

pub fn draw(precision: u64) void {
    if (precision == 0) {
        scr.print("\nplease provide a precision", scr.errorc);
        return;
    }
    scr.drawRect(0, 0, scr.width, scr.height, 0);
    scr.gotoLastLine();
    for (0..scr.height) |y| {
        for (0..scr.width) |x| {
            const cx: f32 = @as(f32, @floatFromInt(x)) - @as(f32, @floatFromInt(scr.width)) / 2.0;
            const cy: f32 = @as(f32, @floatFromInt(y)) - @as(f32, @floatFromInt(scr.height)) / 2.0;
            const dx: f32 = cx / 400.0 - 0.8;
            const dy: f32 = cy / 400.0;

            var a: f32 = dx;
            var b: f32 = dy;
            for (0..precision * 10) |t| {
                const d: f32 = (a * a) - (b * b) + dx;
                b = 2 * (a * b) + dy;
                a = d;
                if (d > 200) {
                    scr.putpixel(x, y, @truncate(t * 12));
                }
            }
        }
    }
}
