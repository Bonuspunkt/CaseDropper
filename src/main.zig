const std = @import("std");
const config = @import("config.zig");
const path_map = @import("path_map.zig");
const handler = @import("handler.zig");
const watcher = @import("watcher.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const stderr = std.fs.File.stderr().deprecatedWriter();
    const stdout = std.fs.File.stdout().deprecatedWriter();

    // Parse configuration
    const cfg = config.load() catch |err| {
        switch (err) {
            error.WwwrootNotFound => stderr.print("Error: WWWROOT directory not found\n", .{}) catch {},
            error.InvalidPort => stderr.print("Error: PORT must be a number between 1 and 65535\n", .{}) catch {},
        }
        std.process.exit(1);
    };

    // Build initial path map
    var pm = path_map.PathMap.init(allocator, cfg.wwwroot) catch |err| {
        stderr.print("Error: Failed to build path map: {}\n", .{err}) catch {};
        std.process.exit(1);
    };
    defer pm.deinit();

    // Start file watcher thread
    _ = std.Thread.spawn(.{}, watcher.watchLoop, .{ &pm, cfg.wwwroot }) catch {
        stderr.print("Warning: File watcher failed to start\n", .{}) catch {};
        // Continue without file watching
    };

    // Initialize thread pool
    var pool: std.Thread.Pool = undefined;
    try pool.init(.{ .allocator = allocator });
    defer pool.deinit();

    // WaitGroup for tracking in-flight connections
    var wg: std.Thread.WaitGroup = .{};

    // Bind and listen
    const address = std.net.Address.parseIp("0.0.0.0", cfg.port) catch unreachable;
    var server = try address.listen(.{ .reuse_address = true });
    defer server.deinit();

    // Log startup info
    stdout.print("Serving files from: {s}\n", .{cfg.wwwroot}) catch {};
    stdout.print("Listening on:       http://0.0.0.0:{d}\n", .{cfg.port}) catch {};
    stdout.print("Protocols:          HTTP/1.0, HTTP/1.1\n", .{}) catch {};
    stdout.print("Directory browsing: {s}\n", .{if (cfg.dir_browsing) "enabled" else "disabled"}) catch {};
    stdout.print("File watching:      enabled\n", .{}) catch {};

    // Accept loop
    while (true) {
        const connection = server.accept() catch |err| {
            std.log.err("Accept error: {}", .{err});
            continue;
        };
        pool.spawnWg(&wg, handler.handleConnection, .{ connection, &pm, cfg });
    }
}
