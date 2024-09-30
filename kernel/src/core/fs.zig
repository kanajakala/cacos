///The most simple filesystem I can do
///All files get deleted upon reboot as they live in ram
const db = @import("../core/debug.zig");

const pages = @import("../memory/pages.zig");
const memory = @import("../memory/memory.zig");
const mem = &memory.memory_region;

const block_size = pages.page_size;

//The super block contains the start address of each file
//Each file is 4kb in size
pub var super_block: pages.Page = undefined;

pub var number_of_files: usize = 0;

const File = struct {
    address: u64,
    name_length: u8, //length of the name of the file in bytes (characters)
    data: []u8,
};

fn checkEmpty(index: usize) bool {
    if (db.sum(mem.*[super_block.start + index .. super_block.start + 8 + index]) == 0) {
        return true;
    }
    return false;
}

pub fn writeFileToSuperBlock(file: File) void {
    //we divide by  8 because the memory is defined in bytes but an address is
    //8 bytes wide
    for (0..block_size / 8) |i| {
        //if the current block is empty
        if (checkEmpty(i * 8)) {
            db.writeToMem64(u64, super_block.start + i * 8, file.address);
            number_of_files += 1;
            return;
        }
    }
}

pub fn createFile(name: []const u8) File {
    //convert name.len to u16
    const length: u8 = @truncate(name.len);
    //allocate space for a new file
    const faddress: pages.Page = pages.alloc(&pages.pageTable) catch pages.empty_page;
    //creation of the file
    //we add 2 to  the start because we also need to store the length of the name which takes 2 bytes
    const file = File{ .address = faddress.start, .name_length = length, .data = mem.*[faddress.start + length + 1 .. faddress.end] };
    //we write the address of the file to the super block
    writeFileToSuperBlock(file);
    //write the length of the name to the first to bytes of the file
    mem.*[faddress.start] = length;
    //write the name to the file
    db.writeStringToMem(faddress.start + 1, name);
    return file;
}

pub fn debugFile(file: File) void {
    db.print("-------------------------------------------------\n");
    file.data[0] = 0xee;
    db.print("Address of file\n");
    var buffer: [8]u8 = undefined;
    db.print(db.numberToStringHex(file.address, &buffer));
    db.print("\nname of the file\n");
    db.print(getName(db.readFromMem(u64, super_block.start)));
    db.print("-------------------------------------------------\n\n");
}

pub fn getName(where: u64) []const u8 {
    const length: u8 = mem.*[where];
    var buffer: [15]u8 = undefined;
    return db.stringFromMem(where + 1, length + 1, &buffer);
}

pub fn init() void {
    super_block = pages.alloc(&pages.pageTable) catch pages.empty_page;
    for (0..10) |_| {
        _ = createFile("abc");
    }
}
