const cpu = @import("../cpu/cpu.zig");
const isr = @import("../cpu/isr.zig");
const mem = @import("../core/memory.zig");
const List = @import("../utils/list.zig").List(u8);
const fs = @import("../core/ramfs.zig");
const std = @import("std");
const console = @import("../interface/console.zig");
const BOOTBOOT = @import("../bootboot.zig").BOOTBOOT;
extern var bootboot: BOOTBOOT;

///output character to debug console
pub inline fn printChar(char: u8) void {
    cpu.outb(0xe9, char);
}

///print to debug console
pub inline fn print(string: []const u8) void {
    for (string) |char| {
        printChar(char);
    }
}

///print errors to console to debug console
pub inline fn printErr(string: []const u8) void {
    //color output in yellow
    print("\u{001b}[31m");
    print(string);
    print("\u{001B}[0m");
}

pub inline fn panic(string: []const u8) void {
    //color output in red
    print("\u{001b}[34m");
    print(string);
    print("\u{001B}[0m");
    cpu.hang();
}

pub fn printValue(n: u128) void {
    var buffer: [32]u8 = undefined;
    print(std.fmt.bufPrint(&buffer, "{X}", .{n}) catch buffer[0..0]);
}

pub fn printValueDec(n: u128) void {
    var buffer: [32]u8 = undefined;
    print(std.fmt.bufPrint(&buffer, "{d}", .{n}) catch buffer[0..0]);
}

pub fn debug(string: []const u8, value: usize, mode: u1) void {
    switch (mode) {
        0 => {
            print("\n");
            print(string);
            print(": ");
            printValue(value);
        },
        1 => {
            print("\n");
            print(string);
            print(": ");
            printValueDec(value);
        },
    }
}

pub fn debugPtr(ptr: anytype) void {
    print("\nDebbugging pointer:");
    debug(" -> value of pointer", @intFromPtr(ptr), 0);
}

pub fn debugStruct(object: anytype) void {
    print("\n------------------------------------------------------------------");
    print("\nDebugging struct: ");
    print(@typeName(@TypeOf(object)));
    inline for (std.meta.fields(@TypeOf(object))) |field| {
        print("\n -> ");
        print(field.name);
        print(" = ");
        printValue(@as(field.type, @field(object, field.name)));
        //printValue(object);
    }
    print("\n------------------------------------------------------------------");
}

pub fn printValueFormat(value: u8, format: u1) void {
    if (format == 0) {
        if (value < 0xf) { //usefull for formating
            print("0");
            printValue(value);
        } else {
            printValue(value);
        }
    } else {
        switch (value) {
            0 => {
                //color output in red
                print("\u{001b}[34m");
                printChar('0');
                print("\u{001B}[0m");
            },
            '\n' => {
                //color output in red
                print("\u{001b}[35m");
                printChar('N');
                print("\u{001B}[0m");
            },
            ' ' => {
                //color output in yellow
                print("\u{001b}[33m");
                printChar('_');
                print("\u{001B}[0m");
            },
            else => printChar(value),
        }
    }
    print(" ");
}

pub fn debugPage(page: []u8, format: u1) void {
    print("\n----debugging page------\n");
    print("informations about the page:\n");
    debug(" -> length of the page", page.len, 1);
    debug(" -> address of the page", @intFromPtr(page.ptr), 0);
    print("\ncontent of the page\n");
    for (0..page.len / 64) |i| {
        for (0..64) |j| {
            const value = page[i * 64 + j];
            printValueFormat(value, format);
        }
    }
    print("\n");
}

pub fn debugMem(index: usize, width: usize, format: u1) void {
    print("\n------------------------------------------------------------------");
    print("\nDebugging memory: ");
    debug(" -> value of \"width\"", width, 0);
    debug(" -> value of \"index\"", index, 0);
    print("\n");
    for (0..width) |i| {
        const value = mem.mmap[index + i];
        printValueFormat(value, format);
    }
}

pub fn dumpPage(page: []u8) void {
    for (0..page.len) |i| {
        const value = page[i];
        printChar(value);
    }
}

pub fn debugList(list: List, format: u1) void {
    print("\n----debugging List------\n");
    print("informations about the page:\n");
    //debug(" -> length of the list", list.size, 1);
    //debug(" -> address of the list", @intFromPtr(&list), 0);
    print("\ncontent of the page\n");
    print("\u{001b}[32m");
    for (0..list.size) |j| {
        const value = list.read(j) catch 0;
        printValueFormat(value, format);
    }
    print("\u{001B}[0m");
}

pub fn debugNode(node: fs.Node) void {
    print("\n----Information about ");
    print(node.name);
    print("in intself----");
    debug(" -> size", node.data.size, 1);
    debug(" -> address of the Node", @intFromPtr(&node), 0);
    debug(" -> address of the data list", @intFromPtr(&node.data), 0);
    debug(" -> address of the name string", @intFromPtr(node.name.ptr), 0);
    print("\n -> data:");
    print("\u{001b}[34m");
    debugList(node.data, 1);
    print("\u{001B}[0m");
    print("\n------------------------------------------------------------------");
}

pub fn tree() !void {
    for (0..fs.node_list.size) |i| {
        const node = try fs.node_list.read(i);
        switch (node.ftype) {
            fs.Ftype.dir => print("\u{001b}[34m"),
            fs.Ftype.text => print("\u{001b}[33m"),
            else => print("\u{001b}[35m"),
        }
        print("\n");
        print(node.name);
        debug(" -> size", node.data.size, 1);
        debug(" -> value of \"parent_id\"", node.parent, 0);
        const name: []const u8 = (try fs.open(node.parent)).name;
        //debugNode(parent);
        print("\n -> parent: ");
        print(name);
        print("\u{001B}[0m\n");
    }
}

pub fn memOverview() void {
    debug("number of pages total", mem.n_pages, 1);
    debug("number of pages used", mem.used_pages, 1);
    print("\npage overview:\n");
    // for (0..mem.n_pages) |i| {
    //     const value = mem.pages[i];
    //     if (value == 1) {
    //         print("\nused page at:");
    //
    //         //color output in red
    //         print("\u{001b}[34m");
    //         printValueDec(i);
    //         print("\u{001B}[0m");
    //     }
    // }
}

///prints the current context
pub fn debugContextInterrupt(context: *isr.InterruptStackFrame) callconv(.{ .x86_64_interrupt  = .{} }) void {
    print("\n------------------------------------------------------------------");
    print("\nDebugging context:");
    debugStruct(context.*);
}

///trigger the interrupt calling the context debug function
pub fn debugContext() void {
    asm volatile ("int $9");
}

pub fn sysInfo() void {
    print("\nSytem information:");
    debug("number of cores", bootboot.numcores, 1);
}

pub fn printPath(path: []u16) void {
    for (0..path.len) |i| {
        const node = fs.open(path[i]) catch fs.root;
        print(node.name);
        print(">");
    }
}

pub fn debugPath(path: []u16) void {
    print("\npath length: ");
    printValueDec(path.len);
    print("\npath content: ");
    for (0..path.len) |i| {
        print("\n path id: ");
        printValueDec(path[i]);
        const node = fs.open(path[i]) catch fs.root;
        print("\n -> name: ");
        print(node.name);
        print("\n -> id: ");
        printValueDec(node.id);
        print("\n -> path: ");
        printPath(node.path);
    }
}
