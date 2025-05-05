const mem = @import("../core/memory.zig");

const db = @import("../utils/debug.zig");

//errors
const errors = error{
    outsideBounds,
    overflow,
};

//the number of pages a list can use
pub const list_size: usize = 16;

pub fn List(comptime T: type) type {
    return struct {
        const Self = @This();
        const page_size = 4096 / @sizeOf(T);

        size: usize, //the size of the list in elements
        n_pages: usize, //the number of pages storing the data
        address_list: [list_size]*[page_size]T, //where the lists are stored

        ///creates and initializes a new list
        pub fn init() !Self {
            return Self{ .size = 0, .n_pages = 0, .address_list = .{undefined} ** list_size };
        }

        ///read content of the list at an index
        pub fn read(self: Self, index: usize) !T {
            //checks
            if (index > self.size) return errors.outsideBounds;
            //get the address of the page which needs to be read
            const page_index = @divFloor(index, page_size);
            const page: *[page_size]T = self.address_list[page_index];
            return page[@mod(index, page_size)];
        }

        ///reads a slice from the list NOTE: the start and end index must be on the same page
        pub fn readSlice(self: Self, i_start: usize, i_end: usize) ![]T {
            //checks
            if (i_start >= self.size or i_end >= self.size) return errors.outsideBounds;

            //get the address of the page which needs to be read
            const page_index = @divFloor(@min(i_start, i_end), page_size);
            const page: *[page_size]T = self.address_list[page_index];
            return page[@mod(@min(i_start, i_end), page_size)..@mod(@max(i_start, i_end), page_size)];
        }

        ///creates room for n more elements
        pub fn expand(self: *Self, n: usize) !void {
            for (0..n) |_| {
                //check if we need to allocate a new page for the list
                if (@rem(self.size, page_size) == 0) {
                    //checks
                    if (self.n_pages >= list_size) return errors.overflow;
                    const page: []u8 = try mem.alloc();
                    self.address_list[@divFloor(self.size, page_size)] = @as(*[page_size]T, @alignCast(@ptrCast(page)));
                    self.n_pages += 1;
                }
                self.size += 1;
            }
        }

        pub fn write(self: *Self, data: T, index: usize) !void {
            //allocate space if the list is too short
            if (index >= self.size) {
                try self.expand(index - self.size + 1);
            }

            //get the address of the page which needs to be written to
            const page_index = @divFloor(index, page_size);
            const page: *[page_size]T = self.address_list[page_index];
            page[@rem(index, page_size)] = data;
        }

        ///put data at the end of the list
        pub fn append(self: *Self, data: T) !void {
            _ = data;
            _ = self;
        }

        ///put a slice at the end of the list
        pub fn appendSlice(self: *Self, data: []T) !void {
            _ = data;
            _ = self;
        }

        ///moves a chunk of data of a width at an index by an offset
        pub fn move(self: *Self, index: usize, width: usize, offset: usize) !void {
            //checks
            if (index > self.size) return errors.outsideBounds;
            if (index == self.size) return self.append(0);

            //add room for the elements
            try self.expand(offset + width);

            //naive approach, TODO: optimize by copying chunks of memory
            for (index..self.size) |i_reverse| {
                const i = self.size - index - i_reverse;
                _ = i;
            }
        }

        pub fn insert(self: *Self, data: T, index: usize) !void {
            //checks
            _ = self;
            _ = data;
            _ = index;
        }

        //TODO: pub fn pop(self: *List) !void {}
        //TODO: pub fn clear(self: *List) !void {} //clears the whole list
    };
}

pub fn init() !void {
    var test_list = try List(u8).init();
    try test_list.write('D', 0);
    try test_list.write('A', 1);
    try test_list.write('C', 2);
    //try test_list.insert('E', 3);

    db.print("\nReading values:\n");
    for (0..3) |i| {
        const data: u8 = try test_list.read(i);
        db.printChar(data);
    }
}
