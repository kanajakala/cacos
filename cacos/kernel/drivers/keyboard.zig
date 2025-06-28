const cpu = @import("../cpu/cpu.zig");
const isr = @import("../cpu/isr.zig");
const pic = @import("../cpu/pic.zig");
const console = @import("../interface/console.zig");
const db = @import("../utils/debug.zig");

const command_port = 0x64;
const data_port = 0x60;

const disable_first_port = 0xAD;
const enable_first_port = disable_first_port + 0x01;
const disable_second_port = 0xA7;
const enable_second_port = disable_second_port + 0x01;
const enable_leds = 0xED;
const led_mask = 0x07;

//global state of keyboard
pub var shifted: bool = false;
pub var control: bool = false;

/// Enable the communication of the PS/2 Keyboard
pub fn enable() void {
    cpu.outb(command_port, enable_first_port);
    cpu.outb(command_port, enable_second_port);
    //light the leds up
    cpu.outb(command_port, enable_leds);
    cpu.outb(command_port, led_mask);
}

/// Disable the communication of the PS/2 Keyboard
pub fn disable() void {
    cpu.outb(command_port, disable_first_port);
    cpu.outb(command_port, disable_second_port);
}

pub const KeyEvent = packed struct(u16) {
    code: Code,
    state: State,
    char: u8,

    pub const Code = enum(u7) {
        key_1,
        key_2,
        key_3,
        key_4,
        key_5,
        key_6,
        key_7,
        key_8,
        key_9,
        key_0,

        key_a,
        key_b,
        key_c,
        key_d,
        key_e,
        key_f,
        key_g,
        key_h,
        key_i,
        key_j,
        key_k,
        key_l,
        key_m,
        key_n,
        key_o,
        key_p,
        key_q,
        key_r,
        key_s,
        key_t,
        key_u,
        key_v,
        key_w,
        key_x,
        key_y,
        key_z,

        minus,
        plus,
        bracket_right,
        bracket_left,
        semicolon,
        quote,
        anti_slash,
        slash,
        comma,
        period,

        enter,
        shift,
        control,
        tab,
        backspace,
        escape,
        spacebar,

        up,
        down,
        right,
        left,

        unknown,
    };

    pub const State = enum(u1) {
        released,
        pressed,
    };
};

