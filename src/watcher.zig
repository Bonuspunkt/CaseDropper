const std = @import("std");
const posix = std.posix;
const linux = std.os.linux;
const path_map = @import("path_map.zig");

const DEBOUNCE_NS: u64 = 1_000_000_000; // 1 second

pub fn watchLoop(pm: *path_map.PathMap, root: []const u8) void {
    watchLoopImpl(pm, root) catch |err| {
        std.log.err("File watcher failed: {}", .{err});
    };
}

fn watchLoopImpl(pm: *path_map.PathMap, root: []const u8) !void {
    const inotify_fd = try posix.inotify_init1(0);
    defer posix.close(inotify_fd);

    const mask: u32 = linux.IN.CREATE | linux.IN.DELETE | linux.IN.MOVED_FROM | linux.IN.MOVED_TO;

    // Watch root directory
    _ = try addWatch(inotify_fd, root, mask);

    // Watch all subdirectories
    addSubdirWatches(inotify_fd, root, mask);

    var event_buf: [4096]u8 = undefined;

    while (true) {
        // Block until an event arrives
        const bytes_read = posix.read(inotify_fd, &event_buf) catch |err| {
            std.log.err("inotify read error: {}", .{err});
            continue;
        };
        if (bytes_read == 0) continue;

        // Debounce: wait for things to settle
        std.Thread.sleep(DEBOUNCE_NS);

        // Drain any buffered events (non-blocking read via poll)
        drainEvents(inotify_fd, &event_buf);

        // Rebuild path map and re-add watches for new directories
        pm.rebuild();
        addSubdirWatches(inotify_fd, root, mask);
    }
}

fn drainEvents(inotify_fd: i32, event_buf: *[4096]u8) void {
    var fds = [_]posix.pollfd{.{
        .fd = inotify_fd,
        .events = linux.POLL.IN,
        .revents = 0,
    }};

    while (true) {
        const ready = posix.poll(&fds, 0) catch break;
        if (ready == 0) break;
        _ = posix.read(inotify_fd, event_buf) catch break;
    }
}

fn addWatch(inotify_fd: i32, path: []const u8, mask: u32) !i32 {
    var z_buf: [4097]u8 = undefined;
    if (path.len >= z_buf.len) return error.NameTooLong;
    @memcpy(z_buf[0..path.len], path);
    z_buf[path.len] = 0;
    return try posix.inotify_add_watchZ(inotify_fd, z_buf[0..path.len :0], mask);
}

fn addSubdirWatches(inotify_fd: i32, root: []const u8, mask: u32) void {
    var dir = std.fs.cwd().openDir(root, .{ .iterate = true }) catch return;
    defer dir.close();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var walker = dir.walk(gpa.allocator()) catch return;
    defer walker.deinit();

    while (walker.next() catch null) |entry| {
        if (entry.kind == .directory) {
            var path_buf: [4096]u8 = undefined;
            const full_path = std.fmt.bufPrint(&path_buf, "{s}/{s}", .{ root, entry.path }) catch continue;
            _ = addWatch(inotify_fd, full_path, mask) catch {};
        }
    }
}
