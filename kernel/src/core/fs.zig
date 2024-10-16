///The most simple filesystem I can do
///All files get deleted upon reboot as they live in ram
const db = @import("../core/debug.zig");

const pages = @import("../memory/pages.zig");
const memory = @import("../memory/memory.zig");
const mem = &memory.memory_region;

pub const block_size = pages.page_size;

//The super block contains the start address of each file
//Each block is 4kb in size

pub const max_files = 1000;
pub var super_block: [max_files]pages.Page = undefined;

pub var number_of_files: usize = 0;

pub var root_address: u64 = undefined;

pub var current_dir: u64 = 0;

pub const max_path_size = 255;

//MEMORY LAYOUT OF FILE
//┌──────┬──────┬────────┬────────────────┬──────────────────┬─────────────────────────┐
//│ type │ size │ length │ parent address │ name of the file │ list of block addresses │
//└──────┴──────┴────────┴────────────────┴──────────────────┴─────────────────────────┘
//  byte   byte   byte     8 bytes (u64)    unknown            rest of the file
//  0      1      2        3                11

fn checkEmpty(index: usize) bool {
    if (db.sum(mem.*[super_block.address + index .. super_block.address + 8 + index]) == 0) {
        return true;
    }
    return false;
}

pub fn writeFileToSuperBlock(file: pages.Page) void {
    for (0..max_files) |i| {
        //if the current block is empty
        if (super_block[i].address == 0) {
            super_block[i] = file;
            number_of_files += 1;
            return;
        }
    }
    db.print("Super Block is full");
}

fn writeHeader(file: pages.Page, ftype: u8, size: u8, length: u8, parent: u64, name: []const u8) void {
    //write the type as a file to the first byte of the file
    file.data[0] = ftype;
    //write the size of the file in blocks to memory
    file.data[1] = size;
    //write the length of the name to the third byte of the file
    file.data[2] = length;

    //set the parent
    db.writeToMem64(u64, file.address + 3, parent);
    //write the name to the file
    db.writeStringToMem(file.address + 3 + 8, name);
}

pub fn createFile(name: []const u8, parent: u64) void {
    //convert name.len to u8
    const length: u8 = @truncate(name.len);

    //allocate space for a new file
    const page: pages.Page = pages.alloc(&pages.pt) catch pages.empty_page;

    //max file size is 400kb for now
    //we write the address of the file to the super block
    writeFileToSuperBlock(page);

    //create the file header
    writeHeader(page, 0, 0, length, parent, name);

    //add a new block;
    addBlock(page.address);
    debugFile(page.address);
}

pub fn createDir(name: []const u8, parent: u64) void {
    //very similar to the creation of a file
    //we simply change the type
    //convert name.len to u8
    const length: u8 = @truncate(name.len);

    //allocate space for a new directory
    const page: pages.Page = pages.alloc(&pages.pt) catch pages.empty_page;

    //we write the address of the directory to the super block
    writeFileToSuperBlock(page);
    writeHeader(page, 1, 0, length, parent, name);
    debugFile(page.address);
}

pub fn setSize(file: u64, size: u8) void {
    mem.*[file + 1] = size;
}

pub fn clearData(file: u64) void {
    const size = getHeaderSize(file);
    const empty: [block_size]u8 = .{0} ** block_size;
    @memcpy(mem.*[file + size .. file + block_size], empty[size..block_size]);
    setSize(file, 0);
}

pub fn addBlock(file: u64) void {
    //check if the type is correct
    if (getType(file) == 1) return;
    //we add one block so we need to change the size
    const size = getSize(file) + 1;
    db.printValue(size);

    //100 blocks is the maximum size for now
    if (size >= 100) return;

    setSize(file, size);
    //add the new block to the first free spot
    const page: pages.Page = pages.alloc(&pages.pt) catch pages.empty_page;
    const offset = getHeaderSize(file) + (size * 8);
    db.writeToMem64(u64, file + offset, page.address);
}

pub fn getBlock(file: u64, index: usize) u64 {
    const hsize = getHeaderSize(file);
    return db.readFromMem(u64, file + hsize + (index * 8));
}

