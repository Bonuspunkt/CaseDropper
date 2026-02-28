# CLAUDE.md

- **MANDATORY — Keep CLAUDE.md up to date**: After every change that adds policy decisions or non-discoverable context, update this file. Do not duplicate information that can be gathered from the codebase on the fly (project structure, tech stack, API endpoints, config, etc.).

## Branching

- The default/main branch is `misstress` (not `main` or `master`)

## Build & Run

```bash
# Native build
zig build -Doptimize=ReleaseSafe
WWWROOT=wwwroot ./zig-out/bin/casedropper

# With Lua URL rewriting
LUA_SCRIPT=scripts/rusify.lua WWWROOT=wwwroot ./zig-out/bin/casedropper

# Docker
docker build -t casedropper .
docker run --rm -p 8080:8080 -e LUA_SCRIPT=/app/scripts/rusify.lua casedropper
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `WWWROOT` | `/app/wwwroot` (in container) | Static files directory |
| `PORT` | `8080` | Listening port |
| `ENABLE_DIRECTORY_BROWSING` | off | Set `true` or `1` to enable |
| `LUA_SCRIPT` | off | Path to Lua script with `rewrite(path)` function |

## Protocol Support

- HTTP/1.0, HTTP/1.1: fully supported
- HTTP/2, HTTP/3: not possible (std.http.Server is HTTP/1.x only, no mature h2c lib in Zig)

## Key Decisions

- Written in Zig 0.15.2, Lua 5.4.7 vendored as C source in `deps/lua/`
- Case-insensitive file serving via `PathMap` (indexes all paths at startup using `std.fs.Dir.walk`)
- Thread-safe path map with `std.Thread.RwLock` (shared reads, exclusive write during rebuild)
- Multi-threaded HTTP serving via `std.Thread.Pool` (defaults to CPU count)
- File watching via Linux inotify, 1-second debounce
- All config via env vars only
- MIME types via compile-time `std.StaticStringMap`
- Cross-compilation via `zig build -Dtarget=...` — no external toolchain needed
- Dockerfile uses `--platform=$BUILDPLATFORM` + Zig cross-compilation (no QEMU for build)
- Scratch container, statically linked binary (musl libc for Lua)
- Lua engine runs at index build time only — zero per-request overhead
- URL percent-decoding in `PathMap.normalizePath` for Unicode URL support
- Lua scripts preserve file extensions, only transform filename stems
