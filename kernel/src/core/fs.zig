///The most simple filesystem I can do
///All files get deleted upon reboot as they live in ram
const db = @import("../core/debug.zig");

const pages = @import("../memory/pages.zig");
const memory = @import("../memory/memory.zig");
const mem = &memory.memory_region;

pub const block_size = pages.page_size;

//The super block contains the start address of each file
//Each file is 4kb in size
pub var super_block: pages.Page = undefined;

pub var number_of_files: usize = 0;

pub var root_address: u64 = undefined;

pub var current_dir: u64 = 0;

pub const max_path_size = 255;

pub const FileType = enum {
    file,
    directory,
};

const File = struct {
    ftype: FileType,
    address: u64,
    name_length: u8, //length of the name of the file in bytes (characters)
    parent: u64,
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

pub fn addressFromSb(index: usize) u64 {
    return db.readFromMem(u64, super_block.start + index * 8);
}

pub fn addressFromName(name: []const u8) u64 {
    for (0..number_of_files) |i| {
        const address: u64 = addressFromSb(i);
        if (db.hashStr(getName(address)) == db.hashStr(name)) {
            return address;
        }
    }
    return 0;
}

pub fn writeData(where: u64, data: []const u8) void {
    //we add 2 because the first byte stores the type and the second the length of the name
    const name_length = mem.*[where + 1];
    @memcpy(mem.*[where + name_length + 10 .. where + data.len + name_length + 10], data[0..]);
}

pub fn getData(where: u64) []u8 {
    const name_length = mem.*[where + 1];
    return mem.*[where + name_length + 10 .. where + block_size];
}

pub fn createFile(name: []const u8, parent: u64) void {
    //convert name.len to u8
    const length: u8 = @truncate(name.len);

    //allocate space for a new file
    const faddress: pages.Page = pages.alloc(&pages.pageTable) catch pages.empty_page;

    //creation of the file
    //we add 2 to  the start because we also need to store the type which takes one byte and the length of the name which takes 1 bytes
    const file = File{ .ftype = FileType.file, .address = faddress.start, .name_length = length, .parent = parent, .data = mem.*[faddress.start + length + 10 .. faddress.end] };

    //we write the address of the file to the super block
    writeFileToSuperBlock(file);

    //write the type as a file to the first byte of the file
    mem.*[faddress.start] = 0;
    //write the length of the name to the second byte of the file
    mem.*[faddress.start + 1] = length;

    //set the parent
    db.writeToMem64(u64, faddress.start + 2, parent);
    //write the name to the file
    db.writeStringToMem(faddress.start + 2 + 8, name);

    debugFiles();
}

pub fn createDir(name: []const u8, parent: u64) void {
    //convert name.len to u8
    const length: u8 = @truncate(name.len);

    //allocate space for a new directory
    const faddress: pages.Page = pages.alloc(&pages.pageTable) catch pages.empty_page;

    //creation of the directory
    //we add 2 to  the start because we also need to store the type which takes one byte and the length of the name which takes 1 bytes
    const dir = File{ .ftype = FileType.directory, .address = faddress.start, .name_length = length, .parent = parent, .data = mem.*[faddress.start + length + 10 .. faddress.end] };

    //we write the address of the directory to the super block
    writeFileToSuperBlock(dir);

    //set the type as a directory in the first byte
    mem.*[faddress.start] = 1;
    //write the length of the name to the second byte of the file
    mem.*[faddress.start + 1] = length;

    //set the parent
    db.writeToMem64(u64, faddress.start + 2, parent);
    //write the name to the directory
    db.writeStringToMem(faddress.start + 10, name);

    debugFiles();
}

pub fn debugFile(file: File) void {
    db.print("-------------------------------------------------\n");
    file.data[0] = 0xee;
    db.print("Address of file\n");
    var buffer: [8]u8 = undefined;
    db.print(db.numberToStringHex(file.address, &buffer));
    db.print("\nname of the file\n");
    db.print(getName(db.readFromMem(u64, super_block.start + file.address / 4000)));
    db.print("\n-------------------------------------------------\n\n");
}

pub fn debugFiles() void {
    db.print("\nALL FILES IN SUPER BLOCK\n");
    for (0..number_of_files) |i| {
        db.print("\n");
        const address = addressFromSb(i);
        var buffer: [16]u8 = undefined;
        db.print("address of file n");
        db.print(db.numberToStringDec(i, &buffer));
        db.print(": ");
        db.print(db.numberToStringHex(address, &buffer));
        db.print("\nname of the file: ");
        db.print(getName(address));
        db.print("\nparent of the file: ");
        //const name_length = mem.*[address + 1];
        db.print(db.numberToStringHex(getParent(address), &buffer));
        db.print("\nRaw memory at this address: \n");
        db.printMem(mem.*[address .. address + 40]);
        db.printArrayFull(mem.*[address .. address + 40]);
        db.print("\n");
    }
    db.print("\n\n");
}

pub fn getName(where: u64) []const u8 {
    const length: u8 = mem.*[where + 1];
    return db.stringFromMem(where + 10, length);
}

pub fn getType(where: u64) FileType {
    const type_byte: u8 = mem.*[where];
    if (type_byte == 1) {
        return FileType.directory;
    } else {
        return FileType.file;
    }
}

pub fn getParent(where: u64) u64 {
    return db.readFromMem(u64, where + 2);
}

pub fn getDataStart(where: u64) u64 {
    const name_length = mem.*[where + 1];
    return where + name_length + 10;
}

pub fn init() void {
    super_block = pages.alloc(&pages.pageTable) catch pages.empty_page;
    //creation of root
    createDir("/", 0);
    const address = addressFromName("/");
    root_address = address;
    current_dir = root_address;
}