pub fn debugFile(file: u64) void {
    db.print("\naddress of file \"");
    db.print(getName(file));
    db.print("\": ");
    db.printValue(file);

    db.print("\ntype of file: ");
    switch (getType(file)) {
        0 => db.print("file"),
        1 => db.print("directory"),
        else => db.print("unknown type"),
    }

    db.print("\nsize of file in blocks: ");
    db.printValue(getSize(file));

    db.print("\nname of the file: ");
    db.print(getName(file));

    db.print("\nparent of the file: ");
    db.printValue(getParent(file));

    db.print("\naddresses of the blocks: \n");
    for (0..getSize(file)) |i| {
        db.print("  ");
        db.printValue(i);
        db.print(": ");
        db.printValue(getBlock(file, i));
        db.print("\n");
    }

    db.print("Raw memory at this file: \n");
    db.printMem(mem.*[file .. file + 40]);
    db.printArrayFull(mem.*[file .. file + 40]);
    db.print("\n");
}

pub fn debugFiles() void {
    db.print("\nALL FILES IN SUPER BLOCK\n");
    for (0..number_of_files) |i| {
        const file = addressFromSb(i);
        debugFile(file);
    }
    db.print("\n\n");
}

pub fn addressFromSb(index: usize) u64 {
    return super_block[index].address;
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

pub fn writeData(file: u64, data: []const u8) void {
    //we overwrite the data:
    clearData(file);
    //How many blocks do we need to write ?
    db.printValueDec(data.len);

    const number_of_blocks = data.len / block_size + 1;
    db.printValueDec(number_of_blocks);

    for (0..number_of_blocks) |i| {
        db.printValueDec(i);
        var block: u64 = undefined;
        addBlock(file);
        //upadte the block address to be the correct one
        block = getBlock(file, i);
        //we need to handle the last block separately
        if (i != number_of_blocks - 1) {
            @memcpy(mem.*[block .. block + block_size], data[i * block_size .. i * block_size + block_size]);
        } else {
            @memcpy(mem.*[block .. block + data.len - (i * block_size)], data[i * block_size .. data.len]);
        }
    }

    debugFile(file);
}

pub fn appendData(file: u64, data: []u8) void {
    const size = getSize(file);
    const number_of_blocks = data.len / block_size + 1;
    db.printValueDec(number_of_blocks);

    for (0..number_of_blocks - 1) |i| {
        var block: u64 = undefined;
        addBlock(file);
        //upadte the block address to be the correct one
        block = getBlock(file, i + size);
        //we need to handle the last block separately
        if (i != number_of_blocks - 1) {
            @memcpy(mem.*[block .. block + block_size], data[i * block_size .. i * block_size + block_size]);
        } else {
            @memcpy(mem.*[block .. block + data.len - (i * block_size)], data[i * block_size .. data.len]);
        }
    }

    debugFile(file);
}

pub fn getData(file: u64) []u8 {
    //How many blocks do we need to read ?
    const number_of_blocks = getSize(file);
    //for now we consider that 100 blocks is the maximum size
    var out: [10 * block_size]u8 = .{0} ** (10 * block_size);

    for (0..number_of_blocks) |i| {
        const block = getBlock(file, i);
        @memcpy(
            out[i * block_size .. i * block_size + block_size],
            mem.*[block .. block + block_size],
        );
    }

    return out[0 .. number_of_blocks * block_size];
}

pub fn loadEmbed(comptime path: []const u8, parent: u64, name: []const u8) void {
    const file: []const u8 = @embedFile(path);
    createFile(name, parent);
    const osfile = addressFromName(name);
    writeData(osfile, file[0..]);
}

pub fn fileExists(name: []const u8) bool {
    for (0..number_of_files) |i| {
        const address = addressFromSb(i);
        if (db.hashStr(name) == db.hashStr(getName(address))) return true;
    }
    return false;
}

pub fn getName(file: u64) []const u8 {
    const length: u8 = mem.*[file + 2];
    return db.stringFromMem(file + 11, length);
}

pub fn getType(file: u64) u8 {
    return mem.*[file];
}

pub fn getParent(file: u64) u64 {
    return db.readFromMem(u64, file + 3);
}

pub fn getDataStart(file: u64) u64 {
    const name_length = mem.*[file + 2];
    return file + name_length + 11;
}

pub fn getHeaderSize(file: u64) usize {
    const name_length = mem.*[file + 2];
    return name_length + 11;
}

pub fn getSize(file: u64) u8 {
    return mem.*[file + 1];
}

pub fn getAddressOfNextBlock(address: u64) u64 {
    return db.readFromMem(u64, address + 11);
}

pub fn init() void {
    super_block = .{pages.empty_page} ** max_files;
    //creation of root
    createDir("/", 0);
    const address = addressFromName("/");
    root_address = address;
    current_dir = root_address;
    loadEmbed("../info.txt", root_address, "info");
    db.print("\nloaded embed");
}
