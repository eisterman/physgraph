const rl = @import("raylib");

pub const CameraSettings = struct {
    pos_speed: f32,
    start: rl.Vector2,
    end: rl.Vector2,
    zoom_ln_speed: f32,
    zoom_ln_min: f32,
    zoom_ln_max: f32,
};

pub fn my_camera_update(camera: *rl.Camera2D, s: *const CameraSettings) void {
    const frame_dt = rl.getFrameTime();
    // Scale all speed on the effective frame DT to have uniform movement at all framerate
    const speed = s.pos_speed / camera.zoom * frame_dt;
    const translation: rl.Vector2 = .{
        .x = @as(f32, @floatFromInt(@intFromBool(rl.isKeyDown(.d) or rl.isKeyDown(.right)))) * speed -
            @as(f32, @floatFromInt(@intFromBool(rl.isKeyDown(.a) or rl.isKeyDown(.left)))) * speed,
        .y = @as(f32, @floatFromInt(@intFromBool(rl.isKeyDown(.s) or rl.isKeyDown(.down)))) * speed -
            @as(f32, @floatFromInt(@intFromBool(rl.isKeyDown(.w) or rl.isKeyDown(.up)))) * speed,
    };
    camera.target = camera.target.add(translation);
    // Box
    if (camera.target.x < s.start.x) {
        camera.target.x = s.start.x;
    } else if (camera.target.x > s.end.x) {
        camera.target.x = s.end.x;
    }
    if (camera.target.y < s.start.y) {
        camera.target.y = s.start.y;
    } else if (camera.target.y > s.end.y) {
        camera.target.y = s.end.y;
    }

    const mouse_wheel = rl.getMouseWheelMove();
    // Uses log scaling to provide consistent zoom speed
    var camera_ln = @log(camera.zoom) + mouse_wheel * s.zoom_ln_speed * frame_dt;
    if (camera_ln > s.zoom_ln_max) {
        camera_ln = s.zoom_ln_max;
    } else if (camera_ln < s.zoom_ln_min) {
        camera_ln = s.zoom_ln_min;
    }
    camera.zoom = @exp(camera_ln);
}
