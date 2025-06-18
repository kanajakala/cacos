const sc = @import("../libs/lib-syscalls.zig");

pub fn print(string: []const u8) void {
    _ = sc.syscall(sc.Syscalls.print, @intFromPtr(string.ptr), string.len, 0, 0);
}
