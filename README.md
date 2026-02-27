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

- 🪶 **~12 MB** image on `scratch`. No OS. No shell. No attack surface. Just vibes. ✌️😎
- 🏗️ **Multi-arch**: `amd64` and `arm64`. Runs on your server 🖥️, your Mac 🍎, your NAS 📼. We don't judge your hardware choices either.
- 🔄 **Hot-reload**: Drop files in, the path map rebuilds itself. No restart needed 🚀. We solved the hard problem so you can keep deploying by drag-and-drop into a mounted volume. 📂➡️📂
- ⚡ **Native AOT**: Statically linked. Starts in milliseconds ⏱️. No runtime required. Your container has fewer dependencies than your morning routine ☕.

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

Three environment variables. That's the entire configuration surface 🎯. If your last project had a 200-line YAML config, this might feel unsettling 😰. That's normal. Breathe through it 🧘.

## 🧠 How It Works

At startup 🏁, `CaseInsensitiveFileProvider` walks the entire web root 🚶 and builds a lowercase lookup map of every file and directory. Incoming request paths are lowercased and matched against this map. It's a `Dictionary<string, string>` 📖.

- Not machine learning 🤖❌
- Not AI 🧠❌
- A dictionary 📚✅

A `FileSystemWatcher` 👁️ monitors the web root for changes. When files are added 🟩, deleted 🟥, or renamed 🟨, the path map is rebuilt automatically after a 1-second debounce ⏳. We considered making it configurable. Then we didn't 💅.

The whole thing compiles to a single static binary via .NET Native AOT 🎯, linked against musl. The final Docker image is `FROM scratch` 🫥 — there is literally nothing in it except the binary and your files. You can't even `docker exec` into it 🚫.

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

Yes ✅. A file watcher picks up changes and rebuilds the path map within a second ⏱️. You don't even have to restart. The future is now 🚀🔮.
</details>

<details>
<summary><b>Why is the image so small? 🤏</b></summary>

- No base OS 🚫🖥️
- No .NET runtime 🚫⚙️
- No ICU 🚫🌍
- No libc 🚫📚

One static binary, compiled ahead of time, running on an empty container 📦🫥. There's nothing left to remove. We tried. We removed the entire operating system 💣. It still works ✅.
</details>

<details>
<summary><b>What architectures are supported? 🏗️</b></summary>

`amd64` and `arm64`. 32-bit ARM (`armv7`) is not supported because .NET Native AOT dropped it 🫳 — take it up with Microsoft, not us 🤷.
</details>

<details>
<summary><b>Why not just use Windows? 🪟</b></summary>

We don't talk about that here 🤫🙅.
</details>

<details>
<summary><b>Is this over-engineered? 🔧🔧🔧</b></summary>

- Statically compiled ⚡
- Ahead-of-time native binary 🎯
- Running in an empty container 🫥
- With a file system watcher 👁️
- And debounced rebuilds ⏳
- Serving files through a case-insensitive lookup table 🗂️

For a problem you could also solve with a symlink 🔗. You tell us 🫠.
</details>

## 📜 License

Do whatever you want with it 🤷. It's a dictionary and a for loop 🔁.

---

Made with ❤️ and questionable priorities 🎪
