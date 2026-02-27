const std = @import("std");
const c = @cImport({
    @cInclude("lua.h");
    @cInclude("lualib.h");
    @cInclude("lauxlib.h");
});

pub const LuaEngine = struct {
    state: *c.lua_State,

    pub fn init(script_path: []const u8) !LuaEngine {
        const L = c.luaL_newstate() orelse return error.LuaInitFailed;
        errdefer c.lua_close(L);

        c.luaL_openlibs(L);

        // Load script file (need null-terminated path)
        var path_buf: [4096]u8 = undefined;
        if (script_path.len >= path_buf.len) return error.PathTooLong;
        @memcpy(path_buf[0..script_path.len], script_path);
        path_buf[script_path.len] = 0;
        const z_path: [*:0]const u8 = path_buf[0..script_path.len :0];

        if (c.luaL_loadfilex(L, z_path, null) != 0) {
            logLuaError(L);
            return error.LuaScriptLoadFailed;
        }

        // Execute the script (defines the global `rewrite` function)
        if (c.lua_pcallk(L, 0, c.LUA_MULTRET, 0, 0, null) != 0) {
            logLuaError(L);
            return error.LuaScriptExecFailed;
        }

        // Verify that `rewrite` function exists
        _ = c.lua_getglobal(L, "rewrite");
        if (c.lua_type(L, -1) != c.LUA_TFUNCTION) {
            std.log.err("Lua script does not define a 'rewrite' function", .{});
            c.lua_settop(L, -2); // pop
            return error.LuaRewriteFunctionMissing;
        }
        c.lua_settop(L, -2); // pop

        return .{ .state = L };
    }

    pub fn deinit(self: *LuaEngine) void {
        c.lua_close(self.state);
    }

    /// Call the Lua `rewrite(path)` function.
    /// Returns the rewritten path copied into `result_buf`,
    /// or null if Lua returns nil or errors.
    pub fn rewritePath(self: *LuaEngine, path: []const u8, result_buf: *[4096]u8) ?[]const u8 {
        const L = self.state;

        // Push the rewrite function
        _ = c.lua_getglobal(L, "rewrite");

        // Push the path argument
        _ = c.lua_pushlstring(L, path.ptr, path.len);

        // Call: 1 argument, 1 result
        if (c.lua_pcallk(L, 1, 1, 0, 0, null) != 0) {
            logLuaError(L);
            return null;
        }

        // Check result type
        if (c.lua_type(L, -1) != c.LUA_TSTRING) {
            c.lua_settop(L, -2); // pop
            return null;
        }

        var result_len: usize = 0;
        const result_ptr = c.lua_tolstring(L, -1, &result_len);
        c.lua_settop(L, -2); // pop

        if (result_ptr == null or result_len == 0 or result_len > result_buf.len) {
            return null;
        }

        // Copy out of Lua-managed memory
        @memcpy(result_buf[0..result_len], result_ptr[0..result_len]);
        return result_buf[0..result_len];
    }

    fn logLuaError(L: *c.lua_State) void {
        var len: usize = 0;
        const msg = c.lua_tolstring(L, -1, &len);
        if (msg != null and len > 0) {
            std.log.err("Lua error: {s}", .{msg[0..len]});
        } else {
            std.log.err("Lua error: (unknown)", .{});
        }
        c.lua_settop(L, -2); // pop error
    }
};
