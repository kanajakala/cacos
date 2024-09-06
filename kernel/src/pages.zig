const cpu = @import("cpu.zig");
const mem = @import("memory.zig");

pub export const page_size: usize = 8000;
pub export const number_of_pages: usize = 100_000;

pub export var pageTable: [number_of_pages]bool = .{false} ** number_of_pages;

pub const errors = error{
    outOfPages,
};

pub const Page = packed struct {
    start: usize,
    end: usize,
};

pub fn alloc(pt: *[number_of_pages]bool) !Page {
    for (pt, 0..number_of_pages) |page, i| {
        if (!page) {
            pt[i] = true;
            var buffer: [20]u8 = undefined;
            cpu.print("Allocation start: ");
            cpu.print(cpu.numberToStringHex(i * page_size, &buffer));
            cpu.printChar('\n');
            cpu.print("Allocation end: ");
            cpu.print(cpu.numberToStringHex(i * page_size + page_size, &buffer));
            cpu.printChar('\n');
            return Page{ .start = i * page_size, .end = i * page_size + page_size };
        }
    }
    return errors.outOfPages;
}
