const cpu = @import("cpu.zig");

pub var idt: [256]Entry = .{};

const Entry = packed struct {
    isr_low: u16,
    kernel_cs: u16,
    ist: u8,
    attributes: u8,
    isr_mid: u16,
    isr_high: u32,
    reserved: u32,
    pub fn setInterruptGate(self: *Entry) void {
        self.gate_type = 0b1110;
    }

    pub fn setTrapGate(self: *Entry) void {
        self.gate_type = 0b1111;
    }

    pub fn setHandler(self: *Entry, address: u64) *Entry {
        self.address_low = @truncate(address);
        self.address_high = @truncate(address >> 16);

        self.segment_selector = cpu.segments.cs();

        self.present = 1;

        return self;
    }
};

fn exceptionHandler() noreturn {
    while (true) {
        cpu.stop();
    }
}
