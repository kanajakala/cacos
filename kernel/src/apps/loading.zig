const db = @import("../core/debug.zig");
const fs = @import("../core/fs.zig");

const mem = @import("../memory/memory.zig");

const stream = @import("../drivers/stream.zig");

pub fn run() void {
    const offset = "run ".len;
    const file: []const u8 = db.firstWordOfArray(stream.stdin[offset..]);

    //the binary file is loaded in memory at a specfic location
    //which is retrieved here
    const binary: u64 = fs.fileToMem(fs.addressFromName(file))[0];

    asm volatile (
        \\jmp *%[address]
        : // no output
        : [address] "{rax}" (mem.virtualFromIndex(binary)),
        : "rax", "memory"
    );
    //taken from https://github.com/yhyadev/yos/src/kernel/arch/x86_64/cpu.zig
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
                );

                // Return to the code we interrupted
                asm volatile (
                    \\iretq
                );
}
