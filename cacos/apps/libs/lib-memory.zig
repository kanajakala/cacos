const sc = @import("../libs/lib-syscalls.zig");

const Allocation = packed struct(u64) { address: u48, length: u16 };

pub fn alloc(n_bytes: u64) []u8 {
    const value = sc.syscall(sc.Syscalls.alloc, n_bytes, 0, 0, 0);
    const allocation: Allocation = @bitCast(value);
    //transform the value into a slice of u8s
    return @as([*]u8, @ptrFromInt(allocation.address))[0..n_bytes];
}

pub fn free(page: []u8) void {
    _ = page;
    const message = "Freed memory";
    _ = sc.syscall(sc.Syscalls.debug, @intFromPtr(message.ptr), message.len, 0, 0);
}
