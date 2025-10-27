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
    db.print("\n entering filesystem path creation:");

    db.print("\nreceived path: ");
    db.print(string_path);

    //we then strip unnecessary separators from the path strings
    var stripped_string_path: []const u8 = strings.strip('/', string_path);
    db.print("\nstripped path: ");
    db.print(stripped_string_path);

    //we have to get the number of tokens in the string
    //eaach token corresponds to a node in the path
    const n_tokens = strings.count('/', stripped_string_path) + 1;
    db.debug("number of tokens",n_tokens,0);

    //check for overflow
    if (n_tokens >= 2048) return path_errors.string_path_too_many_tokens;

    const buffer: *[2048]u16 = @alignCast(@ptrCast(try mem.alloc()));

    for (0..n_tokens) |i| {
        //we read the first token and then remove it for the next iteration
        //stripped_string_path = strings.strip('/', stripped_string_path);
        const token = strings.take_right('/', stripped_string_path);
        db.print("\n  token:  ");
        db.print(token);

        stripped_string_path = strings.cut_right('/', stripped_string_path);
        db.print("\n  cut string:  ");
        db.print(stripped_string_path);

        const id = idFromName(token) catch 0;

        buffer[i] = id;
    }

    db.print("\nDone preparing path, got: \n  ");
    db.debugPath(buffer[0..n_tokens]);
    db.print("\nreceived path: \n  ");
    db.print(string_path);
    return buffer[0..n_tokens];
}

///return the id of a file corresponding to a path
pub fn idFromPath(string_path: []const u8) !u16 {
    _ = try pathFromString(string_path);
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

