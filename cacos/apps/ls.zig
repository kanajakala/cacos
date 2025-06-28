const db = @import("libs/lib-debug.zig");
const fs = @import("libs/lib-fs.zig");
const console = @import("libs/lib-console.zig");
const mem = @import("libs/lib-memory.zig");

///get all the files in a directory
export fn _start() callconv(.C) void {
    //the directory name is in cac_in
    const cac_in = fs.open("/sys/cac-in");

    //we create a buffer, read into it and then print it in one go (two syscalls)
    const buffer: []u8 = mem.alloc(cac_in.size); //we allocate as many bytes as needed
    defer mem.free(buffer); //we must free the buffer when we are done with it

    //fill the buffer with the file content
    cac_in.readToBuffer(0, cac_in.size, buffer);

    //print the buffer
    console.print("\ncontent of cac-in: ");
    console.print(buffer);

    const name = console.wordInString(1,buffer);
console.print("\nname: ");
    console.print(name);


    // for (0..n_of_childs) |i| {
    //     const address: u64 = db.readFromMem(u64, nodes.address + (i * 8) + 1);
    //     const name = fs.getName(address);
    //     switch (fs.getType(address)) {
    //         fs.Type.directory => console.printColor(name, 0xffa300),
    //         fs.Type.text => console.printColor(name, 0x00ffff),
    //         fs.Type.binary => console.printColor(name, 0xaa00bb),
    //         fs.Type.executable => console.printColor(name, 0xbb44ff),
    //         fs.Type.image => console.printColor(name, 0xab03fd),
    //     }
    // }
    //
    // nodes.free(&pages.pt);
}
