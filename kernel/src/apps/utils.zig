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

pub fn ls() void {
    for (0..fs.number_of_files) |i| {
        console.print(fs.getName(db.readFromMem(u64, fs.super_block.start + i * 8)));
    }
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
}

var value: usize = undefined;
var id: usize = undefined;
pub fn testMem() void {
    if (value == 0) {
        console.printErr("Value can't be zero");
        return;
    }

    var buffer: [20]u8 = undefined;

    var memory: pages.Page = pages.alloc(&pages.pageTable) catch |err| { //on errors
        switch (err) {
            pages.errors.outOfPages => console.printErr("Error: out of pages"),
        }
        return;
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
            temp = pages.alloc(&pages.pageTable) catch |err| { //on errors
                switch (err) {
                    pages.errors.outOfPages => console.printErr("Error: out of pages"),
                }
                return;
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

    //used to test writeToMem()
    //
    //scr.print("nAttempting write of large value\n", scr.text);
    //db.writeToMem(u64, memory.start, 0xbbbbbbbbbbbbbbbb);
    //for (memory.start..memory.start + 8) |i| {
    //    scr.print(db.numberToStringHex(mem.memory_region[i], &buffer), 0xffff00);
    //}
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
