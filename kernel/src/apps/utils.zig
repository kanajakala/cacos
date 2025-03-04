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

// FILESYSTEM COMMANDS

///prints all files in provided directory
pub fn ls() void {
    const nodes = fs.getChilds(fs.current_dir);
    const n_of_childs = mem.memory_region[nodes.address];

    for (0..n_of_childs) |i| {
        const address: u64 = db.readFromMem(u64, nodes.address + (i * 8) + 1);
        const name = fs.getName(address);
        switch (fs.getType(address)) {
            fs.Type.directory => console.printColor(name, 0xffa300),
            fs.Type.text => console.printColor(name, 0x00ffff),
            fs.Type.binary => console.printColor(name, 0xaa00bb),
            fs.Type.executable => console.printColor(name, 0xbb44ff),
            fs.Type.image => console.printColor(name, 0xab03fd),
        }
    }

    nodes.free(&pages.pt);
}

//prints complete tree of the filesytem
var recursion_level: usize = 0;
pub fn tree(start: u64) void {
    recursion_level += 1;
    const nodes = fs.getChilds(start);
    const n_of_childs = mem.memory_region[nodes.address];
    scr.newLine();
    for (0..n_of_childs) |i| {
        const address: u64 = db.readFromMem(u64, nodes.address + (i * 8) + 1);
        const name = fs.getName(address);
        for (0..recursion_level) |_| console.printf("    ");
        if (fs.getType(address) == fs.Type.directory) {
            console.printColorf(name, 0xffa300);
            tree(address);
            recursion_level -= 1;
        } else {
            console.printColorf(name, 0x00ffff);
            scr.newLine();
        }
    }
    nodes.free(&pages.pt);
}

pub fn touch() void {
    const offset = "touch ".len;
    const name = db.firstWordOfArray(stream.stdin[offset..]);
    if (fs.fileExists(name)) return console.printErr("File already exists !");
    _ = fs.createFile(name, fs.Type.text, fs.current_dir);
}

pub fn cd() void {
    const offset = "cd ".len;
    const name: []const u8 = db.firstWordOfArray(stream.stdin[offset..]);
    if (db.hashStr(name) == db.hashStr("..")) {
        const parent_dir = fs.getParent(fs.current_dir);
        fs.current_dir = parent_dir;
        return;
    }
    //error checking
    if (!fs.fileExists(name)) return console.printErr(no_file);
    if (fs.getType(fs.addressFromName(name)) != fs.Type.directory) return console.printErr("can't cd into file !");
    fs.current_dir = fs.addressFromName(name);
    if (fs.current_dir == 0) fs.current_dir = fs.root_address;
}

pub fn mv() void {
    const offset = "mv ".len;
    const file: []const u8 = db.firstWordOfArray(stream.stdin[offset..]);
    const parent_dir_name: []const u8 = db.firstWordOfArray(stream.stdin[offset + file.len + 1 ..]);
    db.print(parent_dir_name);

    //if the paarent doesn't exist we rename the file

    if (!fs.fileExists(parent_dir_name)) {
        db.print("changing name\n");
        fs.copyFile(fs.addressFromName(file), parent_dir_name, fs.current_dir);
        //fs.remove(fs.addressFromName(file));
        return;
    }
    var parent_dir: u64 = fs.addressFromName(parent_dir_name);
    //error checking
    if (!fs.fileExists(file)) return console.printErr(no_file);
    if (db.hashStr(file) == db.hashStr("..")) parent_dir = fs.getParent(fs.current_dir);
    if (fs.getType(parent_dir) != fs.Type.directory) return console.printErr("Must move to directory");
    //move the file
    fs.setParent(fs.addressFromName(file), parent_dir);
}

pub fn cp() void {
    const offset = "cp ".len;
    const source_node: []const u8 = db.firstWordOfArray(stream.stdin[offset..]);
    const dest_node: []const u8 = db.firstWordOfArray(stream.stdin[offset + source_node.len + 1 ..]);
    fs.copyFile(fs.addressFromName(source_node), dest_node, fs.current_dir);
}

pub fn rm() void {
    const offset = "rm ".len;
    const node: []const u8 = db.firstWordOfArray(stream.stdin[offset..]);
    fs.remove(fs.addressFromName(node));
}

pub fn mkdir() void {
    const offset = "mkdir ".len;
    const name: []const u8 = db.firstWordOfArray(stream.stdin[offset..]);
    if (fs.fileExists(name)) return console.printErr("File already exists !");
    _ = fs.createFile(name, fs.Type.directory, fs.current_dir);
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
    db.print("\n-----------Writing Data-----------\n");
    const command_offset = "write ".len;
    const file_name = db.firstWordOfArray(stream.stdin[command_offset..]);

    //error checking
    if (!fs.fileExists(file_name)) return console.printErr(no_file);
    if (fs.getType(fs.addressFromName(file_name)) == fs.Type.directory) return console.printErr("can't write to directory !");

    const offset = command_offset + file_name.len + 1;
    const in = stream.stdin[offset..];
    const file = fs.addressFromName(file_name);
    fs.writeData(file, in);
}

pub fn read() void {
    const command_offset = "read ".len;
    const file_name = db.firstWordOfArray(stream.stdin[command_offset..]);

    //error checking
    if (!fs.fileExists(file_name)) return console.printErr(no_file);
    if (fs.getType(fs.addressFromName(file_name)) == fs.Type.directory) return console.printErr("can't read directory !");

    const file: fs.File = fs.open(file_name);
    scr.newLine();
    for (0..file.size * fs.block_size) |i| {
        const data: u8 = file.read(i);
        scr.printChar(data, scr.text);
        stream.append(data);
    }
}

