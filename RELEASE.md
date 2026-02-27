# 🌙🦎 v0.4.0 — "We Put a Scripting Language Inside a Static File Server"

## What's New

We embedded Lua 5.4 into a static file server. On purpose.

### 🌙 Lua URL Rewriting Engine

CaseDropper now ships with an embedded Lua 5.4 scripting engine for URL rewriting. Set `LUA_SCRIPT` to a Lua file that defines a `rewrite(path)` function, and CaseDropper will generate URL aliases at index build time. Both the original path and the rewritten alias serve the same file.

**The key architectural decision:** Lua runs at index time, not per-request. The path map is built once (and rebuilt on file changes), so request handling is still just a hash map lookup. We added a scripting engine and it costs exactly zero nanoseconds at runtime.

```bash
# Cyrillic homoglyph URLs
LUA_SCRIPT=scripts/rusify.lua WWWROOT=wwwroot ./zig-out/bin/casedropper

# Unicode small capitals URLs
LUA_SCRIPT=scripts/smallcaps.lua WWWROOT=wwwroot ./zig-out/bin/casedropper
```

### 📜 Bundled Scripts

| Script | Effect | Before → After |
|--------|--------|----------------|
| `rusify.lua` 🇷🇺 | Full Latin → Cyrillic/Ukrainian | `index.html` → `їиdєж.html` |
| `smallcaps.lua` 🔡 | lowercase → small capitals | `index.html` → `ɪɴᴅᴇx.html` |

`rusify.lua` maps 28 of 52 Latin letters to Cyrillic/Ukrainian equivalents, plus 4 digraph combos:

```
ABCDEFGHIJKLMNOPQRSTUVWXYZ → ДBCDЄFБHЇJКLMИОPQЯ₴TЦVЩЖУZ
abcdefghijklmnopqrstuvwxyz → aвcdєfgнїjкlмиоpqяšтцvшжуz

Digraphs: io→ю  IO→Ю  bi→ы  BI→Ы
```

Decoded from the [fsymbols.com source](https://fsymbols.com/generators/rusify/). Some look identical (`o` → `о`), some are wildly different (`A` → `Д`), and digraphs collapse two chars into one (`biography` → `ыоgяapну`). All of them will confuse your users 🫠.

### 🔧 Write Your Own

```lua
function rewrite(path)
    -- return string for alias, nil to skip
    return path:gsub("hello", "привет")
end
```

Drop it in `scripts/`, set `LUA_SCRIPT`, restart. The path map rebuilds with your aliases. File watching picks up changes automatically.

### 🔗 URL Percent-Decoding

`PathMap.normalizePath` now percent-decodes URLs before lookup. This means Unicode characters in URLs (like Cyrillic or small caps) work correctly when the browser percent-encodes them in the HTTP request. This also fixes edge cases with filenames containing spaces or special characters.

## Breaking Changes

- **musl libc is now statically linked** — Lua needs libc functions (`malloc`, `string.h`, etc.). The binary is still fully static and the scratch container still works, but the binary is slightly larger.
- `PathMap.init()` now takes an optional `LuaEngine` pointer as its third argument.

## Technical Details

- Lua 5.4.7 source vendored in `deps/lua/src/` (32 C files, compiled by Zig's build system)
- Zero external dependencies at build time — Zig compiles the Lua C sources alongside the Zig code
- Cross-compilation to all 9 architectures still works (Lua is pure C99)
- Lua engine lifecycle: init at startup, called during path map build/rebuild, deinit at shutdown
- Error handling: script load failures are fatal (server won't start); runtime errors in `rewrite()` are logged and the path is skipped
- File extensions are preserved by bundled scripts (only stems are transformed)

## Full Changelog

- feat: embed Lua 5.4.7 scripting engine for URL rewriting
- feat: add `LUA_SCRIPT` environment variable
- feat: add `rusify.lua` script (full Latin → Cyrillic/Ukrainian, 28 letters + 4 digraphs, decoded from fsymbols.com source)
- feat: add `smallcaps.lua` script (lowercase → Unicode small capitals)
- feat: add URL percent-decoding in PathMap for Unicode URL support
- build: link musl libc (required by Lua)
- build: vendor Lua 5.4.7 C source in `deps/lua/`
