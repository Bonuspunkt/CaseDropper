const std = @import("std");

pub const PathMap = struct {
    allocator: std.mem.Allocator,
    root: []const u8,
    map: std.StringHashMapUnmanaged([]const u8),
    lock: std.Thread.RwLock,
    string_arena: std.heap.ArenaAllocator,

    pub fn init(allocator: std.mem.Allocator, root: []const u8) !PathMap {
        var pm = PathMap{
            .allocator = allocator,
            .root = root,
            .map = .{},
            .lock = .{},
            .string_arena = std.heap.ArenaAllocator.init(allocator),
        };
        try pm.buildMap();
        return pm;
    }

    pub fn deinit(self: *PathMap) void {
        self.string_arena.deinit();
        self.map.deinit(self.allocator);
    }

    /// Look up a request path (case-insensitive).
    /// Returns the actual filesystem-relative path, or null.
    pub fn resolve(self: *PathMap, request_path: []const u8) ?[]const u8 {
        self.lock.lockShared();
        defer self.lock.unlockShared();

        var buf: [4096]u8 = undefined;
        const normalized = normalizePath(request_path, &buf) orelse return null;
        return self.map.get(normalized);
    }

    /// Rebuild the path map (called from watcher thread after debounce).
    pub fn rebuild(self: *PathMap) void {
        var new_arena = std.heap.ArenaAllocator.init(self.allocator);
        var new_map: std.StringHashMapUnmanaged([]const u8) = .{};

        buildMapInto(self.root, &new_map, &new_arena) catch |err| {
            std.log.err("Failed to rebuild path map: {}", .{err});
            new_arena.deinit();
            return;
        };

        self.lock.lock();
        const old_arena = self.string_arena;
        const old_map = self.map;
        self.map = new_map;
        self.string_arena = new_arena;
        self.lock.unlock();

        // Free old data outside the lock
        var mutable_old_map = old_map;
        mutable_old_map.deinit(self.allocator);
        var mutable_old_arena = old_arena;
        mutable_old_arena.deinit();

        std.log.info("Path map rebuilt ({d} entries)", .{self.map.count()});
    }

    fn buildMap(self: *PathMap) !void {
        try buildMapInto(self.root, &self.map, &self.string_arena);
    }

    fn buildMapInto(
        root: []const u8,
        map: *std.StringHashMapUnmanaged([]const u8),
        arena: *std.heap.ArenaAllocator,
    ) !void {
        const alloc = arena.allocator();
        var dir = try std.fs.cwd().openDir(root, .{ .iterate = true });
        defer dir.close();

        var walker = try dir.walk(alloc);
        defer walker.deinit();

        while (try walker.next()) |entry| {
            const path_copy = try alloc.dupe(u8, entry.path);

            // Build lowercase key
            const lower_copy = try alloc.alloc(u8, entry.path.len);
            _ = std.ascii.lowerString(lower_copy, entry.path);

            // Normalize path separators in the key
            for (lower_copy) |*c| {
                if (c.* == '\\') c.* = '/';
            }

            try map.put(alloc, lower_copy, path_copy);
        }
    }

    fn normalizePath(path: []const u8, buf: *[4096]u8) ?[]const u8 {
        var input = path;
        // Strip leading slashes
        while (input.len > 0 and input[0] == '/') input = input[1..];
        if (input.len == 0 or input.len > buf.len) return null;
        // Lowercase and normalize separators
        const result = std.ascii.lowerString(buf[0..input.len], input);
        for (result) |*c| {
            if (c.* == '\\') c.* = '/';
        }
        return result;
    }
};
