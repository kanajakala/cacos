const fs = @import("../core/ramfs.zig");
const db = @import("../utils/debug.zig");

pub var chars: fs.Node = undefined;

pub fn init() !void {
    chars = try fs.Node.create("chars", fs.Ftype.text, 0);
}
