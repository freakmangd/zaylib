const std = @import("std");
const builtin = @import("builtin");
pub const rm = @import("raymath.zig");
pub const c = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
    @cInclude("rlgl.h");
});

comptime {
    @setEvalBranchQuota(10_000);

    const decls = std.meta.declarations(@This());

    // check for type errors in everything but c decls
    for (decls) |decl| {
        if (!(decl.name.len == 1 and decl.name[0] == 'c')) {
            const d = @field(@This(), decl.name);

            if (@TypeOf(d) == type) switch (@typeInfo(d)) {
                .@"struct", .@"enum", .@"union", .@"opaque" => std.testing.refAllDecls(d),
                else => {},
            };
            _ = &d;
        }
    }

    // make sure structs are synced
    for (decls) |decl| {
        const ThisDecl = @field(@This(), decl.name);

        if (!@hasDecl(c, decl.name) or
            @TypeOf(ThisDecl) != type or
            @typeInfo(ThisDecl) != .@"struct") continue;

        const CDecl = @field(c, decl.name);

        if (@sizeOf(CDecl) != @sizeOf(ThisDecl)) {
            @compileError(
                std.fmt.comptimePrint("Mismatched size for type {s}. Expected {} found {}", .{
                    decl.name,
                    @sizeOf(CDecl),
                    @sizeOf(ThisDecl),
                }),
            );
        }

        if (@typeInfo(CDecl) != .@"struct") continue;

        const ThisDecl_info = @typeInfo(ThisDecl).@"struct";
        const CDecl_info = @typeInfo(CDecl).@"struct";

        if (ThisDecl_info.fields.len != CDecl_info.fields.len) {
            @compileError(
                std.fmt.comptimePrint("Mismatched fields len for type {s}. Expected {} found {}", .{
                    decl.name,
                    CDecl_info.fields.len,
                    ThisDecl_info.fields.len,
                }),
            );
        }

        for (ThisDecl_info.fields) |this_field| {
            const this_field_info = @typeInfo(this_field.type);
            const c_field = @FieldType(CDecl, this_field.name);
            const c_field_info = @typeInfo(c_field);

            if (@offsetOf(ThisDecl, this_field.name) != @offsetOf(CDecl, this_field.name)) {
                @compileError(
                    std.fmt.comptimePrint("Mismatched field offset `{s}` for type `{s}`. Expected {} found {}", .{
                        c_field.name,
                        decl.name,
                        @offsetOf(CDecl, c_field.name),
                        @offsetOf(ThisDecl, this_field.name),
                    }),
                );
            }

            if (this_field.type != c_field) bad_field_type: {
                switch (c_field_info) {
                    .pointer, .optional, .array, .@"struct" => {
                        if (@sizeOf(this_field.type) == @sizeOf(c_field)) break :bad_field_type;
                    },
                    else => {
                        if (c_field_info == .int and this_field_info == .@"enum" and
                            this_field_info.@"enum".tag_type == c_field) break :bad_field_type;
                    },
                }

                @compileError(
                    std.fmt.comptimePrint("Mismatched field type `{s}` for type `{s}`. Expected {} found {}", .{
                        c_field.name,
                        decl.name,
                        c_field.type,
                        this_field.type,
                    }),
                );
            }
        }
    }
}

pub const TraceLogCallback = ?*const fn (c_int, [*c]const u8, [*c]c.struct___va_list_tag_1) callconv(.C) void;
pub const LoadFileDataCallback = ?*const fn ([*c]const u8, [*c]c_int) callconv(.C) [*c]u8;
pub const SaveFileDataCallback = ?*const fn ([*c]const u8, ?*anyopaque, c_int) callconv(.C) bool;
pub const LoadFileTextCallback = ?*const fn ([*c]const u8) callconv(.C) [*c]u8;
pub const SaveFileTextCallback = ?*const fn ([*c]const u8, [*c]u8) callconv(.C) bool;
pub const AudioCallback = ?*const fn (?*anyopaque, c_uint) callconv(.C) void;

pub const Color = extern struct {
    r: u8 = 0,
    g: u8 = 0,
    b: u8 = 0,
    a: u8 = 0,

    pub const lightgray = fromRaylib(c.LIGHTGRAY);
    pub const gray = fromRaylib(c.GRAY);
    pub const darkgray = fromRaylib(c.DARKGRAY);
    pub const yellow = fromRaylib(c.YELLOW);
    pub const gold = fromRaylib(c.GOLD);
    pub const orange = fromRaylib(c.ORANGE);
    pub const pink = fromRaylib(c.PINK);
    pub const red = fromRaylib(c.RED);
    pub const maroon = fromRaylib(c.MAROON);
    pub const green = fromRaylib(c.GREEN);
    pub const lime = fromRaylib(c.LIME);
    pub const darkgreen = fromRaylib(c.DARKGREEN);
    pub const skyblue = fromRaylib(c.SKYBLUE);
    pub const blue = fromRaylib(c.BLUE);
    pub const darkblue = fromRaylib(c.DARKBLUE);
    pub const purple = fromRaylib(c.PURPLE);
    pub const violet = fromRaylib(c.VIOLET);
    pub const darkpurple = fromRaylib(c.DARKPURPLE);
    pub const beige = fromRaylib(c.BEIGE);
    pub const brown = fromRaylib(c.BROWN);
    pub const darkbrown = fromRaylib(c.DARKBROWN);
    pub const white = fromRaylib(c.WHITE);
    pub const black = fromRaylib(c.BLACK);
    pub const blank = fromRaylib(c.BLANK);
    pub const magenta = fromRaylib(c.MAGENTA);
    pub const raywhite = fromRaylib(c.RAYWHITE);

    fn fromRaylib(color: c.Color) Color {
        return .{ .r = color.r, .g = color.g, .b = color.b, .a = color.a };
    }

    pub fn init(r: u8, g: u8, b: u8, a: u8) Color {
        return .{ .r = r, .g = g, .b = b, .a = a };
    }

    pub fn init01(r: f32, g: f32, b: f32, a: f32) Color {
        return init(@intFromFloat(r * 255), @intFromFloat(g * 255), @intFromFloat(b * 255), @intFromFloat(a * 255));
    }

    pub fn splat(v: u8) Color {
        return .{ .r = v, .g = v, .b = v, .a = v };
    }

    pub fn grayTone(v: u8) Color {
        return .{ .r = v, .g = v, .b = v, .a = 255 };
    }

    pub fn randomC() Color {
        return .{
            .r = @intCast(GetRandomValue(0, 255)),
            .g = @intCast(GetRandomValue(0, 255)),
            .b = @intCast(GetRandomValue(0, 255)),
            .a = 255,
        };
    }

    pub fn lerp(a: Color, b: Color, t: f32) Color {
        const ar: f32 = @floatFromInt(a.r);
        const ag: f32 = @floatFromInt(a.g);
        const ab: f32 = @floatFromInt(a.b);
        const aa: f32 = @floatFromInt(a.a);
        const br: f32 = @floatFromInt(b.r);
        const bg: f32 = @floatFromInt(b.g);
        const bb: f32 = @floatFromInt(b.b);
        const ba: f32 = @floatFromInt(b.a);
        return .{
            .r = @intFromFloat(std.math.lerp(ar, br, t)),
            .g = @intFromFloat(std.math.lerp(ag, bg, t)),
            .b = @intFromFloat(std.math.lerp(ab, bb, t)),
            .a = @intFromFloat(std.math.lerp(aa, ba, t)),
        };
    }

    pub const fade = Fade;
    pub const normalize = ColorNormalize;
    pub const fromNormalized = ColorFromNormalized;
    pub const isEqual = ColorIsEqual;
    pub const toInt = ColorToInt;
    pub const toHsv = ColorToHSV;
    pub const fromHsv = ColorFromHSV;
    pub const tint = ColorTint;
    pub const brightness = ColorBrightness;
    pub const contrast = ColorContrast;
    pub const alpha = ColorAlpha;
    pub const alphaBlend = ColorAlphaBlend;

    /// Get a Color struct from hexadecimal value
    pub fn fromHex(hexValue: u32) Color {
        return .{
            .r = @truncate(hexValue >> 24),
            .g = @truncate(hexValue >> 16),
            .b = @truncate(hexValue >> 8),
            .a = @truncate(hexValue),
        };
    }
};

pub const Vector2 = extern struct {
    x: f32 = 0,
    y: f32 = 0,

    pub fn init(x: f32, y: f32) Vector2 {
        return .{ .x = x, .y = y };
    }

    pub fn initAny(x: anytype, y: anytype) Vector2 {
        return .{ .x = toFloat(f32, x), .y = toFloat(f32, y) };
    }

    pub fn splat(v: anytype) Vector2 {
        const v_f32 = toFloat(f32, v);
        return .{ .x = v_f32, .y = v_f32 };
    }

    pub fn toSimd(self: @This()) @Vector(2, f32) {
        return @bitCast(self);
    }

    pub fn addEql(self: *Vector2, other: Vector2) void {
        self.x += other.x;
        self.y += other.y;
    }

    pub fn subEql(self: *Vector2, other: Vector2) void {
        self.x -= other.x;
        self.y -= other.y;
    }

    pub fn toRectangle(self: Vector2, width: f32, height: f32) Rectangle {
        return .{ .x = self.x, .y = self.y, .width = width, .height = height };
    }

    pub fn format(value: Vector2, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.writeAll("Vector2{");
        try std.fmt.formatType(value.x, fmt, options, writer, 0);
        try writer.writeAll(", ");
        try std.fmt.formatType(value.y, fmt, options, writer, 0);
        try writer.writeAll("}");
    }

    pub const one: Vector2 = .{ .x = 1, .y = 1 };
    pub const add = rm.Vector2Add;
    pub const addValue = rm.Vector2AddValue;
    pub const sub = rm.Vector2Subtract;
    pub const subValue = rm.Vector2SubtractValue;
    pub const length = rm.Vector2Length;
    pub const lengthSqr = rm.Vector2LengthSqr;
    pub const dot = rm.Vector2DotProduct;
    pub const distance = rm.Vector2Distance;
    pub const distanceSqr = rm.Vector2DistanceSqr;
    pub const angle = rm.Vector2Angle;
    pub const lineAngle = rm.Vector2LineAngle;
    pub const scale = rm.Vector2Scale;
    pub const mul = rm.Vector2Multiply;
    pub const negate = rm.Vector2Negate;
    pub const div = rm.Vector2Divide;
    pub const normalize = rm.Vector2Normalize;
    pub const transform = rm.Vector2Transform;
    pub const lerp = rm.Vector2Lerp;
    pub const reflect = rm.Vector2Reflect;
    pub const min = rm.Vector2Min;
    pub const max = rm.Vector2Max;
    pub const rotate = rm.Vector2Rotate;
    pub const moveTowards = rm.Vector2MoveTowards;
    pub const invert = rm.Vector2Invert;
    pub const clamp = rm.Vector2Clamp;
    pub const clampValue = rm.Vector2ClampValue;
    pub const equals = rm.Vector2Equals;
    pub const refract = rm.Vector2Refract;
};

pub const Vector3 = extern struct {
    x: f32 = 0,
    y: f32 = 0,
    z: f32 = 0,

    pub fn init(x: f32, y: f32, z: f32) Vector3 {
        return .{ .x = x, .y = y, .z = z };
    }

    pub fn initAny(x: anytype, y: anytype, z: anytype) Vector3 {
        return .{ .x = toFloat(f32, x), .y = toFloat(f32, y), .z = toFloat(f32, z) };
    }

    pub fn splat(v: anytype) Vector3 {
        const v_f32 = toFloat(f32, v);
        return .{ .x = v_f32, .y = v_f32, .z = v_f32 };
    }

    pub fn toSimd(self: @This()) @Vector(3, f32) {
        return @bitCast(self);
    }

    pub fn format(value: Vector3, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.writeAll("(");
        try std.fmt.formatType(value.x, fmt, options, writer, 0);
        try writer.writeAll(", ");
        try std.fmt.formatType(value.y, fmt, options, writer, 0);
        try writer.writeAll(", ");
        try std.fmt.formatType(value.z, fmt, options, writer, 0);
        try writer.writeAll(")");
    }

    pub const one: Vector3 = .{ .x = 1, .y = 1, .z = 1 };
    pub const right: Vector3 = .{ .x = 1 };
    pub const left: Vector3 = .{ .x = -1 };
    pub const up: Vector3 = .{ .y = 1 };
    pub const add = rm.Vector3Add;
    pub const addValue = rm.Vector3AddValue;
    pub const sub = rm.Vector3Subtract;
    pub const subValue = rm.Vector3SubtractValue;
    pub const length = rm.Vector3Length;
    pub const lengthSqr = rm.Vector3LengthSqr;
    pub const dot = rm.Vector3DotProduct;
    pub const distance = rm.Vector3Distance;
    pub const distanceSqr = rm.Vector3DistanceSqr;
    pub const angle = rm.Vector3Angle;
    pub const scale = rm.Vector3Scale;
    pub const mul = rm.Vector3Multiply;
    pub const negate = rm.Vector3Negate;
    pub const div = rm.Vector3Divide;
    pub const normalize = rm.Vector3Normalize;
    pub const transform = rm.Vector3Transform;
    pub const lerp = rm.Vector3Lerp;
    pub const reflect = rm.Vector3Reflect;
    pub const min = rm.Vector3Min;
    pub const max = rm.Vector3Max;
    pub const moveTowards = rm.Vector3MoveTowards;
    pub const invert = rm.Vector3Invert;
    pub const clamp = rm.Vector3Clamp;
    pub const clampValue = rm.Vector3ClampValue;
    pub const equals = rm.Vector3Equals;
    pub const refract = rm.Vector3Refract;
    pub const cross = rm.Vector3CrossProduct;
    pub const perpendicular = rm.Vector3Perpendicular;
    pub const project = rm.Vector3Project;
    pub const reject = rm.Vector3Reject;
    pub const orthoNormalize = rm.Vector3OrthoNormalize;
    pub const rotateByQuaternion = rm.Vector3RotateByQuaternion;
    pub const rotateByAxisAngle = rm.Vector3RotateByAxisAngle;
    pub const barycenter = rm.Vector3Barycenter;
    pub const unproject = rm.Vector3Unproject;
    pub const toFloatV = rm.Vector3ToFloatV;
};

pub const Vector4 = extern struct {
    x: f32 = 0,
    y: f32 = 0,
    z: f32 = 0,
    w: f32 = 0,

    pub fn init(x: f32, y: f32, z: f32, w: f32) Vector4 {
        return .{ .x = x, .y = y, .z = z, .w = w };
    }

    pub fn splat(v: anytype) Vector4 {
        const v_f32 = toFloat(f32, v);
        return .{ .x = v_f32, .y = v_f32, .z = v_f32, .w = v_f32 };
    }

    pub fn toSimd(self: @This()) @Vector(4, f32) {
        return @bitCast(self);
    }

    pub fn format(value: Vector4, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.writeAll("Vector3{");
        try std.fmt.formatType(value.x, fmt, options, writer, 0);
        try writer.writeAll(", ");
        try std.fmt.formatType(value.y, fmt, options, writer, 0);
        try writer.writeAll(", ");
        try std.fmt.formatType(value.z, fmt, options, writer, 0);
        try writer.writeAll(", ");
        try std.fmt.formatType(value.w, fmt, options, writer, 0);
        try writer.writeAll("}");
    }

    pub const vecOne: Vector4 = .{ .x = 1, .y = 1, .z = 1, .w = 1 };
    pub const quatIdentity: Quaternion = .{ .w = 1 };

    pub const vecAdd = rm.Vector4Add;
    pub const vecAddValue = rm.Vector4AddValue;
    pub const vecSub = rm.Vector4Subtract;
    pub const vecSubValue = rm.Vector4SubtractValue;
    pub const vecLength = rm.Vector4Length;
    pub const vecLengthSqr = rm.Vector4LengthSqr;
    pub const vecDot = rm.Vector4DotProduct;
    pub const vecDistance = rm.Vector4Distance;
    pub const vecDistanceSqr = rm.Vector4DistanceSqr;
    pub const vecScale = rm.Vector4Scale;
    pub const vecMul = rm.Vector4Multiply;
    pub const vecNegate = rm.Vector4Negate;
    pub const vecDiv = rm.Vector4Divide;
    pub const vecNormalize = rm.Vector4Normalize;
    pub const vecLerp = rm.Vector4Lerp;
    pub const vecMin = rm.Vector4Min;
    pub const vecMax = rm.Vector4Max;
    pub const vecMoveTowards = rm.Vector4MoveTowards;
    pub const vecInvert = rm.Vector4Invert;
    pub const vecEquals = rm.Vector4Equals;
    pub const quatAdd = rm.QuaternionAdd;
    pub const quatAddValue = rm.QuaternionAddValue;
    pub const quatSubtract = rm.QuaternionSubtract;
    pub const quatSubtractValue = rm.QuaternionSubtractValue;
    pub const quatLength = rm.QuaternionLength;
    pub const quatNormalize = rm.QuaternionNormalize;
    pub const quatInvert = rm.QuaternionInvert;
    pub const quatMultiply = rm.QuaternionMultiply;
    pub const quatScale = rm.QuaternionScale;
    pub const quatDivide = rm.QuaternionDivide;
    pub const quatLerp = rm.QuaternionLerp;
    pub const quatNlerp = rm.QuaternionNlerp;
    pub const quatSlerp = rm.QuaternionSlerp;
    pub const quatFromVector3ToVector3 = rm.QuaternionFromVector3ToVector3;
    pub const quatFromMatrix = rm.QuaternionFromMatrix;
    pub const quatToMatrix = rm.QuaternionToMatrix;
    pub const quatFromAxisAngle = rm.QuaternionFromAxisAngle;
    pub const quatToAxisAngle = rm.QuaternionToAxisAngle;
    pub const quatFromEuler = rm.QuaternionFromEuler;
    pub const quatToEuler = rm.QuaternionToEuler;
    pub const quatTransform = rm.QuaternionTransform;
    pub const quatEquals = rm.QuaternionEquals;
};
pub const Quaternion = Vector4;

pub const Rectangle = extern struct {
    x: f32 = 0,
    y: f32 = 0,
    width: f32 = 0,
    height: f32 = 0,

    pub fn init(x: f32, y: f32, width: f32, height: f32) Rectangle {
        return .{ .x = x, .y = y, .width = width, .height = height };
    }

    pub fn initVector(pos: Vector2, size: Vector2) Rectangle {
        return .{ .x = pos.x, .y = pos.y, .width = size.x, .height = size.y };
    }

    pub fn fromPos(x: f32, y: f32) Rectangle {
        return .{ .x = x, .y = y };
    }

    pub fn fromSize(width: f32, height: f32) Rectangle {
        return .{ .width = width, .height = height };
    }

    pub fn position(self: Rectangle) Vector2 {
        return .{ .x = self.x, .y = self.y };
    }

    pub fn add(self: Rectangle, other: Rectangle) Rectangle {
        return .{
            .x = self.x + other.x,
            .y = self.y + other.y,
            .width = self.width + other.width,
            .height = self.height + other.height,
        };
    }

    pub fn sub(self: Rectangle, other: Rectangle) Rectangle {
        return .{
            .x = self.x - other.x,
            .y = self.y - other.y,
            .width = self.width - other.width,
            .height = self.height - other.height,
        };
    }
};

