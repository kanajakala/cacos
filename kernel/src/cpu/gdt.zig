const cpu = @import("cpu.zig");

//taken from: https://github.com/Tatskaari/zigzag/blob/main/kernel/src/arch/x86/gdt.zig
const SegmentDescriptor = packed struct(u64) {
    limit_lo: u16 = 0,
    base_address_lo: u16 = 0,
    base_address_hi: u8 = 0,
    access: Access,
    limit_hi: u4 = 0,
    reserved_1: u1 = 0,
    long_mode: bool = true,
    reserved_2: u1 = 0,
    use_chunks: bool = false, // Whether the limit represents 0x1000 chunks or just bytes
    base_address_ext: u8 = 0,

    const Access = packed struct(u8) {
        accessed: bool = true, //modified by the cpu
        read_write: bool = true, // If set, code segments are readable, data segments are writable
        grow_down_or_conforming: bool = false, // If set, the segment grows down for data, or for code, sets if it's conforming
        is_code: bool,
        not_system: bool = true,
        ring: u2,
        present: bool = true,
    };
};

const null_segment = SegmentDescriptor{
    .access = .{
        .read_write = false,
        .is_code = false,
        .grow_down_or_conforming = false,
        .ring = 0,
    },
};

const kernel_code = SegmentDescriptor{
    .access = .{
        .is_code = true,
        .ring = 0,
    },
};

const kernel_data = SegmentDescriptor{
    .access = .{
        .is_code = false,
        .ring = 0,
    },
};

const user_code = SegmentDescriptor{
    .access = .{
        .is_code = true,
        .ring = 3,
    },
};

const user_data = SegmentDescriptor{
    .access = .{
        .is_code = false,
        .ring = 3,
    },
};

const GDT = [5]SegmentDescriptor{
    null_segment, // null selector
    kernel_code,
    kernel_data,
    user_code,
    user_data,
};

// The selector is the offset into the gdt or'ed with the ring
pub const kernel_cs = 1 * @sizeOf(SegmentDescriptor) | 0;
pub const kernel_ds = 2 * @sizeOf(SegmentDescriptor) | 0;
pub const user_cs = (3 * @sizeOf(SegmentDescriptor)) | 3;
pub const user_ds = (4 * @sizeOf(SegmentDescriptor)) | 3;

const Gdtr = packed struct(u80) {
    limit: u16,
    base: u64,
};

pub noinline fn flushGdt() void {
    // Loads the data selectors, then does a dummy far return to the next instruction, setting the code selector
    // breaks the linker for some reason
    asm volatile (
        \\ mov $0x10, %ax
        \\ mov %ax, %ds
        \\ mov %ax, %es
        \\ mov %ax, %fs
        \\ mov %ax, %fs
        \\ mov %ax, %ss
        \\ pushq $0x08
        \\ pushq $dummy
        \\ lretq
        \\
        \\ dummy:
    );
}

pub fn init() void {
    const gdtr = Gdtr{
        .base = @intFromPtr(&GDT[0]),
        .limit = @sizeOf(@TypeOf(GDT)) - 1,
    };
    cpu.lgdt(@bitCast(gdtr));
    //causes problem with linker
    //flushGdt();
}
