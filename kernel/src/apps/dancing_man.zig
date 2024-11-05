const scr = @import("../drivers/screen.zig");
const console = @import("../drivers/console.zig");

const db = @import("../core/debug.zig");
const scheduler = @import("../core/scheduler.zig");
const fs = @import("../core/fs.zig");

var id: usize = 0;
const n_of_images = 8;

var images: [n_of_images]scr.Image = .{undefined} ** n_of_images;
pub fn run() void {
    var buffer: [3]u8 = undefined;
    //create the images
    for (0..n_of_images) |i| {
        const name = db.numberToStringDec(i + 1, &buffer);
        const data: []u8 = fs.getData(fs.addressFromName(name));
        images[i] = scr.createImagefromFile(data, name) catch blk: {
            console.printErr("Unsupported image type");
            break :blk scr.empty_image;
        };
        db.print("\n -> Name in struct: ");
        db.print(images[i].name);
    }
    //run the animation
    //used to slow the game down
    // const slower: usize = 1_000_000;
    // var slow: usize = slower;
    db.print(images[0].name);
    db.print(images[2].name);
    db.print(images[3].name);
    db.print(images[4].name);

    for (0..n_of_images) |i| {
        db.print("\n\nname outside the loop: ");
        db.print(images[i].name);
        scr.drawImage(500, 100, images[i]);
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
