const sc = @import("../libs/lib-syscalls.zig");

pub fn print(string: []const u8) void {
    _ = sc.syscall(sc.Syscalls.print, @intFromPtr(string.ptr), string.len, 0, 0);
}

pub fn printChar(value: u8) void {
    _ = sc.syscall(sc.Syscalls.print_char, value, 0, 0, 0);
}
