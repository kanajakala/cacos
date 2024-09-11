const console = @import("../drivers/console.zig");
const scr = @import("../drivers/screen.zig");
const stream = @import("../drivers/stream.zig");

const mem = @import("../memory/memory.zig");
const pages = @import("../memory/pages.zig");

const debug = @import("../cpu/debug.zig");

pub fn info() void {
    console.print("CaCOS: Coherent and Cohesive OS");
    console.print("developped by kanajakala");
}

pub fn echo() void {
    const offset = "echo ".len;
    console.print(stream.stdin[offset..]);
}

pub fn testMem(value: u64) void {
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

    var temp: pages.Page = undefined;
    for (0..value) |i| {
        _ = i;
        temp = pages.alloc(&pages.pageTable) catch |err| { //on errors
            switch (err) {
                pages.errors.outOfPages => console.printErr("Error: out of pages"),
            }
            return;
        };
    }

    memory.end = temp.end;
    scr.print("\nAttempting allocation of ", scr.text);
    scr.print(debug.numberToStringDec(value, &buffer), scr.errorc);
    scr.print(" pages at ", scr.text);
    scr.print(debug.numberToStringHex(memory.start, &buffer), scr.text);

    const value_to_write: u8 = @truncate(value);
    scr.print("\n -> Writing value ", 0x888888);
    scr.print(debug.numberToStringHex(value_to_write, &buffer), 0x888888);

    var iterations: usize = 0;
    for (0..memory.end - memory.start) |j| {
        mem.memory_region[memory.start + j] = value_to_write;
        iterations = j;
    }
    scr.print("\n -> words written: ", 0x0fbbff);
    scr.print(debug.numberToStringDec(iterations, &buffer), scr.errorc);
}

pub fn printMem() void {
    var buffer: [20]u8 = undefined;
    const length = debug.numberToStringDec(mem.memory_region.len / 1_000_000, &buffer);
    scr.print("\nsize of memory: ", scr.text);
    scr.print(length, scr.errorc);
    const number_of_pages = debug.numberToStringDec(pages.number_of_pages, &buffer);
    scr.print("\nnumber of pages: ", scr.text);
    scr.print(number_of_pages, scr.errorc);
    const page_size = debug.numberToStringDec(pages.page_size, &buffer);
    scr.print("\npage size: ", scr.text);
    scr.print(page_size, scr.errorc);
    const free_pages = debug.numberToStringDec(pages.getFreePages(&pages.pageTable), &buffer);
    scr.print("\nnumber of free pages: ", scr.text);
    scr.print(free_pages, scr.errorc);
    const free_mem = debug.numberToStringDec(pages.getFreePages(&pages.pageTable) * pages.page_size / 1_000_000, &buffer);
    scr.print("\nfree memory: ", scr.text);
    scr.print(free_mem, scr.errorc);
    scr.newLine();
}
