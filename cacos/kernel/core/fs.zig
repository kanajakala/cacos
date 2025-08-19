//!This is an interface to interact with the file systems
const strings = @import("../utils/strings.zig");
const ramfs = @import("../core/ramfs.zig");
const std = @import("std");
//TODO: remove later
const db = @import("../utils/debug.zig");


///return an id corresponding to a name
pub fn idFromName(name: []const u8) !u16 {
    //we search through all the files and when we hit the right node we return it
    for (0..ramfs.node_list.size) |i| {
        const current_node: ramfs.Node = try node_list.read(i);
        if (strings.equal(current_node.name, name)) {
            return current_node.id;
        }
    }
    return errors.nodeNotFound;
}

const path_errors = error {
    invalid_string_path,
    invalid_path,
};


///returns a path from a string (eg: "/bin/misc/motd" to [0, 3, 12])
pub fn pathFromString(string_path: []const u8, starting_node: ramfs.Node, starting_index: usize, buffer: *[512]u16) !void {
    const number_of_nodes_in_path = strings.count('/', string_path);
    
    const current_node_name = strings.take('/', string_path, strings.Directions.right);
    const current_node = try ramfs.open(try idFromName(current_node_name));

    //we check if the current node haas the right parrent (the starting node)
    //if it isn't then the provided path is not valid
    if (current_node.path[current_node.path.len - 1] != starting_node.id) return path_errors.invalid_string_path;

    buffer[starting_index] = current_node.id;

    if (number_of_nodes_in_path != 0) {
        try pathFromString(strings.cut('/', string_path, strings.Directions.right), current_node, starting_index + 1, buffer);
    } 
}

///check if a path is valid
///we first check if the root is correct
///then we descend the path and ensure all nodes are in this order
///if the path is correct nothing is returned
///else an error is returned
pub fn checkPath(path: []const u8) !void {
    _ = path;
    return;    
}

///return the id of a file corresponding to a path
pub fn idFromPath(string_path: []const u8) !u16 {
    try checkPath(string_path);

    var path_buffer: [512]u16 = undefined;

    try pathFromString(string_path[1..], root, 0, &path_buffer);
    
    //we search through all the files and when we hit the right node we return it
    for (0..node_list.size) |i| {
        const current_node: ramfs.Node = try node_list.read(i);
        if (std.mem.eql(u16,current_node.path, path_buffer[0..strings.count('/', string_path)])) {
            return current_node.id;
        }
    }
    return errors.nodeNotFound;
} 

