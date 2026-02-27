const std = @import("std");
const http = std.http;

pub fn tryServeListing(
    request: *http.Server.Request,
    wwwroot: []const u8,
    url_path: []const u8,
) !bool {
    const trimmed = std.mem.trimRight(u8, url_path, "/");
    const stripped = std.mem.trimLeft(u8, trimmed, "/");

    var dir_path_buf: [4096]u8 = undefined;
    const dir_path = if (stripped.len == 0)
        wwwroot
    else
        std.fmt.bufPrint(&dir_path_buf, "{s}/{s}", .{ wwwroot, stripped }) catch return false;

    var dir = std.fs.cwd().openDir(dir_path, .{ .iterate = true }) catch return false;
    defer dir.close();

    const allocator = std.heap.page_allocator;
    var buf: std.ArrayList(u8) = .{};
    defer buf.deinit(allocator);

    const w = buf.writer(allocator);
    try w.writeAll(
        \\<!DOCTYPE html>
        \\<html><head><meta charset="utf-8">
        \\<title>Directory:
    );
    try writeEscaped(w, url_path);
    try w.writeAll(
        \\</title>
        \\<style>body{font-family:sans-serif;margin:2em}table{border-collapse:collapse}
        \\td,th{padding:4px 12px;text-align:left}tr:hover{background:#f0f0f0}</style>
        \\</head><body><h1>Directory:
    );
    try writeEscaped(w, url_path);
    try w.writeAll(
        \\</h1><table><tr><th>Name</th><th>Size</th></tr>
    );

    // Parent directory link
    if (stripped.len > 0) {
        const parent = if (std.mem.lastIndexOfScalar(u8, stripped, '/')) |idx|
            stripped[0..idx]
        else
            "";
        try w.writeAll("<tr><td><a href=\"/");
        try writeEscaped(w, parent);
        try w.writeAll("/\">..</a></td><td></td></tr>\n");
    }

    var iter = dir.iterate();
    while (try iter.next()) |entry| {
        try w.writeAll("<tr><td><a href=\"");
        if (url_path.len > 0 and url_path[url_path.len - 1] != '/') {
            try writeEscaped(w, url_path);
            try w.writeAll("/");
        } else {
            try writeEscaped(w, url_path);
        }
        try writeEscaped(w, entry.name);
        if (entry.kind == .directory) try w.writeAll("/");
        try w.writeAll("\">");
        try writeEscaped(w, entry.name);
        if (entry.kind == .directory) try w.writeAll("/");
        try w.writeAll("</a></td><td>");
        if (entry.kind == .file) {
            if (dir.statFile(entry.name)) |stat| {
                try formatSize(w, stat.size);
            } else |_| {}
        }
        try w.writeAll("</td></tr>\n");
    }

    try w.writeAll("</table></body></html>");

    try request.respond(buf.items, .{
        .extra_headers = &.{
            .{ .name = "content-type", .value = "text/html; charset=utf-8" },
        },
    });
    return true;
}

fn writeEscaped(w: anytype, text: []const u8) !void {
    for (text) |c| {
        switch (c) {
            '<' => try w.writeAll("&lt;"),
            '>' => try w.writeAll("&gt;"),
            '&' => try w.writeAll("&amp;"),
            '"' => try w.writeAll("&quot;"),
            else => try w.writeByte(c),
        }
    }
}

fn formatSize(w: anytype, size: u64) !void {
    if (size < 1024) {
        try w.print("{d} B", .{size});
    } else if (size < 1024 * 1024) {
        try w.print("{d:.1} KB", .{@as(f64, @floatFromInt(size)) / 1024.0});
    } else if (size < 1024 * 1024 * 1024) {
        try w.print("{d:.1} MB", .{@as(f64, @floatFromInt(size)) / (1024.0 * 1024.0)});
    } else {
        try w.print("{d:.1} GB", .{@as(f64, @floatFromInt(size)) / (1024.0 * 1024.0 * 1024.0)});
    }
}
