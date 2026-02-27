const std = @import("std");

const mime_types = std.StaticStringMap([]const u8).initComptime(.{
    .{ ".html", "text/html; charset=utf-8" },
    .{ ".htm", "text/html; charset=utf-8" },
    .{ ".css", "text/css; charset=utf-8" },
    .{ ".js", "text/javascript; charset=utf-8" },
    .{ ".mjs", "text/javascript; charset=utf-8" },
    .{ ".json", "application/json" },
    .{ ".xml", "application/xml" },
    .{ ".svg", "image/svg+xml" },
    .{ ".png", "image/png" },
    .{ ".jpg", "image/jpeg" },
    .{ ".jpeg", "image/jpeg" },
    .{ ".gif", "image/gif" },
    .{ ".webp", "image/webp" },
    .{ ".avif", "image/avif" },
    .{ ".ico", "image/x-icon" },
    .{ ".woff", "font/woff" },
    .{ ".woff2", "font/woff2" },
    .{ ".ttf", "font/ttf" },
    .{ ".otf", "font/otf" },
    .{ ".eot", "application/vnd.ms-fontobject" },
    .{ ".txt", "text/plain; charset=utf-8" },
    .{ ".csv", "text/csv" },
    .{ ".pdf", "application/pdf" },
    .{ ".zip", "application/zip" },
    .{ ".gz", "application/gzip" },
    .{ ".tar", "application/x-tar" },
    .{ ".mp3", "audio/mpeg" },
    .{ ".mp4", "video/mp4" },
    .{ ".webm", "video/webm" },
    .{ ".ogg", "audio/ogg" },
    .{ ".wasm", "application/wasm" },
    .{ ".map", "application/json" },
});

pub fn fromPath(path: []const u8) []const u8 {
    const ext = std.fs.path.extension(path);
    if (ext.len == 0 or ext.len > 16) return "application/octet-stream";

    var lower_buf: [16]u8 = undefined;
    const lower = std.ascii.lowerString(lower_buf[0..ext.len], ext);

    return mime_types.get(lower) orelse "application/octet-stream";
}
