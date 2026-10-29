# zaylib

```zig
pub fn main() !void {
    rl.SetTraceLogLevel(.warning);
    rl.SetConfigFlags(.{ .window_resizable = true });

    rl.InitWindow(800, 600, "game");
    defer rl.CloseWindow();

    rl.SetExitKey(.null);

    const font: rl.Font = .initEx("NotoSansMono-Regular.ttf", 16, null);
    defer font.deinit();

    while (!rl.WindowShouldClose()) {
        if (rl.IsKeyDown(.left_control) and rl.IsKeyPressed(.q)) {
            return;
        }

        const mpos = rl.GetMousePosition();

        rl.BeginDrawing();
        defer rl.EndDrawing();

        rl.ClearBackground(.black);

        rl.DrawTextFmtEx("window: {f}, mouse: {f}", .{ rl.GetScreenSize(), mpos }, font, .init(5, 5), 16, 0, .white);
        rl.DrawRectangleLinesEx(.initCenteredV(mpos, .splat(10)), 1, .white);
    }
}
```

+ better text functions
    + `DrawTextSlice*` and `MeasureTextSlice*` functions take a slice rather than a zero-terminated pointer
    + `DrawTextFmt*` functions that take a fmt and args
    + `DrawTextWriter` is an `Io.Writer` interface that prints to a position on screen
+ mostly backwards compatible
    + packed structs replaced c ints, so functions like `SetConfigFlags` and `IsGestureDetected` will have to be updated
    + function names are unchanged, only new ones are added
        + function signatures are changed, but only to turn c pointers into higher context pointers
    + struct fields are unchanged
    + enums have aliases for compatibility: `rl.KeyboardKey.a == rl.KEY_A`
+ decl literals
    + most things have an `.init(...)` that corresponds to the function that would usually be used or just sets fields
        + `.initV` and `.initEx` variants exist as well
    + `.zero`, `.one`, `.splat(v)` for math structs
+ method syntax
    + functions that would make sense as methods are aliased as methods
    + before: `rl.Vector2DistanceSqr(rl.Vector2Lerp(rl.Vector2Add(rl.GetWorldToScreen2D(vec, cam), .one), .splat(100), t), .zero);`
    + after: `cam.getWorldToScreen(vec).add(.one).lerp(.splat(100), t).distanceSqr(.zero)`
+ `*Slice` functions: variants that take or return a slice rather than a pointer and length
+ c pointers are changed to the most appropriate type (ie `[*:E]T`, `?[*]T`, etc.) depending on the actual implementation
    + of course, this could become out of date if raylib changed the implementation, but this would affect C users just as much
+ c enums converted to real enums, and flag ints converted to packed structs
    + `rl.SetConfigFlags(.{ .window_resizable = true })`
+ `GetScreenWidth*`, `GetScreenHeight*`, `GetScreenSize`: variants for returning unsigned, floats, or a Vector2
+ format functions for `Vector*`, `Rectangle`, `Transform`, etc.
+ A bunch of vector, rectangle, and color functions
+ pretty much any time I make a helper function in a project that can be moved here, i move it here
