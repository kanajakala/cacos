///This is used to store various files in ram
///it is designed with the goal to be very compact in ram
const mem = @import("memory.zig");
const list = @import("../utils/list.zig");

//TODO: remove later
const db = @import("../utils/debug.zig");

const max_n_nodes = 4096;
var n_nodes: usize = undefined; //either the actual number of pages in the system or the maximum

var current_nodes = 0;
var current_blocks = 0;

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

pub var node_list: mem.Stack = undefined;
pub var block_list: mem.Stack = undefined;

pub const errors = error{
    outsideBounds,
};

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
    n_blocks: u16, //the number of blocks for this node
    ftype: Ftype, //the type of the node
    parent: ?*Node, //the parent of the node in the filesystem tree, for root the parent is null

    pub inline fn read(self: *Node, index: usize) !u8 {
        if (index >= self.size) return errors.outsideBounds;
        //const block_index = @divFloor(self.size, 4096);
        return 0;
    }

    pub inline fn write(self: *Node, index: usize, data: u8) !void {
        _ = self;
        _ = index + data;
        return;
    }

    pub inline fn addBlock(self: *Node) !void {
        const block = try Node.Block.init(self.id, self.n_blocks);
        try block_list.pushu64(@intFromPtr(&block));
        self.n_blocks += 1;
        current_blocks += 1;
    }

    /// the data of the Node is stored in this struct
    pub const Block = packed struct {
        owner: u16,
        index: u16, //the index of the block in the data
        data: *[4096]u8, //the data of the block

        ///allocates a page for the data and writes a pointer to itself to the block list
        pub fn init(owner: u16, index: u16) !Block {
            var page: []u8 = try mem.alloc();
            return Block{ .owner = owner, .index = index, .data = @ptrCast(&page) };
        }
    };
};

pub fn init() !void {
    try mem.init();
    try list.init();

    //we update the number of available nodes
    n_nodes = mem.n_pages;

    //allocate the stacks for the nnode list and block list
    //node_list = try mem.Stack.init();
    //block_list = try mem.Stack.init();

    //var test_node: Node = Node{ .id = 0, .size = 0, .n_blocks = 0, .ftype = Ftype.empty, .parent = null };
}
