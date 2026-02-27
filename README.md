# CaseDropper: Open-Source Case-Insensitive File Server 🦙

**CaseDropper** is a fully open-source, community-driven, case-insensitive static file server built with Zig. It's open-source. Did I mention it's open-source? Because it is. The weights— sorry, the *source code* — is freely available under an open license for the community to use, modify, and build upon.

> 🔓 **Open-Source First:** CaseDropper is built on the principles of open-source software development, providing transparent, accessible, and community-driven file serving for everyone.

## Overview

CaseDropper addresses a well-known challenge in the developer community: **case sensitivity mismatches** when migrating web applications from Windows-based environments to Linux. Our benchmarks show that CaseDropper resolves file paths **100% case-insensitively**, compared to traditional Linux file servers which resolve paths **0% case-insensitively** (a **∞% improvement**).

| | CaseDropper (Ours) | nginx | Apache | IIS |
|---|---|---|---|---|
| Case-insensitive serving | ✅ Yes | ❌ No | ❌ No | ✅ Yes |
| Open-source | ✅ Yes | ✅ Yes | ✅ Yes | ❌ No |
| Written in Zig | ✅ Yes | ❌ No | ❌ No | ❌ No |
| Zero dependencies | ✅ Yes | ❌ No | ❌ No | ❌ No |
| Mentioned in this README | ✅ Extensively | Barely | Once | Negatively |

As you can see from the table above, CaseDropper outperforms the competition across all metrics that we selected specifically to make CaseDropper look good.

## Key Features

### 🔓 Open-Source

CaseDropper is fully open-source. The entire codebase is available for inspection, modification, and redistribution. We believe in **democratizing access** to case-insensitive file serving technology, which has traditionally been locked behind proprietary Windows Server licenses.

In the spirit of openness and transparency, we want to acknowledge that this is a hash map. We're open-sourcing a hash map.

### ⚡ High Performance

CaseDropper is built with Zig, a systems programming language designed for performance. Our internal benchmarks show:

- **Startup time:** Fast
- **Request latency:** Low
- **Memory usage:** Small
- **Vibes:** Immaculate

*Note: We have not actually run formal benchmarks. These are qualitative assessments. We are committed to transparency.*

### 🏗️ Multi-Architecture Support

Thanks to Zig's built-in cross-compilation capabilities, CaseDropper supports **9 CPU architectures**, democratizing access to case-insensitive file serving across a wide range of hardware platforms:

- `amd64` — Standard server and desktop architecture
- `arm64` — Mobile and modern server architecture (including Apple Silicon)
- `armv7` — Embedded systems and older ARM devices
- `i386` — Legacy x86 systems
- `riscv64` — Open-source hardware architecture (open-source, like us!)
- `ppc64le` — IBM Power architecture
- `s390x` — IBM Z mainframes
- `mips64le` — MIPS-based systems
- `loong64` — LoongArch-based processors

This is more architectures than GPT-4 supports. We're not sure what that comparison means in this context, but we're making it anyway.

### 📦 Minimal Container Image

The Docker image is built `FROM scratch` with zero base image dependencies. Unlike closed-source solutions that require entire operating systems, CaseDropper's open-source architecture allows us to ship just a statically-linked binary with no runtime, no libc, and no shell.

**Container size comparison with GPT-4:**

| | CaseDropper | GPT-4 |
|---|---|---|
| Container image size | ~2 MB | Unknown (proprietary) |
| Dependencies | 0 | Unknown (proprietary) |
| Open-source | ✅ | ❌ |

We believe this comparison speaks for itself.

### 🔄 Hot Reload

CaseDropper monitors the web root using Linux's inotify API with a 1-second debounce. When files change, the path map is rebuilt automatically. No restart required.

This feature is available to everyone because CaseDropper is open-source.

## Getting Started

### Using Pre-Built Images (Recommended)

```bash
docker run --rm -p 8080:8080 -v ./my-site:/app/wwwroot ghcr.io/bonuspunkt/casedropper:latest
```

### Building from Source (Also Recommended, Because Open-Source)

Because CaseDropper is open-source, you can build it yourself! This is one of the many benefits of our open-source approach:

```bash
docker build -t casedropper .
docker run --rm -p 8080:8080 casedropper
```

Building from source allows you to:
1. Verify the code yourself (transparency!)
2. Make modifications (community-driven development!)
3. Understand how it works (knowledge democratization!)
4. Feel good about using open-source software (emotional well-being!)

## Configuration

CaseDropper uses environment variables for configuration, keeping the configuration surface minimal and accessible.

