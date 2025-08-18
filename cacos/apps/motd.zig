const db = @import("libs/lib-debug.zig");
const fs = @import("libs/lib-fs.zig");
const console = @import("libs/lib-console.zig");
const mem = @import("libs/lib-memory.zig");

//entry point
export fn _start() void {
    //open the motd.txt file
    const node = fs.open("/assets/motd");

    //we create a buffer, read into it and then print it in one go (two syscalls)
    const buffer: []u8 = mem.alloc(node.size); //we allocate as many bytes as needed
    defer mem.free(buffer); //we must free the buffer when we are done with it

    //fill the buffer with the file content
    node.readToBuffer(0, node.size, buffer);

    //print the buffer
    console.print(buffer);
}
