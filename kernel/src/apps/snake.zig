const scr = @import("../drivers/screen.zig");
const console = @import("../drivers/console.zig");
const stream = @import("../drivers/stream.zig");

const debug = @import("../cpu/debug.zig");
const scheduler = @import("../cpu/scheduler.zig");

const pages = @import("../memory/pages.zig");
const memory = @import("../memory/memory.zig");

var id: usize = undefined;

const bg = 0xeaaa56;

//game variables
//head coordinates in Cells (snake size)
//that means that x = 2 means coordinate x = 2 * snake_size on the screen
var x: u8 = 25;
var y: u8 = 25;

fn checkCollision(snake: pages.Page, length: usize) bool {
    const mem = &memory.memory_region;
    var i: usize = 0;
    while (i < snake.start + length * 2 - 4) : (i += 2) {
        const cell_1: u8 = mem.*[snake.start + i];
        const cell_2: u8 = mem.*[snake.start + i + 1];
        const region_to_test_1 = mem.*[snake.start + i + 2 .. snake.start + length * 2];
        const region_to_test_2 = mem.*[snake.start + i + 3 .. snake.start + length * 2];
        if (cell_1 != 0 and cell_2 != 0 and debug.elementInArray(u8, cell_1, region_to_test_1, 2) and debug.elementInArray(u8, cell_2, region_to_test_2, 2)) return true;
    }
    return false;
}

fn handleCrash(snake: pages.Page) void {
    scr.drawRect(0, 0, scr.width, scr.height, 0x111111);
    scr.gotoCenter();
    scr.printCenter("Game Over", scr.errorc);
    scr.row += scr.font.height;
    scr.printCenter("Press r to restart", scr.text);
    while (scheduler.running[id]) {
        stream.index = 0;
        if (stream.stdin[0] == 'r') {
            startGame(snake);
            return;
        }
    }
}

fn startGame(snake: pages.Page) void {
    //draw the background
    scr.drawRect(0, 0, scr.width, scr.height, bg);
    x = 25;
    y = 25;
    pages.clearPage(snake);
}

fn run() void {
    const mem = &memory.memory_region;

    //game constants
    const snake_size = 16;
    const snake_color = 0x14591d;

    const length: usize = 5;
    const snake: pages.Page = pages.alloc(&pages.pageTable) catch |err| { //on errors
        switch (err) {
            pages.errors.outOfPages => console.printErr("Error: out of pages"),
        }
        return;
    };

    startGame(snake);

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

    //used to slow the game down
    const slower: usize = 3_000_000;
    var slow: usize = slower;

    while (scheduler.running[id]) {
        if (slow == 0) {
            //check for collisions
            if (x + 1 >= scr.width / snake_size or y + 1 >= scr.height / snake_size or x - 1 <= 0 or y - 1 <= 0 or checkCollision(snake, length)) {
                handleCrash(snake);
            }

            stream.index = 0;
            switch (stream.stdin[0]) {
                'h' => direction = Directions.left,
                'j' => direction = Directions.down,
                'k' => direction = Directions.up,
                'l' => direction = Directions.right,
                else => {},
            }
            //if (x > 0 and x < 9 and y > 0 and y < 9) {
            switch (direction) {
                Directions.up => y -= 1,
                Directions.right => x += 1,
                Directions.down => y += 1,
                Directions.left => x -= 1,
            }
            //}

            debug.shiftMem(snake, 2, length * 2 - 2);
            mem.*[snake.start] = x;
            mem.*[snake.start + 1] = y;

            scr.drawRect(@as(usize, mem.*[snake.start]) * snake_size, @as(usize, mem.*[snake.start + 1]) * snake_size, snake_size, snake_size, snake_color);
            //draw the head
            //clear the tail
            scr.drawRect(@as(usize, mem.*[snake.start + length * 2 - 2]) * snake_size, @as(usize, mem.*[snake.start + length * 2 - 1]) * snake_size, snake_size, snake_size, bg);

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