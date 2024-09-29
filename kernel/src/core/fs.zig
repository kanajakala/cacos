///The most simple filesystem I can do
///All files get deleted upon reboot as they live in ram
const db = @import("../core/debug.zig");

const pages = @import("../memory/pages.zig");
const memory = @import("../memory/memory.zig");
const mem = &memory.memory_region;

const block_size = pages.page_size;

//The super block contains the start address of each file
//Each file is 4kb in size
var super_block: pages.Page = undefined;

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
    var buffer: [15]u8 = undefined;
    db.print(db.stringFromMem(faddress.start + 1, length, &buffer));
    return file;
}

pub fn init() void {
    super_block = pages.alloc(&pages.pageTable) catch pages.empty_page;
    const testf = createFile("Namefe");
    testf.data[0] = 0xee;
    db.print("\nStart of test file\n");
    db.printMem(mem.*[testf.address .. testf.address + 10]);
    db.print("Start of super block\n");
    var buffer: [10]u8 = undefined;
    db.print(db.numberToStringHex(db.readFromMem(u64, super_block.start), &buffer));
}
