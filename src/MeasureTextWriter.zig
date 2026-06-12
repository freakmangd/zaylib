const std = @import("std");
const rl = @import("init.zig");

const MeasureTextWriter = @This();

font: rl.Font,
size: rl.Vector2 = .{},
size_offset: rl.Vector2,
max_width: f32 = 0,
byte_count: f32 = 0,
max_byte_count: f32 = 0,
font_size: f32,
spacing: f32,
interface: std.Io.Writer,

/// I really don't know why Raylib has this minimum, but whatever
const default_font_size = 10; // Default Font chars height in pixel

pub fn init(font_size: f32, options: struct {
    spacing: ?f32 = null,
    font: ?rl.Font = null,
}) MeasureTextWriter {
    return .{
        .font_size = @max(font_size, default_font_size),
        .font = options.font orelse .getDefault(),
        .size_offset = .{ .y = font_size },
        .spacing = options.spacing orelse @divFloor(@max(font_size, default_font_size), default_font_size),
        .interface = .{
            .buffer = &.{}, // no reason to buffer this, and we don't handle it in drain
            .vtable = &.{ .drain = drain },
        },
    };
}

pub fn reset(self: *MeasureTextWriter) void {
    self.size_offset = .{};
}

pub fn print(self: *MeasureTextWriter, comptime fmt: []const u8, args: anytype) void {
    self.interface.print(fmt, args) catch unreachable; // DrawTextWriter's drain cannot return an error
}

fn drain(writer: *std.Io.Writer, data: []const []const u8, _: usize) std.Io.Writer.Error!usize {
    const self: *MeasureTextWriter = @alignCast(@fieldParentPtr("interface", writer));

    var written: usize = 0;
    for (data) |buf| {
        self.size = rl.MeasureTextSliceExOffsets(self.font, buf, self.font_size, self.spacing, &self.max_width, &self.byte_count, &self.max_byte_count, &self.size_offset);
        written += buf.len;
    }

    return written;
}
