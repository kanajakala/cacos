////This is used for the apps to interface with the kernel
const fs = @import("../core/ramfs.zig");
const db = @import("../utils/debug.zig");
const isr = @import("../cpu/isr.zig");
const pic = @import("../cpu/pic.zig");
const mem = @import("../core/memory.zig");
const console = @import("../interface/console.zig");
const std = @import("std");

//this is an enum describing all possible syscalls
//later a script will automaticaly import it into the lib-syscall
pub const Syscalls = enum(u64) {
    print, //print a string to screen
    print_char, //print a char, usefull when the string is not hard-coded
    create, //create a new node
    open, //return a File struct describing the file
    read, //read from a node
    read_to_buffer, //read to a buffer provided by the caller
    write, //write to a node
    write_from_buffer, //write from a buffer provided by the caller
    alloc, //allocate a page
    malloc, //allocate multiple contigous pages
    valloc, //allocate n bytes at ann address
    free, //free a page
    load, //load an elf file
    exec, //execute an elf file
    debug, //print a string to the debug console
    debug_value, //debug ann integer value
};

fn handler(stack_frame: *isr.InterruptStackFrame) callconv(.C) void {
    //Interrupts must end at some point
    defer pic.primary.endInterrupt();

    //the return value will be passed to the caller
    var value: u64 = 0;

    const syscall: Syscalls = @enumFromInt(stack_frame.r8);
    const arg0: u64 = stack_frame.r9;
    const arg1: u64 = stack_frame.r10;
    const arg2: u64 = stack_frame.r11;
    const arg3: u64 = stack_frame.r12;

    switch (syscall) {
        .print => {
            db.print("\n[SYSCALL] print");
            //in this context:
            // arg0 -> pointer to a string
            // arg1 -> length of the string
            console.print(@as([*]u8, @ptrFromInt(arg0))[0..arg1]) catch {
                db.printErr("Print syscall: failed to print string, debugging context:");
            };
        },
        .print_char => {
            db.print("\n[SYSCALL] print_char");
            //in this context:
            // arg0 -> a char
            console.printChar(@truncate(arg0), console.text_color) catch {};
        },
        .open => {
            db.print("\n[SYSCALL] open");
            //in this context:
            // arg0 -> pointer to the name of the file
            // arg1 -> length of the name

            //this is an intermediary representation for the return
            //it then gets packed into an int to convey all the relevant information
            const File = packed struct(u64) {
                id: u16, //id of the node
                ftype: u16, //type of the node
                size: u16, //size of the node in bytes
                parent: u16, //id of the parent of the node
            };
            
            const name: []const u8 = @as([*]u8, @ptrFromInt(arg0))[0..arg1];
            const id: u16 = fs.idFromName(name) catch 
                blk: {
                    db.printErr("\nOpen syscall: failed to open node");
                    break :blk 0;
                };
            
            const Node = fs.open(id) catch fs.root;
            const file = File{ .id = id, .ftype = @intFromEnum(Node.ftype), .size = @truncate(Node.data.size), .parent = Node.parent };
            value = @as(u64, @bitCast(file));
        },
        .read => {
            db.print("\n[SYSCALL] read");
            //in this context
            // arg0 -> index in the file
            // arg1 -> id of the node
            const Node = fs.open(arg1) catch fs.root;
            value = Node.data.read(arg0) catch 0;
        },
        .read_to_buffer => {
            db.print("\n[SYSCALL] read to buffer");
            //in this context
            // arg0 -> index in the file
            // arg1 -> length of the data to  copy
            // arg2 -> pointer to a buffer
            // arg3 -> id of the node
            const Node = fs.open(arg3) catch fs.root;
            const data = Node.data.readSlice(arg0, arg0 + arg1) catch {
                db.printErr("\n[ERROR][SYSCALL] read to buffer: couldn't read slice");
                unreachable;
            };
            const buffer = @as([*]u8, @ptrFromInt(arg2))[0..arg1];
            @memcpy(buffer, data);
        },
        .write => value = 0xcac,
        .alloc => {
            db.print("\n[SYSCALL] alloc");
            //in this context
            // arg0 -> number of bytes to allocate
            const Allocation = packed struct(u64) { address: u48, length: u16 }; //we assume the address and length fit in their respective integer representations
            const page = mem.allocm(std.math.divCeil(u64, arg0, 4096) catch 1) catch unreachable;
            const allocation = Allocation{ .address = @truncate(@intFromPtr(page.ptr)), .length = @truncate(page.len) };
            value = @bitCast(allocation);
        },
        .debug => {
            //in this context:
            // arg0 -> pointer to a string
            // arg1 -> length of the string
            db.print(@as([*]u8, @ptrFromInt(arg0))[0..arg1]);
        },
        .debug_value => {
            //in this context:
            // arg0 -> value
            // arg1 -> mode
            switch (arg1) {
                0 => db.printValue(arg0),
                1 => db.printValueDec(arg0),
                2 => db.printChar(@truncate(arg0)),
                else => db.printErr("Syscall debug value: invalid mode (must be 0 or 1)"),
            }
        },
        else => value = 0xdada,
    }

    //return value
    asm volatile (""
        : //no output
        : [value] "{r8}" (value), //put value in r8
    );
}

pub fn init() void {
    //enable the syscall interrupt in the pic
    pic.primary.enable(2);

    //set the function used to handle syscalls
    isr.handle(2, handler);
}