pub const Font = extern struct {
    baseSize: c_int = 0,
    glyphCount: c_int = 0,
    glyphPadding: c_int = 0,
    texture: Texture2D = .{},
    recs: [*c]Rectangle = null,
    glyphs: [*c]GlyphInfo = null,

    pub const init = LoadFont;
    pub fn initEx(file_name: [*:0]const u8, font_size: c_int, codepoints: ?[]const c_int) Font {
        const ptr: ?[*]const c_int, const len: c_int = codepoints_ptr: {
            const cd = codepoints orelse break :codepoints_ptr .{ null, 0 };
            break :codepoints_ptr .{ cd.ptr, @intCast(cd.len) };
        };
        return LoadFontEx(file_name, font_size, ptr, len);
    }
    pub const initFromImage = LoadFontFromImage;
    pub fn initFromMemory(file_type: [*:0]const u8, file_data: []const u8, font_size: c_int, codepoints: ?[]const c_int) Font {
        const ptr: ?[*]const c_int, const len: c_int = codepoints_ptr: {
            const cd = codepoints orelse break :codepoints_ptr .{ null, 0 };
            break :codepoints_ptr .{ cd.ptr, @intCast(cd.len) };
        };
        return LoadFontFromMemory(file_type, file_data.ptr, @intCast(file_data.len), font_size, ptr, len);
    }
    pub const deinit = UnloadFont;
    pub const isReady = IsFontReady;
    pub const getDefault = GetFontDefault;
    pub const exportAsCode = ExportFontAsCode;
};

pub const Texture = extern struct {
    id: c_uint = 0,
    width: c_int = 0,
    height: c_int = 0,
    mipmaps: c_int = 0,
    format: c_int = 0,

    pub const init = LoadTexture;
    pub const initFromImage = LoadTextureFromImage;
    pub const initCubemap = LoadTextureCubemap;
    pub const deinit = UnloadTexture;
    pub const toImage = LoadImageFromTexture;
    pub const update = UpdateTexture;
    pub const updateRec = UpdateTextureRec;
    pub const genMipmaps = GenTextureMipmaps;
    pub const draw = DrawTexture;
    pub const drawV = DrawTextureV;
    pub const drawEx = DrawTextureEx;
    pub const drawRec = DrawTextureRec;
    pub const drawPro = DrawTexturePro;
    pub const drawNPatch = DrawTextureNPatch;
    pub const isReady = IsTextureReady;
    pub const setWrap = SetTextureWrap;
};
pub const Texture2D = Texture;
pub const TextureCubemap = Texture;

const GlyphInfo = extern struct {
    value: c_int = 0,
    offsetX: c_int = 0,
    offsetY: c_int = 0,
    advanceX: c_int = 0,
    image: Image = .{},
};

pub const Image = extern struct {
    data: ?*anyopaque = null,
    width: c_int = 0,
    height: c_int = 0,
    mipmaps: c_int = 0,
    format: c_int = 0,

    pub const init = LoadImage;
    pub const initRaw = LoadImageRaw;
    pub const initSvg = LoadImageSvg;
    pub const initAnim = LoadImageAnim;
    pub const initAnimFromMemory = LoadImageAnimFromMemory;
    pub const initFromMemory = LoadImageFromMemory;
    pub const initFromTexture = LoadImageFromTexture;
    pub const initText = ImageText;
    pub const initTextEx = ImageTextEx;
    pub const deinit = UnloadImage;
    pub const copy = ImageCopy;
    pub const exportImage = ExportImage;
    pub fn exportToMemory(image: Image, file_type: [*:0]const u8) ?[]u8 {
        var len: c_int = undefined;
        const data = ExportImageToMemory(image, file_type, &len) orelse return null;
        return data[0..@intCast(len)];
    }
    pub const exportAsCode = ExportImageAsCode;

    pub const toFormat = ImageFormat;
    pub const toPot = ImageToPOT;
    pub const crop = ImageCrop;
    pub const alphaCrop = ImageAlphaCrop;
    pub const alphaClear = ImageAlphaClear;
    pub const alphaMask = ImageAlphaMask;
    pub const alphaPremultiply = ImageAlphaPremultiply;
    pub const blurGaussian = ImageBlurGaussian;
    pub const kernelConvolution = ImageKernelConvolution;
    pub const resize = ImageResize;
    pub const resizeNN = ImageResizeNN;
    pub const resizeCanvas = ImageResizeCanvas;
    pub const computeMipmaps = ImageMipmaps;
    pub const ditherImage = ImageDither;
    pub const flipVertical = ImageFlipVertical;
    pub const flipHorizontal = ImageFlipHorizontal;
    pub const rotate = ImageRotate;
    pub const rotateCw = ImageRotateCW;
    pub const rotateCww = ImageRotateCCW;
    pub const colorTint = ImageColorTint;
    pub const colorInvert = ImageColorInvert;
    pub const colorGrayscale = ImageColorGrayscale;
    pub const colorContrast = ImageColorContrast;
    pub const colorBrightness = ImageColorBrightness;
    pub const colorReplace = ImageColorReplace;

    pub const loadColors = LoadImageColors;
    pub const unloadColors = UnloadImageColors;
    pub fn loadColorsSlice(image: Image) ?[]Color {
        return (image.loadColors() orelse return null)[0..@intCast(image.width * image.height)];
    }
    pub fn unloadColorsSlice(colors: ?[]Color) void {
        if (colors) |co| unloadColors(co.ptr);
    }

    pub const loadPalette = LoadImagePalette;
    pub const unloadPalette = UnloadImagePalette;
    pub fn loadPaletteSlice(image: Image, max_palette_size: c_int) ?[]Color {
        var len: c_int = 0;
        const palette = image.loadPalette(max_palette_size, &len) orelse return null;
        return palette[0..@intCast(len)];
    }
    pub fn unloadPaletteSlice(palette: []Color) void {
        unloadPalette(palette.ptr);
    }

    pub const getAlphaBorder = GetImageAlphaBorder;
    pub const getColor = GetImageColor;
    pub const clearBackground = ImageClearBackground;
    pub const drawPixel = ImageDrawPixel;
    pub const drawPixelV = ImageDrawPixelV;
    pub const drawLine = ImageDrawLine;
    pub const drawLineV = ImageDrawLineV;
    pub const drawCircle = ImageDrawCircle;
    pub const drawCircleV = ImageDrawCircleV;
    pub const drawCircleLines = ImageDrawCircleLines;
    pub const drawCircleLinesV = ImageDrawCircleLinesV;
    pub const drawRectangle = ImageDrawRectangle;
    pub const drawRectangleV = ImageDrawRectangleV;
    pub const drawRectangleRec = ImageDrawRectangleRec;
    pub const drawRectangleLines = ImageDrawRectangleLines;
    pub const draw = ImageDraw;
    pub const drawText = ImageDrawText;
    pub const drawTextEx = ImageDrawTextEx;
};

pub const Matrix = extern struct {
    // zig fmt: off
    m0: f32 = 0, m4: f32 = 0, m8 : f32 = 0, m12: f32 = 0,
    m1: f32 = 0, m5: f32 = 0, m9 : f32 = 0, m13: f32 = 0,
    m2: f32 = 0, m6: f32 = 0, m10: f32 = 0, m14: f32 = 0,
    m3: f32 = 0, m7: f32 = 0, m11: f32 = 0, m15: f32 = 0,
    // zig fmt: on

    pub const determinant = rm.MatrixDeterminant;
    pub const trace = rm.MatrixTrace;
    pub const transpose = rm.MatrixTranspose;
    pub const invert = rm.MatrixInvert;
    pub const identity = rm.MatrixIdentity();
    pub const add = rm.MatrixAdd;
    pub const subtract = rm.MatrixSubtract;
    pub const multiply = rm.MatrixMultiply;
    pub const translate = rm.MatrixTranslate;
    pub const rotate = rm.MatrixRotate;
    pub const rotateX = rm.MatrixRotateX;
    pub const rotateY = rm.MatrixRotateY;
    pub const rotateZ = rm.MatrixRotateZ;
    pub const rotateXYZ = rm.MatrixRotateXYZ;
    pub const rotateZYX = rm.MatrixRotateZYX;
    pub const scale = rm.MatrixScale;
    pub const frustum = rm.MatrixFrustum;
    pub const perspective = rm.MatrixPerspective;
    pub const ortho = rm.MatrixOrtho;
    pub const lookAt = rm.MatrixLookAt;
    pub const toFloatV = rm.MatrixToFloatV;
};

pub const RenderTexture = extern struct {
    id: c_uint = 0,
    texture: Texture = .{},
    depth: Texture = .{},

    pub const init = LoadRenderTexture;
    pub const deinit = UnloadRenderTexture;
    pub const isReady = IsRenderTextureReady;
    pub const beginMode = BeginTextureMode;
    pub const endMode = EndTextureMode;
};
pub const RenderTexture2D = RenderTexture;

pub const NPatchInfo = extern struct {
    source: Rectangle = .{},
    left: c_int = 0,
    top: c_int = 0,
    right: c_int = 0,
    bottom: c_int = 0,
    layout: c_int = 0,
};

pub const Camera3D = extern struct {
    position: Vector3 = .{},
    target: Vector3 = .{},
    up: Vector3 = .{},
    fovy: f32 = 0,
    projection: CameraProjection = .perspective,

    pub const beginMode = BeginMode3D;
    pub const endMode = EndMode3D;
    pub const getMatrix = GetCameraMatrix;

    pub fn getScreenToWorldRay(camera: Camera3D, position: Vector2) Ray {
        return GetScreenToWorldRay(position, camera);
    }
    pub fn getScreenToWorldRayEx(camera: Camera3D, position: Vector2, width: f32, height: f32) Ray {
        return GetScreenToWorldRayEx(position, camera, width, height);
    }
    pub fn getWorldToScreen(camera: Camera3D, position: Vector3) Vector2 {
        return GetWorldToScreen(position, camera);
    }
    pub fn getWorldToScreenEx(camera: Camera3D, position: Vector3, width: c_int, height: c_int) Vector2 {
        return GetWorldToScreenEx(position, camera, width, height);
    }

    pub const update = UpdateCamera;
    pub const updatePro = UpdateCameraPro;
};
pub const Camera = Camera3D;

pub const Camera2D = extern struct {
    offset: Vector2 = .{},
    target: Vector2 = .{},
    rotation: f32 = 0,
    zoom: f32 = 0,

    pub const beginMode = BeginMode2D;
    pub const endMode = EndMode2D;
    pub const getMatrix = GetCameraMatrix2D;
    pub fn getWorldToScreen(camera: Camera2D, position: Vector2) Vector2 {
        return GetWorldToScreen2D(position, camera);
    }
    pub fn getScreenToWorld(position: Vector2, camera: Camera2D) Vector2 {
        return GetScreenToWorld2D(position, camera);
    }
};

pub const Mesh = extern struct {
    vertexCount: c_int = 0,
    triangleCount: c_int = 0,
    vertices: [*c]f32 = null,

    texcoords: [*c]f32 = null,
    texcoords2: [*c]f32 = null,
    normals: [*c]f32 = null,
    tangents: [*c]f32 = null,
    colors: [*c]u8 = null,
    indices: [*c]c_ushort = null,

    animVertices: [*c]f32 = null,
    animNormals: [*c]f32 = null,
    boneIds: [*c]u8 = null,
    boneWeights: [*c]f32 = null,
    boneMatrices: [*c]Matrix = null,
    boneCount: c_int = 0,

    vaoId: c_uint = 0,
    vboId: [*c]c_uint = null,

    pub const upload = UploadMesh;
    pub const updateBuffer = UpdateMeshBuffer;
    pub const unload = UnloadMesh;
    pub const draw = DrawMesh;
    pub const drawInstanced = DrawMeshInstanced;
    pub const getBoundingBox = GetMeshBoundingBox;
    pub const genTangents = GenMeshTangents;
    pub const exportMesh = ExportMesh;
    pub const exportMeshAsCode = ExportMeshAsCode;
    pub const genPoly = GenMeshPoly;
    pub const genPlane = GenMeshPlane;
    pub const genCube = GenMeshCube;
    pub const genSphere = GenMeshSphere;
    pub const genHemiSphere = GenMeshHemiSphere;
    pub const genCylinder = GenMeshCylinder;
    pub const genCone = GenMeshCone;
    pub const genTorus = GenMeshTorus;
    pub const genKnot = GenMeshKnot;
    pub const genHeightmap = GenMeshHeightmap;
    pub const genCubicmap = GenMeshCubicmap;
};

pub const Shader = extern struct {
    id: c_uint = 0,
    locs: [*c]c_int = null,

    pub const init = LoadShader;
    pub const initFromMemory = LoadShaderFromMemory;
    pub const isReady = IsShaderReady;
    pub const getLocation = GetShaderLocation;
    pub const getLocationAttrib = GetShaderLocationAttrib;
    pub const setValue = SetShaderValue;
    pub const setValueV = SetShaderValueV;
    pub const setValueMatrix = SetShaderValueMatrix;
    pub const setValueTexture = SetShaderValueTexture;
    pub const deinit = UnloadShader;

    pub const beginMode = BeginShaderMode;
    pub const endMode = EndShaderMode;

    pub fn loc(self: Shader, idx: ShaderLocationIndex) c_int {
        return self.locs[idx.uint()];
    }

    pub fn locPtr(self: *Shader, idx: ShaderLocationIndex) *allowzero c_int {
        return &self.locs[idx.uint()];
    }
};

pub const MaterialMap = extern struct {
    texture: Texture2D = .{},
    color: Color = .{},
    value: f32 = 0,
};

pub const Material = extern struct {
    shader: Shader = .{},
    maps: [*c]MaterialMap = null,
    params: [4]f32 = @splat(0),

    pub const unload = UnloadMaterial;

    pub fn map(self: Material, idx: MaterialMapIndex) MaterialMap {
        return self.maps[idx.uint()];
    }

    pub fn mapPtr(self: *Material, idx: MaterialMapIndex) *allowzero MaterialMap {
        return &self.maps[idx.uint()];
    }

    pub fn default() Material {
        return LoadMaterialDefault();
    }
};

pub const Transform = extern struct {
    translation: Vector3 = .{},
    rotation: Quaternion = .{},
    scale: Vector3 = .{},
};

pub const BoneInfo = extern struct {
    name: [32]u8 = @splat(0),
    parent: c_int = 0,
};

pub const Model = extern struct {
    transform: Matrix = .{},
    meshCount: c_int = 0,
    materialCount: c_int = 0,
    meshes: [*c]Mesh = null,
    materials: [*c]Material = null,
    meshMaterial: [*c]c_int = null,
    boneCount: c_int = 0,
    bones: [*c]BoneInfo = null,
    bindPose: [*c]Transform = null,

    pub const init = LoadModel;
    pub const initFromMesh = LoadModelFromMesh;
    pub const isReady = IsModelReady;
    pub const deinit = UnloadModel;
    pub const getBoundingBox = GetModelBoundingBox;
    pub const draw = DrawModel;
    pub const drawEx = DrawModelEx;
    pub const drawWires = DrawModelWires;
    pub const drawWiresEx = DrawModelWiresEx;
};

pub const ModelAnimation = extern struct {
    boneCount: c_int = 0,
    frameCount: c_int = 0,
    bones: [*c]BoneInfo = null,
    framePoses: [*c][*c]Transform = null,
    name: [32]u8 = .{0} ** 32,
};

pub const Ray = extern struct {
    position: Vector3 = .{},
    direction: Vector3 = .{},
};

pub const RayCollision = extern struct {
    hit: bool = false,
    distance: f32 = 0,
    point: Vector3 = .{},
    normal: Vector3 = .{},
};

pub const BoundingBox = extern struct {
    min: Vector3 = .{},
    max: Vector3 = .{},
};

pub const Wave = extern struct {
    frameCount: c_uint = 0,
    sampleRate: c_uint = 0,
    sampleSize: c_uint = 0,
    channels: c_uint = 0,
    data: ?*anyopaque = null,

    pub const init = LoadWave;
    pub const initFromMemory = LoadWaveFromMemory;
    pub const deinit = UnloadWave;
    pub const exportWave = ExportWave;
    pub const exportWaveAsCode = ExportWaveAsCode;
    pub const toSound = LoadSoundFromWave;
    pub const isReady = IsWaveReady;
    pub const copy = WaveCopy;
    pub const crop = WaveCrop;
    pub const format = WaveFormat;
    pub const loadSamples = LoadWaveSamples;
    pub const unloadSamples = UnloadWaveSamples;
};

pub const rAudioBuffer = opaque {};
pub const rAudioProcessor = opaque {};

pub const AudioStream = extern struct {
    buffer: ?*rAudioBuffer = null,
    processor: ?*rAudioProcessor = null,
    sampleRate: c_uint = 0,
    sampleSize: c_uint = 0,
    channels: c_uint = 0,

    pub const init = LoadAudioStream;
    pub const isReady = IsAudioStreamReady;
    pub const deinit = UnloadAudioStream;
    pub const update = UpdateAudioStream;
    pub const isProcessed = IsAudioStreamProcessed;
    pub const play = PlayAudioStream;
    pub const pause = PauseAudioStream;
    pub const resumeAudioStream = ResumeAudioStream;
    pub const isPlaying = IsAudioStreamPlaying;
    pub const stop = StopAudioStream;
    pub const setVolume = SetAudioStreamVolume;
    pub const setPitch = SetAudioStreamPitch;
    pub const setPan = SetAudioStreamPan;
    pub const setBufferSizeDefault = SetAudioStreamBufferSizeDefault;
    pub const setCallback = SetAudioStreamCallback;
    pub const attachProcessor = AttachAudioStreamProcessor;
    pub const detachProcessor = DetachAudioStreamProcessor;
};

