const debug = @import("debug.zig");

const Process = packed struct {
    id: u32,
    function: *const fn () void,

    pub fn remove(self: *Process) void {
        self.* = undefined;
    }
};

var processes: [256]Process = .{Process{ .id = 0, .function = undefined }} ** 256;

fn testFunc() void {
    debug.print("Called function");
}

fn append(proc: Process) void {
    //We put the process at the first free spot
    for (processes, 0..) |process, i| {
        if (process.id == 0) {
            processes[i] = proc;
            return;
        }
    }
    return debug.panic("No more space for free processes");
}

pub fn remove(proc: Process) void {
    for (processes) |process| {
        if (process.id == proc.id) {
            process.remove;
        }
    }
}

pub fn run(id: u32, func: *const fn () void) void {
    if (id == 0) {
        return debug.panic("Process 0 is reserved");
    }
    //check if process already exists
    for (processes) |process| {
        if (process.id == id) {
            return debug.panic("process already exists");
        }
    }

    append(Process{ .id = id, .function = func });
}

pub fn init() void {
    run(12, &testFunc);
    for (processes) |process| {
        if (process.id != 0) process.function();
    }
}
