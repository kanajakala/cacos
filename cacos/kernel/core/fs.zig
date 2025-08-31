//!This is an interface to interact with the file systems
const strings = @import("../utils/strings.zig");
const ramfs = @import("../core/ramfs.zig");
const mem = @import("memory.zig");
const std = @import("std");
//TODO: remove later
const db = @import("../utils/debug.zig");


///return an id corresponding to a name
pub fn idFromName(name: []const u8) !u16 {
    //we search through all the files and when we hit the right node we return it
    for (0..ramfs.node_list.size) |i| {
        const current_node: ramfs.Node = try ramfs.node_list.read(i);
        if (strings.equal(current_node.name, name)) {
            return current_node.id;
        }
    }
    return ramfs.errors.nodeNotFound;
}


//PATH EVALUATION
//
//  In cacos, path are provided to the kernel using '>' as a separator. For
//  exemple, " />bin>utils>test.bin" " is a path. It is the same as "
//  >/>bin>utils>test.bin>". In the kernel, path are represented as an ordered
//  list of ids representing the nodes of the path. Assuming '/' has id 0, 'bin' id 4 and
//  'test.bin' id 12, the path "/>bin>utils>test.bin" would be treated as
//  [0,4,12]. This allows for greater path length, and faster path operations
//  (probably)

const path_errors = error {
    string_path_too_many_tokens,
    invalid_string_path,
    invalid_path,
};


///returns a path from a string (eg: "/bin/misc/motd" to [0, 3, 12])
pub fn pathFromString(string_path: []const u8) ![]u16 {

    //first the path haas to be correct
    try checkPath(string_path);
    db.print("\npath: ");
    db.print(string_path);

    //we then strip unnecessary separators from the path strings
    var stripped_string_path: []const u8 = strings.strip('>', string_path);
    db.print("\nstripped path: ");
    db.print(stripped_string_path);

    //we have to get the number of tokens in the string
    //eaach token corresponds to a node in the path
    const n_tokens = strings.count('>', stripped_string_path) + 1;

    //check for overflow
    if (n_tokens >= 2048) return path_errors.string_path_too_many_tokens;

    db.print("\nallocating page for path");
    const buffer: *[2048]u16 = @alignCast(@ptrCast(try mem.alloc()));

    db.print("\nstarting reading tokens");
    for (0..n_tokens) |i| {
        //we read the first token and then remove it for the next iteration
        const token = strings.take('>', stripped_string_path, strings.Directions.right);
        db.print("\ntoken: ");
        db.print(token);
        stripped_string_path = strings.cut('>', stripped_string_path, strings.Directions.right);
        db.print("\ncut string: ");
        db.print(stripped_string_path);

        const id = try idFromName(token);
        db.debug("id", id, 1);

        buffer[i] = id;
    }

    return buffer[0..n_tokens];
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
    try pathFromString(path);
    return 0;
    // var path_buffer: [512]u16 = undefined;
    //
    // try pathFromString(string_path[1..], root, 0, &path_buffer);
    //
    // //we search through all the files and when we hit the right node we return it
    // for (0..node_list.size) |i| {
    //     const current_node: ramfs.Node = try node_list.read(i);
    //     if (std.mem.eql(u16,current_node.path, path_buffer[0..strings.count('/', string_path)])) {
    //         return current_node.id;
    //     }
    // }
    // return errors.nodeNotFound;
} 