pub fn stat() void {
    const command_offset = "stat ".len;
    const file_name = db.firstWordOfArray(stream.stdin[command_offset..]);
    if (!fs.fileExists(file_name)) return console.printErr(no_file);
    const file: fs.File = fs.open(file_name);
    var buffer: [10]u8 = undefined;
    console.print("Name: ");
    console.printf(file.name);
    console.print("Type: ");
    console.printf(@tagName(file.ftype));
    console.print("Size: ");
    console.printf(db.numberToStringDec(file.size * fs.block_size / 1_000, &buffer));
    console.printf("kb");
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
    const image: scr.Image = scr.createImagefromFile(data, file_name) catch blk: {
        console.printErr("Unsupported image type");
        break :blk scr.empty_image;
    };
    scr.printImage(image);
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

//EXECUTABLE COMMANDS
pub fn run() void {
    const command_offset = "run ".len;
    const file_name = db.firstWordOfArray(stream.stdin[command_offset..]);
    const file = fs.addressFromName(file_name);
    scheduler.execute(file);
}

//HELP
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

    scr.print("mv [file] [directory]", scr.primary);
    scr.print(" -> Moves the file to the provided directory\n", scr.text);

    scr.print("readhex [file]", scr.primary);
    scr.print(" -> Displays the content of a file iin hexadecimal\n", scr.text);

    scr.print("write [file] [text]", scr.primary);
    scr.print(" -> Writes the provided text to the file, will overwrite the previous text\n", scr.text);

    scr.print("append [file] [text]", scr.primary);
    scr.print(" -> Writes the provided text to the file, will be added after the previous text\n", scr.text);

    scr.print("stat [file]", scr.primary);
    scr.print(" -> Prints informations about a file\n", scr.text);

    scr.print("editor [file]", scr.primary);
    scr.print(" -> Edit the provided file in an interractive editor\n", scr.text);

    scr.print("snake", scr.primary);
    scr.print(" -> Play the famous game in CaCOS !\n", scr.text);

    scr.print("display [file]", scr.primary);
    scr.print(" -> displays the provided image\n", scr.text);

    scr.print("run [executable]", scr.primary);
    scr.print(" -> runs the provided executable\n", scr.text);
}

var value: usize = undefined;
var id: usize = undefined;

pub fn testMem() void {
    if (value == 0) return console.printErr("Value can't be zero");
    if (value >= 100) return console.printErr("Value can't be bigger than 100");

    var buffer: [10]u8 = undefined;

    scr.print("\nAttempting allocation of ", scr.text);
    //this line makes app crash for some reason
    //TODO: fix this and allow for specified range of pages
    //scr.print(db.numberToStringDec(value, &buffer), scr.errorc);
    scr.print(" pages", scr.text);
    db.print("\n\n\nTesting memory !");

    //allocating the pages
    db.print("\nallocating the pages...");
    var page_list: [100]pages.Page = .{pages.empty_page} ** 100;
    db.print("\ncreated array");

    for (0..value) |i| {
        if (scheduler.running[id]) {
            page_list[i] = pages.alloc(&pages.pt) catch |err| switch (err) {
                pages.errors.outOfPages => return console.printErr("Error: out of pages"),
            };
            db.print("\n  allocated ONE page");
        } else return;
    }
    db.print("\nDone allocating");

    const value_to_write: u8 = @truncate(value);
    scr.print("\n -> Writing value ", 0x888888);
    scr.print(db.numberToStringHex(value_to_write, &buffer), 0x888888);

    //writing the value
    db.print("\nWriting values...");
    var iterations: usize = 0;
    for (0..value) |i| {
        if (scheduler.running[id]) {
            for (0..pages.page_size) |j| {
                page_list[i].data[j] = value_to_write;
                iterations = j;
            }
        }
    }
    db.print("\nDone writing values");
    scr.print("\n -> words written: ", 0x0fbbff);
    scr.print(db.numberToStringDec(iterations, &buffer), scr.errorc);
    stream.newLine();
}

pub fn testMemStart(parameter: usize) void {
    value = parameter;
    id = scheduler.getFree();
    const app = scheduler.Process{ .id = id, .name = "test-memory", .function = &testMem };
    scheduler.append(app);
}

pub fn printMem() void {
    var buffer: [20]u8 = undefined;
    const orange = 0xff4e00;

    const length = db.numberToStringDec(mem.memory_region.len / 1_000_000, &buffer);
    scr.print("\nsize of memory: ", scr.text);
    scr.print(length, scr.errorc);
    scr.print("mb", orange);

    const number_of_pages = db.numberToStringDec(pages.number_of_pages / 1_000, &buffer);
    scr.print("\nnumber of pages: ", scr.text);
    scr.print(number_of_pages, scr.errorc);
    scr.print("kp", orange);

    const page_size = db.numberToStringDec(pages.page_size / 1_000, &buffer);
    scr.print("\npage size: ", scr.text);
    scr.print(page_size, scr.errorc);
    scr.print("kb", orange);

    const free_pages = db.numberToStringDec(pages.getFreePages(&pages.pt) / 1_000, &buffer);
    scr.print("\nnumber of free pages: ", scr.text);
    scr.print(free_pages, scr.errorc);
    scr.print("kp", orange);

    const free_mem = db.numberToStringDec(pages.getFreePages(&pages.pt) * pages.page_size / 1_000_000, &buffer);
    scr.print("\nfree memory: ", scr.text);
    scr.print(free_mem, scr.errorc);
    scr.print("mb", orange);

    scr.print("\nused memory: ", scr.text);
    const percent_number = pages.getFreePages(&pages.pt) / pages.number_of_pages;
    const percent = db.numberToStringDec(percent_number, &buffer);
    scr.print(percent, scr.errorc);
    scr.print("%", orange);
}