pub const Sound = extern struct {
    stream: AudioStream = .{},
    frameCount: c_uint = 0,

    pub const init = LoadSound;
    pub const initFromWave = LoadSoundFromWave;
    pub const initAlias = LoadSoundAlias;
    pub const isReady = IsSoundReady;
    pub const update = UpdateSound;
    pub const deinit = UnloadSound;
    pub const deinitAlias = UnloadSoundAlias;
    pub const play = PlaySound;
    pub const stop = StopSound;
    pub const pause = PauseSound;
    pub const resumeSound = ResumeSound;
    pub const isPlaying = IsSoundPlaying;
    pub const setVolume = SetSoundVolume;
    pub const setPitch = SetSoundPitch;
    pub const setPan = SetSoundPan;
};

pub const Music = extern struct {
    stream: AudioStream = .{},
    frameCount: c_uint = 0,
    looping: bool = false,
    ctxType: c_int = 0,
    ctxData: ?*anyopaque = null,

    pub const init = LoadMusicStream;
    pub const initFromMemory = LoadMusicStreamFromMemory;
    pub const deinit = UnloadMusicStream;
    pub const isReady = IsMusicReady;
    pub const play = PlayMusicStream;
    pub const isPlaying = IsMusicStreamPlaying;
    pub const update = UpdateMusicStream;
    pub const stop = StopMusicStream;
    pub const pause = PauseMusicStream;
    pub const resumeStream = ResumeMusicStream;
    pub const seek = SeekMusicStream;
    pub const setVolume = SetMusicVolume;
    pub const setPitch = SetMusicPitch;
    pub const setPan = SetMusicPan;
    pub const getTimeLength = GetMusicTimeLength;
    pub const getTimePlayed = GetMusicTimePlayed;
};

pub const VrDeviceInfo = extern struct {
    hResolution: c_int = 0,
    vResolution: c_int = 0,
    hScreenSize: f32 = 0,
    vScreenSize: f32 = 0,
    eyeToScreenDistance: f32 = 0,
    lensSeparationDistance: f32 = 0,
    interpupillaryDistance: f32 = 0,
    lensDistortionValues: [4]f32 = .{0} ** 4,
    chromaAbCorrection: [4]f32 = .{0} ** 4,
};

pub const VrStereoConfig = extern struct {
    projection: [2]Matrix = @splat(.{}),
    viewOffset: [2]Matrix = @splat(.{}),
    leftLensCenter: [2]f32 = .{0} ** 2,
    rightLensCenter: [2]f32 = .{0} ** 2,
    leftScreenCenter: [2]f32 = .{0} ** 2,
    rightScreenCenter: [2]f32 = .{0} ** 2,
    scale: [2]f32 = .{0} ** 2,
    scaleIn: [2]f32 = .{0} ** 2,

    pub const init = LoadVrStereoConfig;
    pub const deinit = UnloadVrStereoConfig;
    pub const beginMode = BeginVrStereoMode;
    pub const endMode = EndVrStereoMode;
};

pub const FilePathList = extern struct {
    capacity: c_uint = 0,
    count: c_uint = 0,
    paths: [*c][*c]u8 = null,
};

pub const AutomationEvent = extern struct {
    frame: c_uint = 0,
    type: c_uint = 0,
    params: [4]c_int = .{0} ** 4,
};

pub const AutomationEventList = extern struct {
    capacity: c_uint = 0,
    count: c_uint = 0,
    events: [*c]AutomationEvent = null,
};

pub const ConfigFlags = packed struct(c_uint) {
    _0: u1 = 0, // 1
    fullscreen_mode: bool = false, // 2
    window_resizable: bool = false, // 4
    window_undecorated: bool = false, // 8
    window_transparent: bool = false, // 16
    msaa_4x_hint: bool = false, // 32
    vsync_hint: bool = false, // 64
    window_hidden: bool = false, // 128
    window_always_run: bool = false, // 256
    window_minimized: bool = false, // 512
    window_maximized: bool = false, // 1024
    window_unfocused: bool = false, // 2048
    window_topmost: bool = false, // 4096
    window_highdpi: bool = false, // 8192;
    window_mouse_passthrough: bool = false, // 16384;
    borderless_windowed_mode: bool = false, // 32768;
    interlaced_hint: bool = false, // 65536;
    _1: std.meta.Int(.unsigned, @bitSizeOf(c_uint) - 17) = 0,

    test ConfigFlags {
        try std.testing.expectEqual(
            @as(c_uint, @bitCast(ConfigFlags{
                .vsync_hint = true,
                .fullscreen_mode = true,
                .borderless_windowed_mode = true,
                .msaa_4x_hint = true,
            })),
            c.FLAG_VSYNC_HINT |
                c.FLAG_FULLSCREEN_MODE |
                c.FLAG_BORDERLESS_WINDOWED_MODE |
                c.FLAG_MSAA_4X_HINT,
        );
    }
};

pub const TraceLogLevel = enum(c_int) {
    all = c.LOG_ALL,
    trace = c.LOG_TRACE,
    debug = c.LOG_DEBUG,
    info = c.LOG_INFO,
    warning = c.LOG_WARNING,
    @"error" = c.LOG_ERROR,
    fatal = c.LOG_FATAL,
    none = c.LOG_NONE,

    pub fn int(self: @This()) c_int {
        return @intFromEnum(self);
    }
};

pub const KeyboardKey = enum(c_int) {
    null = c.KEY_NULL,
    apostrophe = c.KEY_APOSTROPHE,
    comma = c.KEY_COMMA,
    minus = c.KEY_MINUS,
    period = c.KEY_PERIOD,
    slash = c.KEY_SLASH,
    zero = c.KEY_ZERO,
    one = c.KEY_ONE,
    two = c.KEY_TWO,
    three = c.KEY_THREE,
    four = c.KEY_FOUR,
    five = c.KEY_FIVE,
    six = c.KEY_SIX,
    seven = c.KEY_SEVEN,
    eight = c.KEY_EIGHT,
    nine = c.KEY_NINE,
    semicolon = c.KEY_SEMICOLON,
    equal = c.KEY_EQUAL,
    a = c.KEY_A,
    b = c.KEY_B,
    c = c.KEY_C,
    d = c.KEY_D,
    e = c.KEY_E,
    f = c.KEY_F,
    g = c.KEY_G,
    h = c.KEY_H,
    i = c.KEY_I,
    j = c.KEY_J,
    k = c.KEY_K,
    l = c.KEY_L,
    m = c.KEY_M,
    n = c.KEY_N,
    o = c.KEY_O,
    p = c.KEY_P,
    q = c.KEY_Q,
    r = c.KEY_R,
    s = c.KEY_S,
    t = c.KEY_T,
    u = c.KEY_U,
    v = c.KEY_V,
    w = c.KEY_W,
    x = c.KEY_X,
    y = c.KEY_Y,
    z = c.KEY_Z,
    left_bracket = c.KEY_LEFT_BRACKET,
    backslash = c.KEY_BACKSLASH,
    right_bracket = c.KEY_RIGHT_BRACKET,
    grave = c.KEY_GRAVE,
    space = c.KEY_SPACE,
    escape = c.KEY_ESCAPE,
    enter = c.KEY_ENTER,
    tab = c.KEY_TAB,
    backspace = c.KEY_BACKSPACE,
    insert = c.KEY_INSERT,
    delete = c.KEY_DELETE,
    right = c.KEY_RIGHT,
    left = c.KEY_LEFT,
    down = c.KEY_DOWN,
    up = c.KEY_UP,
    page_up = c.KEY_PAGE_UP,
    page_down = c.KEY_PAGE_DOWN,
    home = c.KEY_HOME,
    end = c.KEY_END,
    caps_lock = c.KEY_CAPS_LOCK,
    scroll_lock = c.KEY_SCROLL_LOCK,
    num_lock = c.KEY_NUM_LOCK,
    print_screen = c.KEY_PRINT_SCREEN,
    pause = c.KEY_PAUSE,
    f1 = c.KEY_F1,
    f2 = c.KEY_F2,
    f3 = c.KEY_F3,
    f4 = c.KEY_F4,
    f5 = c.KEY_F5,
    f6 = c.KEY_F6,
    f7 = c.KEY_F7,
    f8 = c.KEY_F8,
    f9 = c.KEY_F9,
    f10 = c.KEY_F10,
    f11 = c.KEY_F11,
    f12 = c.KEY_F12,
    left_shift = c.KEY_LEFT_SHIFT,
    left_control = c.KEY_LEFT_CONTROL,
    left_alt = c.KEY_LEFT_ALT,
    left_super = c.KEY_LEFT_SUPER,
    right_shift = c.KEY_RIGHT_SHIFT,
    right_control = c.KEY_RIGHT_CONTROL,
    right_alt = c.KEY_RIGHT_ALT,
    right_super = c.KEY_RIGHT_SUPER,
    kb_menu = c.KEY_KB_MENU,
    kp_0 = c.KEY_KP_0,
    kp_1 = c.KEY_KP_1,
    kp_2 = c.KEY_KP_2,
    kp_3 = c.KEY_KP_3,
    kp_4 = c.KEY_KP_4,
    kp_5 = c.KEY_KP_5,
    kp_6 = c.KEY_KP_6,
    kp_7 = c.KEY_KP_7,
    kp_8 = c.KEY_KP_8,
    kp_9 = c.KEY_KP_9,
    kp_decimal = c.KEY_KP_DECIMAL,
    kp_divide = c.KEY_KP_DIVIDE,
    kp_multiply = c.KEY_KP_MULTIPLY,
    kp_subtract = c.KEY_KP_SUBTRACT,
    kp_add = c.KEY_KP_ADD,
    kp_enter = c.KEY_KP_ENTER,
    kp_equal = c.KEY_KP_EQUAL,
    back = c.KEY_BACK,
    menu = c.KEY_MENU,
    volume_up = c.KEY_VOLUME_UP,
    volume_down = c.KEY_VOLUME_DOWN,

    pub fn int(self: @This()) c_int {
        return @intFromEnum(self);
    }
};

pub const MouseButton = enum(c_int) {
    left = c.MOUSE_BUTTON_LEFT,
    right = c.MOUSE_BUTTON_RIGHT,
    middle = c.MOUSE_BUTTON_MIDDLE,
    side = c.MOUSE_BUTTON_SIDE,
    extra = c.MOUSE_BUTTON_EXTRA,
    forward = c.MOUSE_BUTTON_FORWARD,
    back = c.MOUSE_BUTTON_BACK,

    pub fn int(self: @This()) c_int {
        return @intFromEnum(self);
    }
};

pub const MouseCursor = enum(c_int) {
    default = c.MOUSE_CURSOR_DEFAULT,
    arrow = c.MOUSE_CURSOR_ARROW,
    ibeam = c.MOUSE_CURSOR_IBEAM,
    crosshair = c.MOUSE_CURSOR_CROSSHAIR,
    pointing_hand = c.MOUSE_CURSOR_POINTING_HAND,
    resize_ew = c.MOUSE_CURSOR_RESIZE_EW,
    resize_ns = c.MOUSE_CURSOR_RESIZE_NS,
    resize_nwse = c.MOUSE_CURSOR_RESIZE_NWSE,
    resize_nesw = c.MOUSE_CURSOR_RESIZE_NESW,
    resize_all = c.MOUSE_CURSOR_RESIZE_ALL,
    not_allowed = c.MOUSE_CURSOR_NOT_ALLOWED,

    pub fn int(self: @This()) c_int {
        return @intFromEnum(self);
    }
};

pub const GamepadButton = enum(c_int) {
    unknown = c.GAMEPAD_BUTTON_UNKNOWN,
    left_face_up = c.GAMEPAD_BUTTON_LEFT_FACE_UP,
    left_face_right = c.GAMEPAD_BUTTON_LEFT_FACE_RIGHT,
    left_face_down = c.GAMEPAD_BUTTON_LEFT_FACE_DOWN,
    left_face_left = c.GAMEPAD_BUTTON_LEFT_FACE_LEFT,
    right_face_up = c.GAMEPAD_BUTTON_RIGHT_FACE_UP,
    right_face_right = c.GAMEPAD_BUTTON_RIGHT_FACE_RIGHT,
    right_face_down = c.GAMEPAD_BUTTON_RIGHT_FACE_DOWN,
    right_face_left = c.GAMEPAD_BUTTON_RIGHT_FACE_LEFT,
    left_trigger_1 = c.GAMEPAD_BUTTON_LEFT_TRIGGER_1,
    left_trigger_2 = c.GAMEPAD_BUTTON_LEFT_TRIGGER_2,
    right_trigger_1 = c.GAMEPAD_BUTTON_RIGHT_TRIGGER_1,
    right_trigger_2 = c.GAMEPAD_BUTTON_RIGHT_TRIGGER_2,
    middle_left = c.GAMEPAD_BUTTON_MIDDLE_LEFT,
    middle = c.GAMEPAD_BUTTON_MIDDLE,
    middle_right = c.GAMEPAD_BUTTON_MIDDLE_RIGHT,
    left_thumb = c.GAMEPAD_BUTTON_LEFT_THUMB,
    right_thumb = c.GAMEPAD_BUTTON_RIGHT_THUMB,

    pub fn int(self: @This()) c_int {
        return @intFromEnum(self);
    }
};

pub const GamepadAxis = enum(c_int) {
    left_x = c.GAMEPAD_AXIS_LEFT_X,
    left_y = c.GAMEPAD_AXIS_LEFT_Y,
    right_x = c.GAMEPAD_AXIS_RIGHT_X,
    right_y = c.GAMEPAD_AXIS_RIGHT_Y,
    left_trigger = c.GAMEPAD_AXIS_LEFT_TRIGGER,
    right_trigger = c.GAMEPAD_AXIS_RIGHT_TRIGGER,

    pub fn int(self: @This()) c_int {
        return @intFromEnum(self);
    }
};

pub const MaterialMapIndex = enum(c_int) {
    albedo = c.MATERIAL_MAP_ALBEDO,
    metalness = c.MATERIAL_MAP_METALNESS,
    normal = c.MATERIAL_MAP_NORMAL,
    roughness = c.MATERIAL_MAP_ROUGHNESS,
    occlusion = c.MATERIAL_MAP_OCCLUSION,
    emission = c.MATERIAL_MAP_EMISSION,
    height = c.MATERIAL_MAP_HEIGHT,
    cubemap = c.MATERIAL_MAP_CUBEMAP,
    irradiance = c.MATERIAL_MAP_IRRADIANCE,
    prefilter = c.MATERIAL_MAP_PREFILTER,
    brdf = c.MATERIAL_MAP_BRDF,

    pub const diffuse: MaterialMapIndex = .albedo;
    pub const specular: MaterialMapIndex = .metalness;

    pub fn int(self: @This()) c_int {
        return @intFromEnum(self);
    }

    pub fn uint(self: @This()) c_uint {
        return @intCast(@intFromEnum(self));
    }
};

pub const ShaderLocationIndex = enum(c_int) {
    vertex_position = c.SHADER_LOC_VERTEX_POSITION,
    vertex_texcoord01 = c.SHADER_LOC_VERTEX_TEXCOORD01,
    vertex_texcoord02 = c.SHADER_LOC_VERTEX_TEXCOORD02,
    vertex_normal = c.SHADER_LOC_VERTEX_NORMAL,
    vertex_tangent = c.SHADER_LOC_VERTEX_TANGENT,
    vertex_color = c.SHADER_LOC_VERTEX_COLOR,
    matrix_mvp = c.SHADER_LOC_MATRIX_MVP,
    matrix_view = c.SHADER_LOC_MATRIX_VIEW,
    matrix_projection = c.SHADER_LOC_MATRIX_PROJECTION,
    matrix_model = c.SHADER_LOC_MATRIX_MODEL,
    matrix_normal = c.SHADER_LOC_MATRIX_NORMAL,
    vector_view = c.SHADER_LOC_VECTOR_VIEW,
    color_diffuse = c.SHADER_LOC_COLOR_DIFFUSE,
    color_specular = c.SHADER_LOC_COLOR_SPECULAR,
    color_ambient = c.SHADER_LOC_COLOR_AMBIENT,
    map_albedo = c.SHADER_LOC_MAP_ALBEDO,
    map_metalness = c.SHADER_LOC_MAP_METALNESS,
    map_normal = c.SHADER_LOC_MAP_NORMAL,
    map_roughness = c.SHADER_LOC_MAP_ROUGHNESS,
    map_occlusion = c.SHADER_LOC_MAP_OCCLUSION,
    map_emission = c.SHADER_LOC_MAP_EMISSION,
    map_height = c.SHADER_LOC_MAP_HEIGHT,
    map_cubemap = c.SHADER_LOC_MAP_CUBEMAP,
    map_irradiance = c.SHADER_LOC_MAP_IRRADIANCE,
    map_prefilter = c.SHADER_LOC_MAP_PREFILTER,
    map_brdf = c.SHADER_LOC_MAP_BRDF,

    pub const map_diffuse: ShaderLocationIndex = .map_albedo;
    pub const map_specular: ShaderLocationIndex = .map_metalness;

    pub fn int(self: @This()) c_int {
        return @intFromEnum(self);
    }

    pub fn uint(self: @This()) c_uint {
        return @intCast(@intFromEnum(self));
    }
};

pub const ShaderUniformDataType = enum(c_int) {
    float = c.SHADER_UNIFORM_FLOAT,
    vec2 = c.SHADER_UNIFORM_VEC2,
    vec3 = c.SHADER_UNIFORM_VEC3,
    vec4 = c.SHADER_UNIFORM_VEC4,
    int = c.SHADER_UNIFORM_INT,
    ivec2 = c.SHADER_UNIFORM_IVEC2,
    ivec3 = c.SHADER_UNIFORM_IVEC3,
    ivec4 = c.SHADER_UNIFORM_IVEC4,
    sampler2d = c.SHADER_UNIFORM_SAMPLER2D,

    pub fn toInt(self: @This()) c_int {
        return @intFromEnum(self);
    }
};

pub const ShaderAttributeDataType = enum(c_int) {
    float = c.SHADER_ATTRIB_FLOAT,
    vec2 = c.SHADER_ATTRIB_VEC2,
    vec3 = c.SHADER_ATTRIB_VEC3,
    vec4 = c.SHADER_ATTRIB_VEC4,

    pub fn int(self: @This()) c_int {
        return @intFromEnum(self);
    }
};

