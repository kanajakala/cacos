const console = @import("../drivers/console.zig");
const scr = @import("../drivers/screen.zig");
const stream = @import("../drivers/stream.zig");

const mem = @import("../memory/memory.zig");
const pages = @import("../memory/pages.zig");

const db = @import("../core/debug.zig");
const fs = @import("../core/fs.zig");
const scheduler = @import("../core/scheduler.zig");

pub fn info() void {
    console.print("CaCOS: Coherent and Cohesive OS");
    console.print("developed by kanajakala");
}

pub fn echo() void {
    const offset = "echo ".len;
    console.print(stream.stdin[offset..]);
}

const no_file = "No such file";

pub fn ls() void {
    for (0..fs.number_of_files) |i| {
        const address = fs.addressFromSb(i);
        const name = fs.getName(address);
        const ftype: fs.FileType = fs.getType(address);
        if (fs.getParent(address) == fs.current_dir) {
            if (ftype == fs.FileType.directory) {
                console.printInfo(name);
            } else {
                console.print(name);
            }
        }
    }
}

pub fn touch() void {
    const offset = "touch ".len;
    const name = db.firstWordOfArray(stream.stdin[offset..]);
    if (fs.fileExists(name)) return console.printErr("File already exists !");
    fs.createFile(name, fs.current_dir);
}

pub fn cd() void {
    const offset = "cd ".len;
    const name: []const u8 = db.firstWordOfArray(stream.stdin[offset..]);
    if (db.hashStr(name) == db.hashStr("..")) {
        const parent_dir = fs.getParent(fs.current_dir);
        fs.current_dir = parent_dir;
        return;
    }
    if (!fs.fileExists(name)) return console.printErr(no_file);
    fs.current_dir = fs.addressFromName(name);
    if (fs.current_dir == 0) fs.current_dir = fs.root_address;
}

pub fn mkdir() void {
    const offset = "mkdir ".len;
    const name: []const u8 = db.firstWordOfArray(stream.stdin[offset..]);
    if (fs.fileExists(name)) return console.printErr("File already exists !");
    fs.createDir(name, fs.current_dir);
}

pub fn pwd() void {
    const mxpt = fs.max_path_size;
    var path: [mxpt]u64 = .{0} ** mxpt;
    var temp: u64 = fs.current_dir;
    var iterations: usize = 1;
    for (0..mxpt) |i| {
        path[i] = temp;
        temp = fs.getParent(temp);
        if (temp == 0) break;
        iterations += 1;
    }
    console.print("");
    for (1..iterations + 1) |j| {
        console.printf(fs.getName(path[iterations - j]));
        if (j != 1) console.printf("/");
    }
}

pub fn write() void {
    const command_offset = "write ".len;
    const file_name = db.firstWordOfArray(stream.stdin[command_offset..]);
    if (!fs.fileExists(file_name)) return console.printErr(no_file);
    const offset = command_offset + file_name.len + 1;
    const in = stream.stdin[offset .. offset + fs.block_size];
    const file = fs.addressFromName(file_name);
    fs.writeData(file, in);
}

pub fn read() void {
    const command_offset = "read ".len;
    const file_name = db.firstWordOfArray(stream.stdin[command_offset..]);
    if (!fs.fileExists(file_name)) return console.printErr(no_file);
    const file = fs.addressFromName(file_name);
    console.print(fs.getData(file));
}

pub fn readhex() void {
    const command_offset = "readhex ".len;
    const file_name = db.firstWordOfArray(stream.stdin[command_offset..]);
    if (!fs.fileExists(file_name)) return console.printErr(no_file);
    const file = fs.addressFromName(file_name);
    var buffer: [2]u8 = undefined;
    const data = fs.getData(file)[0..1000];
    for (data) |i| {
        scr.print(db.numberToStringHex(i, &buffer), 0xa2f280);
        scr.print(" ", 0);
    }
}

pub fn display() void {
    const command_offset = "display ".len;
    const file_name = db.firstWordOfArray(stream.stdin[command_offset..]);
    if (!fs.fileExists(file_name)) return console.printErr(no_file);
    const file = fs.addressFromName(file_name);
    const data = fs.getData(file);
    const image: scr.Image = scr.createImagefromFile(data) catch blk: {
        console.printErr("Unsupported image type");
        break :blk scr.empty_image;
    };
    scr.drawImage(1000, 100, image);
}

pub fn append() void {
    const command_offset = "append ".len;
    const file_name = db.firstWordOfArray(stream.stdin[command_offset..]);
    if (!fs.fileExists(file_name)) return console.printErr(no_file);
    const offset = command_offset + file_name.len + 1;
    const in = stream.stdin[offset .. offset + fs.block_size];
    const file = fs.addressFromName(file_name);
    fs.appendData(file, in);
}

