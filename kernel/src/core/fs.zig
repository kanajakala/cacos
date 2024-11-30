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

pub const fileErrors = error{
    indexOverflow,
    fileNotFound,
};

pub const File = struct {
    name: []const u8,
    size: u8, //size in blocks
    ftype: Type,
    data: []u64, //slice of block addresses

    pub inline fn read(self: File, index: usize) u8 {
        //if (index >= self.size * block_size) return fileErrors.indexOverflow;
        const page_number = @divFloor(index, block_size); //find the right page
        const page_offset = @mod(index, block_size); //find which position we need to write in the file
        return mem.*[self.data[page_number] + page_offset];
    }

    pub inline fn write(self: File, index: usize, data: u8) void {
        //if (index >= self.size * block_size) return fileErrors.indexOverflow;
        const page_number = @floor(index / block_size); //find the right page
        const page_offset = @mod(index, block_size); //find which position we need to read in the file
        mem.*[self.data[page_number] + page_offset] = data;
    }
};

//MEMORY LAYOUT OF FILE
//┌──────┬──────┬────────┬────────────────┬──────────────────┬─────────────────────────┐
//│ type │ size │ length │ parent address │ name of the file │ list of block addresses │
//└──────┴──────┴────────┴────────────────┴──────────────────┴─────────────────────────┘
//  byte   byte   byte     8 bytes (u64)    length             size
//  0      1      2        3                12                 length + 12
//
// fixed offset = 11
const fixed_header_offset = 11;

pub const Type = enum {
    directory,
    text,
    binary,
    executable,
    image,
};

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
    //db.print("Super Block is full");
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

pub fn createFile(name: []const u8, ftype: Type, parent: u64) void {
    //convert name.len to u8
    const length: u8 = @truncate(name.len);

    //allocate space for a new file
    const page: pages.Page = pages.alloc(&pages.pt) catch pages.empty_page;

    //max file size is 400kb for now
    //we write the address of the file to the super block
    writeFileToSuperBlock(page);

    //create the file header
    writeHeader(page, @intFromEnum(ftype), 0, length, parent, name);

    //add a new block for the data of the file, if the created object is a file;
    if (ftype != Type.directory) addBlock(page.address);
    //debugFile(page.address);
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
    if (getType(file) == Type.directory) return;
    //we add one block so we need to change the size
    const size = getSize(file) + 1;
    //db.printValue(size);

    //100 blocks is the maximum size for now
    if (size >= 100) return;

    setSize(file, size);
    //add the new block to the first free spot
    const page: pages.Page = pages.alloc(&pages.pt) catch pages.empty_page;
    const offset = getHeaderSize(file) + ((size - 1) * 8);
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
    db.print(@tagName(getType(file)));

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
    //db.printValueDec(data.len);

    const number_of_blocks = data.len / block_size + 1;
    //db.printValueDec(number_of_blocks);

    for (0..number_of_blocks) |i| {
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

    //debugFile(file);
}

pub fn appendData(file: u64, data: []u8) void {
    const size = getSize(file);
    const number_of_blocks = data.len / block_size + 1;
    //db.printValueDec(number_of_blocks);

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

    //debugFile(file);
}

pub const max_size = 10;

pub fn getData(file: u64) []u8 {
    //How many blocks do we need to read ?
    const number_of_blocks = getSize(file);

    //check if file is too big:
    if (number_of_blocks > max_size) db.panic("File too biig to read data ! (max size 40kb, I know it'll get fixed...)");

    //for now we consider that max_size blocks is the maximum size
    //extremely wastefull (we create a list of 40kb on the stack...)
    var out: [max_size * block_size]u8 = .{0} ** (max_size * block_size);

    for (0..number_of_blocks) |i| {
        const block = getBlock(file, i);
        @memcpy(
            out[i * block_size .. i * block_size + block_size],
            mem.*[block .. block + block_size],
        );
    }

    return out[0 .. number_of_blocks * block_size];
}

pub fn fileToMem(file: u64) [max_size]u64 {
    //How many blocks do we need to read ?
    const number_of_blocks = getSize(file);

    //check if file is too big:
    if (number_of_blocks > max_size) db.panic("File too biig to read data ! (max size 40kb, I know it'll get fixed...)");
    //maximum size of 40kb files
    var page_list: [max_size]pages.Page = undefined;
    var address_book: [max_size]u64 = undefined;

    for (0..number_of_blocks) |i| {
        //current block we read from
        const block = getBlock(file, i);
        //allocate the right number of pages
        page_list[i] = pages.alloc(&pages.pt) catch pages.empty_page;
        const page: u64 = page_list[i].address;
        address_book[i] = page_list[i].address;
        //copy file content to the page
        @memcpy(
            mem.*[page .. page + block_size],
            mem.*[block .. block + block_size],
        );
    }

    return address_book;
}

pub fn open(file: []const u8) File {
    const address: u64 = addressFromName(file);
    //if (address == 0) return fileErrors.fileNotFound;
    const size = getSize(address);
    const ftype = getType(address);
    //for now max size is 1_000 blocks (4mb)
    var data: [1_000]u64 = .{0} ** 1_000;
    //fill the  data with the block addresses
    for (0..size) |i| {
        data[i] = getBlock(address, i);
    }
    return File{ .name = file, .size = size, .ftype = ftype, .data = &data };
}

pub fn loadEmbed(comptime path: []const u8, parent: u64, name: []const u8, ftype: Type) void {
    const file: []const u8 = @embedFile(path);
    createFile(name, ftype, parent);
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
    return db.stringFromMem(file + fixed_header_offset, length);
}

pub fn getType(file: u64) Type {
    return @enumFromInt(mem.*[file]);
}

pub fn getParent(file: u64) u64 {
    return db.readFromMem(u64, file + 3);
}
pub fn setParent(file: u64, parent: u64) void {
    db.writeToMem64(u64, file + 3, parent);
}

pub fn getDataStart(file: u64) u64 {
    const name_length = mem.*[file + 2];
    return file + name_length + fixed_header_offset;
}

pub fn getHeaderSize(file: u64) usize {
    const size = mem.*[file + 1];
    const name_length = mem.*[file + 2];
    return name_length + size + fixed_header_offset;
}

pub fn getSize(file: u64) u8 {
    return mem.*[file + 1];
}

pub fn getAddressOfNextBlock(address: u64) u64 {
    return db.readFromMem(u64, address + fixed_header_offset);
}

pub fn init() void {
    super_block = .{pages.empty_page} ** max_files;
    //creation of root
    createFile("/", Type.directory, 0);
    const address = addressFromName("/");
    root_address = address;
    current_dir = root_address;
    loadEmbed("../info.txt", root_address, "info", Type.text);
    //db.print("\nloaded embed");
}
