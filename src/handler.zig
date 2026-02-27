const std = @import("std");
const http = std.http;
const path_map = @import("path_map.zig");
const mime = @import("mime.zig");
const config = @import("config.zig");
const dir_browser = @import("dir_browser.zig");

pub fn handleConnection(
    connection: std.net.Server.Connection,
    pm: *path_map.PathMap,
    cfg: config.Config,
) void {
    defer connection.stream.close();

    var recv_buf: [8192]u8 = undefined;
    var send_buf: [8192]u8 = undefined;

    var net_reader = connection.stream.reader(&recv_buf);
    var net_writer = connection.stream.writer(&send_buf);

    var server = http.Server.init(net_reader.interface(), &net_writer.interface);

    while (true) {
        var request = server.receiveHead() catch return;
        handleRequest(&request, pm, cfg) catch return;
        if (!request.head.keep_alive) return;
    }
}

fn handleRequest(
    request: *http.Server.Request,
    pm: *path_map.PathMap,
    cfg: config.Config,
) !void {
    const target = request.head.target;

    // Only support GET and HEAD
    if (request.head.method != .GET and request.head.method != .HEAD) {
        try request.respond("Method Not Allowed", .{ .status = .method_not_allowed, .keep_alive = false });
        return;
    }

    // Strip query string
    const path = if (std.mem.indexOfScalar(u8, target, '?')) |idx|
        target[0..idx]
    else
        target;

    // Reject path traversal
    if (std.mem.indexOf(u8, path, "..") != null) {
        try request.respond("Forbidden", .{ .status = .forbidden });
        return;
    }

    // Try exact file match
    if (pm.resolve(path)) |actual_path| {
        try serveFile(request, cfg.wwwroot, actual_path);
        return;
    }

    // Try default files
    const default_files = [_][]const u8{ "index.html", "index.htm", "default.html", "default.htm" };
    const trimmed = std.mem.trimRight(u8, path, "/");

    for (default_files) |default_name| {
        var buf: [4096]u8 = undefined;
        const combined = std.fmt.bufPrint(&buf, "{s}/{s}", .{ trimmed, default_name }) catch continue;
        if (pm.resolve(combined)) |actual_path| {
            try serveFile(request, cfg.wwwroot, actual_path);
            return;
        }
    }

    // Try directory browsing
    if (cfg.dir_browsing) {
        if (try dir_browser.tryServeListing(request, cfg.wwwroot, path)) return;
    }

    // 404
    try request.respond("Not Found", .{ .status = .not_found });
}

fn serveFile(
    request: *http.Server.Request,
    wwwroot: []const u8,
    relative_path: []const u8,
) !void {
    var path_buf: [4096]u8 = undefined;
    const full_path = std.fmt.bufPrint(&path_buf, "{s}/{s}", .{ wwwroot, relative_path }) catch {
        try request.respond("Internal Server Error", .{ .status = .internal_server_error });
        return;
    };

    const file = std.fs.cwd().openFile(full_path, .{}) catch {
        try request.respond("Not Found", .{ .status = .not_found });
        return;
    };
    defer file.close();

    const stat = file.stat() catch {
        try request.respond("Internal Server Error", .{ .status = .internal_server_error });
        return;
    };

    // Skip directories
    if (stat.kind == .directory) {
        try request.respond("Not Found", .{ .status = .not_found });
        return;
    }

    const content_type = mime.fromPath(relative_path);

    // For HEAD, read the file into memory to get the correct content-length
    // (respond() auto-sets content-length from the body length, and omits the body for HEAD)
    if (request.head.method == .HEAD) {
        // Read file to a temp buffer just to get size for content-length
        // (stat.size is already known, but respond() sets content-length from body.len)
        // We pass a body of the right length so content-length is correct, HEAD omits the body.
        if (stat.size <= 1024 * 1024) { // up to 1MB
            const buf_alloc = std.heap.page_allocator;
            const body = buf_alloc.alloc(u8, @intCast(stat.size)) catch {
                try request.respond("Internal Server Error", .{ .status = .internal_server_error });
                return;
            };
            defer buf_alloc.free(body);
            const n = file.readAll(body) catch {
                try request.respond("Internal Server Error", .{ .status = .internal_server_error });
                return;
            };
            try request.respond(body[0..n], .{
                .extra_headers = &.{
                    .{ .name = "content-type", .value = content_type },
                },
            });
        } else {
            // For large files, use chunked (no content-length) for HEAD
            try request.respond("", .{
                .extra_headers = &.{
                    .{ .name = "content-type", .value = content_type },
                },
            });
        }
        return;
    }

    var stream_buf: [16384]u8 = undefined;
    var response = try request.respondStreaming(&stream_buf, .{
        .content_length = stat.size,
        .respond_options = .{
            .extra_headers = &.{
                .{ .name = "content-type", .value = content_type },
            },
        },
    });

    // Stream file contents
    while (true) {
        var read_buf: [16384]u8 = undefined;
        const bytes_read = file.read(&read_buf) catch break;
        if (bytes_read == 0) break;
        try response.writer.writeAll(read_buf[0..bytes_read]);
    }
    try response.end();
}
