const cpu = @import("cpu.zig");

pub fn restartKeyboard() void {
    const data = cpu.inb(0x61);
    cpu.outb(0x61, data | 0x80);
    cpu.outb(0x61, data | 0x7f);
}

pub inline fn getScanCode() u8 {
    var data: u8 = undefined;
    data = cpu.inb(0x60);
    return data;
}

pub const KeyEvent = packed struct {
    code: Code,
    state: State,

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

        enter,
        tab,
        backspace,
        escape,
        spacebar,

        unknown,
    };

    pub const State = enum(u1) {
        released,
        pressed,
    };
};

pub inline fn map(scancode: u8) KeyEvent {
    return switch (scancode) {
        2, 130 => .{ .code = .key_1, .state = if (scancode >= 129) .released else .pressed },
        3, 131 => .{ .code = .key_2, .state = if (scancode >= 129) .released else .pressed },
        4, 132 => .{ .code = .key_3, .state = if (scancode >= 129) .released else .pressed },
        5, 133 => .{ .code = .key_4, .state = if (scancode >= 129) .released else .pressed },
        6, 134 => .{ .code = .key_5, .state = if (scancode >= 129) .released else .pressed },
        7, 135 => .{ .code = .key_6, .state = if (scancode >= 129) .released else .pressed },
        8, 136 => .{ .code = .key_7, .state = if (scancode >= 129) .released else .pressed },
        9, 137 => .{ .code = .key_8, .state = if (scancode >= 129) .released else .pressed },
        10, 138 => .{ .code = .key_9, .state = if (scancode >= 129) .released else .pressed },
        11, 139 => .{ .code = .key_0, .state = if (scancode >= 129) .released else .pressed },
        16, 144 => .{ .code = .key_q, .state = if (scancode >= 129) .released else .pressed },
        17, 145 => .{ .code = .key_w, .state = if (scancode >= 129) .released else .pressed },
        18, 146 => .{ .code = .key_e, .state = if (scancode >= 129) .released else .pressed },
        19, 147 => .{ .code = .key_r, .state = if (scancode >= 129) .released else .pressed },
        20, 148 => .{ .code = .key_t, .state = if (scancode >= 129) .released else .pressed },
        21, 149 => .{ .code = .key_y, .state = if (scancode >= 129) .released else .pressed },
        22, 150 => .{ .code = .key_u, .state = if (scancode >= 129) .released else .pressed },
        23, 151 => .{ .code = .key_i, .state = if (scancode >= 129) .released else .pressed },
        24, 152 => .{ .code = .key_o, .state = if (scancode >= 129) .released else .pressed },
        25, 153 => .{ .code = .key_p, .state = if (scancode >= 129) .released else .pressed },
        30, 158 => .{ .code = .key_a, .state = if (scancode >= 129) .released else .pressed },
        31, 159 => .{ .code = .key_s, .state = if (scancode >= 129) .released else .pressed },
        32, 160 => .{ .code = .key_d, .state = if (scancode >= 129) .released else .pressed },
        33, 161 => .{ .code = .key_f, .state = if (scancode >= 129) .released else .pressed },
        34, 162 => .{ .code = .key_g, .state = if (scancode >= 129) .released else .pressed },
        35, 163 => .{ .code = .key_h, .state = if (scancode >= 129) .released else .pressed },
        38, 166 => .{ .code = .key_l, .state = if (scancode >= 129) .released else .pressed },
        36, 164 => .{ .code = .key_j, .state = if (scancode >= 129) .released else .pressed },
        37, 165 => .{ .code = .key_k, .state = if (scancode >= 129) .released else .pressed },
        44, 172 => .{ .code = .key_z, .state = if (scancode >= 129) .released else .pressed },
        45, 173 => .{ .code = .key_x, .state = if (scancode >= 129) .released else .pressed },
        46, 174 => .{ .code = .key_c, .state = if (scancode >= 129) .released else .pressed },
        47, 175 => .{ .code = .key_v, .state = if (scancode >= 129) .released else .pressed },
        48, 176 => .{ .code = .key_b, .state = if (scancode >= 129) .released else .pressed },
        49, 177 => .{ .code = .key_n, .state = if (scancode >= 129) .released else .pressed },
        50, 178 => .{ .code = .key_m, .state = if (scancode >= 129) .released else .pressed },
        28, 156 => .{ .code = .enter, .state = if (scancode >= 129) .released else .pressed },
        15, 143 => .{ .code = .tab, .state = if (scancode >= 129) .released else .pressed },
        14, 142 => .{ .code = .backspace, .state = if (scancode >= 129) .released else .pressed },
        1, 129 => .{ .code = .escape, .state = if (scancode >= 129) .released else .pressed },
        57, 185 => .{ .code = .spacebar, .state = if (scancode >= 129) .released else .pressed },
        else => .{ .code = .unknown, .state = .pressed },
    };
}

pub inline fn keyEventToChar(ke: KeyEvent) u8 {
    return switch (ke.code) {
        KeyEvent.Code.key_1 => 0x31,
        KeyEvent.Code.key_2 => 0x32,
        KeyEvent.Code.key_3 => 0x33,
        KeyEvent.Code.key_4 => 0x34,
        KeyEvent.Code.key_5 => 0x35,
        KeyEvent.Code.key_6 => 0x36,
        KeyEvent.Code.key_7 => 0x37,
        KeyEvent.Code.key_8 => 0x38,
        KeyEvent.Code.key_9 => 0x39,
        KeyEvent.Code.key_0 => 0x30,
        KeyEvent.Code.key_a => 0x61,
        KeyEvent.Code.key_b => 0x62,
        KeyEvent.Code.key_c => 0x63,
        KeyEvent.Code.key_d => 0x64,
        KeyEvent.Code.key_e => 0x65,
        KeyEvent.Code.key_f => 0x66,
        KeyEvent.Code.key_g => 0x67,
        KeyEvent.Code.key_h => 0x68,
        KeyEvent.Code.key_i => 0x69,
        KeyEvent.Code.key_j => 0x6A,
        KeyEvent.Code.key_k => 0x6B,
        KeyEvent.Code.key_l => 0x6C,
        KeyEvent.Code.key_m => 0x6D,
        KeyEvent.Code.key_n => 0x6E,
        KeyEvent.Code.key_o => 0x6F,
        KeyEvent.Code.key_p => 0x70,
        KeyEvent.Code.key_q => 0x71,
        KeyEvent.Code.key_r => 0x72,
        KeyEvent.Code.key_s => 0x73,
        KeyEvent.Code.key_t => 0x74,
        KeyEvent.Code.key_u => 0x75,
        KeyEvent.Code.key_v => 0x76,
        KeyEvent.Code.key_w => 0x77,
        KeyEvent.Code.key_x => 0x78,
        KeyEvent.Code.key_y => 0x79,
        KeyEvent.Code.key_z => 0x7a,
        KeyEvent.Code.spacebar => 0x20,
        KeyEvent.Code.enter => 0xa,
        KeyEvent.Code.backspace => 0x08,
        else => 0,
    };
}

pub inline fn listener() u8 {
    if (getScanCode() > 130) return 0;
    const value: u8 = keyEventToChar(map(getScanCode()));
    if (map(getScanCode()).state == KeyEvent.State.pressed) {
        return value;
    } else {
        return 0;
    } //if key is PRESSED
}
