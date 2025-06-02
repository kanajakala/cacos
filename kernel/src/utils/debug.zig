const cpu = @import("../cpu/cpu.zig");
const mem = @import("../core/memory.zig");
const List = @import("../utils/list.zig").List(u8);
const fs = @import("../core/ramfs.zig");
const std = @import("std");
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

pub fn debugPage(page: []u8, format: u1) void {
    print("\n----debugging page------\n");
    print("informations about the page:\n");
    debug(" -> length of the page", page.len, 1);
    debug(" -> address of the page", @intFromPtr(@as(*[4096]u8, @alignCast(@ptrCast(page)))), 0);
    print("\ncontent of the page\n");
    for (0..page.len / 64) |i| {
        for (0..64) |j| {
            const value = page[i * 64 + j];
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
        print("\n");
    }
}

pub fn dumpPage(page: []u8) void {
    for (0..page.len) |i| {
        const value = page[i];
        printChar(value);
    }
}

pub fn debugList(list: List, mode: u1) void {
    print("\n----debugging List------\n");
    print("informations about the page:\n");
    //debug(" -> length of the list", list.size, 1);
    //debug(" -> address of the list", @intFromPtr(&list), 0);
    print("\ncontent of the page\n");
    print("\u{001b}[32m");
    for (0..list.size) |j| {
        const value = list.read(j) catch 0;
        if (mode == 0) {
            if (value < 0xf) { //usefull for formating
                print("0");
                printValue(value);
            } else {
                printValue(value);
            }
            print(" ");
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
                else => printChar(value),
            }
        }
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
    print("\n----Information about ");
    print(node.name);
    print("in the node list----");
    const node_in_list = fs.node_list.read(node.id) catch fs.root;
    print("\naccessed node in list");

    const size = node_in_list.data.size;
    print("\nread size");
    debug(" -> size", size, 1);
    debug(" -> address of the Node", @intFromPtr(&node_in_list), 0);
    debug(" -> address of the data list", @intFromPtr(&node_in_list.data), 0);
    debug(" -> address of the name string", @intFromPtr(node_in_list.name.ptr), 0);
    print("\n -> data:");
    print("\u{001b}[34m");
    debugList(node_in_list.data, 1);
    print("\u{001B}[0m");
    print("\n------------------------------------------------------------------");
}

pub fn memOverview() void {
    debug("number of pages total", mem.n_pages, 1);
    debug("number of pages used", mem.used_pages, 1);
    print("\npage overview:\n");
    for (0..mem.n_pages) |i| {
        const value = mem.pages[i];
        if (value) {
            //color output in red
            print("\u{001b}[34m");
            printChar('u');
            print("\u{001B}[0m");
        } else {
            printChar('f');
        }
        print(" ");
    }
}

pub fn sysInfo() void {
    print("\nSytem information:");
    debug("number of cores", bootboot.numcores, 1);
}
