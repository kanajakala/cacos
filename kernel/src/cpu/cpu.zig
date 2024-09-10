// taken from https://github.com/Tatskaari/zigzag/blob/main/kernel/src/arch/x86/cpu.zig
pub const Context = extern struct {
    // Segmenet registsers. These aren't used in 64bit so should be 0. We use csr3 to control the page table
    es: u64 = 0, // Extra Segment (ES) register, typically used in segmented memory addressing. Should be zero in x86_64.
    ds: u64 = 0, // Data Segment (DS) register, also used in segmented memory addressing. Should bse zero in x86_64

    // These registers can be used as general purpose registers, but may also have some special uses
    r15: u64 = 0, // General-purpose register (R15).
    r14: u64 = 0, // General-purpose register (R14).
    r13: u64 = 0, // General-purpose register (R13).
    r12: u64 = 0, // General-purpose register (R12).
    r11: u64 = 0, // General-purpose register (R11).
    r10: u64 = 0, // General-purpose register (R10).
    r9: u64 = 0, // General-purpose register (R9).
    r8: u64 = 0, // General-purpose register (R8).
    rsi: u64 = 0, // Source Index register (RSI), used as a pointer in array/string operations.
    rdi: u64 = 0, // Destination Index register (RDI), also used as a pointer in array/string operations.
    rdx: u64 = 0, // Data register (RDX), used in I/O operations and arithmetic operations.
    rcx: u64 = 0, // Counter register (RCX), used in loop operations and shift/rotate instructions.
    rbx: u64 = 0, // Base register (RBX), sometimes used to store a pointer to data.
    rax: u64 = 0, // Accumulator register (RAX), often used in arithmetic operations.

    rbp: u64 = 0, // Base Pointer register (RBP), points to the base of the current stack frame.
    rip: u64 = 0, // Instruction Pointer / PC register (RIP), points to the next instruction to be executed.
    cs: u64 = 0, // Code Segment (CS) register, contains the segment selector for the code segment.
    rflags: u64 = 0, // Flags register, holds the status flags and control flags.
    rsp: u64 = 0, // Stack Pointer register (RSP), points to the top of the current stack.
    ss: u64 = 0, // Stack Segment (SS) register, contains the segment selector for the stack segment.
};

pub inline fn stop() noreturn {
    while (true) {
        asm volatile ("hlt");
    }
}

//print to the console
pub inline fn inb(port: u16) u8 {
    return asm volatile ("inb %[port], %[result]"
        : [result] "={al}" (-> u8),
        : [port] "N{dx}" (port),
    );
}

pub inline fn outb(port: u16, data: u8) void {
    asm volatile ("outb %[data], %[port]"
        :
        : [data] "{al}" (data),
          [port] "N{dx}" (port),
    );
}

pub inline fn getCS() u16 {
    return asm volatile ("mov %cs, %[result]"
        : [result] "=r" (-> u16),
    );
}

pub inline fn lgdt(gdtr: u80) void {
    //Load GDT
    asm volatile (
        \\lgdt %[p]
        :
        : [p] "*p" (&gdtr),
    );
}

pub inline fn lidt(idtr: u80) void {
    asm volatile ("lidt %[p]"
        :
        : [p] "*p" (&idtr),
    );
}
