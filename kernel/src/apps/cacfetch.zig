const mem = @import("../memory.zig");
const screen = @import("../screen.zig");
const db = @import("../debug.zig");
const pages = @import("../pages.zig");

fn format(str: []const u8, value: usize, suffix: []const u8) void {
    var buffer: [20]u8 = undefined;
    screen.print(" -> ", screen.primary);
    screen.print(str, screen.text);
    if (value != 0) screen.print(db.numberToStringDec(value, &buffer), screen.errorc);
    screen.print(suffix, screen.text);
    screen.newLine();
}

pub fn run() void {
    screen.newLine();
    const mem_length = mem.memory_region.len / 1_000_000;
    const mem_free: usize = pages.getFreeMem(&pages.pageTable) * pages.page_size / 1_000_000;
    screen.print("\n   .d8888b.            .d8888b.   .d88888b.   .d8888b.  ", screen.accent);
    format("Coherent and Cohesive Operating System by kanajakala", 0, "");
    screen.print("  d88P  Y88b          d88P  Y88b d88P\" \"Y88b d88P  Y88b ", screen.accent);
    format("Total memory: ", mem_length, " Mb");
    screen.print("  888    888          888    888 888     888 Y88b.      ", screen.accent);
    format("Free memory: ", mem_free, " Mb");
    screen.print("  888         8888b.  888        888     888  \"Y888b.   \n", screen.accent);
    screen.print("  888            \"88b 888        888     888     \"Y88b. \n", screen.accent);
    screen.print("  888    888 .d888888 888    888 888     888       \"888 \n", screen.accent);
    screen.print("  Y88b  d88P 888  888 Y88b  d88P Y88b. .d88P Y88b  d88P \n", screen.accent);
    screen.print("   \"Y8888P\"  \"Y888888  \"Y8888P\"   \"Y88888P\"   \"Y8888P\"  \n", screen.accent);
}
