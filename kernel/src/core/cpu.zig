const db = @import("debug.zig");

pub inline fn stop() noreturn {
    while (true) {
        asm volatile ("hlt");
    }
}

///Get value at port
pub inline fn inb(port: u16) u8 {
    return asm volatile ("inb %[port], %[result]"
        : [result] "={al}" (-> u8),
        : [port] "N{dx}" (port),
    );
}

///output value at port
pub inline fn outb(port: u16, data: u8) void {
    asm volatile ("outb %[data], %[port]"
        :
        : [data] "{al}" (data),
          [port] "N{dx}" (port),
    );
}

///Get Code Segment
pub inline fn getCS() u16 {
    return asm volatile ("mov %cs, %[result]"
        : [result] "=r" (-> u16),
    );
}

///Load Global Descriptor Table
pub inline fn lgdt(gdtr: u80) void {
    //Load GDT
    asm volatile (
        \\lgdt %[p]
        :
        : [p] "*p" (&gdtr),
    );
}

///load the Interrupt Descriptor Table
pub inline fn lidt(idtr: u80) void {
    asm volatile ("lidt %[p]"
        :
        : [p] "*p" (&idtr),
    );
}

/// Perform a short I/O delay.
pub fn wait() void {
    // port 0x80 was wired to a hex display in the past and
    // is now mostly unused. Writing garbage data to port 0x80
    // allegedly takes long enough to make everything work on most
    // hardware.
    outb(0x80, 0);
}

///wait for interrupt
pub inline fn hang() noreturn {
    while (true) {
        asm volatile ("hlt");
    }
}

pub fn jump(address: u64) void {
    asm volatile (
        \\call *%[address]
        : // no output
        : [address] "{rax}" (address),
        : "rax", "memory"
    );
}

pub const Context = struct {
    ip: u64, //saves the instruction pointer
    sp: u64, //saves the stack pointer

    pub fn save(self: *Context) void {
        self.ip = getInstructionPointer();
        self.sp = getStackPointer();
        self.debug();
    }

    pub fn restore(self: *Context) void {
        //restore stack pointer
        //const sp = self.sp; //we create consts because inline assembly does't allow struct fields
        //asm volatile (
        //    \\mov %[addr], %%rsp  // Restore stack pointer
        //    :
        //    : [addr] "r" (sp),
        //    : "memory"
        //);
        db.print("  restored stack pointer\n");
        self.debug();
    }

    pub fn debug(self: *Context) void {
        db.print("\nsaved SP: ");
        db.printValue(self.sp);
        db.print("\n-----\n");
        db.print("real SP: ");
        db.printValue(getStackPointer());
        db.print("\n");
    }
};

pub var context: Context = Context{ .ip = 0, .sp = 0 };

pub fn getInstructionPointer() u64 {
    return asm volatile (
        \\call 1f
        \\1:
        \\pop %[ret]
        : [ret] "=r" (-> u64),
        :
        : "memory"
    );
}

fn getStackPointer() u64 {
    return asm volatile (
        \\mov %%rsp, %[ret]
        : [ret] "=r" (-> u64),
        :
        : "memory"
    );
}
