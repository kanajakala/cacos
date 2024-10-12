const std = @import("std");

const fs = @import("../core/fs.zig");
const db = @import("../core/debug.zig");

//load all files into the filesystem
pub fn init() void {
    fs.createDir("assets", fs.root_address);
    const os_asset_dir = fs.addressFromName("assets");
    fs.loadEmbed("../apps/assets/dancing_man/01.ppm", os_asset_dir, "01.ppm");
    fs.loadEmbed("../apps/assets/dancing_man/02.ppm", os_asset_dir, "02.ppm");
    fs.loadEmbed("../apps/assets/dancing_man/03.ppm", os_asset_dir, "03.ppm");
    //fs.loadEmbed("../apps/assets/dancing_man/04.ppm", os_asset_dir, "04.ppm");
    fs.loadEmbed("../apps/assets/dancing_man/05.ppm", os_asset_dir, "05.ppm");
    fs.loadEmbed("../apps/assets/dancing_man/06.ppm", os_asset_dir, "06.ppm");
    fs.loadEmbed("../apps/assets/dancing_man/07.ppm", os_asset_dir, "07.ppm");
    fs.loadEmbed("../apps/assets/dancing_man/08.ppm", os_asset_dir, "08.ppm");
    fs.loadEmbed("../apps/assets/dancing_man/09.ppm", os_asset_dir, "09.ppm");
    fs.loadEmbed("../apps/assets/dancing_man/10.ppm", os_asset_dir, "10.ppm");
    fs.loadEmbed("../apps/assets/dancing_man/11.ppm", os_asset_dir, "11.ppm");
    fs.loadEmbed("../apps/assets/dancing_man/12.ppm", os_asset_dir, "12.ppm");
    fs.loadEmbed("../apps/assets/dancing_man/13.ppm", os_asset_dir, "13.ppm");
    fs.loadEmbed("../apps/assets/dancing_man/14.ppm", os_asset_dir, "14.ppm");
    fs.loadEmbed("../apps/assets/dancing_man/15.ppm", os_asset_dir, "15.ppm");
    //fs.loadEmbed("../apps/assets/dancing_man/16.ppm", os_asset_dir, "16.ppm");
    fs.loadEmbed("../apps/assets/dancing_man/17.ppm", os_asset_dir, "17.ppm");
    fs.loadEmbed("../apps/assets/dancing_man/18.ppm", os_asset_dir, "18.ppm");
    fs.loadEmbed("../apps/assets/dancing_man/19.ppm", os_asset_dir, "19.ppm");
    fs.loadEmbed("../apps/assets/dancing_man/20.ppm", os_asset_dir, "20.ppm");
    fs.loadEmbed("../apps/assets/dancing_man/21.ppm", os_asset_dir, "21.ppm");
    fs.loadEmbed("../apps/assets/dancing_man/22.ppm", os_asset_dir, "22.ppm");
    fs.loadEmbed("../apps/assets/dancing_man/23.ppm", os_asset_dir, "23.ppm");
    fs.loadEmbed("../apps/assets/dancing_man/24.ppm", os_asset_dir, "24.ppm");
    fs.loadEmbed("../apps/assets/dancing_man/25.ppm", os_asset_dir, "25.ppm");
    fs.loadEmbed("../apps/assets/dancing_man/26.ppm", os_asset_dir, "26.ppm");
    fs.loadEmbed("../apps/assets/dancing_man/27.ppm", os_asset_dir, "27.ppm");
    fs.loadEmbed("../apps/assets/dancing_man/28.ppm", os_asset_dir, "28.ppm");
    fs.loadEmbed("../apps/assets/dancing_man/29.ppm", os_asset_dir, "29.ppm");
    fs.loadEmbed("../apps/assets/dancing_man/30.ppm", os_asset_dir, "30.ppm");
    fs.loadEmbed("../apps/assets/dancing_man/31.ppm", os_asset_dir, "31.ppm");
    fs.loadEmbed("../apps/assets/dancing_man/32.ppm", os_asset_dir, "32.ppm");
}
