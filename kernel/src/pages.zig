const cpu = @import("cpu.zig");
const mem = @import("memory.zig");

pub export var page_size: usize = undefined;
pub export var number_of_pages: usize = undefined;

pub export var pageTable: [100_000]bool = .{false} ** 100_000;

const pagesErrors = error{
    outOfPages,
};

pub fn alloc(pt: *[100_000]bool) !usize {
    for (pt, 0..number_of_pages) |page, i| {
        if (!page) {
            pt[i] = true;
            return i * page_size;
        }
    }
    return pagesErrors.outOfPages;
}

pub fn init() void {
    page_size = 8000;
    number_of_pages = 100_000;
}
