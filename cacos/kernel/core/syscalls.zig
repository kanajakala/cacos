////This is used for the apps to interface with the kernel
const fs = @import("../core/ramfs.zig");
const db = @import("../utils/debug.zig");
const isr = @import("../cpu/isr.zig");
const pic = @import("../cpu/pic.zig");
const mem = @import("../core/memory.zig");
const console = @import("../interface/console.zig");
const str = @import("../utils/strings.zig");
const std = @import("std");

//this is an enum describing all possible syscalls
//later a script will automaticaly import it into the lib-syscall
pub const Syscalls = enum(u64) {
    //console:
    print, //print a string to screen
    print_char, //print a char, usefull when the string is not hard-coded
    print_err, //prints an error

    //filesystem:
    create, //create a new node
    open, //return a File struct describing the file
    read, //read from a node
    read_to_buffer, //read to a buffer provided by the caller
    write, //write to a node
    write_from_buffer, //write from a buffer provided by the caller
    get_childs, //get all the childs of a node in a memory page
    node_name_to_buffer, //get the name of a node

    //memory:
    alloc, //allocate a page
    valloc, //allocate n bytes at ann address
    free, //free a page

    //executables:
    load, //load an elf file
    exec, //execute an elf file

    //debug:
    debug, //print a string to the debug console
    debug_value, //debug ann integer value
};

//these are the erros that a syscall can return
pub const sys_err = error {
    failed_to_print,
    no_such_file,
    index_overflow,
    unknown_syscall,
    invalid_debug_value_mode,
};

