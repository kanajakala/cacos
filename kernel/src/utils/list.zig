const db = @import("../utils/debug.zig");
const mem = @import("../core/memory.zig");

//lists
//scheme of how a list works in memory
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

//errors
const list_errors = error{
    outsideBounds,
};

pub const lists_per_page = 128; //each page contains n lists, must be a power of 2
pub const list_size = 4096 / lists_per_page;

//each page allocated for a list is split
//we need to keep track of how full the the current page is
pub var current_subpage: u8 = 0;
pub var current_page: *[4096]u8 = undefined;

pub fn List(comptime T: type) type {
    return struct {
        const Self = @This();
        const page_size = 4096 / @sizeOf(T);

        size: usize, //the size of the list in elements
        address_list: *[list_size / @sizeOf(T)]T, //where the lists are stored

        ///creates and initializes a new list
        pub fn init() !Self {
            //assign the address_list to the correct sub-page, if there is no space left on the current page, assign a new page

            //check if we need to assign a new page for the subpages
            if (current_subpage >= lists_per_page) {
                current_page = @ptrCast(try mem.alloc());
                current_subpage = 0;
            }

            const address_list: *[list_size / @sizeOf(T)]T = @alignCast(@ptrCast(current_page[(current_subpage) * list_size .. (current_subpage + 1) * list_size]));

            return Self{ .size = 0, .address_list = address_list };
        }

        ///read content of the list at an index
        pub fn read(self: Self, index: usize) !T {
            //checks
            if (index >= self.size) return list_errors.outsideBounds;
            //get the address of the page which needs to be read
            const page_index = @divFloor(index, page_size);
            const page: *[page_size]T = @ptrFromInt(self.address_list[page_index]);
            return page[@mod(index, page_size)];
        }

        ///reads a slice from the list NOTE: the start and end index must be on the same page
        pub fn readSlice(self: Self, i_start: usize, i_end: usize) ![]T {
            //checks
            if (i_start >= self.size or i_end >= self.size) return list_errors.outsideBounds;

            //get the address of the page which needs to be read
            const page_index = @divFloor(@min(i_start, i_end), page_size);
            const page: *[page_size]T = @ptrFromInt(self.address_list[page_index]);
            return page[@mod(@min(i_start, i_end), page_size)..@mod(@max(i_start, i_end), page_size)];
        }

        ///put data at the end of the list
        pub fn append(self: *Self, data: T) !void {
            //check if we need to allocate a new page for the list
            if (@rem(self.size, page_size) == 0) {
                const page: []u8 = try mem.alloc();
                self.address_list[@divFloor(self.size, page_size)] = @intFromPtr(@as(*[page_size]T, @alignCast(@ptrCast(page))));
            }

            //get the address of the page which needs to be written to
            const page_index = @divFloor(self.size, page_size);
            const page: *[page_size]T = @ptrFromInt(self.address_list[page_index]);
            page[@mod(self.size, page_size)] = data;

            self.size += 1;
        }

        ///put a slice at the end of the list
        pub fn pushSlice(self: *Self, data: []T) !void {
            //check if we need to allocate a new page for the list
            if (@rem(self.size, page_size) == 0) {
                const page: []u8 = try mem.alloc();
                self.address_list[@divFloor(self.size, page_size)] = @intFromPtr(@as(*[page_size]T, @alignCast(@ptrCast(page))));
            }

            //get the address of the page which needs to be written to
            const page_index = @divFloor(self.size, page_size);
            const page: *[page_size]T = @ptrFromInt(self.address_list[page_index]);

            //copy the slice to the page
            //we could write each element of the slice one by one but it is much faster this way
            @memcpy(page[@mod(self.size, page_size) .. @mod(self.size, page_size) + data.len], data);

            self.size += data.len;
        }

        //TODO: pub fn pop(self: *List) !void {}
        //TODO: pub fn clear(self: *List) !void {} //clears the whole list
    };
}

pub fn init() !void {
    current_page = @ptrCast(try mem.alloc());
}
