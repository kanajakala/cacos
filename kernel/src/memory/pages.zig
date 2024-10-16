const mem = @import("memory.zig");
const cpu = @import("../core/cpu.zig");

pub const page_size: usize = 4000;
pub const number_of_pages: usize = 200_000;

//page table
pub var pt: [number_of_pages]bool = undefined;

//basically null page
//this is used to avoid errors mostly :D
//will  get better later
pub var empty_page: Page = undefined;

pub const errors = error{
    outOfPages,
};

//States a page can be in
//you shouldn't be able to write to a protected page
pub const States = enum {
    protected,
    normal,
};

pub const Page = struct {
    state: States,
    address: usize,
    data: []u8,
};

pub fn alloc(page_table: *[number_of_pages]bool) !Page {
    //we start at one because 1 is reserved
    for (1..number_of_pages) |i| {
        if (!page_table[i]) {
            page_table[i] = true;
            return Page{ .state = States.normal, .address = i * page_size, .data = mem.memory_region[i * page_size .. i * page_size + page_size] };
        }
    }
    return errors.outOfPages;
}

pub fn getFreePages(page_table: *[number_of_pages]bool) usize {
    var tot: usize = 0;
    for (page_table) |page| {
        if (!page) {
            tot += 1;
        }
    }
    return tot;
}

pub fn free(page: Page, page_table: *[number_of_pages]bool) void {
    if (page.address == 0) {
        page_table[0] = false;
    } else {
        page_table[page.address / page_size] = false;
    }
}

pub fn clearPage(page: Page) void {
    for (page.data[0..page_size]) |i| {
        page.data[i] = 0;
    }
}

pub fn init() void {
    empty_page = Page{ .state = States.protected, .address = 0, .data = mem.memory_region[0..page_size] };
    //the first page is reserved
    pt = .{false} ** number_of_pages;
    pt[0] = true;
}
