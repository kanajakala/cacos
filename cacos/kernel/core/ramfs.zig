///This is used to store various files in ram
///it is designed with the goal to be very compact in ram
const mem = @import("memory.zig");
const List = @import("../utils/list.zig").List(u8);
const NodeList = @import("../utils/list.zig").List(Node);
const strings = @import("../utils/strings.zig");
//TODO: remove later
const db = @import("../utils/debug.zig");

//filesystem
//the filesystem is organized in nodes, a node can be any type of file, eg: a text file, an executable but also a directory or a ram page.

//the node list is a groqing array of pointer to the node struct
//each node itself stores it's data in a list

pub var node_list: NodeList = undefined;

pub var n_nodes: usize = 0; //the number of nodes in the filesystem
pub var count: u16 = 0; //counts all created files in the filesystem

pub var current_directory = 0; //changed by apps through system calls

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
    id: u16, //the id of the node, is garantied to be unique
    name: []const u8,
    data: List, //the data stored in the node
    ftype: Ftype, //the type of the node
    parent: u16, //the parent of the node in the filesystem tree, for root the parent is null

    pub fn create(name: []const u8, ftype: Ftype, parent: u16) !Node {
        const data = try List.init();

        const node = Node{ .id = count, .name = name, .data = data, .ftype = ftype, .parent = parent };

        try node_list.write(count, node);

        n_nodes += 1;
        count += 1;
        return node;
    }

    pub fn write(self: *Node, index: usize, data: u8) !void {
        try self.data.write(index, data);
        try self.update();
    }

    pub fn append(self: *Node, data: u8) !void {
        try self.data.append(data);
        try self.update();
    }

    pub fn appendSlice(self: *Node, data: []u8) !void {
        try self.data.appendSlice(data);
        try self.update();
    }

    pub fn update(self: Node) !void {
        try node_list.write(self.id, self);
    }
};

pub fn idFromName(name: []const u8) !u16 {
    //return a node corresponding to a name
    //we search through all the files and when we hit the right node we return it
    for (0..node_list.size) |i| {
        const current_node: Node = try node_list.read(i);
        if (strings.equal(current_node.name, name)) {
            return current_node.id;
        }
    }
    return errors.nodeNotFound;
}

pub fn open(id: usize) !Node {
    //return a node corresponding to an id
    //we search through all the files and when we hit the right node we return it
    for (0..n_nodes) |i| {
        const current_node: Node = try node_list.read(i);
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

    root = try Node.create("/", Ftype.dir, 0);
}
