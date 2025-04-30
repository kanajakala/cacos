const bootboot_zig = @import("../bootboot.zig");

//DEBUG: TODO: remove after debug
const db = @import("../debug.zig");

//Memory variables
//used to get the memory map
extern var bootboot: bootboot_zig.BOOTBOOT;

pub const max_n_pages = 4096;
pub var n_pages: usize = undefined;
pub var n_bytes: usize = undefined;

//a block is a 4096 byte chunk of memory
//the block table lists wether each block is currently written or not.
//TODO: implement a binary space partitioning allocator
var max_pages: [max_n_pages]bool = .{false} ** max_n_pages; //the biggest possible block table
pub var pages: []bool = undefined; //this will get reduced to the size of the number of aactual blocks in the system

pub var mmap: []u8 = undefined; //the usable memory

//stack
pub const stacks_per_page = 4; //each page contains n stacks, must be a multiple of 2
pub const stack_pages = 8; //number of pages allocated for stacks
pub const n_stacks = stacks_per_page * stack_pages; //total number of stacks
pub const stack_size = 4096 / (stacks_per_page * 8);
pub var stacks: [n_stacks]*[stack_size]u64 = undefined; //with 4 stacks per page and 8 pages allocated for stacks: 32 pointers to a slices of memory of length stack size in bytes
pub var stack_map: [n_stacks]bool = .{false} ** n_stacks;

//errors
pub const errors = error{
    memoryMapNotFound,
    noMemoryLeft,
    noStacksLeft,
    stackFull,
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

//scheme of how stacks work in memory
//                      ┌──────────────────────────────────────────────────┐
//                      │                                                  │
// ┌page──────────────┐ │ ┌page───────────┐ ┌page───────────┐       ┌page──▼────────┐
// │                  │ │ │               │ │               │       │               │
// │┌subpage┐┌subpage┐│ │ │╔data═════════╗│ │╔data═════════╗│       │╔data═════════╗│
// ││       ││       ││ │ │║             ║│ │║             ║│       │║             ║│
// ││ ──────────────────┘ │║             ║│ │║             ║│       │║             ║│
// ││       ││       ││   │║             ║│ │║             ║│       │╚═════════════╝│
// │└───────┘└───────┘│   │║             ║│ │║             ║│  ...  │               │
// │┌subpage┐┌subpage┐│   │║             ║│ │║             ║│       │               │
// ││       ││       ││   │║             ║│ │╚═════════════╝│       │               │
// ││       ││ │ │   ││   │║             ║│ │               │       │               │
// ││       ││ │ │   ││   │║             ║│ │               │       │               │
// │└───────┘└─│─│───┘│   │╚═════════════╝│ │               │       │               │
// └───────────│─│────┘   └▲──────────────┘ └▲──────────────┘       └───────────────┘
//             └─│─────────┘                 │
//               └───────────────────────────┘

pub const Stack = struct {
    size: usize, //the size of the stack in elements
    stack_address_list: *[stack_size]u64, //where the stacks are stored

    ///creates and initilaizes a new stack
    pub fn init() !Stack {
        //alocate a page to store the data and write its address to the right stack address list
        //find a stack address list
        var stack_address_list: *[stack_size]u64 = undefined;
        for (0..n_stacks) |i| {
            if (!stack_map[i]) {
                stack_map[i] = true;
                stack_address_list = stacks[i];

                return Stack{ .size = 0, .stack_address_list = stack_address_list };
            }
        }
        return errors.noStacksLeft;
    }

    ///read content of the stack at an index
    pub fn read(self: *Stack, index: usize) !u8 {
        //checks
        if (index >= self.size) return errors.outsideBounds;

        //get the address of the page which needs to be read
        const page_index = @divFloor(index, 4096);
        const page: *[4096]u8 = @ptrFromInt(self.stack_address_list[page_index]);
        return page[@mod(index, 4096)];
    }

    ///reads a slice from the stack NOTE: the start and end index must be on the same page
    pub fn readSlice(self: *Stack, i_start: usize, i_end: usize) ![]u8 {
        //checks
        if (i_start >= self.size or i_end >= self.size) return errors.outsideBounds;

        //get the address of the page which needs to be read
        const page_index = @divFloor(@min(i_start, i_end), 4096);
        const page: *[4096]u8 = @ptrFromInt(self.stack_address_list[page_index]);
        return page[@mod(@min(i_start, i_end), 4096)..@mod(@max(i_start, i_end), 4096)];
    }

    ///push the data on top of the stack
    pub fn push(self: *Stack, data: u8) !void {
        //check if we need to allocate a new page for the stack
        if (@rem(self.size, 4096) == 0) {
            const page: []u8 = try alloc();
            self.stack_address_list[@divFloor(self.size, 4096)] = @intFromPtr(@as(*[4096]u8, @alignCast(@ptrCast(page))));
        }

        //get the address of the page which needs to be written to
        const page_index = @divFloor(self.size, 4096);
        const page: *[4096]u8 = @ptrFromInt(self.stack_address_list[page_index]);
        page[@mod(self.size, 4096)] = data;

        self.size += 1;
    }

    ///push a slice on top of the stack
    pub fn pushSlice(self: *Stack, data: []u8) !void {
        //check if we need to allocate a new page for the stack
        if (@rem(self.size, 4096) == 0) {
            const page: []u8 = try alloc();
            self.stack_address_list[@divFloor(self.size, 4096)] = @intFromPtr(@as(*[4096]u8, @alignCast(@ptrCast(page))));
        }

        //get the address of the page which needs to be written to
        const page_index = @divFloor(self.size, 4096);
        const page: *[4096]u8 = @ptrFromInt(self.stack_address_list[page_index]);
        @memcpy(page[@mod(self.size, 4096) .. @mod(self.size, 4096) + data.len], data);

        self.size += data.len;
    }

    //TODO: pub fn pop(self: *Stack) !void {}
    //TODO: pub fn clear(self: *Stack) !void {} //clears the whole stack
};

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

    //alocate pages for the stack
    for (0..stack_pages) |i| {
        const page: []u8 = alloc() catch mmap[0..0];
        for (0..stacks_per_page) |j| {
            stacks[(i * stacks_per_page) + j] = @alignCast(@ptrCast(page[j * stack_size .. (j + 1) * stack_size]));
        }
    }
}
