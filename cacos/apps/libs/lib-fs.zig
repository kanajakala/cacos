const sc = @import("../libs/lib-syscalls.zig");
const db = @import("../libs/lib-debug.zig");

const Node = packed struct(u64) {
    id: u16, //id of the node
    ftype: u16, //type of the node
    size: u16, //size of the node in bytes
    parent: u16, //id of the parent of the node

    pub fn read(self: Node, index: u64) u8 {
        return @truncate(sc.syscall(sc.Syscalls.read, index, self.id, 0, 0));
    }

    pub fn readToBuffer(self: Node, index: u64, size: u64, buffer: []u8) void {
        if (buffer.len > size) return;
        _ = sc.syscall(sc.Syscalls.read_to_buffer, index, size, @intFromPtr(buffer.ptr), self.id);
    }

    pub fn getChilds(self: Node) []u16 {
            const Allocation = packed struct(u64) { address: u48, length: u16 }; //we assume the address and length fit in their respective integer representations
                                                                                 //here the length will also be the number of children
        const allocation: Allocation = @bitCast(sc.syscall(sc.Syscalls.get_childs, self.id, 0, 0, 0));
        return @as([*]u16, @ptrFromInt(allocation.address))[0..allocation.length];
    }

};

pub fn nameToBuffer(id: u16, buffer: []u8) u64 {
    //this writes data to the buffer
    //returns the length of the name
    return sc.syscall(sc.Syscalls.node_name_to_buffer, id, @intFromPtr(buffer.ptr), 0, 0);
}

pub fn open(name: []const u8) Node {
    const value = sc.syscall(sc.Syscalls.open, @intFromPtr(name.ptr), name.len, 0, 0);
    var node: Node = undefined;
    node = @bitCast(value);
    return node;
}
