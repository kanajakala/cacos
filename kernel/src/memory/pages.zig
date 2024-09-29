const mem = @import("memory.zig");
const cpu = @import("../core/cpu.zig");

pub export const page_size: usize = 4000;
pub export const number_of_pages: usize = 200_000;

pub export var pageTable: [number_of_pages]bool = .{false} ** number_of_pages;

pub const errors = error{
    outOfPages,
};

pub const Page = packed struct {
    start: usize,
    end: usize,
};

pub const empty_page = Page{ .start = 0, .end = 0 };

pub fn alloc(pt: *[number_of_pages]bool) !Page {
    for (pt, 0..number_of_pages) |page, i| {
        if (!page) {
            pt[i] = true;
            return Page{ .start = i * page_size, .end = i * page_size + page_size };
        }
    }
    return errors.outOfPages;
}

pub fn getFreePages(pt: *[number_of_pages]bool) usize {
    var tot: usize = 0;
    for (pt) |page| {
        if (!page) {
            tot += 1;
        }
    }
    return tot;
}

pub fn free(page: Page, pt: *[number_of_pages]bool) void {
    if (page.start == 0) {
        pt[0] = false;
    } else {
        pt[page.start / page_size] = false;
    }
}

pub fn clearPage(page: Page) void {
    for (page.start..page.end) |i| {
        mem.memory_region[i] = 0;
    }
}
