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
    file_length: u8, //length of the file in blocks
    name_length: u8, //length of the name of the file in bytes (characters)
    parent: u64,
    next_block: u64,
    data: []u8,
};

const Block = struct {
    index: u8,
    parent: u64,
    previous_block: u64,
    address: u64,
    next_block: u64,
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

pub fn createFile(name: []const u8, parent: u64, size: usize) void {
    //convert name.len to u8
    const length: u8 = @truncate(name.len);

    db.print("\n\nattempting creation of file: ");
    db.print(name);

    //allocate space for a new file
    const faddress: pages.Page = pages.alloc(&pages.pageTable) catch pages.empty_page;
    var first_block: pages.Page = pages.empty_page;

    //creation of the file

    //number of blocks we need to store the file
    const n_of_blocks: u8 = @as(u8, @truncate(size / block_size + 1));

    db.print("\nnumber of required blocks: ");
    db.printValueDec(n_of_blocks);

    //we also allocate space for the first block if we need one
    if (n_of_blocks > 1) {
        first_block = pages.alloc(&pages.pageTable) catch pages.empty_page;
        db.print("\nallocated space for first block: ");
        db.printValue(first_block.start);
    }

    //max file size is 4mb for now
    var block_list: [1_000]Block = .{undefined} ** 1000;
    db.print("\nCreated block list");

    //allocate space for all the blocks
    for (0..n_of_blocks) |i| {
        const address: u64 = if (i == 0) first_block.start else block_list[i - 1].next_block; //get the address of the allocated space for this block
        const next_block: pages.Page = pages.alloc(&pages.pageTable) catch pages.empty_page;
        db.print("\naddress of current block ");
        db.printValue(address);
        db.print("\naddress of next block: ");
        db.printValue(next_block.start);

        block_list[i] = Block{
            .index = @as(u8, @truncate(i)),
            .parent = faddress.start,
            .previous_block = if (i == 0) faddress.start else block_list[i - 1].address, //get the address from the previous block
            .address = address,
            .next_block = next_block.start,
            .data = mem.*[address .. address + block_size],
        };
    }

    db.print("\nspace should be allocated for the file now");

    const file = File{
        .ftype = FileType.file,
        .address = faddress.start,
        .file_length = n_of_blocks,
        .name_length = length,
        .parent = parent,
        .next_block = block_list[0].address,
        .data = mem.*[faddress.start + length + 19 .. faddress.end], //we add 10 because we need to offset by the header length
    };

    //we write the address of the file to the super block
    writeFileToSuperBlock(file);

    //write the type as a file to the first byte of the file
    mem.*[faddress.start] = 0;
    //write the length of the file in blocks to memory
    mem.*[faddress.start + 1] = n_of_blocks;
    //write the length of the name to the third byte of the file
    mem.*[faddress.start + 2] = length;

    //set the parent
    db.writeToMem64(u64, faddress.start + 3, parent);
    //set the next_block
    db.writeToMem64(u64, faddress.start + 11, first_block.start);
    //write the name to the file
    db.writeStringToMem(faddress.start + 3 + 8 + 8, name);

    db.print("\nDone creating files");
    debugFiles();
}

pub fn createDir(name: []const u8, parent: u64) void {
    //convert name.len to u8
    const length: u8 = @truncate(name.len);

    //allocate space for a new directory
    const faddress: pages.Page = pages.alloc(&pages.pageTable) catch pages.empty_page;

    //creation of the directory
    //we add 2 to  the start because we also need to store the type which takes one byte and the length of the name which takes 1 bytes
    const dir = File{
        .ftype = FileType.directory,
        .address = faddress.start,
        .file_length = 1,
        .name_length = length,
        .parent = parent,
        .next_block = 0, //No next block
        .data = mem.*[faddress.start + length + 17 .. faddress.end], //same as for the files;
    };

    //we write the address of the directory to the super block
    writeFileToSuperBlock(dir);

    //set the type as a directory in the first byte
    mem.*[faddress.start] = 1;
    //write the length of the directory in blocks. A directory is precisely one block in size
    mem.*[faddress.start + 1] = 1;
    //write the length of the name to the second byte of the file
    mem.*[faddress.start + 2] = length;

    //set the parent
    db.writeToMem64(u64, faddress.start + 3, parent);
    //set the address of the next block
    db.writeToMem64(u64, faddress.start + 11, 0xffffffffffffffff);
    //write the name to the directory
    db.writeStringToMem(faddress.start + 19, name);

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
        const address = addressFromSb(i);

        db.print("\naddress of file n");
        db.printValueDec(i);
        db.print(": ");
        db.printValue(address);

        db.print("\ntype of file: ");
        switch (getType(address)) {
            FileType.file => db.print("file"),
            FileType.directory => db.print("directory"),
        }

        db.print("\nsize of file in blocks: ");
        db.printValue(getSize(address));

        db.print("\nnext block of file: ");
        db.printValue(getAddressOfNextBlock(address));

        db.print("\nname of the file: ");
        db.print(getName(address));

        db.print("\nparent of the file: ");
        db.printValue(getParent(address));

        db.print("\nRaw memory at this address: \n");
        db.printMem(mem.*[address .. address + 40]);
        db.printArrayFull(mem.*[address .. address + 40]);
        db.print("\n");
    }
    db.print("\n\n");
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

pub fn writeData(file: u64, data: []const u8) void {
    //we add 2 because the first byte stores the type and the second the file_length
    const name_length = mem.*[file + 2];
    //TODO update to have support for longer files
    const file_size = getSize(file);
    if (data.len >= file_size * block_size) return;
    //we know that the file is big enough to contain our data
    //this represents the number of blocks we need to write
    //for (0..data.len / block_size + 1) |i| {
    @memcpy(mem.*[file + name_length + 19 .. file + data.len + name_length + 19], data[0..]);
    //}
}

pub fn clearFile(file: u64) void {
    writeData(file, .{0} ** block_size);
}

pub fn appendData(file: u64, data: []u8) void {
    //we add 2 because the first byte stores the type and the second the length of the name
    const name_length = mem.*[file + 2];
    //find the end of the data
    var end: usize = 0;
    for (file + name_length + 19..file + block_size + name_length + 19) |i| {
        if (mem.*[i] == 0) {
            end = i;
            break;
        }
    }
    @memcpy(mem.*[end .. end + data.len], data[0..]);
}

pub fn getData(file: u64) []u8 {
    const name_length = mem.*[file + 2];
    return mem.*[file + name_length + 19 .. file + block_size];
}

pub fn loadEmbed(comptime path: []const u8, parent: u64, name: []const u8) void {
    const file: []const u8 = @embedFile(path);
    createFile(name, parent, file.len);
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
    return db.stringFromMem(file + 19, length);
}

pub fn getType(file: u64) FileType {
    const type_byte: u8 = mem.*[file];
    if (type_byte == 1) {
        return FileType.directory;
    } else {
        return FileType.file;
    }
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
    super_block = pages.alloc(&pages.pageTable) catch pages.empty_page;
    //creation of root
    createDir("/", 0);
    const address = addressFromName("/");
    root_address = address;
    current_dir = root_address;
    loadEmbed("../info.txt", root_address, "info");
}
