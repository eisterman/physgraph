const rl = @import("raylib");

pub const Node = struct {
    pos: rl.Vector2,
    vel: rl.Vector2,
};

pub const Edge = struct {
    n1: usize,
    n2: usize,
};
