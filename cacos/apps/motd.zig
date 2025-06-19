const db = @import("libs/lib-debug.zig");
const fs = @import("libs/lib-fs.zig");
const console = @import("libs/lib-console.zig");
const mem = @import("libs/lib-memory.zig");

//entry point
export fn _start() callconv(.C) void {
    //open the motd.txt file
    const node = fs.open("motd.txt");
    db.print("\nnode size: ");
    db.debugValue(node.size, 1);

    //print the motd: naive solution, it is slow because for each character we make a system call which are very expensive
    //for (0..node.size) |i| {
    //    //get the charachter
    //    const data: u8 = node.read(i);
    //    console.printChar(data);
    //}

    //a better solution is to create a buffer, read into it and then print it in one go (two syscalls)
    const buffer: []u8 = mem.alloc(node.size); //we allocate as many bytes as needed
    db.print("\nbuffer size: ");
    db.debugValue(buffer.len, 1);
    defer mem.free(buffer); //we must free the buffer when we are done with it

    //fill the buffer with the file content
    node.readToBuffer(0, node.size, buffer);

    //print the buffer
    console.print(buffer);
}