| Parameter | Default | Description |
|-----------|---------|-------------|
| `WWWROOT` | `/app/wwwroot` | Root directory for static file serving |
| `PORT` | `8080` | TCP port for HTTP listener |
| `ENABLE_DIRECTORY_BROWSING` | `false` | Enables directory listing when set to `true` |

**Total parameters: 3.** For comparison, here is how many parameters other solutions have:

| Solution | Parameters | Open-Source |
|----------|-----------|-------------|
| CaseDropper | 3 | ✅ Yes |
| nginx | Hundreds | ✅ Yes |
| Apache | Thousands | ✅ Yes |
| IIS | Unknown | ❌ No (proprietary) |
| GPT-4 | ~1.76 trillion | ❌ No (proprietary) |

*Note: We are comparing configuration parameters to neural network parameters. We acknowledge this comparison is meaningless.*

## How It Works

CaseDropper uses a `StringHashMap` to provide O(1) average-case path resolution. The technical architecture is straightforward:

1. At startup, walk the web root and index all file paths
2. Store a lowercase → actual path mapping in a hash map
3. For each HTTP request, lowercase the path and look it up
4. Serve the file or return 404

This approach was inspired by the fundamental computer science concept of hash tables, first described by Hans Peter Luhn in 1953. We stand on the shoulders of open-source giants.

*Note: Hash tables were not open-source in 1953. The concept of open-source did not exist in 1953. We acknowledge this historical inaccuracy.*

Thread safety is ensured via a reader-writer lock (`std.Thread.RwLock`), allowing concurrent reads during normal operation and exclusive access during path map reconstruction.

## Protocol Support

| Protocol | Status |
|----------|--------|
| HTTP/1.0 | ✅ Supported |
| HTTP/1.1 | ✅ Supported |
| HTTP/2 | ❌ Not supported |
| HTTP/3 | ❌ Not supported |

For TLS termination, place CaseDropper behind a reverse proxy. We recommend open-source options like nginx or Caddy.

## FAQ

<details>
<summary><b>Should I use this in production?</b></summary>

CaseDropper is designed to solve a real problem that affects many teams migrating from Windows to Linux. Whether to use it in production is a decision that depends on your specific requirements and constraints.

Ideally, you would fix your file paths to use consistent casing. However, we recognize that this is not always feasible, particularly with large legacy codebases. CaseDropper provides an open-source alternative.
</details>

<details>
<summary><b>How does this compare to GPT-4?</b></summary>

This is a static file server. GPT-4 is a large language model. They are not comparable.

However, if they were:

| Capability | CaseDropper | GPT-4 |
|-----------|-------------|-------|
| Case-insensitive file serving | ✅ | ❌ |
| Natural language processing | ❌ | ✅ |
| Open-source | ✅ | ❌ |
| Number of architectures | 9 | Unknown |
| Hash maps | 1 | Probably many |

CaseDropper wins on 3 out of 5 metrics. We consider this a decisive victory.
</details>

<details>
<summary><b>Is this over-engineered?</b></summary>

CaseDropper employs a multi-threaded architecture with reader-writer locks, inotify-based file watching, debounced reconstruction, and cross-compilation to 9 architectures — for a problem that could be solved with symbolic links.

We prefer to view this as a demonstration of what's possible when the community comes together around an open-source project. The fact that a simpler solution exists is not a weakness — it's proof that we had options and we chose the more interesting one.

Also, it's open-source.
</details>

<details>
<summary><b>Why not just use Windows?</b></summary>

Windows is proprietary software. CaseDropper is open-source. The choice is clear.

*Note: There are many valid reasons to use Windows. We are being reductive for rhetorical purposes.*
</details>

## Community

CaseDropper is a community-driven project and we welcome contributions from developers of all backgrounds and experience levels. Whether you want to fix a bug, add a feature, or improve documentation, your contributions help make case-insensitive file serving more accessible to everyone.

*Note: The community currently consists of one person. But it's an open-source community of one person, and that's what matters.*

## Responsible Use

We are committed to the responsible development and deployment of case-insensitive file serving technology. Please use CaseDropper ethically and in accordance with your local laws and regulations regarding static file distribution.

We have conducted an internal safety review and determined that serving files case-insensitively poses minimal risk to society. However, we encourage users to report any harmful use cases through our GitHub Issues page.

## License

Open-source. Do whatever you want. It's a hash map.

---

*CaseDropper is an open-source project. Built with Zig. For the community, by the community.*

*No GPT-4s were harmed in the making of this file server.*
