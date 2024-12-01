const std = @import("std");

const fs = @import("../core/fs.zig");
const db = @import("../core/debug.zig");

//load all files into the filesystem
pub fn init() void {
    fs.createFile("assets", fs.Type.directory, fs.root_address);
    fs.loadEmbed("../filesystem/binaries/test.bin", fs.root_address, "a", fs.Type.executable);
    const os_asset_dir = fs.addressFromName("assets");
    fs.loadEmbed("../filesystem/assets/dancing_man/01.ppm", os_asset_dir, "1", fs.Type.image);
    fs.loadEmbed("../filesystem/assets/dancing_man/02.ppm", os_asset_dir, "2", fs.Type.image);
    fs.loadEmbed("../filesystem/assets/dancing_man/03.ppm", os_asset_dir, "3", fs.Type.image);
    fs.loadEmbed("../filesystem/assets/dancing_man/04.ppm", os_asset_dir, "4", fs.Type.image);
    fs.loadEmbed("../filesystem/assets/dancing_man/05.ppm", os_asset_dir, "5", fs.Type.image);
    fs.loadEmbed("../filesystem/assets/dancing_man/06.ppm", os_asset_dir, "6", fs.Type.image);
    fs.loadEmbed("../filesystem/assets/dancing_man/07.ppm", os_asset_dir, "7", fs.Type.image);
    fs.loadEmbed("../filesystem/assets/dancing_man/08.ppm", os_asset_dir, "8", fs.Type.image);
    fs.loadEmbed("../filesystem/assets/dancing_man/09.ppm", os_asset_dir, "9", fs.Type.image);
    fs.loadEmbed("../filesystem/assets/dancing_man/10.ppm", os_asset_dir, "10", fs.Type.image);
    fs.loadEmbed("../filesystem/assets/dancing_man/11.ppm", os_asset_dir, "11", fs.Type.image);
    fs.loadEmbed("../filesystem/assets/dancing_man/12.ppm", os_asset_dir, "12", fs.Type.image);
    fs.loadEmbed("../filesystem/assets/dancing_man/13.ppm", os_asset_dir, "13", fs.Type.image);
    fs.loadEmbed("../filesystem/assets/dancing_man/14.ppm", os_asset_dir, "14", fs.Type.image);
    fs.loadEmbed("../filesystem/assets/dancing_man/15.ppm", os_asset_dir, "15", fs.Type.image);
    fs.loadEmbed("../filesystem/assets/dancing_man/16.ppm", os_asset_dir, "16", fs.Type.image);
    fs.loadEmbed("../filesystem/assets/dancing_man/17.ppm", os_asset_dir, "17", fs.Type.image);
    fs.loadEmbed("../filesystem/assets/dancing_man/18.ppm", os_asset_dir, "18", fs.Type.image);
    fs.loadEmbed("../filesystem/assets/dancing_man/19.ppm", os_asset_dir, "19", fs.Type.image);
    fs.loadEmbed("../filesystem/assets/dancing_man/20.ppm", os_asset_dir, "20", fs.Type.image);
    fs.loadEmbed("../filesystem/assets/dancing_man/21.ppm", os_asset_dir, "21", fs.Type.image);
    fs.loadEmbed("../filesystem/assets/dancing_man/22.ppm", os_asset_dir, "22", fs.Type.image);
    fs.loadEmbed("../filesystem/assets/dancing_man/23.ppm", os_asset_dir, "23", fs.Type.image);
    fs.loadEmbed("../filesystem/assets/dancing_man/24.ppm", os_asset_dir, "24", fs.Type.image);
    fs.loadEmbed("../filesystem/assets/dancing_man/25.ppm", os_asset_dir, "25", fs.Type.image);
    fs.loadEmbed("../filesystem/assets/dancing_man/26.ppm", os_asset_dir, "26", fs.Type.image);
    fs.loadEmbed("../filesystem/assets/dancing_man/27.ppm", os_asset_dir, "27", fs.Type.image);
    fs.loadEmbed("../filesystem/assets/dancing_man/28.ppm", os_asset_dir, "28", fs.Type.image);
    fs.loadEmbed("../filesystem/assets/dancing_man/29.ppm", os_asset_dir, "29", fs.Type.image);
    fs.loadEmbed("../filesystem/assets/dancing_man/30.ppm", os_asset_dir, "30", fs.Type.image);
    fs.loadEmbed("../filesystem/assets/dancing_man/31.ppm", os_asset_dir, "31", fs.Type.image);
    fs.loadEmbed("../filesystem/assets/dancing_man/32.ppm", os_asset_dir, "32", fs.Type.image);
}
