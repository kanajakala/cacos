const mem = @import("../memory/memory.zig");
const scr = @import("../drivers/screen.zig");
const db = @import("../cpu/debug.zig");
const pages = @import("../memory/pages.zig");

fn format(str: []const u8, value: usize, suffix: []const u8) void {
    var buffer: [20]u8 = undefined;
    scr.print(" -> ", scr.primary);
    scr.print(str, scr.text);
    if (value != 0) scr.print(db.numberToStringDec(value, &buffer), scr.errorc);
    scr.print(suffix, scr.text);
    scr.newLine();
}

pub fn run() void {
    scr.newLine();
    const mem_length = mem.memory_region.len / 1_000_000;
    const mem_free: usize = pages.getFreePages(&pages.pageTable) * pages.page_size / 1_000_000;
    scr.print("\n   .d8888b.            .d8888b.   .d88888b.   .d8888b.  ", scr.accent);
    format("Coherent and Cohesive Operating System by kanajakala", 0, "");
    scr.print("  d88P  Y88b          d88P  Y88b d88P\" \"Y88b d88P  Y88b ", scr.accent);
    format("Total memory: ", mem_length, " Mb");
    scr.print("  888    888          888    888 888     888 Y88b.      ", scr.accent);
    format("Free memory: ", mem_free, " Mb");
    scr.print("  888         8888b.  888        888     888  \"Y888b.   \n", scr.accent);
    scr.print("  888            \"88b 888        888     888     \"Y88b. \n", scr.accent);
    scr.print("  888    888 .d888888 888    888 888     888       \"888 \n", scr.accent);
    scr.print("  Y88b  d88P 888  888 Y88b  d88P Y88b. .d88P Y88b  d88P \n", scr.accent);
    scr.print("   \"Y8888P\"  \"Y888888  \"Y8888P\"   \"Y88888P\"   \"Y8888P\"  \n", scr.accent);
}