pub const PixelFormat = enum(c_int) {
    uncompressed_grayscale = c.PIXELFORMAT_UNCOMPRESSED_GRAYSCALE,
    uncompressed_gray_alpha = c.PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA,
    uncompressed_r5g6b5 = c.PIXELFORMAT_UNCOMPRESSED_R5G6B5,
    uncompressed_r8g8b8 = c.PIXELFORMAT_UNCOMPRESSED_R8G8B8,
    uncompressed_r5g5b5a1 = c.PIXELFORMAT_UNCOMPRESSED_R5G5B5A1,
    uncompressed_r4g4b4a4 = c.PIXELFORMAT_UNCOMPRESSED_R4G4B4A4,
    uncompressed_r8g8b8a8 = c.PIXELFORMAT_UNCOMPRESSED_R8G8B8A8,
    uncompressed_r32 = c.PIXELFORMAT_UNCOMPRESSED_R32,
    uncompressed_r32g32b32 = c.PIXELFORMAT_UNCOMPRESSED_R32G32B32,
    uncompressed_r32g32b32a32 = c.PIXELFORMAT_UNCOMPRESSED_R32G32B32A32,
    uncompressed_r16 = c.PIXELFORMAT_UNCOMPRESSED_R16,
    uncompressed_r16g16b16 = c.PIXELFORMAT_UNCOMPRESSED_R16G16B16,
    uncompressed_r16g16b16a16 = c.PIXELFORMAT_UNCOMPRESSED_R16G16B16A16,
    compressed_dxt1_rgb = c.PIXELFORMAT_COMPRESSED_DXT1_RGB,
    compressed_dxt1_rgba = c.PIXELFORMAT_COMPRESSED_DXT1_RGBA,
    compressed_dxt3_rgba = c.PIXELFORMAT_COMPRESSED_DXT3_RGBA,
    compressed_dxt5_rgba = c.PIXELFORMAT_COMPRESSED_DXT5_RGBA,
    compressed_etc1_rgb = c.PIXELFORMAT_COMPRESSED_ETC1_RGB,
    compressed_etc2_rgb = c.PIXELFORMAT_COMPRESSED_ETC2_RGB,
    compressed_etc2_eac_rgba = c.PIXELFORMAT_COMPRESSED_ETC2_EAC_RGBA,
    compressed_pvrt_rgb = c.PIXELFORMAT_COMPRESSED_PVRT_RGB,
    compressed_pvrt_rgba = c.PIXELFORMAT_COMPRESSED_PVRT_RGBA,
    compressed_astc_4x4_rgba = c.PIXELFORMAT_COMPRESSED_ASTC_4x4_RGBA,
    compressed_astc_8x8_rgba = c.PIXELFORMAT_COMPRESSED_ASTC_8x8_RGBA,

    pub fn int(self: @This()) c_int {
        return @intFromEnum(self);
    }
};

pub const TextureFilter = enum(c_int) {
    point = c.TEXTURE_FILTER_POINT,
    bilinear = c.TEXTURE_FILTER_BILINEAR,
    trilinear = c.TEXTURE_FILTER_TRILINEAR,
    anisotropic_4x = c.TEXTURE_FILTER_ANISOTROPIC_4X,
    anisotropic_8x = c.TEXTURE_FILTER_ANISOTROPIC_8X,
    anisotropic_16x = c.TEXTURE_FILTER_ANISOTROPIC_16X,

    pub fn int(self: @This()) c_int {
        return @intFromEnum(self);
    }
};

pub const TextureWrap = enum(c_int) {
    repeat = c.TEXTURE_WRAP_REPEAT,
    clamp = c.TEXTURE_WRAP_CLAMP,
    mirror_repeat = c.TEXTURE_WRAP_MIRROR_REPEAT,
    mirror_clamp = c.TEXTURE_WRAP_MIRROR_CLAMP,

    pub fn int(self: @This()) c_int {
        return @intFromEnum(self);
    }
};

pub const CubemapLayout = enum(c_int) {
    auto_detect = c.CUBEMAP_LAYOUT_AUTO_DETECT,
    line_vertical = c.CUBEMAP_LAYOUT_LINE_VERTICAL,
    line_horizontal = c.CUBEMAP_LAYOUT_LINE_HORIZONTAL,
    cross_three_by_four = c.CUBEMAP_LAYOUT_CROSS_THREE_BY_FOUR,
    cross_four_by_three = c.CUBEMAP_LAYOUT_CROSS_FOUR_BY_THREE,

    pub fn int(self: @This()) c_int {
        return @intFromEnum(self);
    }
};

pub const FontType = enum(c_int) {
    default = c.FONT_DEFAULT,
    bitmap = c.FONT_BITMAP,
    sdf = c.FONT_SDF,

    pub fn int(self: @This()) c_int {
        return @intFromEnum(self);
    }
};

pub const BlendMode = enum(c_int) {
    alpha = c.BLEND_ALPHA,
    additive = c.BLEND_ADDITIVE,
    multiplied = c.BLEND_MULTIPLIED,
    add_colors = c.BLEND_ADD_COLORS,
    subtract_colors = c.BLEND_SUBTRACT_COLORS,
    alpha_premultiply = c.BLEND_ALPHA_PREMULTIPLY,
    custom = c.BLEND_CUSTOM,
    custom_separate = c.BLEND_CUSTOM_SEPARATE,

    pub fn int(self: @This()) c_int {
        return @intFromEnum(self);
    }
};

pub const Gesture = packed struct(c_uint) {
    pub const none: Gesture = @bitCast(c.GESTURE_NONE);

    tap: bool = false, // c.GESTURE_TAP,
    doubletap: bool = false, // c.GESTURE_DOUBLETAP,
    hold: bool = false, // c.GESTURE_HOLD,
    drag: bool = false, // c.GESTURE_DRAG,
    swipe_right: bool = false, // c.GESTURE_SWIPE_RIGHT,
    swipe_left: bool = false, // c.GESTURE_SWIPE_LEFT,
    swipe_up: bool = false, // c.GESTURE_SWIPE_UP,
    swipe_down: bool = false, // c.GESTURE_SWIPE_DOWN,
    pinch_in: bool = false, // c.GESTURE_PINCH_IN,
    pinch_out: bool = false, // c.GESTURE_PINCH_OUT,
    _: std.meta.Int(.unsigned, @bitSizeOf(c_uint) - 10) = 0,

    test Gesture {
        try std.testing.expectEqual(
            @as(c_uint, @bitCast(Gesture{
                .tap = true,
                .drag = true,
                .swipe_down = true,
                .pinch_out = true,
            })),
            c.GESTURE_TAP |
                c.GESTURE_DRAG |
                c.GESTURE_SWIPE_DOWN |
                c.GESTURE_PINCH_OUT,
        );
    }
};

pub const CameraMode = enum(c_int) {
    custom = c.CAMERA_CUSTOM,
    free = c.CAMERA_FREE,
    orbital = c.CAMERA_ORBITAL,
    first_person = c.CAMERA_FIRST_PERSON,
    third_person = c.CAMERA_THIRD_PERSON,

    pub fn int(self: @This()) c_int {
        return @intFromEnum(self);
    }
};

pub const CameraProjection = enum(c_int) {
    perspective = c.CAMERA_PERSPECTIVE,
    orthographic = c.CAMERA_ORTHOGRAPHIC,

    pub fn int(self: @This()) c_int {
        return @intFromEnum(self);
    }
};

pub const NPatchLayout = enum(c_int) {
    nine_patch = c.NPATCH_NINE_PATCH,
    three_patch_vertical = c.NPATCH_THREE_PATCH_VERTICAL,
    three_patch_horizontal = c.NPATCH_THREE_PATCH_HORIZONTAL,

    pub fn int(self: @This()) c_int {
        return @intFromEnum(self);
    }
};

pub fn DrawTextSlice(text: []const u8, posX: c_int, posY: c_int, font_size: c_int, tint: Color) void {
    DrawTextSliceV(text, .{ .x = @floatFromInt(posX), .y = @floatFromInt(posY) }, font_size, tint);
}

pub fn DrawTextSliceV(text: []const u8, pos: Vector2, font_size: c_int, tint: Color) void {
    var font_size_ = font_size;

    if (Font.getDefault().texture.id != 0) {
        const default_font_size = 10; // Default Font chars height in pixel
        if (font_size_ < default_font_size) font_size_ = default_font_size;
        const spacing = @divFloor(font_size_, default_font_size);

        DrawTextSliceEx(Font.getDefault(), text, pos, font_size_, @floatFromInt(spacing), tint);
    }
}

/// Draw text using Font
/// NOTE: chars spacing is NOT proportional to fontSize
pub fn DrawTextSliceEx(
    _font: Font,
    text: []const u8,
    position: Vector2,
    _fontSize: c_int,
    spacing: f32,
    tint: Color,
) void {
    _ = DrawTextSliceExOffsets(
        _font,
        text,
        position,
        _fontSize,
        spacing,
        tint,
        .{},
    );
}

fn DrawTextSliceExOffsets(
    _font: Font,
    text: []const u8,
    position: Vector2,
    _fontSize: c_int,
    spacing: f32,
    tint: Color,
    offset: Vector2,
) Vector2 {
    var font = _font;
    const fontSize: f32 = @floatFromInt(_fontSize);

    if (font.texture.id == 0) font = Font.getDefault(); // Security check in case of not valid font

    var textOffsetY: f32 = offset.y; // Offset between lines (on linebreak '\n')
    var textOffsetX: f32 = offset.x; // Offset X to next character to draw

    const scaleFactor: f32 = fontSize / @as(f32, @floatFromInt(font.baseSize)); // Character quad scaling factor

    var i: usize = 0;
    while (i < text.len) {
        // Get next codepoint from byte string and glyph index in font
        var codepointByteCount: c_int = 0;
        const codepoint = GetCodepointNext(text[i..].ptr, &codepointByteCount);
        const index: usize = @intCast(GetGlyphIndex(font, codepoint));

        if (codepoint == '\n') {
            textOffsetY += fontSize;
            textOffsetX = 0.0;
        } else {
            if ((codepoint != ' ') and (codepoint != '\t')) {
                DrawTextCodepoint(font, codepoint, .{ .x = position.x + textOffsetX, .y = position.y + textOffsetY }, fontSize, tint);
            }

            if (font.glyphs.?[index].advanceX == 0) {
                textOffsetX += (font.recs.?[index].width * scaleFactor + spacing);
            } else {
                const advance_x: f32 = @floatFromInt(font.glyphs.?[index].advanceX);
                textOffsetX += (advance_x * scaleFactor + spacing);
            }
        }

        i += @intCast(codepointByteCount); // Move text bytes counter to next codepoint
    }

    return Vector2.init(textOffsetX, textOffsetY);
}

pub const DrawTextWriter = struct {
    font: Font,
    pos: Vector2,
    offset: Vector2 = .{},
    font_size: c_int,
    spacing: f32,
    tint: Color,

    pub const Error = error{};

    pub fn init(x: c_int, y: c_int, font_size: c_int, tint: Color) DrawTextWriter {
        return initV(
            Vector2.init(@floatFromInt(x), @floatFromInt(y)),
            font_size,
            tint,
        );
    }

    pub fn initV(pos: Vector2, font_size: c_int, tint: Color) DrawTextWriter {
        var font_size_: c_int = font_size;

        if (Font.getDefault().texture.id != 0) {
            const default_font_size = 10; // Default Font chars height in pixel
            if (font_size_ < default_font_size) font_size_ = default_font_size;
            const spacing = @divFloor(font_size_, default_font_size);

            return initEx(
                Font.getDefault(),
                pos,
                font_size,
                @floatFromInt(spacing),
                tint,
            );
        }

        @panic("No default font found, use initEx or drawTextFmtEx");
    }

    pub fn initEx(font: Font, pos: Vector2, font_size: c_int, spacing: f32, tint: Color) DrawTextWriter {
        return .{
            .font = font,
            .pos = pos,
            .font_size = font_size,
            .spacing = spacing,
            .tint = tint,
        };
    }

    pub fn writer(self: *DrawTextWriter) std.io.GenericWriter(*DrawTextWriter, Error, write) {
        return .{ .context = self };
    }

    pub fn reset(self: *DrawTextWriter) void {
        self.offset = .{};
    }

    pub fn print(self: *DrawTextWriter, comptime fmt: []const u8, args: anytype) void {
        self.writer().print(fmt, args) catch unreachable; // ASSUME: DrawTextWriter's error set is empty
    }

    fn write(self: *DrawTextWriter, bytes: []const u8) Error!usize {
        const offsets = DrawTextSliceExOffsets(
            self.font,
            bytes,
            self.pos,
            self.font_size,
            self.spacing,
            self.tint,
            self.offset,
        );
        self.offset = offsets;
        return bytes.len;
    }
};

pub fn DrawTextFmt(comptime fmt: []const u8, args: anytype, x: c_int, y: c_int, font_size: c_int, tint: Color) void {
    var w = DrawTextWriter.init(x, y, font_size, tint);
    w.writer().print(fmt, args) catch unreachable; // ASSUME: DrawTextWriter's error set is empty
}

pub fn DrawTextFmtV(comptime fmt: []const u8, args: anytype, pos: Vector2, font_size: c_int, tint: Color) void {
    var w = DrawTextWriter.initV(pos, font_size, tint);
    w.writer().print(fmt, args) catch unreachable; // ASSUME: DrawTextWriter's error set is empty
}

pub fn DrawTextFmtEx(comptime fmt: []const u8, args: anytype, font: Font, pos: Vector2, font_size: c_int, spacing: f32, tint: Color) void {
    var w = DrawTextWriter.initEx(font, pos, font_size, spacing, tint);
    w.writer().print(fmt, args) catch unreachable; // ASSUME: DrawTextWriter's error set is empty
}

/// Measure string width for default font
pub fn MeasureTextSlice(text: []const u8, fontSize_: c_int) f32 {
    var textSize: Vector2 = .{};
    var fontSize = fontSize_;

    // Check if default font has been loaded
    if (Font.getDefault().texture.id != 0) {
        const defaultFontSize = 10; // Default Font chars height in pixel
        if (fontSize < defaultFontSize) fontSize = defaultFontSize;
        const spacing = @divFloor(fontSize, defaultFontSize);

        textSize = MeasureTextSliceEx(Font.getDefault(), text, @floatFromInt(fontSize), @floatFromInt(spacing));
    }

    return textSize.x;
}

/// Measure string size for Font
pub fn MeasureTextSliceEx(font: Font, text: []const u8, fontSize: f32, spacing: f32) Vector2 {
    var textSize: Vector2 = .{};

    if (font.texture.id == 0) return textSize; // Security check

    var tempByteCounter: c_int = 0; // Used to count longer text line num chars
    var byteCounter: c_int = 0;

    var textWidth: f32 = 0.0;
    var tempTextWidth: f32 = 0.0; // Used to count longer text line width

    var textHeight = fontSize;
    const scaleFactor: f32 = fontSize / @as(f32, @floatFromInt(font.baseSize));

    var letter: c_int = 0; // Current character
    var index: usize = 0; // Index position in sprite font

    var i: usize = 0;
    while (i < text.len) {
        byteCounter += 1;

        var next: c_int = 0;
        letter = GetCodepointNext(text[i..].ptr, &next);
        index = @intCast(GetGlyphIndex(font, letter));

        i += @intCast(next);

        if (letter != '\n') {
            if (font.glyphs[index].advanceX != 0) {
                textWidth += @floatFromInt(font.glyphs[index].advanceX);
            } else {
                textWidth += font.recs[index].width + @as(f32, @floatFromInt(font.glyphs[index].offsetX));
            }
        } else {
            if (tempTextWidth < textWidth) tempTextWidth = textWidth;
            byteCounter = 0;
            textWidth = 0;
            textHeight += fontSize;
        }

        if (tempByteCounter < byteCounter) tempByteCounter = byteCounter;
    }

    if (tempTextWidth < textWidth) tempTextWidth = textWidth;

    textSize.x = tempTextWidth * scaleFactor + @as(f32, @floatFromInt((tempByteCounter - 1))) * spacing;
    textSize.y = textHeight;

    return textSize;
}

fn toFloat(comptime T: type, v: anytype) T {
    if (comptime builtin.zig_version.order(std.SemanticVersion.parse("0.14.0-dev.1410+13da34955") catch unreachable) == .lt) {
        return switch (@typeInfo(@TypeOf(v))) {
            .ComptimeFloat, .Float => @floatCast(v),
            .ComptimeInt, .Int => @floatFromInt(v),
            else => @compileError("Expected int or float type, found " ++ @typeName(@TypeOf(v))),
        };
    } else {
        return switch (@typeInfo(@TypeOf(v))) {
            .comptime_float, .float => @floatCast(v),
            .comptime_int, .int => @floatFromInt(v),
            else => @compileError("Expected int or float type, found " ++ @typeName(@TypeOf(v))),
        };
    }
}

// redefs

pub fn DrawTriangleFanSlice(points: []const Vector2, color: Color) void {
    DrawTriangleFan(points.ptr, @intCast(points.len), color);
}
pub fn DrawTriangleStripSlice(points: []const Vector2, color: Color) void {
    DrawTriangleStrip(points.ptr, @intCast(points.len), color);
}
pub fn DrawSplineLinearSlice(points: []const Vector2, thick: f32, color: Color) void {
    DrawSplineLinear(points.ptr, @intCast(points.len), thick, color);
}
pub fn DrawSplineBasisSlice(points: []const Vector2, thick: f32, color: Color) void {
    DrawSplineBasis(points.ptr, @intCast(points.len), thick, color);
}
pub fn DrawSplineCatmullRomSlice(points: []const Vector2, thick: f32, color: Color) void {
    DrawSplineCatmullRom(points.ptr, @intCast(points.len), thick, color);
}
pub fn DrawSplineBezierQuadraticSlice(points: []const Vector2, thick: f32, color: Color) void {
    DrawSplineBezierQuadratic(points.ptr, @intCast(points.len), thick, color);
}
pub fn DrawSplineBezierCubicSlice(points: []const Vector2, thick: f32, color: Color) void {
    DrawSplineBezierCubic(points.ptr, @intCast(points.len), thick, color);
}
pub fn DrawLineStripSlice(points: []const Vector2, color: Color) void {
    DrawLineStrip(points.ptr, @intCast(points.len), color);
}
pub fn SetWindowIconsSlice(images: []const Image) void {
    SetWindowIcons(images.ptr, @intCast(images.len));
}
pub fn GetScreenWidthU() c_uint {
    return @intCast(GetScreenWidth());
}
pub fn GetScreenHeightU() c_uint {
    return @intCast(GetScreenHeight());
}
pub fn GetScreenWidthF() f32 {
    return @floatFromInt(GetScreenWidth());
}
pub fn GetScreenHeightF() f32 {
    return @floatFromInt(GetScreenHeight());
}
pub fn LoadRandomSequenceSlice(count: c_uint, min: c_int, max: c_int) []c_int {
    return LoadRandomSequence(count, min, max)[0..count];
}
pub fn UnloadRandomSequenceSlice(sequence: []c_int) void {
    UnloadRandomSequence(sequence.ptr);
}
pub fn LoadFileDataSlice(file_name: [*:0]const u8) ?[]u8 {
    var len: c_int = undefined;
    const data = LoadFileData(file_name, &len) orelse return null;
    return data[0..@intCast(len)];
}
pub fn UnloadFileDataSlice(data: []u8) void {
    UnloadFileData(data.ptr);
}
pub fn LoadFileTextSlice(file_name: [*:0]const u8) ?[]u8 {
    const file_text = LoadFileText(file_name) orelse return null;
    return std.mem.sliceTo(file_text, 0);
}
pub fn UnloadFileTextSlice(text: []u8) void {
    UnloadFileText(text.ptr);
}
pub const GetMouseRay = GetScreenToWorldRay;

