///A demo app made to show how one can use
///CaCOS impressive memory management and
///graphic capabilities to make simple apps
const scr = @import("../drivers/screen.zig");
const console = @import("../drivers/console.zig");
const stream = @import("../drivers/stream.zig");
const kb = @import("../drivers/keyboard.zig");

const db = @import("../core/debug.zig");
const scheduler = @import("../core/scheduler.zig");
const fs = @import("../core/fs.zig");

const pages = @import("../memory/pages.zig");
const memory = @import("../memory/memory.zig");

var id: usize = undefined;

const bg = 0xeaaa56;

var seed: usize = 233;

var file: u64 = undefined;
var highscore: u64 = 0;

//game variables
//head coordinates in Cells (snake size)
//that means that x = 2 means coordinate x = 2 * snake_size on the screen
var x: u8 = 1;
var y: u8 = 1;

var fruit_x: u8 = 12;
var fruit_y: u8 = 12;

var score: usize = 0;

var length: usize = 2;

const Directions = enum {
    up,
    right,
    down,
    left,
};

var direction: Directions = Directions.down;

//TODO see why this doesn't work
fn checkCollision(snake: pages.Page) bool {
    const mem = &memory.memory_region;
    for (snake.start + 2..snake.start + length) |i| {
        if (mem.*[snake.start] == mem.*[i * 2]) {
            if (mem.*[snake.start + 1] == mem.*[i * 2 + 1]) {
                return true;
            }
        }
    }
    return false;
}

fn handleCrash(snake: pages.Page) void {
    var buffer: [10]u8 = undefined;
    scr.drawRect(0, 0, scr.width, scr.height, 0x111111);
    scr.gotoCenter();
    scr.printCenter("Game Over", scr.errorc);
    scr.row += scr.font.height;
    scr.printCenter("-Score-", scr.text);
    scr.row += scr.font.height;
    scr.printCenter(db.numberToStringDec(score, &buffer), scr.primary);
    scr.row += scr.font.height;

    const highestScore = fs.getData(file);
    //write score to score file
    scr.printCenter("-Highest Score-", scr.text);
    scr.row += scr.font.height;
    scr.col -= scr.font.width * 8;
    scr.print(highestScore[0..9], 0xffff00);
    scr.row += scr.font.height;

    //update the highest score
    if (score > highscore) {
        highscore = score;
        fs.writeData(file, db.numberToStringDec(score, &buffer));
    }

    fs.writeData(file, db.numberToStringDec(highscore, &buffer));
    scr.printCenter("Press r to restart, ctrl + c to quit", scr.text);
    while (scheduler.running[id]) {
        stream.index = 0;
        if (stream.stdin[0] == 'r') {
            startGame(snake);
            return;
        }
    }
}

fn drawScore() void {
    var buffer: [10]u8 = undefined;
    scr.col = 2;
    scr.row = 2;
    scr.drawRect(0, 0, scr.width, scr.font.height + 4, 0x111111);
    scr.print("Press Ctrl + C to stop  |  score: ", bg);
    scr.print(db.numberToStringDec(score, &buffer), scr.errorc);
}

fn startGame(snake: pages.Page) void {
    //draw the background
    scr.drawRect(0, 0, scr.width, scr.height, bg);
    pages.clearPage(snake);
    x = 4;
    y = 4;
    score = 0;
    length = 2;
    memory.memory_region[snake.start] = 5;
    memory.memory_region[snake.start + 1] = 4;
    memory.memory_region[snake.start + 2] = 4;
    memory.memory_region[snake.start + 3] = 4;
    direction = Directions.right;
}

fn run() void {
    const mem = &memory.memory_region;

    //game constants
    const snake_size = 20;
    const snake_color = 0x14591d;

    const snake: pages.Page = pages.alloc(&pages.pageTable) catch |err| { //on errors
        switch (err) {
            pages.errors.outOfPages => console.printErr("Error: out of pages"),
        }
        return;
    };

    startGame(snake);

    //create the score file
    fs.createDir("snake", fs.root_address);
    fs.createFile("highscore.snake", fs.addressFromName("snake"));
    file = fs.addressFromName("highscore.snake");
    //fs.writeData(file, "0");

    //when we are done we must free the memory
    defer pages.free(snake, &pages.pageTable);
    stream.captured = true;

    //used to slow the game down
    const slower: usize = 2_500_000;
    var slow: usize = slower;

    while (scheduler.running[id]) {
        if (slow == 0) {
            drawScore();
            //check for collisions
            if (x + 1 >= scr.width / snake_size or y + 1 >= scr.height / snake_size or x - 1 <= 0 or y <= 0 or checkCollision(snake)) {
                handleCrash(snake);
            }

            if (!scheduler.running[id]) return;

            stream.index = 0;
            if (stream.stdin[0] == 'h' or stream.stdin[0] == kb.keyEventToChar(kb.KeyEvent.Code.left) and direction != Directions.right) direction = Directions.left;
            if (stream.stdin[0] == 'j' or stream.stdin[0] == kb.keyEventToChar(kb.KeyEvent.Code.down) and direction != Directions.up) direction = Directions.down;
            if (stream.stdin[0] == 'k' or stream.stdin[0] == kb.keyEventToChar(kb.KeyEvent.Code.up) and direction != Directions.down) direction = Directions.up;
            if (stream.stdin[0] == 'l' or stream.stdin[0] == kb.keyEventToChar(kb.KeyEvent.Code.right) and direction != Directions.left) direction = Directions.right;

            switch (direction) {
                Directions.up => y -= 1,
                Directions.right => x += 1,
                Directions.down => y += 1,
                Directions.left => x -= 1,
            }

            //check for collision with fruit
            if (x == fruit_x and y == fruit_y) {
                scr.drawRect(@as(usize, fruit_x) * snake_size, @as(usize, fruit_y) * snake_size, snake_size, snake_size, snake_color);
                seed += x;
                fruit_x = @as(u8, @truncate(@mod(db.hashNumber(seed), scr.width / (snake_size + 5))));
                seed += length;
                fruit_y = @as(u8, @truncate(@mod(db.hashNumber(seed), scr.height / (snake_size + 5))));
                score += 1;
                length += 1;
            }

            db.shiftMem(snake, 2, length * 2 - 2);
            mem.*[snake.start] = x;
            mem.*[snake.start + 1] = y;

            //draw the head
            scr.drawRect(@as(usize, mem.*[snake.start]) * snake_size, @as(usize, mem.*[snake.start + 1]) * snake_size, snake_size, snake_size, snake_color);
            //clear the tail
            scr.drawRect(@as(usize, mem.*[snake.start + length * 2 - 2]) * snake_size, @as(usize, mem.*[snake.start + length * 2 - 1]) * snake_size, snake_size, snake_size, bg);
            //draw the fruit
            scr.drawRect(@as(usize, fruit_x) * snake_size, @as(usize, fruit_y) * snake_size, snake_size, snake_size, 0xff0000);

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
