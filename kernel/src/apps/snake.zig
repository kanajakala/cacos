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
    for (2..length) |i| {
        if (snake.data[i] == snake.data[i * 2]) {
            if (snake.data[1] == snake.data[i * 2 + 1]) {
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
    scr.printCenter("Type snake to restart", scr.text);
    //when we are done we must free the memory
    defer snake.free(&pages.pt);
    snake.free(&pages.pt);
    //then we stop
    scheduler.stop(id);
    stream.captured = false;
    stream.flush();
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
    snake.data[0] = 5;
    snake.data[1] = 4;
    snake.data[2] = 4;
    snake.data[3] = 4;
    direction = Directions.right;
}

fn run() void {
    //game constants
    const snake_size = 20;
    const snake_color = 0x14591d;

    const snake: pages.Page = pages.alloc(&pages.pt) catch |err| switch (err) { //on errors
        pages.errors.outOfPages => return console.printErr("Error: out of pages"),
    };

    startGame(snake);

    //create the score file
    _ = fs.createFile("snake", fs.Type.directory, fs.root_address);
    file = fs.createFile("highscore.snake", fs.Type.text, fs.addressFromName("snake"));

    stream.captured = true;

    //used to slow the game down
    const slower: usize = 2_500_000;
    var slow: usize = slower;

    while (scheduler.running[id]) {
        if (slow == 0) {
            drawScore();
            //check for collisions
            if (x + 1 >= scr.width / snake_size or y + 1 >= scr.height / snake_size or x <= 0 or y <= 0 or checkCollision(snake)) {
                handleCrash(snake);
            }

            if (!scheduler.running[id]) return;

            stream.index = 0;
            if (stream.stdin[0] == kb.keyEventToChar(kb.KeyEvent.Code.left) and direction != Directions.right) direction = Directions.left;
            if (stream.stdin[0] == kb.keyEventToChar(kb.KeyEvent.Code.down) and direction != Directions.up) direction = Directions.down;
            if (stream.stdin[0] == kb.keyEventToChar(kb.KeyEvent.Code.up) and direction != Directions.down) direction = Directions.up;
            if (stream.stdin[0] == kb.keyEventToChar(kb.KeyEvent.Code.right) and direction != Directions.left) direction = Directions.right;

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
            snake.data[0] = x;
            snake.data[1] = y;

            //draw the head
            scr.drawRect(@as(usize, snake.data[0]) * snake_size, @as(usize, snake.data[1]) * snake_size, snake_size, snake_size, snake_color);
            //clear the tail
            scr.drawRect(@as(usize, snake.data[length * 2 - 2]) * snake_size, @as(usize, snake.data[length * 2 - 1]) * snake_size, snake_size, snake_size, bg);
            //draw the fruit
            scr.drawRect(@as(usize, fruit_x) * snake_size, @as(usize, fruit_y) * snake_size, snake_size, snake_size, 0xff0000);

            slow = slower;
        } else slow -= 1;
    }
}

pub fn start() void {
    db.print("starting Snake !");
    id = scheduler.getFree();
    const app = scheduler.Process{ .id = id, .name = "snake", .function = &run };
    scheduler.append(app);
}
