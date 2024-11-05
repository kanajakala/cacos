const db = @import("../core/debug.zig");

const binary: []const u8 = @embedFile("test.bin");
var address: u64 = undefined;

pub fn run() void {
    address = @intFromPtr(&binary);
    asm volatile (
        \\call *%[address]
        \\ret
        : // no output
        : [address] "{rax}" (address),
        : "rax", "memory"
    );
}
