# 📦✨🔥 CaseDropper 🔥✨📦

> Finally. The **case-insensitive file serving** experience you never asked for 🙃, now available on Linux 🐧 via Docker 🐳.

- [ ] Did you migrate your lovingly crafted static site from IIS to nginx? 💀
- [ ] Did `<img src="Images/Logo.PNG">` start 404ing because the file is actually `images/logo.png`? 😱
- [ ] Did your predecessor hardcode paths with the confidence 💪 of someone who has never heard of a case-sensitive filesystem? 🫣
- [ ] Did the intern capitalize every folder name like it was a proper noun? 🤦

We've got you covered. No judgement. Okay, some judgement. 😏

## 🤔 What It Does

Serves static files. Case-insensitively. That's it. That's the whole thing. 🎉🎊🥳

`/INDEX.HTML`, `/index.html`, `/iNdEx.HtMl` — all the same file. Just like the good old days on Windows Server 2003. 🪟💾👴

- 🪶 **Tiny image** on `scratch`. No OS. No shell. No attack surface. Just vibes. ✌️😎
- 🏗️ **Multi-arch**: `amd64`, `arm64`, `armv7`, `i386`, `riscv64`, `ppc64le`, `s390x`, `mips64le`, `loong64`. Runs on your server 🖥️, your Mac 🍎, your toaster 🍞. We don't judge your hardware choices either.
- 🔄 **Hot-reload**: Drop files in, the path map rebuilds itself. No restart needed 🚀. We solved the hard problem so you can keep deploying by drag-and-drop into a mounted volume. 📂➡️📂
- ⚡ **Zig**: Statically linked. Starts in microseconds ⏱️. No runtime required. Your container has fewer dependencies than your morning routine ☕.
- 🌙 **Lua scripting**: Embedded Lua 5.4 engine 🦎🤝🌙 rewrites URLs at index time. Ships with `rusify.lua` 🇷🇺 (`ABCDEFGHIJKLMNOPQRSTUVWXYZ` → `ДBCDЄFБHЇJКLMИОPQЯ₴TЦVЩЖУZ`, plus digraphs `io`→`ю` `bi`→`ы`) and `smallcaps.lua` 🔡 (`index` → `ɪɴᴅᴇx`). Your users will think you've been hacked. You haven't. Probably 🤷.

## 🚀 Quick Start

A pre-built image is published to GitHub Container Registry 📦. No build step required, just mount your files and go:

```bash
docker run --rm -p 8080:8080 -v ./my-site:/app/wwwroot ghcr.io/bonuspunkt/casedropper:latest
```

Or build it yourself, if you have trust issues 🫣:

```bash
docker build -t casedropper .
docker run --rm -p 8080:8080 casedropper
```

Your files 📄. Any casing 🔤. Port 8080 🔌. You're welcome 🫡.

## ⚙️ Configuration

All configuration is done via environment variables 🌍, because we're running on Linux now and we've moved past clicking through property dialogs 🖱️❌.

| Variable | Default | Description |
|----------|---------|-------------|
| `WWWROOT` 📁 | `/app/wwwroot` | Where your files live 🏠 |
| `PORT` 🔌 | `8080` | Listening port. Yes, you can change it. No, we won't help you pick one 🤷 |
| `ENABLE_DIRECTORY_BROWSING` 👀 | off | Set `true` or `1` to enable. Recreates the nostalgia of browsing `http://localhost/` and seeing every file listed in a table 📋. Your security team will love it 😬 |
| `LUA_SCRIPT` 🌙 | off | Path to a Lua script defining a `rewrite(path)` function 🔄. URLs are rewritten at index time, not per-request. Zero overhead. Infinite chaos potential 🔥 |

Four environment variables. That's the entire configuration surface 🎯. If your last project had a 200-line YAML config, this might feel unsettling 😰. That's normal. Breathe through it 🧘.

## 🌙 Lua URL Rewriting

Because case-insensitive serving wasn't unhinged enough 🤪, we embedded an entire Lua 5.4 scripting engine. Write a Lua script with a `rewrite(path)` function and CaseDropper will generate URL aliases at index time 📇. Both the original path and the rewritten alias resolve to the same file. Zero per-request overhead 🏎️💨.

```bash
# Serve files with Cyrillic homoglyph URLs 🇷🇺
docker run --rm -p 8080:8080 \
  -e LUA_SCRIPT=/app/scripts/rusify.lua \
  ghcr.io/bonuspunkt/casedropper:latest

# /index.html     → 200 ✅
# /їиdєж.html    → 200 ✅  (every letter mapped to Cyrillic. You can barely tell 👀)
```

Ships with two scripts 📜📜:

