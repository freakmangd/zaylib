pub fn main() !void {
    rl.InitWindow(800, 600, "game");
    defer rl.CloseWindow();

    while (!rl.WindowShouldClose()) {
        const mpos = rl.GetMousePosition();

        rl.BeginDrawing();
        defer rl.EndDrawing();

        rl.ClearBackground(.black);

        rl.DrawTextFmt("window: {f}, mouse: {f}", .{ rl.GetScreenSize(), mpos }, 5, 5, 20, .white);
        rl.DrawRectangleLinesEx(.initCenteredV(mpos, .splat(10)), 1, .white);
    }
}

const std = @import("std");
const rl = @import("rl");
