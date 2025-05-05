///This is used to store various files in ram
///it is designed with the goal to be very compact in ram
const mem = @import("memory.zig");
const list = @import("../utils/list.zig").List(u8);

//TODO: remove later
const db = @import("../utils/debug.zig");

//filesystem
//the filesystem is organized in nodes, a node can be any type of file, eg: a text file, an executable but also a directory or a ram page.

//the node list is a groqing array of pointer to the node struct
//each node itself stores it's data in a list

pub var node_list: list.List() = undefined;

pub var n_nodes: usize = 0; //the number of nodes in the filesystem

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
pub const Node = struct {
    id: usize, //the id of the node, is garantied to be unique
    name: []const u8,
    size: u32, //the size of the data of the node in bytes
    data: list, //the data stored in the node
    ftype: Ftype, //the type of the node
    parent: ?*Node, //the parent of the node in the filesystem tree, for root the parent is null

    pub fn create(name: []const u8, ftype: Ftype, parent: ?*Node) !Node {
        //create a new list
        const data = try list.init();
        return Node{ .id = n_nodes, .name = name, .size = 0, .data = data, .ftype = ftype, .parent = parent };
    }
};

pub fn init() !void {
    try mem.init();

    //we update the number of available nodes
    n_nodes = mem.n_pages;

    //allocate the stacks for the nnode list and block list
    //node_list = try mem.Stack.init();
    //block_list = try mem.Stack.init();

    //var test_node: Node = Node{ .id = 0, .size = 0, .n_blocks = 0, .ftype = Ftype.empty, .parent = null };
}
