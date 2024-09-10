//taken from https://github.com/Tatskaari/zigzag/blob/main/kernel/src/arch/x86/idt.zig
const cpu = @import("cpu.zig");
const screen = @import("../drivers/screen.zig");

/// Interrupt Descriptor Table Register: used to tell the CPU about the location and legnth of the IDTEntry array below
/// Interrupt Descriptor Table: the actual table that contains all the interrupt vectors to handle IRQs
var idt: [256]IDTEntry = undefined;

/// IDTEntry is an entry in the interrupt descriptor table
const IDTEntry = packed struct(u128) {
    isr_low: u16, // first 16 bits of the function pointer
    kernel_cs: u16, // The code segment for the kernel. This should be whatever you set it to when you set this in the GDT.
    ist: u8 = 0, // Legacy nonense. Set this to 0.
    flags: u8, // Sets the gate type, dpl, and p fields
    isr_mid: u16, // The next 16 bits of the function pointer
    isr_high: u32, // The last 32 bits of the function pointer
    reserved: u32 = 0,
};

pub fn setDescriptor(vector: usize, isrPtr: usize, dpl: u8) void {
    var entry = &idt[vector];

    entry.isr_low = @truncate(isrPtr & 0xFFFF);
    entry.isr_mid = @truncate((isrPtr >> 16) & 0xFFFF);
    entry.isr_high = @truncate(isrPtr >> 32);
    //your code selector may be different!
    entry.kernel_cs = cpu.getCS();
    //trap gate + present + DPL
    entry.flags = 0b1110 | ((dpl & 0b11) << 5) | (1 << 7);
    //ist disabled
    entry.ist = 0;
}
// Represents the function signature of an interupt
const Interrupt = *const fn (*cpu.Context) callconv(.C) void;

// Structure pointing to the IDT
const IDTR = packed struct(u80) {
    offset: u64,
    size: u16,
};

pub fn load() void {
    const idtr = IDTR{ .offset = @intFromPtr(&idt[0]), .size = (@sizeOf(@TypeOf(idt))) - 1 };
    cpu.lidt(@bitCast(idtr));
}

pub const InterruptStackFrame = extern struct {
    eflags: u32,
    eip: u32,
    cs: u32,
    stack_pointer: u32,
    stack_segment: u32,
};

export fn divErrISR(_: *InterruptStackFrame) callconv(.Interrupt) void {
    screen.print("Div by zero!", screen.errorc);
}
export fn testISR(_: *InterruptStackFrame) callconv(.Interrupt) void {
    screen.print("Interrupted!", screen.primary);
}

pub fn init() void {
    setDescriptor(0, @intFromPtr(&divErrISR), 0);
    setDescriptor(0x10, @intFromPtr(&testISR), 0);
    asm volatile ("int $0x10");
}
