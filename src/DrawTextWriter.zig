const std = @import("std");
const rl = @import("init.zig");

const DrawTextWriter = @This();

font: rl.Font,
pos: rl.Vector2,
offset: rl.Vector2 = .{},
font_size: c_int,
spacing: f32,
tint: rl.Color,
interface: std.Io.Writer,

/// I really don't know why Raylib has this minimum, but whatever
const default_font_size = 10; // Default Font chars height in pixel

pub fn init(pos: rl.Vector2, font_size: c_int, tint: rl.Color, options: struct {
    spacing: ?f32 = null,
    font: ?rl.Font = null,
}) DrawTextWriter {
    return .{
        .pos = pos,
        .font_size = @max(font_size, default_font_size),
        .tint = tint,
        .font = options.font orelse .getDefault(),
        .spacing = options.spacing orelse @floatFromInt(@divFloor(@max(font_size, default_font_size), default_font_size)),
        .interface = .{
            .buffer = &.{}, // no reason to buffer this, right?
            .vtable = &.{ .drain = drain },
        },
    };
}

pub fn reset(self: *DrawTextWriter) void {
    self.offset = .{};
}

pub fn print(self: *DrawTextWriter, comptime fmt: []const u8, args: anytype) void {
    self.interface.print(fmt, args) catch unreachable; // DrawTextWriter's drain cannot return an error
}

fn drain(writer: *std.Io.Writer, data: []const []const u8, _: usize) std.Io.Writer.Error!usize {
    const self: *DrawTextWriter = @alignCast(@fieldParentPtr("interface", writer));

    var written: usize = 0;
    for (data) |buf| {
        written += buf.len;
        const offsets = rl.DrawTextSliceExOffsets(
            self.font,
            buf,
            self.pos,
            self.font_size,
            self.spacing,
            self.tint,
            self.offset,
        );
        self.offset = offsets;
    }

    return written;
}
