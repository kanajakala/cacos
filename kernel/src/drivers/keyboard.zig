const cpu = @import("../cpu/cpu.zig");

pub var shifted: bool = false;

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
        shift,
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
        42, 170 => .{ .code = .shift, .state = if (scancode >= 129) .released else .pressed },
        //15, 143 => .{ .code = .tab, .state = if (scancode >= 129) .released else .pressed },
        14, 142 => .{ .code = .backspace, .state = if (scancode >= 129) .released else .pressed },
        1, 129 => .{ .code = .escape, .state = if (scancode >= 129) .released else .pressed },
        57, 185 => .{ .code = .spacebar, .state = if (scancode >= 129) .released else .pressed },
        else => .{ .code = .unknown, .state = .pressed },
    };
}

pub inline fn keyEventToChar(ke: KeyEvent) u8 {
    //normal keymap:
    if (!shifted) {
        return switch (ke.code) {
            KeyEvent.Code.key_1 => '1',
            KeyEvent.Code.key_2 => '2',
            KeyEvent.Code.key_3 => '3',
            KeyEvent.Code.key_4 => '4',
            KeyEvent.Code.key_5 => '5',
            KeyEvent.Code.key_6 => '6',
            KeyEvent.Code.key_7 => '7',
            KeyEvent.Code.key_8 => '8',
            KeyEvent.Code.key_9 => '9',
            KeyEvent.Code.key_0 => '0',
            KeyEvent.Code.key_a => 'a',
            KeyEvent.Code.key_b => 'b',
            KeyEvent.Code.key_c => 'c',
            KeyEvent.Code.key_d => 'd',
            KeyEvent.Code.key_e => 'e',
            KeyEvent.Code.key_f => 'f',
            KeyEvent.Code.key_g => 'g',
            KeyEvent.Code.key_h => 'h',
            KeyEvent.Code.key_i => 'i',
            KeyEvent.Code.key_j => 'j',
            KeyEvent.Code.key_k => 'k',
            KeyEvent.Code.key_l => 'l',
            KeyEvent.Code.key_m => 'm',
            KeyEvent.Code.key_n => 'n',
            KeyEvent.Code.key_o => 'o',
            KeyEvent.Code.key_p => 'p',
            KeyEvent.Code.key_q => 'q',
            KeyEvent.Code.key_r => 'r',
            KeyEvent.Code.key_s => 's',
            KeyEvent.Code.key_t => 't',
            KeyEvent.Code.key_u => 'u',
            KeyEvent.Code.key_v => 'v',
            KeyEvent.Code.key_w => 'w',
            KeyEvent.Code.key_x => 'x',
            KeyEvent.Code.key_y => 'y',
            KeyEvent.Code.key_z => 'z',

            KeyEvent.Code.spacebar => 0x20,
            KeyEvent.Code.enter => 0xa,
            KeyEvent.Code.backspace => 0x08,
            else => 0,
        };
    } else {
        return switch (ke.code) {
            KeyEvent.Code.key_1 => '!',
            KeyEvent.Code.key_2 => '@',
            KeyEvent.Code.key_3 => '#',
            KeyEvent.Code.key_4 => '$',
            KeyEvent.Code.key_5 => '%',
            KeyEvent.Code.key_6 => '^',
            KeyEvent.Code.key_7 => '&',
            KeyEvent.Code.key_8 => '*',
            KeyEvent.Code.key_9 => '(',
            KeyEvent.Code.key_0 => ')',
            KeyEvent.Code.key_a => 'A',
            KeyEvent.Code.key_b => 'B',
            KeyEvent.Code.key_c => 'C',
            KeyEvent.Code.key_d => 'D',
            KeyEvent.Code.key_e => 'E',
            KeyEvent.Code.key_f => 'F',
            KeyEvent.Code.key_g => 'G',
            KeyEvent.Code.key_h => 'H',
            KeyEvent.Code.key_i => 'I',
            KeyEvent.Code.key_j => 'J',
            KeyEvent.Code.key_k => 'K',
            KeyEvent.Code.key_l => 'L',
            KeyEvent.Code.key_m => 'M',
            KeyEvent.Code.key_n => 'N',
            KeyEvent.Code.key_o => 'O',
            KeyEvent.Code.key_p => 'P',
            KeyEvent.Code.key_q => 'Q',
            KeyEvent.Code.key_r => 'R',
            KeyEvent.Code.key_s => 'S',
            KeyEvent.Code.key_t => 'T',
            KeyEvent.Code.key_u => 'U',
            KeyEvent.Code.key_v => 'V',
            KeyEvent.Code.key_w => 'W',
            KeyEvent.Code.key_x => 'X',
            KeyEvent.Code.key_y => 'Y',
            KeyEvent.Code.key_z => 'Z',
            else => 0,
        };
    }
}

pub inline fn listener() u8 {
    const key: KeyEvent = map(getScanCode());
    const value: u8 = keyEventToChar(key);

    if (key.state == KeyEvent.State.pressed and key.code == KeyEvent.Code.shift) shifted = true;
    if (key.state == KeyEvent.State.released and key.code == KeyEvent.Code.shift) shifted = false;
    if (key.state == KeyEvent.State.pressed) {
        return value;
    } else {
        return 0;
    } //if key is PRESSED
}
