const int = @import("../cpu/int.zig");
const pic = @import("../cpu/pic.zig");
const db = @import("../utils/debug.zig");

pub var ticks: usize = 0;
pub const ticks_per_second = 18; //ticks per second

pub const Timer = struct {
    started: usize,
    previous: usize,

    pub fn start() Timer {
        const current = ticks;
        return Timer{ .started = current, .previous = current };
    }

    /// Reads the timer value since start or the last reset in nanoseconds.
    pub fn read(self: *Timer) usize {
        return ticks - self.started;
    }

    /// Resets the timer value to 0/now.
    pub fn reset(self: *Timer) void {
        self.started = ticks;
    }

    /// Returns the current value of the timer in nanoseconds, then resets it.
    pub fn lap(self: *Timer) usize {
        defer self.started = ticks;
        return self.read();
    }
};

pub fn ticks2seconds(time: usize) usize {
    return time / ticks_per_second;
}

pub fn sleep_ticks(time: usize) void {
    const current = ticks;
    while (current + time >= ticks) {}
}

pub fn sleep(time: usize) void {
    sleep_ticks(time * ticks_per_second);
}

fn time_handler(_: *int.InterruptStackFrame) callconv(.C) void {
    //Interrupts must end at some point
    defer pic.primary.endInterrupt();
    ticks += 1;
}

pub fn init() !void {
    //enable the time interrupt in the pic
    pic.primary.enable(0);

    //set the function used to handle keypresses
    int.handle(0, time_handler);
}
