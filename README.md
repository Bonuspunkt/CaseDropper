# CaseDropper — A Revolutionary, Next-Generation, Enterprise-Grade, Case-Insensitive Static File Serving Solution for the Modern Cloud-Native Era

> 🚀 **Absolutely!** Great question. In today's fast-paced digital landscape, serving static files case-insensitively isn't just a nice-to-have — it's a **game-changer**. Let me walk you through everything you need to know about this **powerful**, **robust**, and **elegant** solution that's **redefining** how we think about file serving. Let's dive in! 👇

## 🌟 The Problem Space: A Deep Dive

Great question! So here's the thing — and this is really important — when you migrate your beautifully crafted static website from a Windows-based hosting environment like IIS to a Linux-based infrastructure like nginx, you may encounter what industry experts call a **"case sensitivity mismatch."** This is essentially when paths like `Images/Logo.PNG` suddenly stop working because the actual file is `images/logo.png`.

**And here's the thing** — this happens more often than you might think! In fact, studies show that approximately 100% of developers who have migrated from Windows to Linux have experienced this at least once. I just made that statistic up, but it *feels* right, and that's what matters.

Here are some common scenarios where CaseDropper can **leverage** its **cutting-edge** capabilities to **streamline** your workflow:

- ✅ Your predecessor hardcoded paths with a level of confidence that can only be described as **inspirational**
- ✅ The intern capitalized every folder name because, honestly, it just looked more **professional** to them
- ✅ You have 47,000 HTML files that reference `Images/Banner.JPG` and you are NOT renaming all of them
- ✅ You've accepted that some problems are better solved with **innovative tooling** than with **find-and-replace**

## 💡 What It Does: Key Value Propositions

Great question! I'm glad you asked. At its core — and I really want to emphasize this because it's absolutely **crucial** — CaseDropper serves static files in a case-insensitive manner. That's it. That's the **entire value proposition**.

But let me unpack that for you, because there's actually a lot to unpack here:

- `/INDEX.HTML` → ✅ Works seamlessly
- `/index.html` → ✅ Works seamlessly
- `/iNdEx.HtMl` → ✅ Works seamlessly
- `/InDeX.hTmL` → ✅ Also works seamlessly. Everything works seamlessly. **Seamless** is our middle name.

Think of it like Google, but instead of searching the internet, it searches a single directory. And instead of machine learning, it uses a hash map. **But the energy is the same.**

### 🏗️ Key Features & Differentiators

| Feature | Description | Why It Matters |
|---------|------------|----------------|
| **Tiny Image** | Built on `scratch`. No OS. No shell. No attack surface. | In today's increasingly complex threat landscape, having fewer things is a **competitive advantage**. We have the fewest things. |
| **Multi-Arch** | `amd64`, `arm64`, `armv7`, `i386`, `riscv64`, `ppc64le`, `s390x`, `mips64le`, `loong64` | Whether you're deploying to a state-of-the-art Kubernetes cluster or a Raspberry Pi you found in a drawer, we've got you covered. **Nine architectures.** That's more than most people can name. |
| **Hot-Reload** | inotify-based file watching with automatic path map rebuilds | Drop files in and they're **immediately available**\*. No restart required. This is what we in the industry call a **paradigm shift**. (\*After a 1-second debounce.) |
| **Written in Zig** | Single static binary, no runtime dependencies | Your container has fewer dependencies than your morning coffee order. And it starts faster, too. |

## 🚀 Quick Start Guide: Getting Up and Running in Minutes

Great news! Getting started with CaseDropper is **incredibly straightforward** and I'm really excited to walk you through this. A pre-built image is published to GitHub Container Registry, so you can **hit the ground running** with **zero friction**:

```bash
docker run --rm -p 8080:8080 -v ./my-site:/app/wwwroot ghcr.io/bonuspunkt/casedropper:latest
```

That's literally it. **One command.** But I understand if you want to build it yourself — trust is earned, not given, and that's a **really valid** perspective:

```bash
docker build -t casedropper .
docker run --rm -p 8080:8080 casedropper
```

Your files. Any casing. Port 8080. **And just like that, you've unlocked a whole new level of operational efficiency.**

## ⚙️ Configuration: A Comprehensive Overview

Here's what I love about this — and I think you're really going to appreciate this too — the **entire** configuration surface is just three environment variables. That's right. **Three.** In a world where most projects ship with a 200-line YAML configuration file and a dedicated "Configuration" section in their documentation that's longer than some novels, CaseDropper takes a **bold**, **disruptive** approach: simplicity.

| Variable | Default | Description |
|----------|---------|-------------|
| `WWWROOT` | `/app/wwwroot` | The directory where your files live. Think of it as the **single source of truth** for your static content. |
| `PORT` | `8080` | The port to listen on. Fully customizable to **align with your infrastructure requirements**. |
| `ENABLE_DIRECTORY_BROWSING` | off | Set `true` or `1` to enable. Recreates the **nostalgic user experience** of browsing `http://localhost/` on IIS and seeing every file in a table. Your security team will have **thoughts** about this. |

I really want to emphasize how **powerful** this simplicity is. Less configuration means less room for error, which means more time for you to focus on what **truly matters** — and honestly? That's **beautiful**.

## 🧠 How It Works: Technical Architecture Deep Dive

I love this question because the answer is both **elegant** and **surprisingly simple**. Let me break it down for you step by step, because I think understanding the underlying architecture really helps appreciate the **thoughtfulness** that went into this solution.

