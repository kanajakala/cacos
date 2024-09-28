///The most simple filesystem I can do
///All files get deleted upon reboot as they live in ram

const db = @import("../core/debug.zig");

const pages = @import("../memory/pages.zig");
const memory = @import("../memory/memory.zig.zig");
const mem = &memory.memory_region;

const block_size = pages.page_size;

//The super block contains the start address of each file
//Each file is 4kb in size
const super_block = pages.alloc(mem).start;

const File = struct {
    address: u64,
    name: []const u8,
    data: []u8,
}

pub fn writeFileToSuperBlock(File) {
    //we divide by  8 because the memory is defined in bytes but an address is
    //8 bytes wide
    for (block_size / 8) |i| {
        if (debug.sum(mem[super_block..super_block+8]))
    }
}

//creates a file and return its start address
pub def createFile(name: []const u8) u64 {
    return 0;
}

