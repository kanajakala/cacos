const fs = @import("../core/ramfs.zig");
const List = @import("../utils/list.zig").List(u8);
const strings = @import("../utils/strings.zig");
const mem = @import("../core/memory.zig");
const cpu = @import("../cpu/cpu.zig");
const std = @import("std");
const db = @import("../utils/debug.zig");

////LOAD ELF BINARIES

pub const max_prog_headers = 10;

pub const errors = error{
    invalidElfFile,
    invalidElfArchitecture,
};

pub const ELF_Header = packed struct(u512) {
    magic: u32,
    bit_type: u8, //32bit or 64bits
    endianness: u8,
    header_version: u8,
    os_abi: u8,
    padding: u64,
    elf_type: u16,
    architecture: u16,
    elf_version: u32,
    entry_address: u64,
    prog_header_table_offset: u64,
    section_header_table_offset: u64,
    flags: u32,
    header_size: u16,
    entry_size: u16,
    n_entries: u16,
    entry_size_section_header: u16,
    n_entries_section_header: u16,
    section_index: u16,
};

const Seg_type = enum(u32) {
    unused = 0, //do not use
    load = 1, //needs to be loaded
    dynamic = 2, //unusported !
    note = 4, //notes
    prog_header_table = 6, //the table itself, doesn't need to be loaded
    gnu_eh_frame = 0x6474e550, //GCC .eh_frame_hdr segment
    gnu_stack = 0x6474e551, //GCC stack
};

pub const Program_Header = packed struct(u448) {
    segment_type: Seg_type,
    flags: u32,
    file_data_offset: u64,
    mem_address: u64,
    physical_address: u64,
    file_segment_size: u64,
    mem_segment_size: u64,
    section_alignement: u64,
};

fn check(elf: List) !void {
    if (!strings.equal(try elf.readSlice(0, 4), "\x7fELF")) return errors.invalidElfFile; //check magic
    if (try elf.read(4) != 2) return errors.invalidElfArchitecture; //file must be 64bit format
    if (try elf.read(5) != 1) return errors.invalidElfArchitecture; //file must be little endian
    return;
}

pub fn load(id: usize) !void {
    //read the elf file
    const elf_file = try fs.open(id);
    const elf: List = elf_file.data;

    //check that it is correct (magic + code type)
    //if it isn't an error will be returned thanks to the try statement
    try check(elf);

    //read the elf header
    const elf_header_bytes: [64]u8 = (try elf.readSlice(0, 64))[0..64].*;
    const elf_header: ELF_Header = @bitCast(elf_header_bytes);

    //read the program headers
    //see how many segments must be loaded into memory and where
    //and load each segment at p_vaddr after allocating p_memsz
    const page_index: usize = 0;
    _ = page_index;
    for (0..elf_header.n_entries) |i| {
        //we read the the program header
        const offset = elf_header.prog_header_table_offset + i * 56;
        const header_bytes = (try elf.readSlice(offset, offset + i * 56))[0..56].*;
        const prog_header: Program_Header = @bitCast(header_bytes);

        //we need to load the segment only if it is loadable
        if (prog_header.segment_type == Seg_type.load) {
            //the data to be loaded is at p_offset in the file and is of size p_filesz
            //if p_memsz is bigger than p_filesz we must pad with zeroes

            const region = try mem.valloc(mem.virtualFromPhysical(prog_header.mem_address), prog_header.mem_segment_size);

            //we copy the data
            const data = (try elf.readSlice(prog_header.file_data_offset, prog_header.file_data_offset + prog_header.file_segment_size));
            @memcpy(region, data);
        }
    }
    cpu.jump(elf_header.entry_address);
}
