const scr = @import("../drivers/screen.zig");
const console = @import("../drivers/console.zig");
const stream = @import("../drivers/stream.zig");

const debug = @import("../cpu/debug.zig");
const scheduler = @import("../cpu/scheduler.zig");

const pages = @import("../memory/pages.zig");
const memory = @import("../memory/memory.zig");

var id: usize = undefined;

fn run() void {
    const mem = memory.memory_region;
    //draw the background
    const bg = 0xeaaa56;
    scr.drawRect(0, 0, scr.width, scr.height, bg);

    //game constants
    const snake_size = 16;
    const snake_color = 0x14591d;

    //game variables
    //head coordinates in Cells (snake size)
    //that means that x = 2 means coordinate x = 2 * snake_size on the screen
    var x: u8 = 0;
    var y: u8 = 0;
    const length: usize = 3;
    const snake: pages.Page = pages.alloc(&pages.pageTable) catch |err| { //on errors
        switch (err) {
            pages.errors.outOfPages => console.printErr("Error: out of pages"),
        }
        return;
    };

    //when we are done we must free the memory
    defer pages.free(snake, &pages.pageTable);

    const Directions = enum {
        up,
        right,
        down,
        left,
    };

    var direction: Directions = Directions.down;

    stream.captured = true;

    const slower: usize = 10_000_000;
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
            switch (direction) {
                Directions.up => y -= 1,
                Directions.right => x += 1,
                Directions.down => y += 1,
                Directions.left => x -= 1,
            }

            debug.shiftMem(snake, 2, length * 2 - 1);
            mem[snake.start] = x;
            mem[snake.start + 1] = y;

            //draw the head
            scr.drawRect(mem[snake.start] * snake_size, mem[snake.start + 1] * snake_size, snake_size, snake_size, snake_color);
            //clear the tail
            scr.drawRect(mem[snake.start + length - 1] * snake_size, mem[snake.start + length] * snake_size, snake_size, snake_size, bg);

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
