const std = @import("std");

pub const Config = struct {
    wwwroot: []const u8,
    port: u16,
    dir_browsing: bool,
    lua_script: ?[]const u8,
};

pub const ConfigError = error{
    WwwrootNotFound,
    InvalidPort,
    LuaScriptNotFound,
};

pub fn load() ConfigError!Config {
    const wwwroot = std.posix.getenv("WWWROOT") orelse "wwwroot";
    const port = blk: {
        const port_str = std.posix.getenv("PORT") orelse "8080";
        break :blk std.fmt.parseInt(u16, port_str, 10) catch return error.InvalidPort;
    };
    if (port == 0) return error.InvalidPort;

    const dir_env = std.posix.getenv("ENABLE_DIRECTORY_BROWSING") orelse "";
    const dir_browsing = std.ascii.eqlIgnoreCase(dir_env, "true") or
        std.mem.eql(u8, dir_env, "1");

    const lua_script = std.posix.getenv("LUA_SCRIPT");

    // Validate wwwroot exists
    var dir = std.fs.cwd().openDir(wwwroot, .{}) catch return error.WwwrootNotFound;
    dir.close();

    // Validate lua script exists
    if (lua_script) |script| {
        var file = std.fs.cwd().openFile(script, .{}) catch return error.LuaScriptNotFound;
        file.close();
    }

    return .{
        .wwwroot = wwwroot,
        .port = port,
        .dir_browsing = dir_browsing,
        .lua_script = lua_script,
    };
}