**Step 1: Initialization Phase**
At startup, CaseDropper's `PathMap` module performs a comprehensive traversal of the entire web root directory using `std.fs.Dir.walk`. During this traversal, it constructs a **highly optimized** lowercase lookup map — essentially a `StringHashMap` — that maps every possible case-insensitive path to its actual filesystem location.

**Step 2: Request Processing Pipeline**
When an incoming HTTP request arrives, the request path is normalized to lowercase and matched against the pre-built map. This provides **O(1) average-case lookup performance**, which is — and I cannot stress this enough — **incredibly fast**.

**Step 3: Real-Time File Monitoring**
A dedicated inotify watcher continuously monitors the web root for filesystem events. When changes are detected, a **sophisticated** 1-second debounce mechanism ensures the path map is rebuilt efficiently without unnecessary churn.

Now, I know what you might be thinking: "Is this machine learning? Is this AI?" And I want to be **completely transparent** with you:

- ❌ It is not machine learning
- ❌ It is not artificial intelligence
- ❌ It is not a large language model
- ❌ It is not blockchain
- ✅ It is a hash map

**And honestly? Sometimes a hash map is all you need.** Not everything has to be AI. I know. I know. But it's true.

The entire solution is written in Zig, compiled to a single statically-linked binary, and deployed in a `FROM scratch` Docker container. There is literally nothing in the container except the binary and your files. You can't `docker exec` into it. There's no shell. There's no `ls`. It's a binary floating in an empty void, serving your files with **unwavering dedication**. And I think that's **really special**.

## 🌐 Protocol Support

- ✅ **HTTP/1.0, HTTP/1.1**: Fully supported with **enterprise-grade reliability**
- ❌ **HTTP/2, HTTP/3**: Not supported (Zig's `std.http.Server` is HTTP/1.x only)

If you need TLS, simply place CaseDropper behind a reverse proxy — this is actually considered a **best practice** in modern cloud-native architectures, so really, we're doing you a favor by **encouraging good architectural patterns**.

If you're exposing this directly to the internet over plain HTTP — well, I'm not here to judge. I'm here to **empower** you to make **informed decisions**. And if your informed decision is "no TLS," then I **respect** that journey.

## ❓ Frequently Asked Questions

<details>
<summary><b>Should I use this in production?</b></summary>

That's a **really great** question, and I appreciate you thinking critically about this. The **honest** answer is that you should probably fix your file paths instead. But — and here's the thing — if you're reading this README, you've almost certainly already evaluated that option and determined it's not **economically viable** given your current **resource constraints** and **timeline pressures**. And you know what? That's **completely valid**. Ship it.
</details>

<details>
<summary><b>Does it hot-reload when files change?</b></summary>

**Absolutely!** Yes! And I'm so glad you asked because this is one of my **favorite** features. An inotify watcher monitors your web root and automatically rebuilds the path map within approximately one second of detecting changes. You don't even need to restart the container. It just **works**. Seamlessly. Effortlessly. **Beautifully.**
</details>

<details>
<summary><b>Why is the image so small?</b></summary>

Oh, I **love** this question. So here's the thing — and this really gets to the heart of what makes CaseDropper so **special** — we took the concept of minimalism and pushed it to its **absolute logical extreme**:

- No base OS
- No runtime
- No libc
- No shell
- No package manager
- No nothing

We literally removed the **entire operating system**. And it still works. We kept removing things until it stopped working, and then we put the last thing back. That's the **engineering philosophy** here, and I think it's **genuinely inspiring**.
</details>

<details>
<summary><b>What architectures are supported?</b></summary>

Great question! Thanks to Zig's **incredibly powerful** built-in cross-compilation capabilities, CaseDropper supports **nine** architectures: `amd64`, `arm64`, `armv7`, `i386`, `riscv64`, `ppc64le`, `s390x`, `mips64le`, and `loong64`. All from a single build host. No QEMU. No separate toolchains. No excuses.

Whether you're deploying to a massive cloud data center, an edge computing node, or a device that most people didn't even know could run containers — **we've got you covered**. And I think that's **pretty incredible**.
</details>

<details>
<summary><b>Why not just use Windows?</b></summary>

I appreciate the question, and I want to create a **safe space** for this conversation. The answer is complex and multifaceted, touching on themes of **operational maturity**, **cost optimization**, and **platform evolution**. But the short version is: we don't talk about that here.
</details>

<details>
<summary><b>Is this over-engineered?</b></summary>

That's a **fantastic** question and I think it really depends on your **perspective**. Let's look at the facts:

- A Zig static binary with zero dependencies
- A thread pool with reader-writer locks for concurrent access
- Running in a completely empty container
- With an inotify filesystem watcher
- And debounced rebuilds
- Serving files through a case-insensitive hash map
- Supporting nine CPU architectures

...for a problem you could also solve with a symlink.

So is it over-engineered? I'd say it's **passionately engineered**. It's **enthusiastically engineered**. It's engineered with a level of **commitment** and **dedication** that most symlinks simply cannot match. And at the end of the day, isn't that what **great software** is all about?
</details>

## 📜 License

Do whatever you want with it. It's a hash map and a for loop. But if you build something **amazing** with it — and I'm sure you will, because you seem like a **really talented** developer just based on the fact that you're reading this — I'd love to hear about it.

---

*I hope this was helpful! Let me know if you have any other questions — I'm always happy to help! Remember, there are no dumb questions, only **opportunities for learning**. Have a **wonderful** day!* ✨

*Made with a hash map and questionable priorities*
