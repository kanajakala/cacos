const debug = @import("debug.zig");

pub const Process = struct {
    id: u32,
    function: *const fn () void,

    pub fn remove(self: *Process) void {
        stop(self.id);
    }
    pub fn run(self: *const Process) void {
        self.function();
        //after the function is run we deinitialize it
        @constCast(self).remove();
    }
};

//empy process
const empty: Process = Process{ .id = 0, .function = undefined };
//list of all processes to be run
pub var processes: [256]Process = .{empty} ** 256;
//State of all processes (true means that the process is running)
pub var running: [256]bool = .{false} ** 256;

pub fn append(proc: Process) void {
    if (proc.id == 0) return debug.panic("Process 0 is reserved");
    if (proc.id >= 255) return debug.panic("id can't be bigger than 255");

    processes[proc.id] = proc;
    running[proc.id] = true;
}

pub fn stop(id: usize) void {
    if (id >= 255) return debug.panic("id can't be bigger than 255");
    processes[id] = empty;
    running[id] = false;
}
pub fn stopAll() void {
    for (0..processes.len - 1) |i| {
        stop(i);
    }
}

pub fn init() void {
    while (true) {
        for (processes) |process| {
            if (process.id != 0) process.run();
        }
    }
}