// tweaked c-import generations

pub extern fn DrawCircle(centerX: c_int, centerY: c_int, radius: f32, color: Color) void;
pub extern fn DrawCircleSectorLines(center: Vector2, radius: f32, startAngle: f32, endAngle: f32, segments: c_int, color: Color) void;
pub extern fn DrawCircleSector(center: Vector2, radius: f32, startAngle: f32, endAngle: f32, segments: c_int, color: Color) void;
pub extern fn DrawCircleGradient(centerX: c_int, centerY: c_int, radius: f32, color1: Color, color2: Color) void;
pub extern fn DrawCircleV(center: Vector2, radius: f32, color: Color) void;
pub extern fn DrawCircleLines(centerX: c_int, centerY: c_int, radius: f32, color: Color) void;
pub extern fn DrawCircleLinesV(center: Vector2, radius: f32, color: Color) void;
pub extern fn DrawEllipse(centerX: c_int, centerY: c_int, radiusH: f32, radiusV: f32, color: Color) void;
pub extern fn DrawEllipseLines(centerX: c_int, centerY: c_int, radiusH: f32, radiusV: f32, color: Color) void;
pub extern fn DrawRing(center: Vector2, innerRadius: f32, outerRadius: f32, startAngle: f32, endAngle: f32, segments: c_int, color: Color) void;
pub extern fn DrawRingLines(center: Vector2, innerRadius: f32, outerRadius: f32, startAngle: f32, endAngle: f32, segments: c_int, color: Color) void;
pub extern fn DrawRectangle(posX: c_int, posY: c_int, width: c_int, height: c_int, color: Color) void;
pub extern fn DrawRectangleV(position: Vector2, size: Vector2, color: Color) void;
pub extern fn DrawRectangleRec(rec: Rectangle, color: Color) void;
pub extern fn DrawRectanglePro(rec: Rectangle, origin: Vector2, rotation: f32, color: Color) void;
pub extern fn DrawRectangleGradientV(posX: c_int, posY: c_int, width: c_int, height: c_int, color1: Color, color2: Color) void;
pub extern fn DrawRectangleGradientH(posX: c_int, posY: c_int, width: c_int, height: c_int, color1: Color, color2: Color) void;
pub extern fn DrawLineEx(startPos: Vector2, endPos: Vector2, thick: f32, color: Color) void;
pub extern fn DrawLineBezier(startPos: Vector2, endPos: Vector2, thick: f32, color: Color) void;
pub extern fn DrawRectangleGradientEx(rec: Rectangle, col1: Color, col2: Color, col3: Color, col4: Color) void;
pub extern fn DrawRectangleLines(posX: c_int, posY: c_int, width: c_int, height: c_int, color: Color) void;
pub extern fn DrawRectangleLinesEx(rec: Rectangle, lineThick: f32, color: Color) void;
pub extern fn DrawRectangleRounded(rec: Rectangle, roundness: f32, segments: c_int, color: Color) void;
pub extern fn DrawRectangleRoundedLines(rec: Rectangle, roundness: f32, segments: c_int, color: Color) void;
pub extern fn DrawRectangleRoundedLinesEx(rec: Rectangle, roundness: f32, segments: c_int, line_thickness: f32, color: Color) void;
pub extern fn DrawTriangle(v1: Vector2, v2: Vector2, v3: Vector2, color: Color) void;
pub extern fn DrawTriangleLines(v1: Vector2, v2: Vector2, v3: Vector2, color: Color) void;
// c-translate says points is mutable, but raylib doesnt mutate points
pub extern fn DrawLineStrip(points: [*]const Vector2, pointCount: c_int, color: Color) void;
// c-translate says points is mutable, but raylib doesnt mutate points
pub extern fn DrawTriangleFan(points: [*]const Vector2, pointCount: c_int, color: Color) void;
// c-translate says points is mutable, but raylib doesnt mutate points
pub extern fn DrawTriangleStrip(points: [*]const Vector2, pointCount: c_int, color: Color) void;
pub extern fn DrawPoly(center: Vector2, sides: c_int, radius: f32, rotation: f32, color: Color) void;
pub extern fn DrawPolyLines(center: Vector2, sides: c_int, radius: f32, rotation: f32, color: Color) void;
pub extern fn DrawPolyLinesEx(center: Vector2, sides: c_int, radius: f32, rotation: f32, lineThick: f32, color: Color) void;
// c-translate says points is mutable, but raylib doesnt mutate points
pub extern fn DrawSplineLinear(points: [*]const Vector2, pointCount: c_int, thick: f32, color: Color) void;
// c-translate says points is mutable, but raylib doesnt mutate points
pub extern fn DrawSplineBasis(points: [*]const Vector2, pointCount: c_int, thick: f32, color: Color) void;
// c-translate says points is mutable, but raylib doesnt mutate points
pub extern fn DrawSplineCatmullRom(points: [*]const Vector2, pointCount: c_int, thick: f32, color: Color) void;
// c-translate says points is mutable, but raylib doesnt mutate points
pub extern fn DrawSplineBezierQuadratic(points: [*]const Vector2, pointCount: c_int, thick: f32, color: Color) void;
// c-translate says points is mutable, but raylib doesnt mutate points
pub extern fn DrawSplineBezierCubic(points: [*]const Vector2, pointCount: c_int, thick: f32, color: Color) void;
pub extern fn DrawSplineSegmentLinear(p1: Vector2, p2: Vector2, thick: f32, color: Color) void;
pub extern fn DrawSplineSegmentBasis(p1: Vector2, p2: Vector2, p3: Vector2, p4: Vector2, thick: f32, color: Color) void;
pub extern fn DrawSplineSegmentCatmullRom(p1: Vector2, p2: Vector2, p3: Vector2, p4: Vector2, thick: f32, color: Color) void;
pub extern fn DrawSplineSegmentBezierQuadratic(p1: Vector2, c2: Vector2, p3: Vector2, thick: f32, color: Color) void;
pub extern fn DrawSplineSegmentBezierCubic(p1: Vector2, c2: Vector2, c3: Vector2, p4: Vector2, thick: f32, color: Color) void;
pub extern fn GetCodepointNext(text: [*]const u8, codepointSize: *c_int) c_int;
pub extern fn InitWindow(width: c_int, height: c_int, title: [*:0]const u8) void;
pub extern fn CloseWindow() void;
pub extern fn WindowShouldClose() bool;
pub extern fn BeginDrawing() void;
pub extern fn EndDrawing() void;
pub extern fn ClearBackground(color: Color) void;
pub extern fn DrawTextCodepoint(font: Font, codepoint: c_int, position: Vector2, fontSize: f32, tint: Color) void;
pub extern fn DrawPixel(posX: c_int, posY: c_int, color: Color) void;
pub extern fn DrawPixelV(position: Vector2, color: Color) void;
pub extern fn DrawLine(startPosX: c_int, startPosY: c_int, endPosX: c_int, endPosY: c_int, color: Color) void;
pub extern fn DrawLineV(startPos: Vector2, endPos: Vector2, color: Color) void;
pub extern fn LoadImageFromScreen() Image;
pub extern fn IsImageReady(image: Image) bool;
pub extern fn UnloadImage(image: Image) void;
pub extern fn GenImageColor(width: c_int, height: c_int, color: Color) Image;
pub extern fn GenImageGradientLinear(width: c_int, height: c_int, direction: c_int, start: Color, end: Color) Image;
pub extern fn GenImageGradientRadial(width: c_int, height: c_int, density: f32, inner: Color, outer: Color) Image;
pub extern fn GenImageGradientSquare(width: c_int, height: c_int, density: f32, inner: Color, outer: Color) Image;
pub extern fn GenImageChecked(width: c_int, height: c_int, checksX: c_int, checksY: c_int, col1: Color, col2: Color) Image;
pub extern fn GenImageWhiteNoise(width: c_int, height: c_int, factor: f32) Image;
pub extern fn GenImagePerlinNoise(width: c_int, height: c_int, offsetX: c_int, offsetY: c_int, scale: f32) Image;
pub extern fn GenImageCellular(width: c_int, height: c_int, tileSize: c_int) Image;
pub extern fn GenImageText(width: c_int, height: c_int, text: [*:0]const u8) Image;
pub extern fn ImageCopy(image: Image) Image;
pub extern fn ImageFromImage(image: Image, rec: Rectangle) Image;
pub extern fn LoadFontEx(fileName: [*:0]const u8, fontSize: c_int, codepoints: ?[*]const c_int, codepointCount: c_int) Font;
pub extern fn LoadFontFromImage(image: Image, key: Color, firstChar: c_int) Font;
pub extern fn LoadFontFromMemory(fileType: [*:0]const u8, fileData: [*]const u8, dataSize: c_int, fontSize: c_int, codepoints: ?[*]const c_int, codepointCount: c_int) Font;
pub extern fn UnloadFont(font: Font) void;
pub extern fn IsFontReady(font: Font) bool;
pub extern fn GetFontDefault() Font;
pub extern fn LoadFont(fileName: [*:0]const u8) Font;
pub extern fn ExportFontAsCode(font: Font, fileName: [*:0]const u8) bool;
pub extern fn Fade(color: Color, alpha: f32) Color;
pub extern fn ColorFromNormalized(normalized: Vector4) Color;
pub extern fn ColorIsEqual(col1: Color, col2: Color) bool;
pub extern fn ColorToInt(color: Color) c_int;
pub extern fn ColorNormalize(color: Color) Vector4;
pub extern fn ColorToHSV(color: Color) Vector3;
pub extern fn ColorFromHSV(hue: f32, saturation: f32, value: f32) Color;
pub extern fn ColorTint(color: Color, tint: Color) Color;
pub extern fn ColorBrightness(color: Color, factor: f32) Color;
pub extern fn ColorContrast(color: Color, contrast: f32) Color;
pub extern fn ColorAlpha(color: Color, alpha: f32) Color;
pub extern fn GetColor(hexValue: c_uint) Color;
pub extern fn ColorAlphaBlend(dst: Color, src: Color, tint: Color) Color;
pub extern fn GetGlyphIndex(font: Font, codepoint: c_int) c_int;
pub extern fn LoadTexture(fileName: [*:0]const u8) Texture2D;
pub extern fn LoadTextureFromImage(image: Image) Texture2D;
pub extern fn LoadTextureCubemap(image: Image, layout: CubemapLayout) TextureCubemap;
pub extern fn LoadImage(fileName: [*:0]const u8) Image;
pub extern fn LoadImageRaw(fileName: [*:0]const u8, width: c_int, height: c_int, format: c_int, headerSize: c_int) Image;
pub extern fn LoadImageSvg(fileNameOrString: [*:0]const u8, width: c_int, height: c_int) Image;
pub extern fn LoadImageAnim(fileName: [*:0]const u8, frames: *c_int) Image;
pub extern fn LoadImageAnimFromMemory(fileType: [*:0]const u8, fileData: [*c]const u8, dataSize: c_int, frames: *c_int) Image;
pub extern fn LoadImageFromMemory(fileType: [*:0]const u8, fileData: [*c]const u8, dataSize: c_int) Image;
pub extern fn LoadImageFromTexture(texture: Texture2D) Image;
pub extern fn GenTextureMipmaps(texture: *Texture2D) void;
pub extern fn ExportImage(image: Image, fileName: [*:0]const u8) bool;
pub extern fn ExportImageToMemory(image: Image, fileType: [*:0]const u8, fileSize: *c_int) ?[*]u8;
pub extern fn ExportImageAsCode(image: Image, fileName: [*:0]const u8) bool;
pub extern fn ImageText(text: [*:0]const u8, fontSize: c_int, color: Color) Image;
pub extern fn ImageTextEx(font: Font, text: [*:0]const u8, fontSize: f32, spacing: f32, tint: Color) Image;
pub extern fn ImageFormat(image: *Image, newFormat: c_int) void;
pub extern fn ImageToPOT(image: *Image, fill: Color) void;
pub extern fn ImageCrop(image: *Image, crop: Rectangle) void;
pub extern fn ImageAlphaCrop(image: *Image, threshold: f32) void;
pub extern fn ImageAlphaClear(image: *Image, color: Color, threshold: f32) void;
pub extern fn ImageAlphaMask(image: *Image, alphaMask: Image) void;
pub extern fn ImageAlphaPremultiply(image: *Image) void;
pub extern fn ImageBlurGaussian(image: *Image, blurSize: c_int) void;
pub extern fn ImageKernelConvolution(image: *Image, kernel: [*]const f32, kernelSize: c_int) void;
pub extern fn ImageResize(image: *Image, newWidth: c_int, newHeight: c_int) void;
pub extern fn ImageResizeNN(image: *Image, newWidth: c_int, newHeight: c_int) void;
pub extern fn ImageResizeCanvas(image: *Image, newWidth: c_int, newHeight: c_int, offsetX: c_int, offsetY: c_int, fill: Color) void;
pub extern fn ImageMipmaps(image: *Image) void;
pub extern fn ImageDither(image: *Image, rBpp: c_int, gBpp: c_int, bBpp: c_int, aBpp: c_int) void;
pub extern fn ImageFlipVertical(image: *Image) void;
pub extern fn ImageFlipHorizontal(image: *Image) void;
pub extern fn ImageRotate(image: *Image, degrees: c_int) void;
pub extern fn ImageRotateCW(image: *Image) void;
pub extern fn ImageRotateCCW(image: *Image) void;
pub extern fn ImageColorTint(image: *Image, color: Color) void;
pub extern fn ImageColorInvert(image: *Image) void;
pub extern fn ImageColorGrayscale(image: *Image) void;
pub extern fn ImageColorContrast(image: *Image, contrast: f32) void;
pub extern fn ImageColorBrightness(image: *Image, brightness: c_int) void;
pub extern fn ImageColorReplace(image: *Image, color: Color, replace: Color) void;
pub extern fn LoadImageColors(image: Image) ?[*]Color;
pub extern fn LoadImagePalette(image: Image, maxPaletteSize: c_int, colorCount: *c_int) ?[*]Color;
pub extern fn UnloadImageColors(colors: ?[*]Color) void;
pub extern fn UnloadImagePalette(colors: ?[*]Color) void;
pub extern fn GetImageAlphaBorder(image: Image, threshold: f32) Rectangle;
pub extern fn GetImageColor(image: Image, x: c_int, y: c_int) Color;
pub extern fn ImageClearBackground(dst: *Image, color: Color) void;
pub extern fn ImageDrawPixel(dst: *Image, posX: c_int, posY: c_int, color: Color) void;
pub extern fn ImageDrawPixelV(dst: *Image, position: Vector2, color: Color) void;
pub extern fn ImageDrawLine(dst: *Image, startPosX: c_int, startPosY: c_int, endPosX: c_int, endPosY: c_int, color: Color) void;
pub extern fn ImageDrawLineV(dst: *Image, start: Vector2, end: Vector2, color: Color) void;
pub extern fn ImageDrawCircle(dst: *Image, centerX: c_int, centerY: c_int, radius: c_int, color: Color) void;
pub extern fn ImageDrawCircleV(dst: *Image, center: Vector2, radius: c_int, color: Color) void;
pub extern fn ImageDrawCircleLines(dst: *Image, centerX: c_int, centerY: c_int, radius: c_int, color: Color) void;
pub extern fn ImageDrawCircleLinesV(dst: *Image, center: Vector2, radius: c_int, color: Color) void;
pub extern fn ImageDrawRectangle(dst: *Image, posX: c_int, posY: c_int, width: c_int, height: c_int, color: Color) void;
pub extern fn ImageDrawRectangleV(dst: *Image, position: Vector2, size: Vector2, color: Color) void;
pub extern fn ImageDrawRectangleRec(dst: *Image, rec: Rectangle, color: Color) void;
pub extern fn ImageDrawRectangleLines(dst: *Image, rec: Rectangle, thick: c_int, color: Color) void;
pub extern fn ImageDraw(dst: *Image, src: Image, srcRec: Rectangle, dstRec: Rectangle, tint: Color) void;
pub extern fn ImageDrawText(dst: *Image, text: [*:0]const u8, posX: c_int, posY: c_int, fontSize: c_int, color: Color) void;
pub extern fn ImageDrawTextEx(dst: *Image, font: Font, text: [*:0]const u8, position: Vector2, fontSize: f32, spacing: f32, tint: Color) void;
pub extern fn IsWindowReady() bool;
pub extern fn IsWindowFullscreen() bool;
pub extern fn IsWindowHidden() bool;
pub extern fn IsWindowMinimized() bool;
pub extern fn IsWindowMaximized() bool;
pub extern fn IsWindowFocused() bool;
pub extern fn IsWindowResized() bool;
pub extern fn IsWindowState(flag: ConfigFlags) bool;
pub extern fn SetWindowState(flags: ConfigFlags) void;
pub extern fn ClearWindowState(flags: ConfigFlags) void;
pub extern fn ToggleFullscreen() void;
pub extern fn ToggleBorderlessWindowed() void;
pub extern fn MaximizeWindow() void;
pub extern fn MinimizeWindow() void;
pub extern fn RestoreWindow() void;
pub extern fn SetWindowIcon(image: Image) void;
pub extern fn SetWindowIcons(images: ?[*]const Image, count: c_int) void;
pub extern fn SetWindowTitle(title: [*:0]const u8) void;
pub extern fn SetWindowPosition(x: c_int, y: c_int) void;
pub extern fn SetWindowMonitor(monitor: c_int) void;
pub extern fn SetWindowMinSize(width: c_int, height: c_int) void;
pub extern fn SetWindowMaxSize(width: c_int, height: c_int) void;
pub extern fn SetWindowSize(width: c_int, height: c_int) void;
pub extern fn SetWindowOpacity(opacity: f32) void;
pub extern fn SetWindowFocused() void;
pub extern fn GetWindowHandle() ?*anyopaque;
pub extern fn GetScreenWidth() c_int;
pub extern fn GetScreenHeight() c_int;
pub extern fn GetRenderWidth() c_int;
pub extern fn GetRenderHeight() c_int;
pub extern fn GetMonitorCount() c_int;
pub extern fn GetCurrentMonitor() c_int;
pub extern fn GetMonitorPosition(monitor: c_int) Vector2;
pub extern fn GetMonitorWidth(monitor: c_int) c_int;
pub extern fn GetMonitorHeight(monitor: c_int) c_int;
pub extern fn GetMonitorPhysicalWidth(monitor: c_int) c_int;
pub extern fn GetMonitorPhysicalHeight(monitor: c_int) c_int;
pub extern fn GetMonitorRefreshRate(monitor: c_int) c_int;
pub extern fn GetWindowPosition() Vector2;
pub extern fn GetWindowScaleDPI() Vector2;
pub extern fn GetMonitorName(monitor: c_int) [*:0]const u8;
pub extern fn SetClipboardText(text: [*:0]const u8) void;
pub extern fn GetClipboardText() ?[*:0]const u8;
pub extern fn EnableEventWaiting() void;
pub extern fn DisableEventWaiting() void;
pub extern fn ShowCursor() void;
pub extern fn HideCursor() void;
pub extern fn IsCursorHidden() bool;
pub extern fn EnableCursor() void;
pub extern fn DisableCursor() void;
pub extern fn IsCursorOnScreen() bool;
pub extern fn BeginMode2D(camera: Camera2D) void;
pub extern fn EndMode2D() void;
pub extern fn BeginMode3D(camera: Camera3D) void;
pub extern fn EndMode3D() void;
pub extern fn BeginTextureMode(target: RenderTexture2D) void;
pub extern fn EndTextureMode() void;
pub extern fn BeginShaderMode(shader: Shader) void;
pub extern fn EndShaderMode() void;
pub extern fn BeginBlendMode(mode: BlendMode) void;
pub extern fn EndBlendMode() void;
pub extern fn BeginScissorMode(x: c_int, y: c_int, width: c_int, height: c_int) void;
pub extern fn EndScissorMode() void;
pub extern fn BeginVrStereoMode(config: VrStereoConfig) void;
pub extern fn EndVrStereoMode() void;
pub extern fn LoadVrStereoConfig(device: VrDeviceInfo) VrStereoConfig;
pub extern fn UnloadVrStereoConfig(config: VrStereoConfig) void;
pub extern fn LoadShader(vsFileName: ?[*:0]const u8, fsFileName: ?[*:0]const u8) Shader;
pub extern fn LoadShaderFromMemory(vsCode: ?[*:0]const u8, fsCode: ?[*:0]const u8) Shader;
pub extern fn IsShaderReady(shader: Shader) bool;
pub extern fn GetShaderLocation(shader: Shader, uniformName: [*:0]const u8) c_int;
pub extern fn GetShaderLocationAttrib(shader: Shader, attribName: [*:0]const u8) c_int;
pub extern fn SetShaderValue(shader: Shader, locIndex: c_int, value: ?*const anyopaque, uniformType: ShaderUniformDataType) void;
pub extern fn SetShaderValueV(shader: Shader, locIndex: c_int, value: ?*const anyopaque, uniformType: ShaderUniformDataType, count: c_int) void;
pub extern fn SetShaderValueMatrix(shader: Shader, locIndex: c_int, mat: Matrix) void;
pub extern fn SetShaderValueTexture(shader: Shader, locIndex: c_int, texture: Texture2D) void;
pub extern fn UnloadShader(shader: Shader) void;
pub extern fn GetScreenToWorldRay(position: Vector2, camera: Camera) Ray;
pub extern fn GetScreenToWorldRayEx(position: Vector2, camera: Camera, width: f32, height: f32) Ray;
pub extern fn GetWorldToScreen(position: Vector3, camera: Camera) Vector2;
pub extern fn GetWorldToScreenEx(position: Vector3, camera: Camera, width: c_int, height: c_int) Vector2;
pub extern fn GetWorldToScreen2D(position: Vector2, camera: Camera2D) Vector2;
pub extern fn GetScreenToWorld2D(position: Vector2, camera: Camera2D) Vector2;
pub extern fn GetCameraMatrix(camera: Camera) Matrix;
pub extern fn GetCameraMatrix2D(camera: Camera2D) Matrix;
pub extern fn SetTargetFPS(fps: c_int) void;
pub extern fn GetFrameTime() f32;
pub extern fn GetTime() f64;
pub extern fn GetFPS() c_int;
pub extern fn SwapScreenBuffer() void;
pub extern fn PollInputEvents() void;
pub extern fn WaitTime(seconds: f64) void;
pub extern fn SetRandomSeed(seed: c_uint) void;
pub extern fn GetRandomValue(min: c_int, max: c_int) c_int;
pub extern fn LoadRandomSequence(count: c_uint, min: c_int, max: c_int) [*]c_int;
pub extern fn UnloadRandomSequence(sequence: [*]c_int) void;
pub extern fn TakeScreenshot(fileName: [*:0]const u8) void;
pub extern fn SetConfigFlags(flags: ConfigFlags) void;
pub extern fn OpenURL(url: [*:0]const u8) void;
pub extern fn TraceLog(logLevel: TraceLogLevel, text: [*:0]const u8, ...) void;
pub extern fn SetTraceLogLevel(logLevel: TraceLogLevel) void;
pub extern fn MemAlloc(size: c_uint) ?*anyopaque;
pub extern fn MemRealloc(ptr: ?*anyopaque, size: c_uint) ?*anyopaque;
pub extern fn MemFree(ptr: ?*anyopaque) void;
pub extern fn SetTraceLogCallback(callback: TraceLogCallback) void;
pub extern fn SetLoadFileDataCallback(callback: LoadFileDataCallback) void;
pub extern fn SetSaveFileDataCallback(callback: SaveFileDataCallback) void;
pub extern fn SetLoadFileTextCallback(callback: LoadFileTextCallback) void;
pub extern fn SetSaveFileTextCallback(callback: SaveFileTextCallback) void;
pub extern fn IsKeyPressed(key: KeyboardKey) bool;
pub extern fn IsKeyPressedRepeat(key: KeyboardKey) bool;
pub extern fn IsKeyDown(key: KeyboardKey) bool;
pub extern fn IsKeyReleased(key: KeyboardKey) bool;
pub extern fn IsKeyUp(key: KeyboardKey) bool;
pub extern fn GetKeyPressed() KeyboardKey;
pub extern fn GetCharPressed() c_int;
pub extern fn SetExitKey(key: KeyboardKey) void;
pub extern fn LoadFileData(fileName: [*:0]const u8, dataSize: *c_int) ?[*]u8;
pub extern fn UnloadFileData(data: [*]u8) void;
pub extern fn SaveFileData(fileName: [*:0]const u8, data: ?*const anyopaque, dataSize: c_int) bool;
pub extern fn ExportDataAsCode(data: [*]const u8, dataSize: c_int, fileName: [*:0]const u8) bool;
pub extern fn LoadFileText(fileName: [*:0]const u8) ?[*:0]u8;
pub extern fn UnloadFileText(text: [*]u8) void;
pub extern fn SaveFileText(fileName: [*:0]const u8, text: [*:0]u8) bool;
pub extern fn FileExists(fileName: [*:0]const u8) bool;
pub extern fn DirectoryExists(dirPath: [*:0]const u8) bool;
pub extern fn IsFileExtension(fileName: [*:0]const u8, ext: [*:0]const u8) bool;
pub extern fn MeasureText(text: [*:0]const u8, fontSize: c_int) c_int;
pub extern fn SetTextureFilter(texture: Texture2D, filter: TextureFilter) void;
pub extern fn DrawTexture(texture: Texture2D, posX: c_int, posY: c_int, tint: Color) void;
pub extern fn DrawTextureV(texture: Texture2D, position: Vector2, tint: Color) void;
pub extern fn DrawTextureEx(texture: Texture2D, position: Vector2, rotation: f32, scale: f32, tint: Color) void;
pub extern fn DrawTextureRec(texture: Texture2D, source: Rectangle, position: Vector2, tint: Color) void;
pub extern fn DrawTexturePro(texture: Texture2D, source: Rectangle, dest: Rectangle, origin: Vector2, rotation: f32, tint: Color) void;
pub extern fn DrawTextureNPatch(texture: Texture2D, nPatchInfo: NPatchInfo, dest: Rectangle, origin: Vector2, rotation: f32, tint: Color) void;
pub extern fn GetFileLength(fileName: [*:0]const u8) c_int;
pub extern fn GetFileExtension(fileName: [*:0]const u8) [*:0]const u8;
pub extern fn GetFileName(filePath: [*:0]const u8) [*:0]const u8;
pub extern fn GetFileNameWithoutExt(filePath: [*:0]const u8) [*:0]const u8;
pub extern fn GetDirectoryPath(filePath: [*:0]const u8) [*:0]const u8;
pub extern fn GetPrevDirectoryPath(dirPath: [*:0]const u8) [*:0]const u8;
pub extern fn GetWorkingDirectory() ?[*:0]const u8;
pub extern fn GetApplicationDirectory() [*:0]const u8;
pub extern fn ChangeDirectory(dir: [*:0]const u8) bool;
pub extern fn IsPathFile(path: [*:0]const u8) bool;
pub extern fn IsMouseButtonPressed(button: MouseButton) bool;
pub extern fn IsMouseButtonDown(button: MouseButton) bool;
pub extern fn IsMouseButtonReleased(button: MouseButton) bool;
pub extern fn IsMouseButtonUp(button: MouseButton) bool;
pub extern fn GetMouseX() c_int;
pub extern fn GetMouseY() c_int;
pub extern fn GetMousePosition() Vector2;
pub extern fn GetMouseDelta() Vector2;
pub extern fn SetMousePosition(x: c_int, y: c_int) void;
pub extern fn SetMouseOffset(offsetX: c_int, offsetY: c_int) void;
pub extern fn SetMouseScale(scaleX: f32, scaleY: f32) void;
pub extern fn GetMouseWheelMove() f32;
pub extern fn GetMouseWheelMoveV() Vector2;
pub extern fn SetMouseCursor(cursor: MouseCursor) void;
pub extern fn LoadDirectoryFiles(dirPath: [*:0]const u8) FilePathList;
pub extern fn LoadDirectoryFilesEx(basePath: [*:0]const u8, filter: ?[*:0]const u8, scanSubdirs: bool) FilePathList;
pub extern fn UnloadDirectoryFiles(files: FilePathList) void;
pub extern fn IsFileDropped() bool;
pub extern fn LoadDroppedFiles() FilePathList;
pub extern fn UnloadDroppedFiles(files: FilePathList) void;
pub extern fn IsGamepadAvailable(gamepad: c_int) bool;
pub extern fn GetGamepadName(gamepad: c_int) [*:0]const u8;
pub extern fn IsGamepadButtonPressed(gamepad: c_int, button: GamepadButton) bool;
pub extern fn IsGamepadButtonDown(gamepad: c_int, button: GamepadButton) bool;
pub extern fn IsGamepadButtonReleased(gamepad: c_int, button: GamepadButton) bool;
pub extern fn IsGamepadButtonUp(gamepad: c_int, button: GamepadButton) bool;
pub extern fn GetGamepadButtonPressed() GamepadButton;
pub extern fn GetGamepadAxisCount(gamepad: c_int) c_int;
pub extern fn GetGamepadAxisMovement(gamepad: c_int, axis: GamepadAxis) f32;
pub extern fn SetGamepadMappings(mappings: [*:0]const u8) c_int;
pub extern fn SetGamepadVibration(gamepad: c_int, leftMotor: f32, rightMotor: f32) void;
pub extern fn GetTouchX() c_int;
pub extern fn GetTouchY() c_int;
pub extern fn GetTouchPosition(index: c_int) Vector2;
pub extern fn GetTouchPointId(index: c_int) c_int;
pub extern fn GetTouchPointCount() c_int;
pub extern fn SetGesturesEnabled(flags: Gesture) void;
pub extern fn IsGestureDetected(gesture: Gesture) bool;
pub extern fn GetGestureDetected() Gesture;
pub extern fn GetGestureHoldDuration() f32;
pub extern fn GetGestureDragVector() Vector2;
pub extern fn GetGestureDragAngle() f32;
pub extern fn GetGesturePinchVector() Vector2;
pub extern fn GetGesturePinchAngle() f32;
pub extern fn LoadMusicStream(fileName: [*c]const u8) Music;
pub extern fn LoadMusicStreamFromMemory(fileType: [*c]const u8, data: [*c]const u8, dataSize: c_int) Music;
pub extern fn IsMusicReady(music: Music) bool;
pub extern fn UnloadMusicStream(music: Music) void;
pub extern fn PlayMusicStream(music: Music) void;
pub extern fn IsMusicStreamPlaying(music: Music) bool;
pub extern fn UpdateMusicStream(music: Music) void;
pub extern fn StopMusicStream(music: Music) void;
pub extern fn PauseMusicStream(music: Music) void;
pub extern fn ResumeMusicStream(music: Music) void;
pub extern fn SeekMusicStream(music: Music, position: f32) void;
pub extern fn SetMusicVolume(music: Music, volume: f32) void;
pub extern fn SetMusicPitch(music: Music, pitch: f32) void;
pub extern fn SetMusicPan(music: Music, pan: f32) void;
pub extern fn GetMusicTimeLength(music: Music) f32;
pub extern fn GetMusicTimePlayed(music: Music) f32;
pub extern fn UploadMesh(mesh: *Mesh, dynamic: bool) void;
pub extern fn UpdateMeshBuffer(mesh: Mesh, index: c_int, data: ?*const anyopaque, dataSize: c_int, offset: c_int) void;
pub extern fn UnloadMesh(mesh: Mesh) void;
pub extern fn DrawMesh(mesh: Mesh, material: Material, transform: Matrix) void;
pub extern fn DrawMeshInstanced(mesh: Mesh, material: Material, transforms: [*c]const Matrix, instances: c_int) void;
pub extern fn GetMeshBoundingBox(mesh: Mesh) BoundingBox;
pub extern fn GenMeshTangents(mesh: *Mesh) void;
pub extern fn ExportMesh(mesh: Mesh, fileName: [*:0]const u8) bool;
pub extern fn ExportMeshAsCode(mesh: Mesh, fileName: [*:0]const u8) bool;
pub extern fn GenMeshPoly(sides: c_int, radius: f32) Mesh;
pub extern fn GenMeshPlane(width: f32, length: f32, resX: c_int, resZ: c_int) Mesh;
pub extern fn GenMeshCube(width: f32, height: f32, length: f32) Mesh;
pub extern fn GenMeshSphere(radius: f32, rings: c_int, slices: c_int) Mesh;
pub extern fn GenMeshHemiSphere(radius: f32, rings: c_int, slices: c_int) Mesh;
pub extern fn GenMeshCylinder(radius: f32, height: f32, slices: c_int) Mesh;
pub extern fn GenMeshCone(radius: f32, height: f32, slices: c_int) Mesh;
pub extern fn GenMeshTorus(radius: f32, size: f32, radSeg: c_int, sides: c_int) Mesh;
pub extern fn GenMeshKnot(radius: f32, size: f32, radSeg: c_int, sides: c_int) Mesh;
pub extern fn GenMeshHeightmap(heightmap: Image, size: Vector3) Mesh;
pub extern fn GenMeshCubicmap(cubicmap: Image, cubeSize: Vector3) Mesh;
pub extern fn LoadModel(fileName: [*:0]const u8) Model;
pub extern fn LoadModelFromMesh(mesh: Mesh) Model;
pub extern fn IsModelReady(model: Model) bool;
pub extern fn UnloadModel(model: Model) void;
pub extern fn GetModelBoundingBox(model: Model) BoundingBox;
pub extern fn DrawModel(model: Model, position: Vector3, scale: f32, tint: Color) void;
pub extern fn DrawModelEx(model: Model, position: Vector3, rotationAxis: Vector3, rotationAngle: f32, scale: Vector3, tint: Color) void;
pub extern fn DrawModelWires(model: Model, position: Vector3, scale: f32, tint: Color) void;
pub extern fn DrawModelWiresEx(model: Model, position: Vector3, rotationAxis: Vector3, rotationAngle: f32, scale: Vector3, tint: Color) void;
pub extern fn LoadRenderTexture(width: c_int, height: c_int) RenderTexture2D;
pub extern fn UnloadRenderTexture(target: RenderTexture2D) void;
pub extern fn LoadSound(fileName: [*:0]const u8) Sound;
pub extern fn LoadSoundFromWave(wave: Wave) Sound;
pub extern fn LoadSoundAlias(source: Sound) Sound;
pub extern fn IsSoundReady(sound: Sound) bool;
pub extern fn UpdateSound(sound: Sound, data: ?*const anyopaque, sampleCount: c_int) void;
pub extern fn UnloadSound(sound: Sound) void;
pub extern fn UnloadSoundAlias(alias: Sound) void;
pub extern fn PlaySound(sound: Sound) void;
pub extern fn StopSound(sound: Sound) void;
pub extern fn PauseSound(sound: Sound) void;
pub extern fn ResumeSound(sound: Sound) void;
pub extern fn IsSoundPlaying(sound: Sound) bool;
pub extern fn SetSoundVolume(sound: Sound, volume: f32) void;
pub extern fn SetSoundPitch(sound: Sound, pitch: f32) void;
pub extern fn SetSoundPan(sound: Sound, pan: f32) void;
pub extern fn LoadWave(fileName: [*c]const u8) Wave;
pub extern fn LoadWaveFromMemory(fileType: [*c]const u8, fileData: [*c]const u8, dataSize: c_int) Wave;
pub extern fn UnloadWave(wave: Wave) void;
pub extern fn ExportWave(wave: Wave, fileName: [*:0]const u8) bool;
pub extern fn ExportWaveAsCode(wave: Wave, fileName: [*:0]const u8) bool;
pub extern fn IsWaveReady(wave: Wave) bool;
pub extern fn WaveCopy(wave: Wave) Wave;
pub extern fn LoadAudioStream(sampleRate: c_uint, sampleSize: c_uint, channels: c_uint) AudioStream;
pub extern fn IsAudioStreamReady(stream: AudioStream) bool;
pub extern fn UnloadAudioStream(stream: AudioStream) void;
pub extern fn UpdateAudioStream(stream: AudioStream, data: ?*const anyopaque, frameCount: c_int) void;
pub extern fn IsAudioStreamProcessed(stream: AudioStream) bool;
pub extern fn PlayAudioStream(stream: AudioStream) void;
pub extern fn PauseAudioStream(stream: AudioStream) void;
pub extern fn ResumeAudioStream(stream: AudioStream) void;
pub extern fn IsAudioStreamPlaying(stream: AudioStream) bool;
pub extern fn StopAudioStream(stream: AudioStream) void;
pub extern fn SetAudioStreamVolume(stream: AudioStream, volume: f32) void;
pub extern fn SetAudioStreamPitch(stream: AudioStream, pitch: f32) void;
pub extern fn SetAudioStreamPan(stream: AudioStream, pan: f32) void;
pub extern fn SetAudioStreamBufferSizeDefault(size: c_int) void;
pub extern fn SetAudioStreamCallback(stream: AudioStream, callback: AudioCallback) void;
pub extern fn AttachAudioStreamProcessor(stream: AudioStream, processor: AudioCallback) void;
pub extern fn DetachAudioStreamProcessor(stream: AudioStream, processor: AudioCallback) void;
pub extern fn UpdateCamera(camera: *Camera, mode: CameraMode) void;
pub extern fn UpdateCameraPro(camera: *Camera, movement: Vector3, rotation: Vector3, zoom: f32) void;
pub extern fn IsTextureReady(texture: Texture2D) bool;
pub extern fn UnloadTexture(texture: Texture2D) void;
pub extern fn IsRenderTextureReady(target: RenderTexture2D) bool;
pub extern fn UpdateTexture(texture: Texture2D, pixels: ?*const anyopaque) void;
pub extern fn UpdateTextureRec(texture: Texture2D, rec: Rectangle, pixels: ?*const anyopaque) void;
pub extern fn SetTextureWrap(texture: Texture2D, wrap: TextureWrap) void;
pub extern fn InitAudioDevice() void;
pub extern fn CloseAudioDevice() void;
pub extern fn IsAudioDeviceReady() bool;
pub extern fn SetMasterVolume(volume: f32) void;
pub extern fn GetMasterVolume() f32;
pub extern fn AttachAudioMixedProcessor(processor: AudioCallback) void;
pub extern fn DetachAudioMixedProcessor(processor: AudioCallback) void;
pub extern fn LoadMaterialDefault() Material;
pub extern fn DrawText(text: [*:0]const u8, posX: c_int, posY: c_int, fontSize: c_int, color: Color) void;

