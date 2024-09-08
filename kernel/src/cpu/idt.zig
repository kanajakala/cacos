const cpu = @import("cpu.zig");
const scr = @import("../drivers/screen.zig");
const debug = @import("../cpu/debug.zig");

var idt: [256]entry = undefined;

//an entry in the Interrupt Desciptor Table
const entry = packed struct {
    isr_low: u16, // first 16 bits of the function pointer
    kernel_cs: u16, // The code segment for the kernel. This should be whatever you set it to when you set this in the GDT.
    ist: u8 = 0, // Legacy nonense. Set this to 0.
    flags: u8, // Sets the gate type, dpl, and p fields
    isr_mid: u16, // The next 16 bits of the function pointer
    isr_high: u32, // The last 32 bits of the function pointer
    reserved: u32 = 0,
};

//get the Code Segment (??)
//taken from https://github.com/yhyadev/yos/blob/master/src/kernel/arch/x86_64/cpu.zig
pub inline fn getCS() u16 {
    return asm volatile ("mov %cs, %[result]"
        : [result] "={rax}" (-> u16),
    );
}

//most of the code taken from https://github.com/Tatskaari/zigzag/blob/main/notes/x86/interrupts/IDT%20-%20interrupt%20descriptor%20table.md
pub fn setDescriptor(vector: usize, isrPtr: usize, dpl: u8) void {
    var IDTentry = &idt[vector];

    IDTentry.isr_low = @truncate(isrPtr & 0xFFFF);
    IDTentry.isr_mid = @truncate((isrPtr >> 16) & 0xFFFF);
    IDTentry.isr_high = @truncate(isrPtr >> 32);
    //your code selector may be different!
    IDTentry.kernel_cs = getCS();
    //trap gate + present + DPL
    IDTentry.flags = 0b1110 | ((dpl & 0b11) << 5) | (1 << 7);
    //ist disabled
    IDTentry.ist = 0;
}

pub const InterruptStackFrame = extern struct {
    eflags: u32,
    eip: u32,
    cs: u32,
    stack_pointer: u32,
    stack_segment: u32,
};

pub fn load() void {
    const IDTR = packed struct(u80) {
        address: u64,
        size: u16,
    };

    const idtr = IDTR{ .address = @intFromPtr(&idt[0]), .size = (@sizeOf(@TypeOf(idt))) - 1 };

    asm volatile ("lidt (%[idtr])"
        :
        : [idtr] "{rax}" (idtr),
    );
}

pub fn init() void {
    scr.print("Loading IDT\n", scr.text);
    setDescriptor(0, @intFromPtr(&divErrISR), 0);
    setDescriptor(0x10, @intFromPtr(&customInterupt), 0);
    load();
    scr.print("Loaded IDT", scr.text);
    //test the custom interrupt
    //asm volatile ("int $0x10");
}

fn divErrISR(_: *InterruptStackFrame) callconv(.Interrupt) void {
    scr.print("Div by zero!", scr.errorc);
}

fn customInterupt(_: *InterruptStackFrame) callconv(.Interrupt) void {
    debug.print("Interrupted!");
}
