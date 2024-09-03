const limine = @import("limine");
const fmt = @import("std").fmt;
const cpu = @import("cpu.zig");
const screen = @import("screen.zig");

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

pub fn printMem() void {
    var buffer: [20]u8 = undefined;
    const length = cpu.numberToString(memory_region.len, &buffer);
    screen.print("\nlength of memory: ", 0xeeeeee);
    cpu.print("length of memory: ");

    screen.print(length, 0xffaa32);
    cpu.print(length);

    screen.printChar('\n', 0xff0000);
    cpu.printChar('\n');
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
}
