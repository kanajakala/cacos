const db = @import("debug.zig");
const pic = @import("pic.zig");
const idt = @import("idt.zig");
const cpu = @import("cpu.zig");
const fs = @import("fs.zig");
const mem = @import("../memory/memory.zig");

pub const Process = struct {
    id: usize,
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
    if (proc.id == 0) return db.panic("Process 0 is reserved");
    if (proc.id >= 255) return db.panic("id can't be bigger than 255");

    processes[proc.id] = proc;
    running[proc.id] = true;
}

pub fn getFree() usize {
    for (1..running.len - 1) |i| {
        if (!running[i]) return i;
    }
    db.panic("All process space is used");
    return 0;
}

pub fn stop(id: usize) void {
    if (id >= 255) return db.panic("id can't be bigger than 255");
    processes[id] = empty;
    running[id] = false;
}
pub fn stopAll() void {
    for (0..processes.len - 1) |i| {
        stop(i);
    }
}

//  binary loading

pub fn execute(file: u64) void {

    //the binary file is loaded in memory at a specfic location
    //which is retrieved here
    const binary: u64 = fs.fileToMem(file)[0];

    db.print("first context save:");
    cpu.context.save();

    db.print("\njumping to start of binary\n");
    cpu.jump(mem.virtualFromIndex(binary));

    db.print("returned to kernel\n");
}

pub fn returnToKernel(_: *idt.InterruptStackFrame) callconv(.C) void {
    db.print("\n\nReturning to kernel...\n");
    db.print("\ncontext after interrupt call");
    cpu.context.debug();
    db.print("\nattempting to restore kernel:\n");
    cpu.context.restore();
    db.print("Restore succesful\n");
}

pub fn init() void {
    //enable the kernel return interrupt
    pic.primary.enable(2);

    //set the function used to handle keypresses
    idt.handle(2, returnToKernel);

    //The Kernel is process 0 and is always running
    running[0] = true;
    while (true) {
        for (processes) |process| {
            if (process.id != 0) process.run();
        }
    }
}