fn handle_syscall(syscall: Syscalls, arg0: u64, arg1: u64, arg2: u64, arg3: u64) sys_err!u64 {

    switch (syscall) {
        //
        //
        //
        //CONSOLE SYSTEM CALLS
        //they are used to output text to the cacos console
        //
        //in this context:
        // arg0 -> pointer to a string
        // arg1 -> length of the string
        .print => {
            db.print("\n[SYSCALL] print");
            console.print(@as([*]u8, @ptrFromInt(arg0))[0..arg1]) catch {
                db.printErr("[Print syscall] failed to print string");
            };
        },
        //in this context:
        // arg0 -> pointer to a string
        // arg1 -> length of the string
        .print_err => {
            db.print("\n[SYSCALL] print error");
            console.printErr(@as([*]u8, @ptrFromInt(arg0))[0..arg1]) catch {
                db.printErr("[Print err syscall]  failed to print string");
            };
        },
        //in this context:
        // arg0 -> a char
        .print_char => {
            db.print("\n[SYSCALL] print_char");
            console.printChar(@truncate(arg0), console.text_color) catch {};
        },
        //
        //
        //
        //FILESYSTEM CALLS:
        //they are used to modify and read the cacos filesystem
        //
        //in this context:
        // arg0 -> pointer to the path of the file
        // arg1 -> length of the name
        .open => {
            db.print("\n[SYSCALL] open");

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
                    db.printErr("\n[Open syscall] failed to open node");
                    break :blk 0;
                };

            const Node = fs.open(id) catch fs.root;
            const file = File{ .id = id, .ftype = @intFromEnum(Node.ftype), .size = @truncate(Node.data.size), .parent = 0 };
            return @as(u64, @bitCast(file));
        },
        //
        //in this context
        // arg0 -> index in the file
        // arg1 -> id of the node
        .read => {
            db.print("\n[SYSCALL] read");
            const Node = fs.open(arg1) catch fs.root;
            return Node.data.read(arg0) catch 0;
        },
        //
        //in this context
        // arg0 -> index in the file
        // arg1 -> length of the data to  copy
        // arg2 -> pointer to a buffer
        // arg3 -> id of the node
        .read_to_buffer => {
            db.print("\n[SYSCALL] read to buffer");
            const Node = fs.open(arg3) catch fs.root;
            const data = Node.data.readSlice(arg0, arg0 + arg1) catch {
                db.printErr("\n[ERROR][SYSCALL] read to buffer: couldn't read slice");
                unreachable;
            };
            const buffer = @as([*]u8, @ptrFromInt(arg2))[0..arg1];
            @memcpy(buffer, data);
        },
        .write => return 0xcac,
        .write_from_buffer => return 0xcac,
        //
        //in this context
        // arg0 -> id of the node we need to get the children of
        // TODO: optimize this as this is a common operation and is very slow
        .get_childs => {
            db.print("\n[SYSCALL] get children");
            
            //the ids of the nodes will be written to a memory page
            //the id is u16 and so takes up two bytes of space
            //we can have up to 4096 children by allocating two pages, which is plenty
            //if there are more children they will simply not be included
            const Allocation = packed struct(u64) { address: u48, length: u16 }; //we assume the address and length fit in their respective integer representations
                                                                                 //here the length will also be the number of children

            //we allocate a pages
            const base_page: []u8 = mem.allocm(2) catch mem.mmap[0..4096*2];
            //we convert the allocated slice to a slice of u16 to fit the file ids
            const page: []u16 = @as([*]u16, @alignCast(@ptrCast(base_page.ptr)))[0..base_page.len];

            //the node we get the children of
            const parent = fs.open(arg0) catch fs.root;

            //we check every file :O this is kinda slow but will do for now
             var n_childs: usize = 0;
            for (0..fs.node_list.size) |i| {
                //we check if the node being tested has the right parent, is so we write it to the buffer
                //the tested node is a child if its path without the last node (it's name) is the same as the parent
                const node = fs.node_list.read(i) catch fs.root; 

                if (str.equal(str.cut('/', node.path, str.Directions.left), parent.path) and node.id != 0) {
                    page[n_childs] = node.id;
                    n_childs += 1;
                }
            }
            // db.debug("children page address at syscall time", @intFromPtr(page.ptr), 0);

            return @bitCast(Allocation{.address = @truncate(@intFromPtr(page.ptr)), .length = @truncate(@min(page.len, n_childs))});
        },
        //
        //in this context
        // arg0 -> id of the node
        // arg1 -> address of the name buffer
        .node_name_to_buffer => {
            db.print("\n[SYSCALL] get node name");
            const node = fs.open(arg0) catch fs.root;
            @memcpy(@as([*]u8, @ptrFromInt(arg1))[0..node.name.len], node.name[0..node.name.len]);
            return node.name.len;
        },
        //
        //MEMORY SYSTEM CALLS:
        //they are used to allocate and free memory in various ways
        //
        //in this context
        // arg0 -> number of bytes to allocate
        .alloc => {
            db.print("\n[SYSCALL] alloc");
            const Allocation = packed struct(u64) { address: u48, length: u16 }; //we assume the address and length fit in their respective integer representations
            const page = mem.allocm(std.math.divCeil(u64, arg0, 4096) catch 1) catch unreachable;
            return @bitCast(Allocation{ .address = @truncate(@intFromPtr(page.ptr)), .length = @truncate(page.len) });
        },
        //
        //
        //
        //DEBUG SYSTEM CALLS
        //they are used to output text to the debug console
        //
        //in this context:
        // arg0 -> pointer to a string
        // arg1 -> length of the string
        .debug => {
            db.print(@as([*]u8, @ptrFromInt(arg0))[0..arg1]);
        },
        //in this context:
        // arg0 -> value
        // arg1 -> mode
        .debug_value => {
            switch (arg1) {
                0 => db.printValue(arg0),
                1 => db.printValueDec(arg0),
                2 => db.printChar(@truncate(arg0)),
                else => return sys_err.invalid_debug_value_mode,
            }
        },
        else => return sys_err.unknown_syscall,
    }
    return 0;
}


fn handler(stack_frame: *isr.InterruptStackFrame) callconv(.c) void {
    //Interrupts must end at some point
    defer pic.primary.endInterrupt();

    //the return value will be passed to the caller

    const syscall: Syscalls = @enumFromInt(stack_frame.r8);
    const arg0: u64 = stack_frame.r9;
    const arg1: u64 = stack_frame.r10;
    const arg2: u64 = stack_frame.r11;
    const arg3: u64 = stack_frame.r12;

    if (handle_syscall(syscall,arg0,arg1,arg2,arg3)) |result| {
        //return value in r8
        asm volatile (""
            : //no output
            : [value] "{r8}" (result), //put value in r8
            [err] "{r9}" (0) //no error
        );

    } else |err| {
        db.print("\nhandler caught error");
        //return error
        asm volatile (""
            : //no output
            : [value] "{r8}" (0), //put no value in r8
            [err] "{r9}" (@intFromError(err) + 1)
        );
    }
}

pub fn init() void {
    //enable the syscall interrupt in the pic
    pic.primary.enable(2);

    //set the function used to handle syscalls
    isr.handle(2, handler);
}
