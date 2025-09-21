# Physgraph
Graph visualizer using Zig and Raylib.

I model the edges as springs so that the graph auto-arrange itself in a good position.

### How to build
First, you need Zig 0.15.1 installed on your pc.
If you have build problems you need raylib installed from your OS repositories.

After that you need to build the first time allowing internet fetching of dependencies:
```
zig build --fetch
```

After that you can build with `zig build` without needing `--fetch`.

To build and run, you can do `zig build run`.

