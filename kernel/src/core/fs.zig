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
    name: []const u8,
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
            db.writeToMem(u64, super_block.start + i * 8, file.address);
            return;
        }
    }
}

pub fn createFile(name: []const u8) File {
    const faddress: pages.Page = pages.alloc(&pages.pageTable) catch pages.empty_page;
    const file = File{ .address = faddress.start, .name = name, .data = mem.*[faddress.start..faddress.end] };
    writeFileToSuperBlock(file);
    return file;
}

pub fn init() void {
    super_block = pages.alloc(&pages.pageTable) catch pages.empty_page;
    const testf = createFile("test");
    testf.data[0] = 0xee;
    db.print("\nStart of test file\n");
    db.printMem(mem.*[testf.address .. testf.address + 10]);
    db.print("Start of super block\n");
    var buffer: [10]u8 = undefined;
    db.print(db.numberToStringHex(db.readFromMem(u64, super_block.start), &buffer));
}