// non-tweaked

pub extern fn WaveCrop(wave: [*c]Wave, initSample: c_int, finalSample: c_int) void;
pub extern fn WaveFormat(wave: [*c]Wave, sampleRate: c_int, sampleSize: c_int, channels: c_int) void;
pub extern fn LoadWaveSamples(wave: Wave) [*c]f32;
pub extern fn UnloadWaveSamples(samples: [*c]f32) void;
pub extern fn GetFileModTime(fileName: [*c]const u8) c_long;
pub extern fn CompressData(data: [*c]const u8, dataSize: c_int, compDataSize: [*c]c_int) [*c]u8;
pub extern fn DecompressData(compData: [*c]const u8, compDataSize: c_int, dataSize: [*c]c_int) [*c]u8;
pub extern fn EncodeDataBase64(data: [*c]const u8, dataSize: c_int, outputSize: [*c]c_int) [*c]u8;
pub extern fn DecodeDataBase64(data: [*c]const u8, outputSize: [*c]c_int) [*c]u8;
pub extern fn LoadAutomationEventList(fileName: [*c]const u8) AutomationEventList;
pub extern fn UnloadAutomationEventList(list: AutomationEventList) void;
pub extern fn ExportAutomationEventList(list: AutomationEventList, fileName: [*c]const u8) bool;
pub extern fn SetAutomationEventList(list: [*c]AutomationEventList) void;
pub extern fn SetAutomationEventBaseFrame(frame: c_int) void;
pub extern fn StartAutomationEventRecording() void;
pub extern fn StopAutomationEventRecording() void;
pub extern fn PlayAutomationEvent(event: AutomationEvent) void;
pub extern fn SetShapesTexture(texture: Texture2D, source: Rectangle) void;
pub extern fn GetShapesTexture() Texture2D;
pub extern fn GetShapesTextureRectangle() Rectangle;
pub extern fn GetSplinePointLinear(startPos: Vector2, endPos: Vector2, t: f32) Vector2;
pub extern fn GetSplinePointBasis(p1: Vector2, p2: Vector2, p3: Vector2, p4: Vector2, t: f32) Vector2;
pub extern fn GetSplinePointCatmullRom(p1: Vector2, p2: Vector2, p3: Vector2, p4: Vector2, t: f32) Vector2;
pub extern fn GetSplinePointBezierQuad(p1: Vector2, c2: Vector2, p3: Vector2, t: f32) Vector2;
pub extern fn GetSplinePointBezierCubic(p1: Vector2, c2: Vector2, c3: Vector2, p4: Vector2, t: f32) Vector2;
pub extern fn CheckCollisionRecs(rec1: Rectangle, rec2: Rectangle) bool;
pub extern fn CheckCollisionCircles(center1: Vector2, radius1: f32, center2: Vector2, radius2: f32) bool;
pub extern fn CheckCollisionCircleRec(center: Vector2, radius: f32, rec: Rectangle) bool;
pub extern fn CheckCollisionPointRec(point: Vector2, rec: Rectangle) bool;
pub extern fn CheckCollisionPointCircle(point: Vector2, center: Vector2, radius: f32) bool;
pub extern fn CheckCollisionPointTriangle(point: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) bool;
pub extern fn CheckCollisionPointPoly(point: Vector2, points: [*c]Vector2, pointCount: c_int) bool;
pub extern fn CheckCollisionLines(startPos1: Vector2, endPos1: Vector2, startPos2: Vector2, endPos2: Vector2, collisionPoint: [*c]Vector2) bool;
pub extern fn CheckCollisionPointLine(point: Vector2, p1: Vector2, p2: Vector2, threshold: c_int) bool;
pub extern fn GetCollisionRec(rec1: Rectangle, rec2: Rectangle) Rectangle;
pub extern fn GetPixelColor(srcPtr: ?*anyopaque, format: c_int) Color;
pub extern fn SetPixelColor(dstPtr: ?*anyopaque, color: Color, format: c_int) void;
pub extern fn GetPixelDataSize(width: c_int, height: c_int, format: c_int) c_int;
pub extern fn LoadFontData(fileData: [*c]const u8, dataSize: c_int, fontSize: c_int, codepoints: [*c]c_int, codepointCount: c_int, @"type": c_int) [*c]GlyphInfo;
pub extern fn GenImageFontAtlas(glyphs: [*c]const GlyphInfo, glyphRecs: [*c][*c]Rectangle, glyphCount: c_int, fontSize: c_int, padding: c_int, packMethod: c_int) Image;
pub extern fn UnloadFontData(glyphs: [*c]GlyphInfo, glyphCount: c_int) void;
pub extern fn DrawFPS(posX: c_int, posY: c_int) void;
pub extern fn DrawTextEx(font: Font, text: [*c]const u8, position: Vector2, fontSize: f32, spacing: f32, tint: Color) void;
pub extern fn DrawTextPro(font: Font, text: [*c]const u8, position: Vector2, origin: Vector2, rotation: f32, fontSize: f32, spacing: f32, tint: Color) void;
pub extern fn DrawTextCodepoints(font: Font, codepoints: [*c]const c_int, codepointCount: c_int, position: Vector2, fontSize: f32, spacing: f32, tint: Color) void;
pub extern fn SetTextLineSpacing(spacing: c_int) void;
pub extern fn MeasureTextEx(font: Font, text: [*c]const u8, fontSize: f32, spacing: f32) Vector2;
pub extern fn GetGlyphInfo(font: Font, codepoint: c_int) GlyphInfo;
pub extern fn GetGlyphAtlasRec(font: Font, codepoint: c_int) Rectangle;
pub extern fn LoadUTF8(codepoints: [*c]const c_int, length: c_int) [*c]u8;
pub extern fn UnloadUTF8(text: [*c]u8) void;
pub extern fn LoadCodepoints(text: [*c]const u8, count: [*c]c_int) [*c]c_int;
pub extern fn UnloadCodepoints(codepoints: [*c]c_int) void;
pub extern fn GetCodepointCount(text: [*c]const u8) c_int;
pub extern fn GetCodepoint(text: [*c]const u8, codepointSize: [*c]c_int) c_int;
pub extern fn GetCodepointPrevious(text: [*c]const u8, codepointSize: [*c]c_int) c_int;
pub extern fn CodepointToUTF8(codepoint: c_int, utf8Size: [*c]c_int) [*c]const u8;
pub extern fn TextCopy(dst: [*c]u8, src: [*c]const u8) c_int;
pub extern fn TextIsEqual(text1: [*c]const u8, text2: [*c]const u8) bool;
pub extern fn TextLength(text: [*c]const u8) c_uint;
pub extern fn TextFormat(text: [*c]const u8, ...) [*c]const u8;
pub extern fn TextSubtext(text: [*c]const u8, position: c_int, length: c_int) [*c]const u8;
pub extern fn TextReplace(text: [*c]const u8, replace: [*c]const u8, by: [*c]const u8) [*c]u8;
pub extern fn TextInsert(text: [*c]const u8, insert: [*c]const u8, position: c_int) [*c]u8;
pub extern fn TextJoin(textList: [*c][*c]const u8, count: c_int, delimiter: [*c]const u8) [*c]const u8;
pub extern fn TextSplit(text: [*c]const u8, delimiter: u8, count: [*c]c_int) [*c][*c]const u8;
pub extern fn TextAppend(text: [*c]u8, append: [*c]const u8, position: [*c]c_int) void;
pub extern fn TextFindIndex(text: [*c]const u8, find: [*c]const u8) c_int;
pub extern fn TextToUpper(text: [*c]const u8) [*c]const u8;
pub extern fn TextToLower(text: [*c]const u8) [*c]const u8;
pub extern fn TextToPascal(text: [*c]const u8) [*c]const u8;
pub extern fn TextToInteger(text: [*c]const u8) c_int;
pub extern fn TextToFloat(text: [*c]const u8) f32;
pub extern fn DrawLine3D(startPos: Vector3, endPos: Vector3, color: Color) void;
pub extern fn DrawPoint3D(position: Vector3, color: Color) void;
pub extern fn DrawCircle3D(center: Vector3, radius: f32, rotationAxis: Vector3, rotationAngle: f32, color: Color) void;
pub extern fn DrawTriangle3D(v1: Vector3, v2: Vector3, v3: Vector3, color: Color) void;
pub extern fn DrawTriangleStrip3D(points: [*c]Vector3, pointCount: c_int, color: Color) void;
pub extern fn DrawCube(position: Vector3, width: f32, height: f32, length: f32, color: Color) void;
pub extern fn DrawCubeV(position: Vector3, size: Vector3, color: Color) void;
pub extern fn DrawCubeWires(position: Vector3, width: f32, height: f32, length: f32, color: Color) void;
pub extern fn DrawCubeWiresV(position: Vector3, size: Vector3, color: Color) void;
pub extern fn DrawSphere(centerPos: Vector3, radius: f32, color: Color) void;
pub extern fn DrawSphereEx(centerPos: Vector3, radius: f32, rings: c_int, slices: c_int, color: Color) void;
pub extern fn DrawSphereWires(centerPos: Vector3, radius: f32, rings: c_int, slices: c_int, color: Color) void;
pub extern fn DrawCylinder(position: Vector3, radiusTop: f32, radiusBottom: f32, height: f32, slices: c_int, color: Color) void;
pub extern fn DrawCylinderEx(startPos: Vector3, endPos: Vector3, startRadius: f32, endRadius: f32, sides: c_int, color: Color) void;
pub extern fn DrawCylinderWires(position: Vector3, radiusTop: f32, radiusBottom: f32, height: f32, slices: c_int, color: Color) void;
pub extern fn DrawCylinderWiresEx(startPos: Vector3, endPos: Vector3, startRadius: f32, endRadius: f32, sides: c_int, color: Color) void;
pub extern fn DrawCapsule(startPos: Vector3, endPos: Vector3, radius: f32, slices: c_int, rings: c_int, color: Color) void;
pub extern fn DrawCapsuleWires(startPos: Vector3, endPos: Vector3, radius: f32, slices: c_int, rings: c_int, color: Color) void;
pub extern fn DrawPlane(centerPos: Vector3, size: Vector2, color: Color) void;
pub extern fn DrawRay(ray: Ray, color: Color) void;
pub extern fn DrawGrid(slices: c_int, spacing: f32) void;
pub extern fn DrawBoundingBox(box: BoundingBox, color: Color) void;
pub extern fn DrawBillboard(camera: Camera, texture: Texture2D, position: Vector3, size: f32, tint: Color) void;
pub extern fn DrawBillboardRec(camera: Camera, texture: Texture2D, source: Rectangle, position: Vector3, size: Vector2, tint: Color) void;
pub extern fn DrawBillboardPro(camera: Camera, texture: Texture2D, source: Rectangle, position: Vector3, up: Vector3, size: Vector2, origin: Vector2, rotation: f32, tint: Color) void;
pub extern fn LoadMaterials(fileName: [*c]const u8, materialCount: [*c]c_int) [*c]Material;
pub extern fn IsMaterialReady(material: Material) bool;
pub extern fn UnloadMaterial(material: Material) void;
pub extern fn SetMaterialTexture(material: [*c]Material, mapType: c_int, texture: Texture2D) void;
pub extern fn SetModelMeshMaterial(model: [*c]Model, meshId: c_int, materialId: c_int) void;
pub extern fn LoadModelAnimations(fileName: [*c]const u8, animCount: [*c]c_int) [*c]ModelAnimation;
pub extern fn UpdateModelAnimation(model: Model, anim: ModelAnimation, frame: c_int) void;
pub extern fn UnloadModelAnimation(anim: ModelAnimation) void;
pub extern fn UnloadModelAnimations(animations: [*c]ModelAnimation, animCount: c_int) void;
pub extern fn IsModelAnimationValid(model: Model, anim: ModelAnimation) bool;
pub extern fn CheckCollisionSpheres(center1: Vector3, radius1: f32, center2: Vector3, radius2: f32) bool;
pub extern fn CheckCollisionBoxes(box1: BoundingBox, box2: BoundingBox) bool;
pub extern fn CheckCollisionBoxSphere(box: BoundingBox, center: Vector3, radius: f32) bool;
pub extern fn GetRayCollisionSphere(ray: Ray, center: Vector3, radius: f32) RayCollision;
pub extern fn GetRayCollisionBox(ray: Ray, box: BoundingBox) RayCollision;
pub extern fn GetRayCollisionMesh(ray: Ray, mesh: Mesh, transform: Matrix) RayCollision;
pub extern fn GetRayCollisionTriangle(ray: Ray, p1: Vector3, p2: Vector3, p3: Vector3) RayCollision;
pub extern fn GetRayCollisionQuad(ray: Ray, p1: Vector3, p2: Vector3, p3: Vector3, p4: Vector3) RayCollision;

