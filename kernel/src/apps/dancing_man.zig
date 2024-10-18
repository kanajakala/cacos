const scr = @import("../drivers/screen.zig");
const console = @import("../drivers/console.zig");

const db = @import("../core/debug.zig");
const scheduler = @import("../core/scheduler.zig");
const fs = @import("../core/fs.zig");

var id: usize = 0;
const n_of_images = 8;

pub fn run() void {
    //scuffed way of initializing an array of slices
    //the empty array will then be replaced with actual data
    var images: [n_of_images]scr.Image = .{undefined} ** n_of_images;
    var buffer: [3]u8 = undefined;
    //create the images
    for (0..n_of_images) |i| {
        const name = db.numberToStringDec(i + 1, &buffer);
        const data: []u8 = fs.getData(fs.addressFromName(name));
        images[i] = scr.createImagefromFile(data, name) catch blk: {
            console.printErr("Unsupported image type");
            break :blk scr.empty_image;
        };
    }
    //run the animation
    //used to slow the game down
    // const slower: usize = 1_000_000;
    // var slow: usize = slower;

    for (images) |img| {
        db.print("\n\nname outside the loop: ");
        db.print(img.name);
        scr.drawImage(500, 100, img);
    }

    //while (scheduler.running[id]) {
    //    const i: usize = 7;
    //    while (i < n_of_images) {
    //        if (slow == 0) {
    //            scr.drawImage(500, 100, images[i]);
    //            slow = slower;
    //        } else slow -= 1;
    //    }
    //}
}

pub fn start() void {
    scr.clear();
    id = scheduler.getFree();
    const app = scheduler.Process{ .id = id, .function = &run };
    scheduler.append(app);
}
