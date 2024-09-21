const scr = @import("../drivers/screen.zig");
const console = @import("../drivers/console.zig");
const stream = @import("../drivers/stream.zig");

const debug = @import("../cpu/debug.zig");
const scheduler = @import("../cpu/scheduler.zig");

var id: usize = undefined;

fn run() void {
    //draw the background
    const bg = 0xeaaa56;
    scr.drawRect(0, 0, scr.width, scr.height, bg);

    //game constants
    const snake_size = 16;
    const snake_color = 0x14591d;

    //game variables
    var x: usize = 0;
    var y: usize = 0;
    //var snake = [_]bool{true,true,true};

    const Directions = enum {
        up,
        right,
        down,
        left,
    };

    var direction: Directions = Directions.down;

    stream.captured = true;

    const slower: usize = 30_000_000;
    var slow: usize = slower;

    while (scheduler.running[id]) {
        if (slow == 0) {
            stream.index = 0;
            switch (stream.stdin[0]) {
                'h' => direction = Directions.left,
                'j' => direction = Directions.down,
                'k' => direction = Directions.up,
                'l' => direction = Directions.right,
                else => {},
            }
            debug.printChar(stream.stdin[1]);
            switch (direction) {
                Directions.up => y -= snake_size,
                Directions.right => x += snake_size,
                Directions.down => y += snake_size,
                Directions.left => x -= snake_size,
            }
            scr.drawRect(x, y, snake_size, snake_size, snake_color);
            slow = slower;
        } else slow -= 1;
    }
    stream.captured = false;
}

pub fn start() void {
    id = scheduler.getFree();
    const app = scheduler.Process{ .id = id, .function = &run };
    scheduler.append(app);
}
