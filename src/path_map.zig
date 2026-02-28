const std = @import("std");
const lua_engine = @import("lua_engine.zig");

pub const PathMap = struct {
    allocator: std.mem.Allocator,
    root: []const u8,
    map: std.StringHashMapUnmanaged([]const u8),
    lock: std.Thread.RwLock,
    string_arena: std.heap.ArenaAllocator,
    lua: ?*lua_engine.LuaEngine,

    pub fn init(allocator: std.mem.Allocator, root: []const u8, lua: ?*lua_engine.LuaEngine) !PathMap {
        var pm = PathMap{
            .allocator = allocator,
            .root = root,
            .map = .{},
            .lock = .{},
            .string_arena = std.heap.ArenaAllocator.init(allocator),
            .lua = lua,
        };
        try pm.buildMap();
        return pm;
    }

    pub fn deinit(self: *PathMap) void {
        self.string_arena.deinit();
        self.map.deinit(self.allocator);
    }

    /// Look up a request path (case-insensitive, percent-decoded).
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

        buildMapInto(self.root, &new_map, &new_arena, self.lua) catch |err| {
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
        try buildMapInto(self.root, &self.map, &self.string_arena, self.lua);
    }

    fn buildMapInto(
        root: []const u8,
        map: *std.StringHashMapUnmanaged([]const u8),
        arena: *std.heap.ArenaAllocator,
        lua: ?*lua_engine.LuaEngine,
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
            for (lower_copy) |*ch| {
                if (ch.* == '\\') ch.* = '/';
            }

            try map.put(alloc, lower_copy, path_copy);

            // Generate Lua alias if engine is available
            if (lua) |l| {
                var rewrite_buf: [4096]u8 = undefined;
                if (l.rewritePath(entry.path, &rewrite_buf)) |alias| {
                    // Only add if different from original
                    if (!std.mem.eql(u8, alias, entry.path)) {
                        // Lowercase the alias for case-insensitive lookup
                        var alias_lower_buf: [4096]u8 = undefined;
                        if (alias.len <= alias_lower_buf.len) {
                            for (alias, 0..) |byte, i| {
                                alias_lower_buf[i] = std.ascii.toLower(byte);
                                if (alias_lower_buf[i] == '\\') alias_lower_buf[i] = '/';
                            }
                            const alias_key = try alloc.dupe(u8, alias_lower_buf[0..alias.len]);

                            // Don't overwrite existing entries (original paths take priority)
                            const gop = try map.getOrPut(alloc, alias_key);
                            if (!gop.found_existing) {
                                gop.value_ptr.* = path_copy;
                            }
                        }
                    }
                }
            }
        }
    }

    fn normalizePath(path: []const u8, buf: *[4096]u8) ?[]const u8 {
        var input = path;
        // Strip leading slashes
        while (input.len > 0 and input[0] == '/') input = input[1..];
        if (input.len == 0 or input.len > buf.len) return null;

        // Percent-decode, lowercase, and normalize separators in one pass
        var out_len: usize = 0;
        var i: usize = 0;
        while (i < input.len) {
            var byte = input[i];

            if (byte == '%' and i + 2 < input.len) {
                if (hexDigit(input[i + 1])) |hi| {
                    if (hexDigit(input[i + 2])) |lo| {
                        if (out_len >= buf.len) return null;
                        buf[out_len] = (@as(u8, hi) << 4) | @as(u8, lo);
                        // Only lowercase ASCII bytes
                        buf[out_len] = std.ascii.toLower(buf[out_len]);
                        out_len += 1;
                        i += 3;
                        continue;
                    }
                }
            }

            // Regular byte: lowercase and normalize separator
            byte = std.ascii.toLower(byte);
            if (byte == '\\') byte = '/';
            if (out_len >= buf.len) return null;
            buf[out_len] = byte;
            out_len += 1;
            i += 1;
        }

        if (out_len == 0) return null;
        return buf[0..out_len];
    }

    fn hexDigit(ch: u8) ?u4 {
        return switch (ch) {
            '0'...'9' => @intCast(ch - '0'),
            'A'...'F' => @intCast(ch - 'A' + 10),
            'a'...'f' => @intCast(ch - 'a' + 10),
            else => null,
        };
    }
};
