const debug = @import("debug.zig");

pub fn restartKeyboard() void {
    const data = debug.inb(0x61);
    debug.outb(0x61, data | 0x80);
    debug.outb(0x61, data | 0x7f);
}

pub inline fn getScanCode() u8 {
    var data: u8 = undefined;
    data = debug.inb(0x60);
    return data;
}
