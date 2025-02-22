///A Simple Text editing app
const scr = @import("../drivers/screen.zig");
const console = @import("../drivers/console.zig");
const stream = @import("../drivers/stream.zig");
const kb = @import("../drivers/keyboard.zig");

const db = @import("../core/debug.zig");
const scheduler = @import("../core/scheduler.zig");
const fs = @import("../core/fs.zig");

var id: usize = undefined;

var file: u64 = undefined;

var cursor: usize = 0;

//width of a line in characters
var width: usize = undefined;

//Find the index corresponding to the end of the file
pub fn findEndOfFile(arr: []u8) usize {
    var col: usize = 0;
    var row: usize = 0;
    for (arr) |el| {
        //we add a whole line when a new line char is encountered and remove the current line height
        if (el == '\n') {
            row += 1;
        }
        if (el == 0) return width * (row);
        col += 1;
        if (col >= width) {
            row += 1;
            col = 0;
        }
    }
    return 0;
}

fn run() void {
    width = (scr.width / scr.font.width);

    var allocated_data: [fs.block_size]u8 = .{0} ** fs.block_size;
    var data: []u8 = allocated_data[0 .. fs.getSize(file) * fs.block_size];
    const file_data: []u8 = fs.getData(file);
    db.print("Copied data\n");
    @memcpy(data[0..file_data.len], file_data);

    stream.flush();
    scr.clear();
    scr.gotoStart();

    //print the current data in the file
    for (data) |char| {
        scr.printChar(char, scr.text);
    }

    //goto the end of the file
    cursor = findEndOfFile(file_data);
    scr.gotoChar(cursor);

    while (scheduler.running[id]) {
        //display the text
        const key = stream.current_key;
        const value: u8 = kb.keyEventToChar(key.code);
        //if the key is pressed
        //check if we need to write file
        if (stream.current_modifier == kb.KeyEvent.Code.key_s) {
            fs.writeData(file, data);
        }
        if (key.state == kb.KeyEvent.State.pressed and value != 0 and stream.current_modifier == kb.KeyEvent.Code.unknown) {
            //check if we need to write file
            if (stream.current_modifier == kb.KeyEvent.Code.key_s) {
                fs.writeData(file, data);
            }
            data[cursor] = value;

            //display the text
            scr.clearChar();
            scr.printChar(value, scr.primary);

            //reset the pressed key
            stream.current_key = kb.empty_key;

            //handle overflow
            if (cursor + 1 >= fs.block_size) cursor = 0;

            //update the cursor
            cursor += 1;
        }
    }
}

pub fn start() void {
    const command_offset = "editor ".len;
    const file_name = db.firstWordOfArray(stream.stdin[command_offset..]);
    file = fs.addressFromName(file_name);

    stream.captured = true;

    id = scheduler.getFree();
    const app = scheduler.Process{ .id = id, .name = "editor", .function = &run };
    scheduler.append(app);
}
