//taken from https://github.com/Tatskaari/zigzag/blob/main/kernel/src/arch/x86/idt.zig
const cpu = @import("cpu.zig");
const pic = @import("pic.zig");
const screen = @import("../drivers/screen.zig");
const console = @import("../drivers/console.zig");

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
    setDescriptor(1, @intFromPtr(&handleDivisionError), 0);
    setDescriptor(2, @intFromPtr(&handleDebug), 0);
    setDescriptor(3, @intFromPtr(&handleBreakpoint), 0);
    setDescriptor(4, @intFromPtr(&handleOverflow), 0);
    setDescriptor(5, @intFromPtr(&handleBoundRangeExceeded), 0);
    setDescriptor(6, @intFromPtr(&handleInvalidOpcode), 0);
    setDescriptor(7, @intFromPtr(&handleDeviceNotAvailable), 0);
    setDescriptor(8, @intFromPtr(&handleDoubleFault), 0);
    setDescriptor(9, @intFromPtr(&handleSegmentationFault), 0);
    setDescriptor(10, @intFromPtr(&handleSegmentationFault), 0);
    setDescriptor(11, @intFromPtr(&handleSegmentationFault), 0);
    setDescriptor(12, @intFromPtr(&handleGeneralProtectionFault), 0);
    setDescriptor(13, @intFromPtr(&handlePageFault), 0);
    setDescriptor(14, @intFromPtr(&handleX87FloatingPointException), 0);
    setDescriptor(15, @intFromPtr(&handleAlignmentCheck), 0);
    setDescriptor(16, @intFromPtr(&handleMachineCheck), 0);
    setDescriptor(17, @intFromPtr(&handleSIMDFloatingPointException), 0);
    setDescriptor(18, @intFromPtr(&handleVirtualizationException), 0);
    setDescriptor(19, @intFromPtr(&handleControlProtectionException), 0);
    setDescriptor(20, @intFromPtr(&handleHypervisorInjectionException), 0);
    setDescriptor(22, @intFromPtr(&handleVMMCommunicationException), 0);
    setDescriptor(22, @intFromPtr(&handleSecurityException), 0);

    //initialize the PIC
    pic.primary.init(0x20);
    pic.secondary.init(0x28);
}

fn handleDivisionError(_: *InterruptStackFrame) callconv(.Interrupt) void {
    console.printErr("division error");
}

fn handleDebug(_: *InterruptStackFrame) callconv(.Interrupt) void {
    console.printErr("debug");
}

fn handleBreakpoint(_: *InterruptStackFrame) callconv(.Interrupt) void {
    console.printErr("breakpoint");
}

fn handleOverflow(_: *InterruptStackFrame) callconv(.Interrupt) void {
    console.printErr("overflow");
}

fn handleBoundRangeExceeded(_: *InterruptStackFrame) callconv(.Interrupt) void {
    console.printErr("bound range exceeded");
}

fn handleInvalidOpcode(_: *InterruptStackFrame) callconv(.Interrupt) void {
    console.printErr("invalid opcode");
}

fn handleDeviceNotAvailable(_: *InterruptStackFrame) callconv(.Interrupt) void {
    console.printErr("device not available");
}

fn handleDoubleFault(_: *InterruptStackFrame) callconv(.Interrupt) void {
    console.printErr("double fault");
}

fn handleSegmentationFault(_: *InterruptStackFrame) callconv(.Interrupt) void {
    console.printErr("segmentation fault");
}

fn handleGeneralProtectionFault(_: *InterruptStackFrame) callconv(.Interrupt) void {
    console.printErr("general protection fault");
}

fn handlePageFault(_: *InterruptStackFrame) callconv(.Interrupt) void {
    console.printErr("page fault");
}

fn handleX87FloatingPointException(_: *InterruptStackFrame) callconv(.Interrupt) void {
    console.printErr("x87 floating point exception");
}

fn handleAlignmentCheck(_: *InterruptStackFrame) callconv(.Interrupt) void {
    console.printErr("alignment check: {}");
}

fn handleMachineCheck(_: *InterruptStackFrame) callconv(.Interrupt) void {
    console.printErr("machine check");
}

fn handleSIMDFloatingPointException(_: *InterruptStackFrame) callconv(.Interrupt) void {
    console.printErr("simd floating point exception");
}

fn handleVirtualizationException(_: *InterruptStackFrame) callconv(.Interrupt) void {
    console.printErr("virtualization exception");
}

fn handleControlProtectionException(_: *InterruptStackFrame) callconv(.Interrupt) void {
    console.printErr("control protection exception");
}

fn handleHypervisorInjectionException(_: *InterruptStackFrame) callconv(.Interrupt) void {
    console.printErr("hypervisor injection exception");
}

fn handleVMMCommunicationException(_: *InterruptStackFrame) callconv(.Interrupt) void {
    console.printErr("vmm communication exception");
}

fn handleSecurityException(_: *InterruptStackFrame) callconv(.Interrupt) void {
    console.printErr("security exception");
}
