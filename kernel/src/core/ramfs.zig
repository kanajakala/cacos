///This is used to store various files in ram
///it is designed with the goal to be very compact in ram
const mem = @import("memory.zig");
const List = @import("../utils/list.zig").List(u8);
const NodeList = @import("../utils/list.zig").List(Node);
const std = @import("std");

//TODO: remove later
const db = @import("../utils/debug.zig");
const time = @import("../cpu/time.zig");

//filesystem
//the filesystem is organized in nodes, a node can be any type of file, eg: a text file, an executable but also a directory or a ram page.

//the node list is a groqing array of pointer to the node struct
//each node itself stores it's data in a list

pub var node_list: NodeList = undefined;

pub var n_nodes: usize = 0; //the number of nodes in the filesystem
pub var count: usize = 0; //counts all created files in the filesystem

pub const errors = error{
    outsideBounds,
    nodeNotFound,
};

//the root of all the other files:
pub var root: Node = undefined;

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
    data: List, //the data stored in the node
    ftype: Ftype, //the type of the node
    parent: ?*Node, //the parent of the node in the filesystem tree, for root the parent is null

    pub fn create(name: []const u8, ftype: Ftype, parent: ?*Node) !void {
        const data = try List.init();
        const node = Node{ .id = count, .name = name, .data = data, .ftype = ftype, .parent = parent };

        try node_list.write(node, count);

        n_nodes += 1;
        count += 1;
    }

    pub fn update(self: Node) !void {
        try node_list.write(self, self.id);
    }
};

pub fn open(id: usize) !Node {
    //return a node corresponding to an id
    //we search through all the files and when we hit the right node we return it
    for (0..n_nodes) |i| {
        const current_node: Node = try node_list.read(i);
        db.print(current_node.name);
        //db.debug("node address", try node_list.read(i), 0);
        if (current_node.id == id) {
            return current_node;
        }
    }
    return errors.nodeNotFound;
}

pub fn init() !void {
    try mem.init();

    //we initialize the node list
    node_list = try NodeList.init();

    try Node.create("/", Ftype.dir, null);
    const data = "test data inside root to see if I can read it from another place";
    root = (try open(0));
    db.print("\ncreated root");
    try root.data.appendSlice(@constCast(data[0..]));
    try root.update();
    db.print("\nappendedn root");
    db.debugNode(root);
}
