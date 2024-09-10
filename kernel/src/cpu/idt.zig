//taken from https://github.com/Tatskaari/zigzag/blob/main/kernel/src/arch/x86/idt.zig
const cpu = @import("cpu.zig");
const screen = @import("../drivers/screen.zig");

/// IDTEntry is an entry in the interrupt descriptor table
const IDTEntry = packed struct(u128) {
    isr_low: u16, // first 16 bits of the function pointer
    selector: u16, // The code segment for the kernel. This should be whatever you set it to when you set this in the GDT.
    zero: u8 = 0, // Legacy nonense. Set this to 0.
    flags: u8, // Sets the gate type, dpl, and p fields
    isr_mid: u16, // The next 16 bits of the function pointer
    isr_high: u32, // The last 32 bits of the function pointer
    reserved: u32 = 0,
};

var idt: [256]IDTEntry = undefined;
// Structure pointing to the IDT
const IDTR = packed struct(u80) {
    size: u16,
    offset: u64,
};
pub fn setDescriptor(vector: usize, isrPtr: usize, dpl: u8) void {
    var entry = &idt[vector];

    entry.isr_low = @truncate(isrPtr & 0xFFFF);
    entry.isr_mid = @truncate((isrPtr >> 16) & 0xFFFF);
    entry.isr_high = @truncate(isrPtr >> 32);
    //your code selector may be different!
    entry.selector = cpu.getCS();
    //trap gate + present + DPL
    entry.flags = 0b1110 | ((dpl & 0b11) << 5) | (1 << 7);
    //ist disabled
    entry.zero = 0;
}

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
    screen.print("[ERROR]: Div by zero!", screen.errorc);
}

pub fn init() void {
    load();
    //set descriptors for various errors
    setDescriptor(0, @intFromPtr(&divErrISR), 0);
}
