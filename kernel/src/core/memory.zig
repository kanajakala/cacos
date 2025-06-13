const bootboot_zig = @import("../bootboot.zig");
const db = @import("../utils/debug.zig");

//Memory variables
//used to get the memory map
extern var bootboot: bootboot_zig.BOOTBOOT;

pub var n_pages: usize = undefined;
pub var n_bytes: usize = undefined;
pub var used_pages: usize = 0;
pub var offset: usize = 0;

//a page is a 4096 byte chunk of memory
//the page table lists wether each block is currently written or not.
//TODO: implement a binary space partitioning allocator

//the start of usable memory in blocks
pub var mem_start: u64 = undefined;
pub var pages: []u1 = undefined;

pub var mmap: []u8 = undefined; //the usable memory

//errors
pub const errors = error{
    mem_map_not_found,
    mem_out_of_memory,
    mem_outside_bounds,
    mem_region_not_free,
};

///returns a continous slice of memory to be used
pub fn alloc() ![]u8 {
    //the first page is a fallback page and is reserved
    for (1..n_pages - 1) |i| {
        if (pages[i] == 0) {
            pages[i] = 1;
            used_pages += 1;
            return mmap[i * 4096 .. (i + 1) * 4096];
        }
    }
    return errors.mem_out_of_memory;
}

///checks if a region is free
pub fn checkRegion(start: usize, width: usize) bool {
    //we need to find which blocks correspond to this region
    const block_start = start / 4096;
    const block_end = (start + width) / 4096;

    //check for a continous slice
    for (block_start..block_end) |j| {
        if (pages[j] == 1) {
            return false;
        }
    }
    return true;
}

///sets the page from start to start+n to be state (free or not)
pub fn setState(state: u1, start: usize, n: usize) !void {
    //check for overflwo
    if (start >= n_pages or start + n >= n_pages) return errors.mem_outside_bounds;
    for (start..start + n) |i| {
        pages[i] = state;
    }
    switch (state) {
        1 => used_pages += n,
        0 => used_pages -= n,
    }
}

///returns a continous slice of memory to be used that spans multiple pages (Allocate-Multiple)
///TODO: refactor because this is ugly, but it works
pub fn allocm(n: usize) ![]u8 {
    var i: usize = 0;
    var found: bool = false;
    //find a suitable region
    for (0..n_pages - n) |_| {
        found = checkRegion(i * 4096, n * 4096);
        if (found) break;
        i += 1;
    }
    if (found) {
        try setState(1, i, n);
        return mmap[i * 4096 .. (i + n) * 4096];
    } else {
        return errors.mem_out_of_memory;
    }
}

///returns a slice of memory starting at the virtual address of width (Virtual-Allocation)
///TODO: check for collisions
pub fn valloc(address: usize, width: usize) ![]u8 {
    //we need to find which blocks correspond to this region
    const block_start = address / 4096;
    const block_end = (address + width) / 4096;

    //check for overflow:
    if (address >= n_bytes or address + width >= n_bytes) return errors.mem_outside_bounds;

    //check if the region is free
    if (!checkRegion(address, width)) return errors.mem_region_not_free;

    //we set these blocks as used
    try setState(1, block_start, block_start - block_end + 1);

    //we return the region
    return mmap[address .. address + width];
}

pub fn free(page: []u8) !void {
    used_pages -= 1;
    pages[@intFromPtr(page.ptr) / 4096] = 0;
    db.debug("value of \"@intFromPtr(page)\"", @intFromPtr(page.ptr), 0);
}

pub fn physicalFromVirtual(address: u64) u64 {
    return address + offset;
}

pub fn virtualFromPhysical(address: u64) u64 {
    return address - offset;
}

pub fn init() !void {
    //we iterate over the memory entries
    const entries: [*]bootboot_zig.MMapEnt = @ptrCast(&bootboot.mmap);

    //we try to find the best one
    var mmap_ent: bootboot_zig.MMapEnt = entries[0];
    const n_entries = 6;
    var best: usize = 0;
    var best_size: usize = mmap_ent.getSizeInBytes();
    for (0..n_entries) |i| {
        mmap_ent = entries[i];
        if (mmap_ent.getSizeInBytes() >= best_size and mmap_ent.isFree() and mmap_ent.getType() == bootboot_zig.MMapType.free) {
            best = i;
            best_size = mmap_ent.getSizeInBytes();
        }
    }
    mmap_ent = entries[best];
    //we update the number of available nodes
    n_pages = mmap_ent.getSizeIn4KiBPages();
    n_bytes = mmap_ent.getSizeInBytes();

    //the start is not 0 because the first part is used to store which pages are used
    mem_start = n_pages;

    //the memory can be accessed as a slice
    offset = mmap_ent.getPtr();
    mmap = @as([*]u8, @ptrFromInt(offset))[0..n_bytes];

    //we create the bitmap controlling the page allocation
    pages = @as([*]u1, @ptrFromInt(offset))[0..mem_start];
    //we set the first pages as used because they are used to store the pages themselves
    try setState(1, 0, mem_start / 4096);
}
