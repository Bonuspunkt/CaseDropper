const std = @import("std");

pub const Config = struct {
    wwwroot: []const u8,
    port: u16,
    dir_browsing: bool,
};

pub const ConfigError = error{
    WwwrootNotFound,
    InvalidPort,
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

    // Validate wwwroot exists
    var dir = std.fs.cwd().openDir(wwwroot, .{}) catch return error.WwwrootNotFound;
    dir.close();

    return .{
        .wwwroot = wwwroot,
        .port = port,
        .dir_browsing = dir_browsing,
    };
}