| Script | What it does | Example |
|--------|-------------|---------|
| `rusify.lua` 🇷🇺 | Full Latin → Cyrillic/Ukrainian | `index` → `їиdєж` (28 letters + 4 digraphs 🫣) |
| `smallcaps.lua` 🔡 | lowercase → sᴍᴀʟʟ ᴄᴀᴘs | `index` → `ɪɴᴅᴇx` (fancy ✨) |

<details>
<summary><b>rusify.lua full mapping table 🇷🇺🔤</b></summary>

```
ABCDEFGHIJKLMNOPQRSTUVWXYZ
ДBCDЄFБHЇJКLMИОPQЯ₴TЦVЩЖУZ

abcdefghijklmnopqrstuvwxyz
aвcdєfgнїjкlмиоpqяšтцvшжуz
```

Digraphs (matched first): `io`→`ю` · `IO`→`Ю` · `bi`→`ы` · `BI`→`Ы`

28 of 52 letters get swapped, plus 4 digraph combos. File extensions are preserved 📎. Decoded from the [fsymbols.com source](https://fsymbols.com/generators/rusify/) 🔍.
</details>

Write your own 📝! The contract is simple:

```lua
function rewrite(path)
    -- return a string for the alias, or nil to skip
    return path:gsub("cat", "кот")  -- 🐱→🐱 but in Russian
end
```

The Lua engine runs only during path map builds 🏗️ (startup + file changes). Request handling is still just a hash map lookup 📖. We added a scripting engine and somehow made it zero-cost at runtime 🧙‍♂️.

## 🧠 How It Works

At startup 🏁, `PathMap` walks the entire web root 🚶 and builds a lowercase lookup map of every file and directory. Incoming request paths are lowercased and matched against this map. It's a `StringHashMap` 📖.

- Not machine learning 🤖❌
- Not AI 🧠❌
- A hash map 📚✅

An inotify watcher 👁️ monitors the web root for changes. When files are added 🟩, deleted 🟥, or renamed 🟨, the path map is rebuilt automatically after a 1-second debounce ⏳. We considered making it configurable. Then we didn't 💅.

The whole thing is written in Zig 🦎 with an embedded Lua 5.4 engine 🌙, compiled to a single static binary. The final Docker image is `FROM scratch` 🫥 — there is literally nothing in it except the binary, your files, and some Lua scripts. You can't even `docker exec` into it 🚫.

- There's no shell 🐚❌
- There's no `ls` 📋❌
- It's a binary in a void 🕳️
- It's beautiful 🥲

## 🌐 Protocol Support

- ✅ HTTP/1.0, HTTP/1.1: fully supported 💯
- ❌ HTTP/2, HTTP/3: not happening (no TLS 🔒🚫)

If you need TLS 🔐, put it behind a reverse proxy like a normal person 🧑‍💻. If you're exposing this directly to the internet 🌍 over plain HTTP, that's between you and your conscience 😇😈.

## ❓ FAQ

<details>
<summary><b>Should I use this in production? 🏭</b></summary>

You should probably fix your paths instead 🛤️. But if you're reading this, you've likely already accepted that's not happening. Ship it 🚢.
</details>

<details>
<summary><b>Does it hot-reload when files change? 🔄</b></summary>

Yes ✅. An inotify watcher picks up changes and rebuilds the path map within a second ⏱️. You don't even have to restart. The future is now 🚀🔮.
</details>

<details>
<summary><b>Why is the image so small? 🤏</b></summary>

- No base OS 🚫🖥️
- No runtime 🚫⚙️
- musl libc statically linked (Lua needs it, but it's baked in 🍞)

One static Zig binary running on an empty container 📦🫥. There's nothing left to remove. We tried. We removed the entire operating system 💣. It still works ✅.
</details>

<details>
<summary><b>What architectures are supported? 🏗️</b></summary>

`amd64`, `arm64`, `armv7`, `i386`, `riscv64`, `ppc64le`, `s390x`, `mips64le`, and `loong64`. Thanks to Zig's built-in cross-compilation 🦎, we target 9 architectures from a single build host. No QEMU, no separate toolchains, no excuses 🫡.
</details>

<details>
<summary><b>Why not just use Windows? 🪟</b></summary>

We don't talk about that here 🤫🙅.
</details>

<details>
<summary><b>Is this over-engineered? 🔧🔧🔧</b></summary>

- Zig static binary ⚡
- With an embedded Lua 5.4 scripting engine 🌙
- Thread pool with reader-writer locks 🔒
- Running in an empty container 🫥
- With an inotify file system watcher 👁️
- And debounced rebuilds ⏳
- Serving files through a case-insensitive hash map 🗂️
- That also indexes Cyrillic homoglyph aliases 🇷🇺
- Generated by a scripting language inside a systems language inside an empty container 🤯

For a problem you could also solve with a symlink 🔗. You tell us 🫠.
</details>

## 📜 License

Do whatever you want with it 🤷. It's a hash map and a for loop 🔁.

---

Made with ❤️, questionable priorities 🎪, and an embedded scripting language 🌙