pub const struct_rlVertexBuffer = extern struct {
    elementCount: c_int = @import("std").mem.zeroes(c_int),
    vertices: [*c]f32 = @import("std").mem.zeroes([*c]f32),
    texcoords: [*c]f32 = @import("std").mem.zeroes([*c]f32),
    normals: [*c]f32 = @import("std").mem.zeroes([*c]f32),
    colors: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    indices: [*c]c_uint = @import("std").mem.zeroes([*c]c_uint),
    vaoId: c_uint = @import("std").mem.zeroes(c_uint),
    vboId: [5]c_uint = @import("std").mem.zeroes([5]c_uint),
};
pub const rlVertexBuffer = struct_rlVertexBuffer;
pub const struct_rlDrawCall = extern struct {
    mode: c_int = @import("std").mem.zeroes(c_int),
    vertexCount: c_int = @import("std").mem.zeroes(c_int),
    vertexAlignment: c_int = @import("std").mem.zeroes(c_int),
    textureId: c_uint = @import("std").mem.zeroes(c_uint),
};
pub const rlDrawCall = struct_rlDrawCall;
pub const struct_rlRenderBatch = extern struct {
    bufferCount: c_int = @import("std").mem.zeroes(c_int),
    currentBuffer: c_int = @import("std").mem.zeroes(c_int),
    vertexBuffer: [*c]rlVertexBuffer = @import("std").mem.zeroes([*c]rlVertexBuffer),
    draws: [*c]rlDrawCall = @import("std").mem.zeroes([*c]rlDrawCall),
    drawCounter: c_int = @import("std").mem.zeroes(c_int),
    currentDepth: f32 = @import("std").mem.zeroes(f32),
};
pub const rlRenderBatch = struct_rlRenderBatch;

pub const VertexAttributeIntType = enum(c_int) {
    byte = 0x1400,
    unsigned_byte = 0x1401,
    short = 0x1402,
    unsigned_short = 0x1403,
    int = 0x1404,
    unsigned_int = 0x1405,
};

pub const VertexAttributeType = enum(c_int) {
    byte = 0x1400,
    unsigned_byte = 0x1401,
    short = 0x1402,
    unsigned_short = 0x1403,
    int = 0x1404,
    unsigned_int = 0x1405,
    half_float = 0x140B,
    float = 0x1406,
    double = 0x140A,
    fixed = 0x140C,
    int_2_10_10_10_rev = 0x8D9F,
    unsigned_int_2_10_10_10_rev = 0x8368,
    unsigned_int_10f_11f_11f_rev = 0x8C3B,
};

pub const VertexAttributeLongType = enum(c_int) {
    double = 0x140A,
};