pub fn help() void {
    //simple help menu to explain commands
    scr.newLine();
    scr.print("info", scr.primary);
    scr.print(" -> Prints info about the system\n", scr.text);

    scr.print("meminfo", scr.primary);
    scr.print(" -> Prints info about the memory\n", scr.text);

    scr.print("testmem <number of pages>", scr.primary);
    scr.print(" -> Test the allocation of n pages\n", scr.text);

    scr.print("fractal <precision>", scr.primary);
    scr.print(" -> Displays a fractal with n iterations\n", scr.text);

    scr.print("clear", scr.primary);
    scr.print(" -> Clears the screen\n", scr.text);

    scr.print("motd", scr.primary);
    scr.print(" -> Prints the CaCOS ASCII logo\n", scr.text);

    scr.print("cacfetch", scr.primary);
    scr.print(" -> Prints detailled info about the system\n", scr.text);

    scr.print("test", scr.primary);
    scr.print(" -> Just a command to see if the CLI is working\n", scr.text);

    scr.print("logo", scr.primary);
    scr.print(" -> Displays the systems logo (image)\n", scr.text);

    scr.print("stop", scr.primary);
    scr.print(" -> Stops the system\n", scr.text);

    scr.print("echo [text]", scr.primary);
    scr.print(" -> prints the provided text to stdout\n", scr.text);

    scr.print("ls", scr.primary);
    scr.print(" -> lists all of the file in the system\n", scr.text);

    scr.print("touch [file]", scr.primary);
    scr.print(" -> creates a new file\n", scr.text);

    scr.print("pwd", scr.primary);
    scr.print(" -> prints the current working directory\n", scr.text);

    scr.print("cd", scr.primary);
    scr.print(" -> changes the current working directory\n", scr.text);

    scr.print("read [file]", scr.primary);
    scr.print(" -> Displays the content of a file in plain text\n", scr.text);

    scr.print("readhex [file]", scr.primary);
    scr.print(" -> Displays the content of a file iin hexadecimal\n", scr.text);

    scr.print("write [file] [text]", scr.primary);
    scr.print(" -> Writes the provided text to the file, will overwrite the previous text\n", scr.text);

    scr.print("append [file] [text]", scr.primary);
    scr.print(" -> Writes the provided text to the file, will be added after the previous text\n", scr.text);

    scr.print("editor [file]", scr.primary);
    scr.print(" -> Edit the provided file in an interractive editor\n", scr.text);

    scr.print("snake", scr.primary);
    scr.print(" -> Play the famous game in CaCOS !\n", scr.text);

    scr.print("display [file]", scr.primary);
    scr.print(" -> displays the provided image\n", scr.text);
}

var value: usize = undefined;
var id: usize = undefined;

pub fn testMem() void {
    if (value == 0) {
        console.printErr("Value can't be zero");
        return;
    }

    var buffer: [20]u8 = undefined;

    var memory: pages.Page = pages.alloc(&pages.pageTable) catch |err| switch (err) {
        pages.errors.outOfPages => return console.printErr("Error: out of pages"),
    };

    scr.print("\nAttempting allocation of ", scr.text);
    scr.print(db.numberToStringDec(value, &buffer), scr.errorc);
    scr.print(" pages at ", scr.text);
    scr.print(db.numberToStringHex(memory.start, &buffer), scr.text);

    //allocating the pages
    var temp: pages.Page = undefined;
    for (0..value) |i| {
        if (scheduler.running[id]) {
            _ = i;
            temp = pages.alloc(&pages.pageTable) catch |err| switch (err) {
                pages.errors.outOfPages => return console.printErr("Error: out of pages"),
            };
        } else return;
    }
    memory.end = temp.end;

    const value_to_write: u8 = @truncate(value);
    scr.print("\n -> Writing value ", 0x888888);
    scr.print(db.numberToStringHex(value_to_write, &buffer), 0x888888);

    //writing the value
    var iterations: usize = 0;
    for (0..memory.end - memory.start) |j| {
        if (scheduler.running[id]) {
            mem.memory_region[memory.start + j] = value_to_write;
            iterations = j;
        }
    }
    scr.print("\n -> words written: ", 0x0fbbff);
    scr.print(db.numberToStringDec(iterations, &buffer), scr.errorc);
    stream.newLine();
}

pub fn testMemStart(parameter: usize) void {
    value = parameter;
    id = scheduler.getFree();
    const app = scheduler.Process{ .id = id, .function = &testMem };
    scheduler.append(app);
}

pub fn printMem() void {
    var buffer: [20]u8 = undefined;
    const length = db.numberToStringDec(mem.memory_region.len / 1_000_000, &buffer);
    scr.print("\nsize of memory: ", scr.text);
    scr.print(length, scr.errorc);
    const number_of_pages = db.numberToStringDec(pages.number_of_pages, &buffer);
    scr.print("\nnumber of pages: ", scr.text);
    scr.print(number_of_pages, scr.errorc);
    const page_size = db.numberToStringDec(pages.page_size, &buffer);
    scr.print("\npage size: ", scr.text);
    scr.print(page_size, scr.errorc);
    const free_pages = db.numberToStringDec(pages.getFreePages(&pages.pageTable), &buffer);
    scr.print("\nnumber of free pages: ", scr.text);
    scr.print(free_pages, scr.errorc);
    const free_mem = db.numberToStringDec(pages.getFreePages(&pages.pageTable) * pages.page_size / 1_000_000, &buffer);
    scr.print("\nfree memory: ", scr.text);
    scr.print(free_mem, scr.errorc);
    scr.newLine();
}
