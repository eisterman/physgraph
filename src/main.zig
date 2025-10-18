const std = @import("std");
const rl = @import("raylib");
const graph = @import("graph.zig");
const mycamera = @import("camera.zig");

pub fn main() !void {
    //
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 1280;
    const screenHeight = 720;

    rl.initWindow(screenWidth, screenHeight, "Graph Viz");
    defer rl.closeWindow(); // Close window and OpenGL context

    var camera = rl.Camera2D{
        .offset = .{ .x = screenWidth / 2, .y = screenHeight / 2 },
        .target = .{ .x = 0.0, .y = 0.0 },
        .rotation = 0.0,
        .zoom = @exp(3.0),
    };

    const camset = mycamera.CameraSettings{
        .pos_speed = 400.0,
        .start = .{ .x = -20.0, .y = -20.0 },
        .end = .{ .x = 20.0, .y = 20.0 },
        .zoom_ln_speed = 6.0,
        .zoom_ln_min = -1.0,
        .zoom_ln_max = 5.0,
    };

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------
    var nodes = [_]?graph.Node{null} ** 1024;
    var edges = [_]?graph.Edge{null} ** 1024;

    var rng = std.Random.DefaultPrng.init(@intCast(std.time.timestamp())); // 152

    for (0..20) |i| {
        const x = rng.random().float(f32) * 20.0 - 10;
        const y = rng.random().float(f32) * 20.0 - 10;
        nodes[i] = graph.Node{ .pos = rl.Vector2{ .x = x, .y = y }, .vel = rl.Vector2{ .x = 0, .y = 0 } };
    }
    // for (0..20) |i| {
    //     for ((i + 1)..20) |j| {
    //         edges[20 * i + j] = graph.Edge{ .n1 = i, .n2 = j };
    //     }
    // }
    for (0..60) |i| {
        const n1 = rng.random().uintAtMost(usize, 19);
        const n2 = rng.random().uintAtMost(usize, 19);
        if (n1 == n2) continue;
        edges[i] = graph.Edge{ .n1 = n1, .n2 = n2 };
    }
    const k: f32 = 10.0;
    const r0: f32 = 10.0;
    const zeta: f32 = 0.04; // damping
    const eps: f32 = 0.001;
    const m: f32 = 1.0;
    _ = eps;

    const k_2: f32 = 5.0;
    const r0_2: f32 = 20.0;

    const nodeRad: f32 = 0.4;

    var movingNode: ?usize = null;
    var alreadyDown: bool = false;

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        // Move nodes
        const mouse = rl.getScreenToWorld2D(rl.getMousePosition(), camera);
        if (!alreadyDown and rl.isMouseButtonDown(.left)) {
            for (&nodes, 0..) |*node, i| {
                const n = &(node.* orelse continue);
                if (rl.checkCollisionPointCircle(mouse, n.pos, nodeRad)) {
                    if (n.pinned == true) break;
                    n.pinned = true;
                    n.vel = .{ .x = 0, .y = 0 };
                    movingNode = i;
                    break;
                }
            }
            alreadyDown = true;
        } else if (alreadyDown and movingNode != null) {
            nodes[movingNode.?].?.pos = mouse;
        }
        if (rl.isMouseButtonUp(.left)) {
            if (movingNode) |n| nodes[n].?.pinned = false;
            movingNode = null;
            alreadyDown = false;
        }
        // Simulation
        const dt = rl.getFrameTime();
        var forces = [_]rl.Vector2{.{ .x = 0, .y = 0 }} ** 20;
        // Node elastic force
        for (0..20) |i| {
            for (i + 1..20) |j| {
                const n1 = (nodes[i] orelse continue);
                const n2 = (nodes[j] orelse continue);
                const r = n1.pos.subtract(n2.pos);
                const dr = r.length() - r0_2;
                const f_1 = r.normalize().scale(-k_2 * dr);
                if (!n1.pinned) forces[i] = forces[i].add(f_1);
                if (!n2.pinned) forces[j] = forces[j].add(f_1.negate());
            }
        }
        // Edge elastic force
        for (edges) |edge| {
            const e = edge orelse continue;
            const n1 = &(nodes[e.n1] orelse continue);
            const n2 = &(nodes[e.n2] orelse continue);
            // Elastic Force (Hooke's Law)
            const r = n1.*.pos.subtract(n2.*.pos);
            const dr = r.length() - r0;
            const f_1 = r.normalize().scale(-k * dr); // F = -k(r1-r2)
            if (!n1.pinned) forces[e.n1] = forces[e.n1].add(f_1);
            if (!n2.pinned) forces[e.n2] = forces[e.n2].add(f_1.negate());
        }
        // Apply Force, Damping, dv = xdt
        for (0..20) |i| {
            const n = &(nodes[i] orelse continue);
            n.vel = n.vel.add(forces[i].scale(dt / m)).scale(1 - zeta);
            forces[i] = .{ .x = 0, .y = 0 };
            n.pos = n.pos.add(n.vel.scale(dt));
        }
        //----------------------------------------------------------------------------------
        mycamera.my_camera_update(&camera, &camset);
        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);

        {
            camera.begin();
            defer camera.end();

            for (edges) |edge| {
                const e = edge orelse continue;
                const n1 = nodes[e.n1] orelse continue;
                const n2 = nodes[e.n2] orelse continue;

                rl.drawLineEx(n1.pos, n2.pos, 0.1, .black);
                // Draw arrow
                const arrowLength: f32 = 0.7;
                const arrowBase: f32 = arrowLength / 3;
                const norm_director = n1.pos.subtract(n2.pos).normalize();
                const v1 = n2.pos.add(norm_director.scale(nodeRad));
                const vcenter = v1.add(norm_director.scale(arrowLength));
                const v2 = vcenter.add(norm_director.rotate(std.math.pi / 2.0).scale(arrowBase));
                const v3 = vcenter.add(norm_director.rotate(-std.math.pi / 2.0).scale(arrowBase));
                rl.drawTriangle(v1, v2, v3, .black);
            }

            for (nodes) |node| {
                const n = node orelse continue;
                rl.drawCircleV(n.pos, nodeRad, if (n.pinned) .blue else .red);
            }
        }

        // rl.drawText("Congrats! You created your first window!", 190, 200, 20, .light_gray);
        //----------------------------------------------------------------------------------
    }
}

test "simple test" {
    const gpa = std.testing.allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa); // Try commenting this out and see if zig detects the memory leak!
    try list.append(gpa, 42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "fuzz example" {
    const Context = struct {
        fn testOne(context: @This(), input: []const u8) anyerror!void {
            _ = context;
            // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.fuzz(Context{}, Context.testOne, .{});
}
