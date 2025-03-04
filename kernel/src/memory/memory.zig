const limine = @import("limine");
const fmt = @import("std").fmt;
const pages = @import("pages.zig");
const db = @import("../core/debug.zig");
const scr = @import("../drivers/screen.zig");

// code taken from https://github.com/yhyadev/yos
export var memory_map_request: limine.MemoryMapRequest = .{};
pub var memory_region: []u8 = undefined;

//Higher half code ?
export var hhdm_request: limine.HhdmRequest = .{};
pub var hhdm_offset: usize = undefined;

pub var virtual_offset: usize = undefined;

/// Convert physical addresses to higher half virtual addresses by adding the higher half direct
/// map offset
pub inline fn virtualFromPhysical(address: u64) u64 {
    return address + hhdm_offset;
}
//might not work
pub inline fn virtualFromIndex(index: u64) u64 {
    return virtual_offset + index;
}

fn hhinit() void {
    const maybe_hhdm_response = hhdm_request.response;

    if (maybe_hhdm_response == null) {
        db.panic("could not retrieve information about the higher half kernel");
    }

    const hhdm_response = maybe_hhdm_response.?;

    hhdm_offset = hhdm_response.offset;
}

pub fn init() void {
    const maybe_memory_map_response = memory_map_request.response;

    if (maybe_memory_map_response == null) {
        db.panic("\nCould not fetch RAM info\n");
    }
    const memory_map_response = maybe_memory_map_response.?;
    var best_memory_region: ?[]u8 = null;

    hhinit();

    for (memory_map_response.entries()) |memory_map_entry| {
        if (memory_map_entry.kind == .usable and (best_memory_region == null or memory_map_entry.length > best_memory_region.?.len)) {
            best_memory_region = @as([*]u8, @ptrFromInt(virtualFromPhysical(memory_map_entry.base)))[0..memory_map_entry.length];
            virtual_offset = virtualFromPhysical(memory_map_entry.base);
        }
    }

    if (best_memory_region == null) {
        db.panic("could not find a usable memory region");
    }

    memory_region = best_memory_region.?;
    //pages.init();
}
