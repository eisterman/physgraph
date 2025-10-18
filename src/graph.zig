const std = @import("std");
const rl = @import("raylib");

pub const Node = struct {
    pos: rl.Vector2,
    vel: rl.Vector2,
    // Metadata
    pinned: bool = false,
};

pub const Edge = struct {
    n1: usize, // starting
    n2: usize, // pointing to
};

pub const NodeEdges = struct {
    allocator: std.mem.Allocator,
    starting_from: std.ArrayList(usize),
    pointing_to: std.ArrayList(usize),

    fn deinit(self: @This()) void {
        self.starting_from.deinit(self.allocator);
        self.pointing_to.deinit(self.allocator);
    }
};

pub const Graph = struct {
    allocator: std.mem.Allocator,
    nodes: std.ArrayList(?Node),
    edges: std.ArrayList(?Edge),
    empty_nodes: std.ArrayList(usize), // stack with top at high index
    empty_edges: std.ArrayList(usize), // stack with top at high index

    const Self = @This();

    fn initCapacity(allocator: std.mem.Allocator, n_nodes: usize, n_edges: usize) !Self {
        const nodes = try std.ArrayList(?Node).initCapacity(allocator, n_nodes);
        const edges = try std.ArrayList(?Edge).initCapacity(allocator, n_edges);
        const empty_nodes = try std.ArrayList(usize).empty;
        const empty_edges = try std.ArrayList(usize).empty;
        return Self{
            .allocator = allocator,
            .nodes = nodes,
            .edges = edges,
            .empty_nodes = empty_nodes,
            .empty_edges = empty_edges,
        };
    }

    fn addNode(self: Self, node: Node) !usize {
        // Check if there are free empty nodes in the already allocated
        const free_node = self.empty_nodes.pop();
        if (free_node) |free_node_val| {
            self.nodes[free_node_val] = node;
            return free_node_val;
        } else {
            (try self.nodes.addOne(self.allocator)).* = node;
            return self.nodes.items.len - 1;
        }
    }

    fn addEdge(self: Self, edge: Edge) !usize {
        const free_edge = self.empty_edges.pop();
        if (free_edge) |free_edge_val| {
            self.edges[free_edge_val] = edge;
            return free_edge_val;
        } else {
            (try self.edges.addOne(self.allocator)).* = edge;
            return self.edges.items.len - 1;
        }
    }

    fn findNodeEdges(self: Self, node_id: usize) NodeEdges {
        const starting_from = std.ArrayList(usize).empty;
        const pointing_to = std.ArrayList(usize).empty;
        for (self.edges.items, 0..) |edge, edge_id| {
            if (edge) |edge_val| {
                if (edge_val.n1 == node_id) {
                    starting_from.append(self.allocator, edge_id);
                } else if (edge_val.n2 == node_id) {
                    pointing_to.append(self.allocator, edge_id);
                }
            } else continue;
        }
    }
};
