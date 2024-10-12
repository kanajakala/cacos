const std = @import("std");

const mem = @import("../memory/memory.zig");
const pages = @import("../memory/pages.zig");

const scr = @import("../drivers/screen.zig");

const db = @import("../core/debug.zig");
const scheduler = @import("../core/scheduler.zig");

const id: usize = 0;
const n_of_images = 32;

pub fn run() void {
    var images: [n_of_images]pages.Page = .{pages.empty_page} ** n_of_images;

    //load all images to memory
    for (0..n_of_images) |i| {
        //string concatenation
        var buffer = [_]u8{undefined} ** 100;
        const path = std.fmt.bufPrint(&buffer, "./assets/dancing_man/{s}.ppm", .{i}) catch "./assets/dancing_man/01.ppm";

        images[i] = db.loadFileToMem(path);
    }
}

pub fn start() void {
    scr.clearScreen();
    id = scheduler.getFree();
    const app = scheduler.Process{ .id = id, .function = &run };
    scheduler.append(app);
}
