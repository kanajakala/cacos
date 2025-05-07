const mem = @import("../core/memory.zig");

const db = @import("../utils/debug.zig");

//errors
const errors = error{
    outsideBounds,
    overflow,
    copyBackwardsOverflow,
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
        pub inline fn read(self: Self, index: usize) !T {
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

        pub inline fn write(self: *Self, data: T, index: usize) !void {
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
        pub inline fn append(self: *Self, data: T) !void {
            try self.write(data, self.size + 1);
        }

        ///put a slice at the end of the list
        pub inline fn appendSlice(self: *Self, data: []T) !void {
            inline for (0..data.len) |i| {
                try self.append(data[i]);
            }
        }

        ///copy data at index to dest
        ///NOTE: it can expand the list if needed
        ///NOTE: it will owerwrite what was written at dest
        pub inline fn copy(self: *Self, source: usize, dest: usize) !void {
            try self.write(try self.read(source), dest);
        }

        ///copies data to a temporary page to avoid copy copy superposition issues
        inline fn copyChunkBackwards(self: *Self, index: usize, width: usize, dest: usize) !void {
            if (width >= page_size) return errors.copyBackwardsOverflow;

            //make space for the copied data:
            if (dest + width >= self.size) try self.expand(width - (self.size - dest));

            db.print("\nCopying backwards!");

            //allocate a page as the buffer
            const buffer: *[page_size]T = @alignCast(@ptrCast(try mem.alloc()));

            if (width + @rem(index, page_size) >= page_size) {
                const part_one_size = page_size - @rem(index, page_size);
                const part_two_size = width - part_one_size;

                const part_one: []T = self.address_list[index / page_size][index .. index + part_one_size];
                const part_two: []T = self.address_list[(index + width) / page_size][0..part_two_size];

                @memcpy(buffer[0..part_one_size], part_one);
                @memcpy(buffer[part_one_size .. part_one_size + part_two_size], part_two);
            } else {
                @memcpy(buffer[0..width], self.address_list[index / page_size][index .. index + width]);
            }

            db.print("\nstatte of buffer after data fill:");
            db.debugPage(buffer, 1);

            //buffer is now full, we can copy to the destination
            if (width + @rem(dest, page_size) >= page_size) {
                const part_one_size = page_size - @rem(dest, page_size);
                const part_two_size = width - part_one_size;

                @memcpy(self.address_list[dest / page_size][dest .. dest + part_one_size], buffer[0..part_one_size]);
                @memcpy(self.address_list[(dest + width) / page_size][0..part_two_size], buffer[part_one_size .. part_one_size + part_two_size]);
            } else {
                @memcpy(self.address_list[dest / page_size][dest .. dest + width], buffer[0..width]);
            }
        }

        ///moves a chunk of data of a width at an index by an offset
        pub inline fn copyChunk(self: *Self, index: usize, width: usize, dest: usize) !void {
            //checks
            if (index > self.size) return errors.outsideBounds;
            if (index + width > dest) {
                try self.copyChunkBackwards(index, width, dest);
            } else {

                //naive approach, TODO: optimize by copying chunks of memory
                for (index..index + width) |i| {
                    db.print("\ncopying");
                    try self.copy(i, dest + i);
                }
            }
        }

        pub fn insert(self: *Self, data: T, index: usize) !void {
            if (index > self.size) return errors.outsideBounds;
            try self.copyChunk(index, self.size - index, index + 1);
            try self.write(data, index);
        }

        //TODO: pub fn clear(self: *List) !void {} //clears the whole list
    };
}

pub fn init() !void {
    var test_list = try List(u8).init();
    try test_list.write('a', 0);
    try test_list.write('c', 1);
    try test_list.write('d', 2);
    try test_list.write('e', 3);
    try test_list.write('f', 4);
    try test_list.write('g', 5);

    try test_list.insert('b', 1);

    db.print("\nReading values:\n");
    for (0..test_list.size) |i| {
        const data: u8 = try test_list.read(i);
        db.printChar(data);
        if (data == 0) db.printChar('X');
    }
}