pub extern fn rlMatrixMode(mode: c_int) void;
pub extern fn rlPushMatrix() void;
pub extern fn rlPopMatrix() void;
pub extern fn rlLoadIdentity() void;
pub extern fn rlTranslatef(x: f32, y: f32, z: f32) void;
pub extern fn rlRotatef(angle: f32, x: f32, y: f32, z: f32) void;
pub extern fn rlScalef(x: f32, y: f32, z: f32) void;
pub extern fn rlMultMatrixf(matf: [*c]const f32) void;
pub extern fn rlFrustum(left: f64, right: f64, bottom: f64, top: f64, znear: f64, zfar: f64) void;
pub extern fn rlOrtho(left: f64, right: f64, bottom: f64, top: f64, znear: f64, zfar: f64) void;
pub extern fn rlViewport(x: c_int, y: c_int, width: c_int, height: c_int) void;
pub extern fn rlSetClipPlanes(nearPlane: f64, farPlane: f64) void;
pub extern fn rlGetCullDistanceNear() f64;
pub extern fn rlGetCullDistanceFar() f64;
pub extern fn rlBegin(mode: c_int) void;
pub extern fn rlEnd() void;
pub extern fn rlVertex2i(x: c_int, y: c_int) void;
pub extern fn rlVertex2f(x: f32, y: f32) void;
pub extern fn rlVertex3f(x: f32, y: f32, z: f32) void;
pub extern fn rlTexCoord2f(x: f32, y: f32) void;
pub extern fn rlNormal3f(x: f32, y: f32, z: f32) void;
pub extern fn rlColor4ub(r: u8, g: u8, b: u8, a: u8) void;
pub extern fn rlColor3f(x: f32, y: f32, z: f32) void;
pub extern fn rlColor4f(x: f32, y: f32, z: f32, w: f32) void;
pub extern fn rlEnableVertexArray(vaoId: c_uint) bool;
pub extern fn rlDisableVertexArray() void;
pub extern fn rlEnableVertexBuffer(id: c_uint) void;
pub extern fn rlDisableVertexBuffer() void;
pub extern fn rlEnableVertexBufferElement(id: c_uint) void;
pub extern fn rlDisableVertexBufferElement() void;
pub extern fn rlEnableVertexAttribute(index: c_uint) void;
pub extern fn rlDisableVertexAttribute(index: c_uint) void;
pub extern fn rlActiveTextureSlot(slot: c_int) void;
pub extern fn rlEnableTexture(id: c_uint) void;
pub extern fn rlDisableTexture() void;
pub extern fn rlEnableTextureCubemap(id: c_uint) void;
pub extern fn rlDisableTextureCubemap() void;
pub extern fn rlTextureParameters(id: c_uint, param: c_int, value: c_int) void;
pub extern fn rlCubemapParameters(id: c_uint, param: c_int, value: c_int) void;
pub extern fn rlEnableShader(id: c_uint) void;
pub extern fn rlDisableShader() void;
pub extern fn rlEnableFramebuffer(id: c_uint) void;
pub extern fn rlDisableFramebuffer() void;
pub extern fn rlGetActiveFramebuffer() c_uint;
pub extern fn rlActiveDrawBuffers(count: c_int) void;
pub extern fn rlBlitFramebuffer(srcX: c_int, srcY: c_int, srcWidth: c_int, srcHeight: c_int, dstX: c_int, dstY: c_int, dstWidth: c_int, dstHeight: c_int, bufferMask: c_int) void;
pub extern fn rlBindFramebuffer(target: c_uint, framebuffer: c_uint) void;
pub extern fn rlEnableColorBlend() void;
pub extern fn rlDisableColorBlend() void;
pub extern fn rlEnableDepthTest() void;
pub extern fn rlDisableDepthTest() void;
pub extern fn rlEnableDepthMask() void;
pub extern fn rlDisableDepthMask() void;
pub extern fn rlEnableBackfaceCulling() void;
pub extern fn rlDisableBackfaceCulling() void;
pub extern fn rlColorMask(r: bool, g: bool, b: bool, a: bool) void;
pub extern fn rlSetCullFace(mode: c_int) void;
pub extern fn rlEnableScissorTest() void;
pub extern fn rlDisableScissorTest() void;
pub extern fn rlScissor(x: c_int, y: c_int, width: c_int, height: c_int) void;
pub extern fn rlEnableWireMode() void;
pub extern fn rlEnablePointMode() void;
pub extern fn rlDisableWireMode() void;
pub extern fn rlSetLineWidth(width: f32) void;
pub extern fn rlGetLineWidth() f32;
pub extern fn rlEnableSmoothLines() void;
pub extern fn rlDisableSmoothLines() void;
pub extern fn rlEnableStereoRender() void;
pub extern fn rlDisableStereoRender() void;
pub extern fn rlIsStereoRenderEnabled() bool;
pub extern fn rlClearColor(r: u8, g: u8, b: u8, a: u8) void;
pub extern fn rlClearScreenBuffers() void;
pub extern fn rlCheckErrors() void;
pub extern fn rlSetBlendMode(mode: c_int) void;
pub extern fn rlSetBlendFactors(glSrcFactor: c_int, glDstFactor: c_int, glEquation: c_int) void;
pub extern fn rlSetBlendFactorsSeparate(glSrcRGB: c_int, glDstRGB: c_int, glSrcAlpha: c_int, glDstAlpha: c_int, glEqRGB: c_int, glEqAlpha: c_int) void;
pub extern fn rlglInit(width: c_int, height: c_int) void;
pub extern fn rlglClose() void;
pub extern fn rlLoadExtensions(loader: ?*anyopaque) void;
pub extern fn rlGetVersion() c_int;
pub extern fn rlSetFramebufferWidth(width: c_int) void;
pub extern fn rlGetFramebufferWidth() c_int;
pub extern fn rlSetFramebufferHeight(height: c_int) void;
pub extern fn rlGetFramebufferHeight() c_int;
pub extern fn rlGetTextureIdDefault() c_uint;
pub extern fn rlGetShaderIdDefault() c_uint;
pub extern fn rlGetShaderLocsDefault() [*c]c_int;
pub extern fn rlLoadRenderBatch(numBuffers: c_int, bufferElements: c_int) rlRenderBatch;
pub extern fn rlUnloadRenderBatch(batch: rlRenderBatch) void;
pub extern fn rlDrawRenderBatch(batch: [*c]rlRenderBatch) void;
pub extern fn rlSetRenderBatchActive(batch: [*c]rlRenderBatch) void;
pub extern fn rlDrawRenderBatchActive() void;
pub extern fn rlCheckRenderBatchLimit(vCount: c_int) bool;
pub extern fn rlSetTexture(id: c_uint) void;
pub extern fn rlLoadVertexArray() c_uint;
pub extern fn rlLoadVertexBuffer(buffer: ?*const anyopaque, size: c_int, dynamic: bool) c_uint;
pub extern fn rlLoadVertexBufferElement(buffer: ?*const anyopaque, size: c_int, dynamic: bool) c_uint;
pub extern fn rlUpdateVertexBuffer(bufferId: c_uint, data: ?*const anyopaque, dataSize: c_int, offset: c_int) void;
pub extern fn rlUpdateVertexBufferElements(id: c_uint, data: ?*const anyopaque, dataSize: c_int, offset: c_int) void;
pub extern fn rlUnloadVertexArray(vaoId: c_uint) void;
pub extern fn rlUnloadVertexBuffer(vboId: c_uint) void;
pub extern fn rlSetVertexAttribute(index: c_uint, compSize: c_int, @"type": VertexAttributeType, normalized: bool, stride: c_int, pointer: ?*const anyopaque) void;
pub extern fn glVertexAttribPointer(index: c_uint, compSize: c_int, @"type": VertexAttributeType, normalized: bool, stride: c_int, pointer: ?*const anyopaque) void;
pub extern fn glVertexAttribIPointer(index: c_uint, compSize: c_int, @"type": VertexAttributeIntType, stride: c_int, pointer: ?*const anyopaque) void;
pub extern fn glVertexAttribLPointer(index: c_uint, compSize: c_int, @"type": VertexAttributeLongType, stride: c_int, pointer: ?*const anyopaque) void;
pub extern fn rlSetVertexAttributeDivisor(index: c_uint, divisor: c_int) void;
pub extern fn rlSetVertexAttributeDefault(locIndex: c_int, value: ?*const anyopaque, attribType: ShaderAttributeDataType, count: c_int) void;
pub extern fn rlDrawVertexArray(offset: c_int, count: c_int) void;
pub extern fn rlDrawVertexArrayElements(offset: c_int, count: c_int, buffer: ?*const anyopaque) void;
pub extern fn rlDrawVertexArrayInstanced(offset: c_int, count: c_int, instances: c_int) void;
pub extern fn rlDrawVertexArrayElementsInstanced(offset: c_int, count: c_int, buffer: ?*const anyopaque, instances: c_int) void;
pub extern fn rlLoadTexture(data: ?*const anyopaque, width: c_int, height: c_int, format: c_int, mipmapCount: c_int) c_uint;
pub extern fn rlLoadTextureDepth(width: c_int, height: c_int, useRenderBuffer: bool) c_uint;
pub extern fn rlLoadTextureCubemap(data: ?*const anyopaque, size: c_int, format: c_int) c_uint;
pub extern fn rlUpdateTexture(id: c_uint, offsetX: c_int, offsetY: c_int, width: c_int, height: c_int, format: c_int, data: ?*const anyopaque) void;
pub extern fn rlGetGlTextureFormats(format: c_int, glInternalFormat: [*c]c_uint, glFormat: [*c]c_uint, glType: [*c]c_uint) void;
pub extern fn rlGetPixelFormatName(format: c_uint) [*c]const u8;
pub extern fn rlUnloadTexture(id: c_uint) void;
pub extern fn rlGenTextureMipmaps(id: c_uint, width: c_int, height: c_int, format: c_int, mipmaps: [*c]c_int) void;
pub extern fn rlReadTexturePixels(id: c_uint, width: c_int, height: c_int, format: c_int) ?*anyopaque;
pub extern fn rlReadScreenPixels(width: c_int, height: c_int) [*c]u8;
pub extern fn rlLoadFramebuffer() c_uint;
pub extern fn rlFramebufferAttach(fboId: c_uint, texId: c_uint, attachType: c_int, texType: c_int, mipLevel: c_int) void;
pub extern fn rlFramebufferComplete(id: c_uint) bool;
pub extern fn rlUnloadFramebuffer(id: c_uint) void;
pub extern fn rlLoadShaderCode(vsCode: [*c]const u8, fsCode: [*c]const u8) c_uint;
pub extern fn rlCompileShader(shaderCode: [*c]const u8, @"type": c_int) c_uint;
pub extern fn rlLoadShaderProgram(vShaderId: c_uint, fShaderId: c_uint) c_uint;
pub extern fn rlUnloadShaderProgram(id: c_uint) void;
pub extern fn rlGetLocationUniform(shaderId: c_uint, uniformName: [*c]const u8) c_int;
pub extern fn rlGetLocationAttrib(shaderId: c_uint, attribName: [*c]const u8) c_int;
pub extern fn rlSetUniform(locIndex: c_int, value: ?*const anyopaque, uniformType: ShaderUniformDataType, count: c_int) void;
pub extern fn rlSetUniformMatrix(locIndex: c_int, mat: Matrix) void;
pub extern fn rlSetUniformSampler(locIndex: c_int, textureId: c_uint) void;
pub extern fn rlSetShader(id: c_uint, locs: [*c]c_int) void;
pub extern fn rlLoadComputeShaderProgram(shaderId: c_uint) c_uint;
pub extern fn rlComputeShaderDispatch(groupX: c_uint, groupY: c_uint, groupZ: c_uint) void;
pub extern fn rlLoadShaderBuffer(size: c_uint, data: ?*const anyopaque, usageHint: c_int) c_uint;
pub extern fn rlUnloadShaderBuffer(ssboId: c_uint) void;
pub extern fn rlUpdateShaderBuffer(id: c_uint, data: ?*const anyopaque, dataSize: c_uint, offset: c_uint) void;
pub extern fn rlBindShaderBuffer(id: c_uint, index: c_uint) void;
pub extern fn rlReadShaderBuffer(id: c_uint, dest: ?*anyopaque, count: c_uint, offset: c_uint) void;
pub extern fn rlCopyShaderBuffer(destId: c_uint, srcId: c_uint, destOffset: c_uint, srcOffset: c_uint, count: c_uint) void;
pub extern fn rlGetShaderBufferSize(id: c_uint) c_uint;
pub extern fn rlBindImageTexture(id: c_uint, index: c_uint, format: c_int, readonly: bool) void;
pub extern fn rlGetMatrixModelview() Matrix;
pub extern fn rlGetMatrixProjection() Matrix;
pub extern fn rlGetMatrixTransform() Matrix;
pub extern fn rlGetMatrixProjectionStereo(eye: c_int) Matrix;
pub extern fn rlGetMatrixViewOffsetStereo(eye: c_int) Matrix;
pub extern fn rlSetMatrixProjection(proj: Matrix) void;
pub extern fn rlSetMatrixModelview(view: Matrix) void;
pub extern fn rlSetMatrixProjectionStereo(right: Matrix, left: Matrix) void;
pub extern fn rlSetMatrixViewOffsetStereo(right: Matrix, left: Matrix) void;
pub extern fn rlLoadDrawCube() void;
pub extern fn rlLoadDrawQuad() void;

pub const rl_default_batch_buffer_elements = c.RL_DEFAULT_BATCH_BUFFER_ELEMENTS;
pub const rl_default_batch_buffers = c.RL_DEFAULT_BATCH_BUFFERS;
pub const rl_default_batch_drawcalls = c.RL_DEFAULT_BATCH_DRAWCALLS;
pub const rl_default_batch_max_texture_units = c.RL_DEFAULT_BATCH_MAX_TEXTURE_UNITS;
pub const rl_max_matrix_stack_size = c.RL_MAX_MATRIX_STACK_SIZE;
pub const rl_max_shader_locations = c.RL_MAX_SHADER_LOCATIONS;
pub const rl_cull_distance_near = c.RL_CULL_DISTANCE_NEAR;
pub const rl_cull_distance_far = c.RL_CULL_DISTANCE_FAR;
pub const rl_texture_wrap_s = c.RL_TEXTURE_WRAP_S;
pub const rl_texture_wrap_t = c.RL_TEXTURE_WRAP_T;
pub const rl_texture_mag_filter = c.RL_TEXTURE_MAG_FILTER;
pub const rl_texture_min_filter = c.RL_TEXTURE_MIN_FILTER;
pub const rl_texture_filter_nearest = c.RL_TEXTURE_FILTER_NEAREST;
pub const rl_texture_filter_linear = c.RL_TEXTURE_FILTER_LINEAR;
pub const rl_texture_filter_mip_nearest = c.RL_TEXTURE_FILTER_MIP_NEAREST;
pub const rl_texture_filter_nearest_mip_linear = c.RL_TEXTURE_FILTER_NEAREST_MIP_LINEAR;
pub const rl_texture_filter_linear_mip_nearest = c.RL_TEXTURE_FILTER_LINEAR_MIP_NEAREST;
pub const rl_texture_filter_mip_linear = c.RL_TEXTURE_FILTER_MIP_LINEAR;
pub const rl_texture_filter_anisotropic = c.RL_TEXTURE_FILTER_ANISOTROPIC;
pub const rl_texture_mipmap_bias_ratio = c.RL_TEXTURE_MIPMAP_BIAS_RATIO;
pub const rl_texture_wrap_repeat = c.RL_TEXTURE_WRAP_REPEAT;
pub const rl_texture_wrap_clamp = c.RL_TEXTURE_WRAP_CLAMP;
pub const rl_texture_wrap_mirror_repeat = c.RL_TEXTURE_WRAP_MIRROR_REPEAT;
pub const rl_texture_wrap_mirror_clamp = c.RL_TEXTURE_WRAP_MIRROR_CLAMP;
pub const rl_modelview = c.RL_MODELVIEW;
pub const rl_projection = c.RL_PROJECTION;
pub const rl_texture = c.RL_TEXTURE;
pub const rl_lines = c.RL_LINES;
pub const rl_triangles = c.RL_TRIANGLES;
pub const rl_quads = c.RL_QUADS;
pub const rl_unsigned_byte = c.RL_UNSIGNED_BYTE;
pub const rl_float = c.RL_FLOAT;
pub const rl_stream_draw = c.RL_STREAM_DRAW;
pub const rl_stream_read = c.RL_STREAM_READ;
pub const rl_stream_copy = c.RL_STREAM_COPY;
pub const rl_static_draw = c.RL_STATIC_DRAW;
pub const rl_static_read = c.RL_STATIC_READ;
pub const rl_static_copy = c.RL_STATIC_COPY;
pub const rl_dynamic_draw = c.RL_DYNAMIC_DRAW;
pub const rl_dynamic_read = c.RL_DYNAMIC_READ;
pub const rl_dynamic_copy = c.RL_DYNAMIC_COPY;
pub const rl_fragment_shader = c.RL_FRAGMENT_SHADER;
pub const rl_vertex_shader = c.RL_VERTEX_SHADER;
pub const rl_compute_shader = c.RL_COMPUTE_SHADER;
pub const rl_zero = c.RL_ZERO;
pub const rl_one = c.RL_ONE;
pub const rl_src_color = c.RL_SRC_COLOR;
pub const rl_one_minus_src_color = c.RL_ONE_MINUS_SRC_COLOR;
pub const rl_src_alpha = c.RL_SRC_ALPHA;
pub const rl_one_minus_src_alpha = c.RL_ONE_MINUS_SRC_ALPHA;
pub const rl_dst_alpha = c.RL_DST_ALPHA;
pub const rl_one_minus_dst_alpha = c.RL_ONE_MINUS_DST_ALPHA;
pub const rl_dst_color = c.RL_DST_COLOR;
pub const rl_one_minus_dst_color = c.RL_ONE_MINUS_DST_COLOR;
pub const rl_src_alpha_saturate = c.RL_SRC_ALPHA_SATURATE;
pub const rl_constant_color = c.RL_CONSTANT_COLOR;
pub const rl_one_minus_constant_color = c.RL_ONE_MINUS_CONSTANT_COLOR;
pub const rl_constant_alpha = c.RL_CONSTANT_ALPHA;
pub const rl_one_minus_constant_alpha = c.RL_ONE_MINUS_CONSTANT_ALPHA;
pub const rl_func_add = c.RL_FUNC_ADD;
pub const rl_min = c.RL_MIN;
pub const rl_max = c.RL_MAX;
pub const rl_func_subtract = c.RL_FUNC_SUBTRACT;
pub const rl_func_reverse_subtract = c.RL_FUNC_REVERSE_SUBTRACT;
pub const rl_blend_equation = c.RL_BLEND_EQUATION;
pub const rl_blend_equation_rgb = c.RL_BLEND_EQUATION_RGB;
pub const rl_blend_equation_alpha = c.RL_BLEND_EQUATION_ALPHA;
pub const rl_blend_dst_rgb = c.RL_BLEND_DST_RGB;
pub const rl_blend_src_rgb = c.RL_BLEND_SRC_RGB;
pub const rl_blend_dst_alpha = c.RL_BLEND_DST_ALPHA;
pub const rl_blend_src_alpha = c.RL_BLEND_SRC_ALPHA;
pub const rl_blend_color = c.RL_BLEND_COLOR;
pub const rl_read_framebuffer = c.RL_READ_FRAMEBUFFER;
pub const rl_draw_framebuffer = c.RL_DRAW_FRAMEBUFFER;
pub const rl_default_shader_attrib_location_position = c.RL_DEFAULT_SHADER_ATTRIB_LOCATION_POSITION;
pub const rl_default_shader_attrib_location_texcoord = c.RL_DEFAULT_SHADER_ATTRIB_LOCATION_TEXCOORD;
pub const rl_default_shader_attrib_location_normal = c.RL_DEFAULT_SHADER_ATTRIB_LOCATION_NORMAL;
pub const rl_default_shader_attrib_location_color = c.RL_DEFAULT_SHADER_ATTRIB_LOCATION_COLOR;
pub const rl_default_shader_attrib_location_tangent = c.RL_DEFAULT_SHADER_ATTRIB_LOCATION_TANGENT;
pub const rl_default_shader_attrib_location_texcoord2 = c.RL_DEFAULT_SHADER_ATTRIB_LOCATION_TEXCOORD2;
pub const rl_default_shader_attrib_location_indices = c.RL_DEFAULT_SHADER_ATTRIB_LOCATION_INDICES;
