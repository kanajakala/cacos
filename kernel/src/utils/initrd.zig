const fs = @import("../core/ramfs.zig");
const db = @import("../utils/debug.zig");
const time = @import("../cpu/time.zig");
const cpu = @import("../cpu/cpu.zig");
const strings = @import("../utils/strings.zig");
const std = @import("std");

const BOOTBOOT = @import("../bootboot.zig").BOOTBOOT;
pub const max_size = @import("../bootboot.zig").INITRD_MAXSIZE * 1_000_000;
extern var bootboot: BOOTBOOT;

pub const errors = error{
    noNameFound,
};

//the initrd is in tar format
//we need to unpack it

//in tar the size is specified as a string of ASCII with the file size in octal
fn oct2bin(str: []const u8) u32 {
    var n: u32 = 0;
    for (0..str.len) |i| {
        n *= 8;
        n += @as(u32, str[i]) - '0';
    }
    return n;
}

// returns file size and pointer to file data in out
fn tar_lookup(archive: [*]u8, filename: [*:0]const u8, out: *[*]u8) u32 {
    var ptr: [*]u8 = archive;

    while (std.mem.eql(u8, ptr[257..262], "ustar")) {
        const filesize = oct2bin(ptr + 0x7c, 11);

        if (std.mem.eql(u8, std.mem.span(ptr), std.mem.span(filename))) {
            out.* = ptr + 512;
            return filesize;
        }

        ptr += (((filesize + 511) / 512) + 1) * 512;
    }

    return 0;
}

fn find_name(data: *[100]u8) []const u8 {
    var name_size: usize = 0;
    for (data) |char| {
        if (char == 0) break;
        name_size += 1;
    }
    return @constCast(data[0..name_size]);
}

pub fn unpack() !void {
    const initrd: *[max_size]u8 = @as(*[max_size]u8, @ptrFromInt(bootboot.initrd_ptr));

    //this variable contains the address of the start of the header of the current file
    var offset: usize = 0;
    var i: usize = 0;

    while (offset + 2048 < bootboot.initrd_size - 1024) : (i += 1) { //the end of the file is signified with two blocks of 521bytes filled with zeroes

        //we need to get the data of the current file
        const name_full = find_name(@ptrCast(initrd[offset .. offset + 100]));
        const size: u32 = oct2bin(initrd[offset + 124 .. offset + 135]);
        const right: strings.Directions = strings.Directions.right;
        if (strings.equal(name_full, "cacos.elf") or strings.equal(strings.take('/', name_full, right), "..") or strings.equal(strings.take('/', name_full, right), ".")) {
            offset += (((size + 511) / 512) + 1) * 512;
            continue;
        } //we don't need to load the kernel into the kernel
        const data: []u8 = initrd[offset + 512 .. offset + 512 + size];
        const ftype = switch (initrd[156]) {
            5 => fs.Ftype.dir,
            else => fs.Ftype.text,
        };
        db.print("\n\nFull name: ");
        db.print(name_full);

        const parent_name = strings.take('/', strings.cut('/', name_full, right), right); //we remove the name of the file and take the first name
        db.print("\n -> parent name: ");
        db.print(parent_name);

        const name = strings.take('/', name_full, right);

        const parent_id = fs.idFromName(parent_name) catch 0;

        //then we create the corresponding file in the fs
        var node: fs.Node = try fs.Node.create(name, ftype, parent_id);

        try node.appendSlice(data);

        //we go to the next file
        offset += (((size + 511) / 512) + 1) * 512;
    }
}
