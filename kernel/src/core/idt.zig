//taken from https://github.com/Tatskaari/zigzag/blob/main/kernel/src/arch/x86/idt.zig
const cpu = @import("cpu.zig");
const pic = @import("pic.zig");
const gdt = @import("gdt.zig");
const db = @import("debug.zig");
const scheduler = @import("scheduler.zig");
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
const IDTPTR = packed struct(u80) {
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
    const idtptr = IDTPTR{ .offset = @intFromPtr(&idt[0]), .size = (@sizeOf(@TypeOf(idt))) - 1 };
    cpu.lidt(@bitCast(idtptr));
}

pub const InterruptStackFrame = extern struct {
    eflags: u32,
    eip: u32,
    cs: u32,
    stack_pointer: u32,
    stack_segment: u32,
};

/// Offset by the amount of traps in the Interrupt Descriptor Table
pub inline fn offset(irq: u8) u8 {
    return irq + 32;
}

/// Handle specific interrupt request (the interrupt number is offsetted by `offset` function)
/// taken from https://github.com/yhyadev/yos/blob/master/src/kernel/arch/x86_64/cpu.zig
pub fn handle(irq: u8, comptime handler: *const fn (*InterruptStackFrame) callconv(.C) void) void {
    const lambda = struct {
        pub fn interruptRequestEntry() callconv(.Naked) void {
            // Save the context on stack to be restored later
            asm volatile (
                \\push %rbp
                \\push %rax
                \\push %rbx
                \\push %rcx
                \\push %rdx
                \\push %rdi
                \\push %rsi
                \\push %r8
                \\push %r9
                \\push %r10
                \\push %r11
                \\push %r12
                \\push %r13
                \\push %r14
                \\push %r15
                \\mov %ds, %rax
                \\push %rax
                \\mov %es, %rax
                \\push %rax
                \\mov $0x10, %ax
                \\mov %ax, %ds
                \\mov %ax, %es
                \\cld
            );

            // Allow the handler to modify the context by passing a pointer to it
            asm volatile (
                \\mov %rsp, %rdi
            );

            // Now call the handler using the function pointer we have, this is possible with
            // the derefrence operator in AT&T assembly syntax
            asm volatile (
                \\call *%[handler]
                :
                : [handler] "{rax}" (handler),
            );

            // Restore the context (which is potentially modified)
            asm volatile (
                \\pop %rax
                \\mov %rax, %es
                \\pop %rax
                \\mov %rax, %ds
                \\pop %r15
                \\pop %r14
                \\pop %r13
                \\pop %r12
                \\pop %r11
                \\pop %r10
                \\pop %r9
                \\pop %r8
                \\pop %rsi
                \\pop %rdi
                \\pop %rdx
                \\pop %rcx
                \\pop %rbx
                \\pop %rax
                \\pop %rbp
                \\iretq
            );
        }
    };
    // We add the function to the idt
    // we also need to offset by 32 because those are reserved for exceptions
    setDescriptor(irq + 32, @intFromPtr(&lambda.interruptRequestEntry), 0);
}

pub fn init() void {
    load();
    //set descriptors for various errors
    setDescriptor(0, @intFromPtr(&handleDivisionError), 0);
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
    pic.primary.disableAll();
    pic.secondary.disableAll();
    pic.primary.enable(pic.cascade_irq);
}

fn handleDivisionError(_: *InterruptStackFrame) callconv(.Interrupt) void {
    console.printErr("division error");
    db.panic("division error");
}

fn handleDebug(_: *InterruptStackFrame) callconv(.Interrupt) void {
    console.printErr("debug");
    db.panic("debug");
}

fn handleBreakpoint(_: *InterruptStackFrame) callconv(.Interrupt) void {
    scheduler.stopAll();
    console.printErr("breakpoint");
}

fn handleOverflow(_: *InterruptStackFrame) callconv(.Interrupt) void {
    console.printErr("overflow");
    db.panic("overflow");
}

fn handleBoundRangeExceeded(_: *InterruptStackFrame) callconv(.Interrupt) void {
    console.printErr("bound range exceeded");
    db.panic("bound range exceeded");
}

fn handleInvalidOpcode(_: *InterruptStackFrame) callconv(.Interrupt) void {
    console.printErr("invalid opcode");
    db.panic("invalid opcode");
}

fn handleDeviceNotAvailable(_: *InterruptStackFrame) callconv(.Interrupt) void {
    console.printErr("device not available");
    db.panic("device not available");
}

fn handleDoubleFault(_: *InterruptStackFrame) callconv(.Interrupt) void {
    console.printErr("double fault");
    db.panic("double fault");
}

fn handleSegmentationFault(_: *InterruptStackFrame) callconv(.Interrupt) void {
    console.printErr("segmentation fault");
    db.panic("segmentation fault");
}

fn handleGeneralProtectionFault(_: *InterruptStackFrame) callconv(.Interrupt) void {
    console.printErr("general protection fault");
    db.panic("general protection fault");
}

fn handlePageFault(_: *InterruptStackFrame) callconv(.Interrupt) void {
    console.printErr("page fault");
    //db.panic("page fault");
}

fn handleX87FloatingPointException(_: *InterruptStackFrame) callconv(.Interrupt) void {
    console.printErr("x87 floating point exception");
    db.panic("x87 floating point exception");
}

fn handleAlignmentCheck(_: *InterruptStackFrame) callconv(.Interrupt) void {
    console.printErr("alignment check: {}");
    db.panic("alignment check: {}");
}

fn handleMachineCheck(_: *InterruptStackFrame) callconv(.Interrupt) void {
    console.printErr("machine check");
    db.panic("machine check");
}

fn handleSIMDFloatingPointException(_: *InterruptStackFrame) callconv(.Interrupt) void {
    console.printErr("simd floating point exception");
    db.panic("simd floating point exception");
}

fn handleVirtualizationException(_: *InterruptStackFrame) callconv(.Interrupt) void {
    console.printErr("virtualization exception");
    db.panic("virtualization exception");
}

fn handleControlProtectionException(_: *InterruptStackFrame) callconv(.Interrupt) void {
    console.printErr("control protection exception");
    db.panic("control protection exception");
}

fn handleHypervisorInjectionException(_: *InterruptStackFrame) callconv(.Interrupt) void {
    console.printErr("hypervisor injection exception");
    db.panic("hypervisor injection exception");
}

fn handleVMMCommunicationException(_: *InterruptStackFrame) callconv(.Interrupt) void {
    console.printErr("vmm communication exception");
    db.panic("vmm communication exception");
}

fn handleSecurityException(_: *InterruptStackFrame) callconv(.Interrupt) void {
    console.printErr("security exception");
    db.panic("security exception");
}
