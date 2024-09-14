const scr = @import("../drivers/screen.zig");
const console = @import("../drivers/console.zig");

const debug = @import("../cpu/debug.zig");
const scheduler = @import("../cpu/scheduler.zig");

pub fn draw() void {
    const precision = 200;
    if (precision == 0) {
        console.printErr("please provide a precision");
        return;
    }
    scr.drawRect(0, 0, scr.width, scr.height, 0);
    scr.gotoFirstLine();
    scr.print("Press any key to interrupt\n", 0xaaffff);
    for (0..scr.height) |y| {
        for (0..scr.width) |x| {
            if (scheduler.running[34]) {
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
}

pub fn run() void {
    const app = scheduler.Process{ .id = 34, .function = &draw };
    scheduler.append(app);
}
