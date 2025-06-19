const sc = @import("../libs/lib-syscalls.zig");

pub fn print(string: []const u8) void {
    _ = sc.syscall(sc.Syscalls.debug, @intFromPtr(string.ptr), string.len, 0, 0);
}

pub fn debugValue(value: u64, mode: u8) void {
    _ = sc.syscall(sc.Syscalls.debugValue, value, mode, 0, 0);
}
