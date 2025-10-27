const db = @import("../utils/debug.zig");
const str = @import("../utils/strings.zig");

pub fn fail(exec_error: ?anyerror, error_message: []const u8) void {
    db.printErr("\n Test error: ");
    if (exec_error) db.printErr(@errorName(exec_error));
    db.printErr(" \n   -> ");
    db.printErr(error_message);
}

pub fn run_tests() void {

    db.print("\n\n------------------\nRUNNING TESTS:\n");

    //string tests
    const strings: [4][]const u8 = .{"/bin/home/ls", "bin/test/ls", "/bin/.", "bin/.."};

    var string: []const u8 = str.take_left('/',strings[0])[1..];
    if (!str.equal(string, "ls")) {
        db.printErr("Take left not working as expected on string ");
        db.print(strings[0]);
        db.printErr(" expected 'ls' got: ");
        db.print(string);
    }
    string = str.take_right('/',strings[1]);
    if (!str.equal(string, "bin")) {
        db.printErr("Take right not working as expected on string ");
        db.print(strings[1]);
        db.printErr(" expected 'bin' got: ");
        db.print(string);
    }
    db.print("\n\n------------------\nDONE TESTING\n");
}
