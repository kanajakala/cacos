//taken from https://github.com/Tatskaari/zigzag/blob/main/kernel/src/arch/x86/idt.zig
const cpu = @import("cpu.zig");
const pic = @import("pic.zig");
const gdt = @import("gdt.zig");
const db = @import("../utils/debug.zig");

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
    stack_pointer: u64,
    stack_segment: u64,
    r12: u64,
    r11: u64,
    r10: u64,
    r9: u64,
    r8: u64,
};

/// Handle specific interrupt request
/// taken from https://github.com/yhyadev/yos/blob/master/src/kernel/arch/x86_64/cpu.zig
pub fn handle(irq: u8, comptime handler: *const fn (*InterruptStackFrame) callconv(.c) void) void {
    const lambda = struct {
        pub fn interruptRequestEntry() callconv(.naked) void {
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
                \\pop %r12
                \\pop %r11
                \\pop %r10
                // we don't pop r8 as it is used for returns
                // we also don't pop r9 as it is used for errors
                // we do a dummy pops instead so that the values stay correct
                //first dummy pop
                \\pop %rsi 
                //second dummy pop
                \\pop %rsi
                //real pop this time
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

pub fn init() !void {
    load();
    //set descriptors for various errors
    setDescriptor(0, @intFromPtr(&handleDivisionError), 0);
    setDescriptor(1, @intFromPtr(&handleDebug), 0);
    setDescriptor(3, @intFromPtr(&handleBreakpoint), 0);
    setDescriptor(4, @intFromPtr(&handleOverflow), 0);
    setDescriptor(5, @intFromPtr(&handleBoundRangeExceeded), 0);
    setDescriptor(6, @intFromPtr(&handleInvalidOpcode), 0);
    setDescriptor(7, @intFromPtr(&handleDeviceNotAvailable), 0);
    setDescriptor(8, @intFromPtr(&handleDoubleFault), 0);
    setDescriptor(10, @intFromPtr(&handleSegmentationFault), 0);
    setDescriptor(13, @intFromPtr(&handleGeneralProtectionFault), 0);
    setDescriptor(14, @intFromPtr(&handlePageFault), 0);
    setDescriptor(17, @intFromPtr(&handleAlignmentCheck), 0);
    setDescriptor(18, @intFromPtr(&handleMachineCheck), 0);
    setDescriptor(19, @intFromPtr(&handleSIMDFloatingPointException), 0);

    //interrupt redirected for debugging
    setDescriptor(9, @intFromPtr(&db.debugContextInterrupt), 0);

    //initialize the PIC
    pic.primary.init(0x20);
    pic.secondary.init(0x28);
    pic.primary.disableAll();
    pic.secondary.disableAll();
    pic.primary.enable(pic.cascade_irq);
}

fn handleDivisionError(_: *InterruptStackFrame) callconv(.{ .x86_64_interrupt  = .{} }) void {
    db.panic("ERROR: DivisionError\n");
}

fn handleDebug(_: *InterruptStackFrame) callconv(.{ .x86_64_interrupt = .{} }) void {
    db.panic("ERROR: Debug\n");
}

fn handleBreakpoint(_: *InterruptStackFrame) callconv(.{ .x86_64_interrupt = .{} }) void {
    db.panic("ERROR: Breakpoint\n");
}

fn handleOverflow(_: *InterruptStackFrame) callconv(.{ .x86_64_interrupt = .{} }) void {
    db.panic("ERROR: Overflow\n");
}

fn handleBoundRangeExceeded(_: *InterruptStackFrame) callconv(.{ .x86_64_interrupt = .{} }) void {
    db.panic("ERROR: BoundRangeExceeded\n");
}

fn handleInvalidOpcode(_: *InterruptStackFrame) callconv(.{ .x86_64_interrupt = .{} }) void {
    db.panic("ERROR: InvalidOpcode\n");
}

fn handleDeviceNotAvailable(_: *InterruptStackFrame) callconv(.{ .x86_64_interrupt = .{} }) void {
    db.panic("ERROR: DeviceNotAvailable\n");
}

fn handleDoubleFault(_: *InterruptStackFrame) callconv(.{ .x86_64_interrupt = .{} }) void {
    db.panic("ERROR: DoubleFault\n");
}

fn handleSegmentationFault(_: *InterruptStackFrame) callconv(.{ .x86_64_interrupt = .{} }) void {
    db.panic("ERROR: SegmentationFault\n");
}

fn handleGeneralProtectionFault(_: *InterruptStackFrame) callconv(.{ .x86_64_interrupt = .{} }) void {
    db.panic("ERROR: GeneralProtectionFault\n");
}

fn handlePageFault(_: *InterruptStackFrame) callconv(.{ .x86_64_interrupt = .{} }) void {
    db.panic("ERROR: PageFault\n");
}

fn handleAlignmentCheck(_: *InterruptStackFrame) callconv(.{ .x86_64_interrupt = .{} }) void {
    db.panic("ERROR: AlignmentCheck\n");
}

fn handleMachineCheck(_: *InterruptStackFrame) callconv(.{ .x86_64_interrupt = .{} }) void {
    db.panic("ERROR: MachineCheck\n");
}

fn handleSIMDFloatingPointException(_: *InterruptStackFrame) callconv(.{ .x86_64_interrupt = .{} }) void {
    db.panic("ERROR: SIMDFloatingPointException\n");
}
