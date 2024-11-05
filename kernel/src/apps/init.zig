const std = @import("std");

const fs = @import("../core/fs.zig");
const db = @import("../core/debug.zig");

const test_app = @import("test_app_loading.zig");

//load all files into the filesystem
pub fn init() void {
    fs.createDir("assets", fs.root_address);
    const os_asset_dir = fs.addressFromName("assets");
    fs.loadEmbed("../apps/assets/dancing_man/01.ppm", os_asset_dir, "1");
    fs.loadEmbed("../apps/assets/dancing_man/02.ppm", os_asset_dir, "2");
    fs.loadEmbed("../apps/assets/dancing_man/03.ppm", os_asset_dir, "3");
    fs.loadEmbed("../apps/assets/dancing_man/04.ppm", os_asset_dir, "4");
    fs.loadEmbed("../apps/assets/dancing_man/05.ppm", os_asset_dir, "5");
    fs.loadEmbed("../apps/assets/dancing_man/06.ppm", os_asset_dir, "6");
    fs.loadEmbed("../apps/assets/dancing_man/07.ppm", os_asset_dir, "7");
    fs.loadEmbed("../apps/assets/dancing_man/08.ppm", os_asset_dir, "8");
    fs.loadEmbed("../apps/assets/dancing_man/09.ppm", os_asset_dir, "9");
    fs.loadEmbed("../apps/assets/dancing_man/10.ppm", os_asset_dir, "10");
    fs.loadEmbed("../apps/assets/dancing_man/11.ppm", os_asset_dir, "11");
    fs.loadEmbed("../apps/assets/dancing_man/12.ppm", os_asset_dir, "12");
    fs.loadEmbed("../apps/assets/dancing_man/13.ppm", os_asset_dir, "13");
    fs.loadEmbed("../apps/assets/dancing_man/14.ppm", os_asset_dir, "14");
    fs.loadEmbed("../apps/assets/dancing_man/15.ppm", os_asset_dir, "15");
    fs.loadEmbed("../apps/assets/dancing_man/16.ppm", os_asset_dir, "16");
    fs.loadEmbed("../apps/assets/dancing_man/17.ppm", os_asset_dir, "17");
    fs.loadEmbed("../apps/assets/dancing_man/18.ppm", os_asset_dir, "18");
    fs.loadEmbed("../apps/assets/dancing_man/19.ppm", os_asset_dir, "19");
    fs.loadEmbed("../apps/assets/dancing_man/20.ppm", os_asset_dir, "20");
    fs.loadEmbed("../apps/assets/dancing_man/21.ppm", os_asset_dir, "21");
    fs.loadEmbed("../apps/assets/dancing_man/22.ppm", os_asset_dir, "22");
    fs.loadEmbed("../apps/assets/dancing_man/23.ppm", os_asset_dir, "23");
    fs.loadEmbed("../apps/assets/dancing_man/24.ppm", os_asset_dir, "24");
    fs.loadEmbed("../apps/assets/dancing_man/25.ppm", os_asset_dir, "25");
    fs.loadEmbed("../apps/assets/dancing_man/26.ppm", os_asset_dir, "26");
    fs.loadEmbed("../apps/assets/dancing_man/27.ppm", os_asset_dir, "27");
    fs.loadEmbed("../apps/assets/dancing_man/28.ppm", os_asset_dir, "28");
    fs.loadEmbed("../apps/assets/dancing_man/29.ppm", os_asset_dir, "29");
    fs.loadEmbed("../apps/assets/dancing_man/30.ppm", os_asset_dir, "30");
    fs.loadEmbed("../apps/assets/dancing_man/31.ppm", os_asset_dir, "31");
    fs.loadEmbed("../apps/assets/dancing_man/32.ppm", os_asset_dir, "32");
    test_app.run();
}
