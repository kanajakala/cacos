const bootboot_zig = @import("../bootboot.zig");
const list = @import("../utils/list.zig");

//Memory variables
//used to get the memory map
extern var bootboot: bootboot_zig.BOOTBOOT;

pub const max_n_pages = 4096;
pub var n_pages: usize = undefined;
pub var n_bytes: usize = undefined;

//a page is a 4096 byte chunk of memory
//the page table lists wether each block is currently written or not.
//TODO: implement a binary space partitioning allocator
var max_pages: [max_n_pages]bool = .{false} ** max_n_pages; //the biggest possible block table
pub var pages: []bool = undefined; //this will get reduced to the size of the number of actual blocks in the system

pub var mmap: []u8 = undefined; //the usable memory
//errors
pub const errors = error{
    memoryMapNotFound,
    noMemoryLeft,
    outsideBounds,
};

///returns a continous slice of memory to be used
pub fn alloc() ![]u8 {
    //the first page is a fallback page and is reserved
    for (1..n_pages - 1) |i| {
        if (!pages[i]) {
            pages[i] = true;
            return mmap[i * 4096 .. (i + 1) * 4096];
        }
    }
    return errors.noMemoryLeft;
}

pub fn free(page: []u8) !void {
    pages[@intFromPtr(page) / 4096] = false;
}

pub fn init() !void {
    //check if the memory region is valid
    if (bootboot.mmap.getType() != bootboot_zig.MMapType.free or !bootboot.mmap.isFree()) return errors.memoryMapNotFound;

    //we update the number of available nodes
    n_pages = @min(bootboot.mmap.getSizeIn4KiBPages(), max_n_pages);
    n_bytes = @min(bootboot.mmap.getSizeInBytes(), max_n_pages * 4096);

    //the memory can be accessed as an array ( write -> mmap[index] = value  | read -> print(mmap[index]))
    mmap = @as([*]u8, @ptrFromInt(bootboot.mmap.getPtr()))[0..n_bytes];
    //update the node list to be the correct size
    pages = max_pages[0..n_pages];

    //initialize the lists system
    try list.init();
}