pub inline fn map(scancode: u8) KeyEvent {
    return switch (scancode) {
        2, 130 => .{ .code = .key_1, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) '1' else '!' },
        3, 131 => .{ .code = .key_2, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) '2' else '@' },
        4, 132 => .{ .code = .key_3, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) '3' else '#' },
        5, 133 => .{ .code = .key_4, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) '4' else '$' },
        6, 134 => .{ .code = .key_5, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) '5' else '%' },
        7, 135 => .{ .code = .key_6, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) '6' else '^' },
        8, 136 => .{ .code = .key_7, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) '7' else '7' },
        9, 137 => .{ .code = .key_8, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) '8' else '8' },
        10, 138 => .{ .code = .key_9, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) '9' else '9' },
        11, 139 => .{ .code = .key_0, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) '0' else '0' },
        16, 144 => .{ .code = .key_q, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) 'q' else 'Q' },
        17, 145 => .{ .code = .key_w, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) 'w' else 'W' },
        18, 146 => .{ .code = .key_e, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) 'e' else 'E' },
        19, 147 => .{ .code = .key_r, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) 'r' else 'R' },
        20, 148 => .{ .code = .key_t, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) 't' else 'T' },
        21, 149 => .{ .code = .key_y, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) 'y' else 'Y' },
        22, 150 => .{ .code = .key_u, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) 'u' else 'U' },
        23, 151 => .{ .code = .key_i, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) 'i' else 'I' },
        24, 152 => .{ .code = .key_o, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) 'o' else 'O' },
        25, 153 => .{ .code = .key_p, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) 'p' else 'P' },
        30, 158 => .{ .code = .key_a, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) 'a' else 'A' },
        31, 159 => .{ .code = .key_s, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) 's' else 'S' },
        32, 160 => .{ .code = .key_d, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) 'd' else 'D' },
        33, 161 => .{ .code = .key_f, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) 'f' else 'F' },
        34, 162 => .{ .code = .key_g, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) 'g' else 'G' },
        35, 163 => .{ .code = .key_h, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) 'h' else 'H' },
        38, 166 => .{ .code = .key_l, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) 'l' else 'L' },
        36, 164 => .{ .code = .key_j, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) 'j' else 'J' },
        37, 165 => .{ .code = .key_k, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) 'k' else 'K' },
        44, 172 => .{ .code = .key_z, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) 'z' else 'Z' },
        45, 173 => .{ .code = .key_x, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) 'x' else 'X' },
        46, 174 => .{ .code = .key_c, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) 'c' else 'C' },
        47, 175 => .{ .code = .key_v, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) 'v' else 'V' },
        48, 176 => .{ .code = .key_b, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) 'b' else 'B' },
        49, 177 => .{ .code = .key_n, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) 'n' else 'N' },
        50, 178 => .{ .code = .key_m, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) 'm' else 'M' },

        12, 140 => .{ .code = .minus, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) '-' else '_' },
        13, 141 => .{ .code = .plus, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) '+' else '=' },
        26, 154 => .{ .code = .bracket_right, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) '[' else ']' },
        27, 155 => .{ .code = .bracket_left, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) '{' else '}' },
        39, 167 => .{ .code = .semicolon, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) ';' else ':' },
        40, 168 => .{ .code = .quote, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) '\"' else '\'' },
        43, 171 => .{ .code = .anti_slash, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) '\\' else '|' },
        51, 179 => .{ .code = .comma, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) ',' else '<' },
        52, 180 => .{ .code = .period, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) '.' else '>' },
        53, 183 => .{ .code = .slash, .state = if (scancode >= 129) .released else .pressed, .char = if (!shifted) '/' else '?' },

        28, 156 => .{ .code = .enter, .state = if (scancode >= 129) .released else .pressed, .char = 0 },
        42, 170 => .{ .code = .shift, .state = if (scancode >= 129) .released else .pressed, .char = 0 },
        29, 157 => .{ .code = .control, .state = if (scancode >= 129) .released else .pressed, .char = 0 },
        //15, 143 => .{ .code = .tab, .state = if (scancode >= 129) .released else .pressed },
        14, 142 => .{ .code = .backspace, .state = if (scancode >= 129) .released else .pressed, .char = 0 },
        1, 129 => .{ .code = .escape, .state = if (scancode >= 129) .released else .pressed, .char = 0 },
        57, 185 => .{ .code = .spacebar, .state = if (scancode >= 129) .released else .pressed, .char = ' ' },

        72, 200 => .{ .code = .up, .state = if (scancode >= 129) .released else .pressed, .char = 0 },
        75, 203 => .{ .code = .left, .state = if (scancode >= 129) .released else .pressed, .char = 0 },
        77, 205 => .{ .code = .right, .state = if (scancode >= 129) .released else .pressed, .char = 0 },
        80, 208 => .{ .code = .down, .state = if (scancode >= 129) .released else .pressed, .char = 0 },

        else => .{ .code = .unknown, .state = .pressed, .char = 0 },
    };
}

fn keyboard_handler(_: *isr.InterruptStackFrame) callconv(.C) void {
    //Interrupts must end at some point
    defer pic.primary.endInterrupt();
    //We get the key from the key input port and convert it to a keyEvent
    const key = map(cpu.inb(0x60));
    //shift handling
    if (key.state == KeyEvent.State.pressed and key.code == KeyEvent.Code.shift) shifted = true;
    if (key.state == KeyEvent.State.released and key.code == KeyEvent.Code.shift) shifted = false;
    //control handling
    if (key.state == KeyEvent.State.pressed and key.code == KeyEvent.Code.control) control = true;
    if (key.state == KeyEvent.State.released and key.code == KeyEvent.Code.control) control = false;

    console.handle(key) catch |err| {
        db.printErr("\nerror in keyboard:\n");
        db.printErr(@errorName(err));
    };
}

pub fn init() void {
    //diable keyboard to prevent weird things from happening
    disable();

    pic.primary.enable(1);
    //set the function used to handle keypresses
    isr.handle(1, keyboard_handler);

    enable();
}
