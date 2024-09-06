const limine = @import("limine");
const fmt = @import("std").fmt;
const cpu = @import("cpu.zig");
const screen = @import("screen.zig");
const pages = @import("pages.zig");

// code taken from https://github.com/yhyadev/yos
export var memory_map_request: limine.MemoryMapRequest = .{};
pub var memory_region: []u8 = undefined;

//Higher half code ?
export var hhdm_request: limine.HhdmRequest = .{};
pub var hhdm_offset: usize = undefined;

/// Convert physical addresses to higher half virtual addresses by adding the higher half direct
/// map offset
pub inline fn virtualFromPhysical(physical: u64) u64 {
    return physical + hhdm_offset;
}

fn hhinit() void {
    const maybe_hhdm_response = hhdm_request.response;

    if (maybe_hhdm_response == null) {
        cpu.panic("could not retrieve information about the higher half kernel");
    }

    const hhdm_response = maybe_hhdm_response.?;

    hhdm_offset = hhdm_response.offset;
}

pub fn testMem(value: u8) void {
    var buffer: [20]u8 = undefined;
    const mem: pages.Page = pages.alloc(&pages.pageTable) catch |err| { //on errors
        switch (err) {
            pages.errors.outOfPages => screen.print("Error: out of pages", 0xff0000),
        }
        return;
    };
    screen.print("\nAttempting allocation of 1 page at ", 0xeeeeee);
    screen.print(cpu.numberToStringHex(mem.start, &buffer), 0xeeeeee);

    screen.print("\n -> Writing value ", 0x888888);
    screen.print(cpu.numberToStringHex(value, &buffer), 0x888888);

    var iterations: usize = 0;
    for (0..mem.end - mem.start) |j| {
        memory_region[mem.start + j] = value;
        iterations = j;
    }
    screen.print("\n -> words written: ", 0x0fbbff);
    screen.print(cpu.numberToStringDec(iterations, &buffer), 0xff0000);
    screen.print("\n -> reading word 0: ", 0x00ff00);
    screen.print(cpu.numberToStringHex(memory_region[mem.start], &buffer), 0xff0000);
    screen.print("\n -> reading word 8000 (page size): ", 0x00ff00);
    screen.print(cpu.numberToStringHex(memory_region[mem.end - 1], &buffer), 0xff0000);
    screen.print("\n -> freeing memory\n", 0xfb342);
    pages.free(mem, &pages.pageTable);
}

pub fn printMem() void {
    var buffer: [20]u8 = undefined;
    const length = cpu.numberToStringHex(memory_region.len, &buffer);
    screen.print("\nlength of memory: ", 0xeeeeee);
    screen.print(length, 0xffaa32);
    const number_of_pages = cpu.numberToStringDec(pages.number_of_pages, &buffer);
    screen.print("\nnumber of pages: ", 0xeeeeee);
    screen.print(number_of_pages, 0xffaa32);
    const page_size = cpu.numberToStringDec(pages.page_size, &buffer);
    screen.print("\npage size: ", 0xeeeeee);
    screen.print(page_size, 0xffaa32);
    screen.newLine();
}

pub fn init() void {
    cpu.print("Loading memory\n");
    const maybe_memory_map_response = memory_map_request.response;

    if (maybe_memory_map_response == null) {
        cpu.panic("\nCould not fetch RAM info\n");
    }
    const memory_map_response = maybe_memory_map_response.?;
    var best_memory_region: ?[]u8 = null;

    hhinit();

    for (memory_map_response.entries()) |memory_map_entry| {
        if (memory_map_entry.kind == .usable and (best_memory_region == null or memory_map_entry.length > best_memory_region.?.len)) {
            //best_memory_region = @as([*]u8, @ptrFromInt(memory_map_entry.base))[0..memory_map_entry.length];
            best_memory_region = @as([*]u8, @ptrFromInt(virtualFromPhysical(memory_map_entry.base)))[0..memory_map_entry.length];
        }
    }

    if (best_memory_region == null) {
        cpu.panic("could not find a usable memory region");
    }

    memory_region = best_memory_region.?;
    //pages.init();
}
