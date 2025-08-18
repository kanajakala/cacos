const db = @import("libs/lib-debug.zig");
const fs = @import("libs/lib-fs.zig");
const console = @import("libs/lib-console.zig");
const mem = @import("libs/lib-memory.zig");

///get all the files in a directory
export fn _start() void {
    //the directory name is in cac_in
    const cac_in = fs.open("cac_in");

    //we create a buffer, read into it and then print it in one go (two syscalls)
    const buffer: []u8 = mem.alloc(cac_in.size); //we allocate as many bytes as needed
    defer mem.free(buffer); //we must free the buffer when we are done with it

    //fill the buffer with the file content
    cac_in.readToBuffer(0, cac_in.size, buffer);

    const name = console.wordInString(1,buffer);

    const node = fs.open(name);
    const children = node.getChilds();


    for (children) |child| {
        const len = fs.nameToBuffer(child, buffer);
        console.print(buffer[0..len]);
        console.print("\n");
    }

    // nodes.free(&pages.pt);
}
