///This is used to store various files in ram
///it is designed with the goal to be very compact in ram
const mem = @import("memory.zig");

const max_n_nodes = 4096;
var n_nodes: usize = undefined; //either the actual number of pages in the system or the maximum

//filesystem
//the filesystem is organized in nodes, a node can be any type of file, eg: a text file, an executable but also a directory or a ram page.
//pub const empty_node = Node{ .name = "", .size = 0, .ftype = Ftype.empty, .parent = null, .block_list = .{0} ** 10 };
//pub const max_nodes: [max_n_nodes]Node = empty_node ** max_n_nodes; //list of all node
//pub const nodes: []Node = undefined; //list of all node

//the list of nodes is stored in ram in a stack
//it is a list of pointer to the node struct
//currently we allocate a single page so there can be 4096 / 8 = 512 nodes in the filesystem
//each node writes data in blocks which are of size one page
//the addresses of these blocks are stored in a stack

pub var node_list: *[512]u64 = undefined;
pub var block_list: *[512]u64 = undefined;

//the different node types
pub const Ftype = enum(u8) {
    empty, //empty node
    dir, //a directory, does not contain data
    raw, //raw binary file
    text, //utf8 encoded text
};

//The filesystem is entirely made of these
pub const Node = packed struct {
    id: u16, //the id of the node
    size: u32, //the size of the data of the node in bytes
    ftype: Ftype, //the type of the node
    parent: ?*Node, //the parent of the node in the filesystem tree, for root the parent is null
    block_list: [10]usize, //the list of addresses of the blocks of the data

    pub fn read(self: *Node, index: usize) !u8 {
        _ = self;
        _ = index;
        return 0;
    }

    pub fn write(self: *Node, index: usize, data: u8) !void {
        _ = self;
        _ = index + data;
        return;
    }
};

pub const Block = packed struct {
    owner: @TypeOf(Node.id), //the Node which owns the block
    data: *[4096]u8, //the data of the block
};

pub fn init() !void {
    try mem.init();

    //we update the number of available nodes
    n_nodes = mem.n_pages;

    //we have to convert the slice of u8 a slice of u64
    const page: []u8 = mem.alloc() catch mem.mmap[0..0];
    node_list = @alignCast(@ptrCast(page));
}
