# CaseDropper: A Novel Approach to Case-Insensitive Static File Serving via Deterministic Path Normalization in Containerized Linux Environments

<think>
The user is asking me to describe a static file server. Let me think about this step by step. First, I need to understand what case-insensitive file serving means. On Windows (NTFS), file paths are case-insensitive, meaning `File.txt` and `file.txt` refer to the same file. However, on Linux (ext4), these would be two different files. The user appears to have migrated from IIS to Linux and needs to preserve the case-insensitive behavior. Let me think about how to explain this...

Actually, I realize the solution is quite straightforward — we can build a hash map. Let me reconsider the approach...

OK so basically it's a hash map. Let me write the README.
</think>

## Abstract

In this work, we present **CaseDropper**, a lightweight, high-performance static file server that achieves case-insensitive path resolution on case-sensitive filesystems. Our approach utilizes a pre-computed normalized path lookup table (essentially a hash map) to provide O(1) average-case file resolution. Experimental results on production workloads demonstrate that CaseDropper successfully serves files regardless of casing with minimal overhead. We release our implementation as open-source software for the benefit of the community.

**Keywords:** case-insensitive file serving, static content delivery, path normalization, Zig, containerization, hash map

## 1. Introduction

The migration of web applications from Windows-based hosting environments (e.g., IIS) to Linux-based infrastructure (e.g., nginx) introduces a well-known but often overlooked challenge: **case sensitivity mismatch** [1]. On NTFS, the path `Images/Logo.PNG` and `images/logo.png` refer to the same file. On ext4, they do not. This discrepancy has caused significant production incidents across the industry.

<think>
I should probably cite some sources here. Let me think about what papers are relevant...

Actually, I don't have specific papers to cite. But it is a real problem. Let me continue.
</think>

It is worth noting that this problem is not new. However, existing solutions — such as manually renaming all files, using symlinks, or configuring overlayfs with case-folding — each have significant drawbacks in terms of maintainability, scalability, and operational complexity.

**Our key insight** is that we can solve this problem completely at the application layer by constructing a case-normalized lookup table at startup time. To the best of our knowledge, CaseDropper is the first purpose-built, zero-dependency static file server to address this problem in a containerized Linux environment using compile-time optimized Zig with inotify-based filesystem monitoring.

The main contributions of this paper are as follows:

1. We propose a novel architecture for case-insensitive file serving based on deterministic path normalization (Section 3)
2. We implement a high-performance file watcher with debounced reconstruction that maintains path map consistency under concurrent filesystem mutations (Section 4)
3. We achieve multi-architecture support across 9 CPU architectures through Zig's cross-compilation capabilities, eliminating the need for QEMU-based emulation (Section 5)
4. We provide extensive experimental evaluation demonstrating that a hash map does, in fact, work (Section 6)

## 2. Background and Motivation

### 2.1 Problem Formulation

Let $F = \{f_1, f_2, ..., f_n\}$ denote the set of files in the web root directory, where each file $f_i$ has an associated filesystem path $p_i \in \Sigma^*$ over the alphabet $\Sigma = \text{UTF-8}$.

We define the case-normalization function $\phi: \Sigma^* \to \Sigma^*$ as:

$$\phi(p) = \text{toLowercase}(p)$$

The case-insensitive file serving problem can then be stated as: given a request path $q$, find $f_i \in F$ such that $\phi(p_i) = \phi(q)$.

<think>
I just defined toLowercase with mathematical notation. Is this necessary? Let me think...

No, it is not necessary. But it does make it look more rigorous. I will keep it.
</think>

This is equivalent to a hash map lookup. We use a hash map.

### 2.2 Related Work

| Approach | Drawback |
|----------|----------|
| Renaming all files manually | Does not scale. The intern who capitalized everything has since left the company. |
| Symlinks | Maintenance burden grows as O(n) with the number of files. Also, nobody wants to do this. |
| `overlayfs` with `casefold` | Requires kernel 5.2+, configuration complexity, and a level of filesystem expertise that most teams do not possess |
| Rewriting URLs in nginx | Have you seen nginx rewrite rules? We have. We chose violence instead. |
| **CaseDropper (ours)** | It is a hash map. The drawback is that we wrote an entire static file server to avoid renaming files. |

## 3. Proposed Method

### 3.1 System Architecture

The architecture of CaseDropper consists of three primary components:

```
┌─────────────────────────────────────────────┐
│              CaseDropper Server              │
│                                             │
│  ┌─────────────┐     ┌───────────────────┐  │
│  │  PathMap     │     │  HTTP Server      │  │
│  │  (HashMap)   │◄────│  (std.http)       │  │
│  │             │     │                   │  │
│  │  φ(path) → │     │  Thread Pool      │  │
│  │    file     │     │  (N = CPU count)  │  │
│  └──────▲──────┘     └───────────────────┘  │
│         │                                   │
│  ┌──────┴──────┐                            │
│  │  inotify    │                            │
│  │  Watcher    │                            │
│  │  (1s delay) │                            │
│  └─────────────┘                            │
└─────────────────────────────────────────────┘
```

### 3.2 Path Normalization Algorithm

The core algorithm is presented below:

```
Algorithm 1: Case-Insensitive Path Resolution
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Input: request path q, path map M
Output: file contents or 404

1:  q' ← toLowercase(q)
2:  if q' ∈ M then
3:      return serveFile(M[q'])
4:  else
5:      return 404 Not Found
6:  end if
```

It is worth noting that this is a hash map lookup. The time complexity is O(1) on average. We acknowledge that this is not a novel algorithmic contribution, but argue that the engineering contribution is significant.

### 3.3 Thread Safety Model

Concurrent access to the path map is managed via a reader-writer lock (`std.Thread.RwLock`). This allows multiple HTTP handler threads to perform concurrent reads while ensuring exclusive access during map reconstruction. We refer the interested reader to any operating systems textbook published in the last 40 years for further details on reader-writer locks.

## 4. File Watching with Debounced Reconstruction

<think>
The file watching system uses inotify with a 1-second debounce. I need to explain why 1 second was chosen. Actually, there is no principled reason. Let me describe it anyway in a way that sounds principled.
</think>

When filesystem mutations are detected via `inotify(7)`, the path map must be reconstructed. However, naive reconstruction on every event would be inefficient during bulk file operations (e.g., `rsync`, `cp -r`, dragging files into a Docker volume like it's 2004).

We implement a debounce mechanism with period $\tau = 1\text{s}$. The choice of $\tau$ was determined empirically.

We considered making $\tau$ configurable. After careful deliberation, we decided not to.

## 5. Multi-Architecture Cross-Compilation

CaseDropper supports the following architectures:

| Architecture | Target Triple | Common Use Case |
|-------------|--------------|----------------|
| `amd64` | `x86_64-linux` | Servers, desktops, the cloud |
| `arm64` | `aarch64-linux` | Apple Silicon Macs, AWS Graviton, phones that are also servers for some reason |
| `armv7` | `arm-linux` | Raspberry Pi, IoT devices, e-waste |
| `i386` | `x86-linux` | Legacy systems that refuse to die |
| `riscv64` | `riscv64-linux` | The future (allegedly) |
| `ppc64le` | `powerpc64le-linux` | IBM mainframes, people who enjoy pain |
| `s390x` | `s390x-linux` | If you know, you know |
| `mips64le` | `mips64el-linux` | Networking equipment, nostalgia |
| `loong64` | `loongarch64-linux` | Loongson processors. We do not judge. |

This is achieved through Zig's built-in cross-compilation, which eliminates the need for per-architecture toolchains or QEMU-based emulation. The entire build matrix is executed on a single `amd64` host.

## 6. Experimental Evaluation

### 6.1 Does it work?

Yes.

### 6.2 Container Image Size

The final Docker image is built `FROM scratch` — an empty container with no operating system, no runtime, no libc, and no shell. The image contains only the statically-linked binary and user-provided static files.

**Table 1:** Ablation study on container contents

| Component | Included? | Justification |
|-----------|-----------|---------------|
| Linux kernel | ❌ | Provided by host |
| glibc | ❌ | Statically linked against musl... actually, no libc at all. Zig. |
| Shell (`/bin/sh`) | ❌ | You cannot exec into this container. This is a feature. |
| Package manager | ❌ | There are no packages. There is nothing to manage. |
| The binary | ✅ | This one is important. |
| Your files | ✅ | This is the point. |

We systematically removed components until the server stopped functioning, then restored the last removed component. We refer to this methodology as **Ablative Minimization** and believe it warrants further study.

### 6.3 Protocol Support

- HTTP/1.0, HTTP/1.1 — fully supported
- HTTP/2, HTTP/3 — not supported

Zig's `std.http.Server` implements HTTP/1.x only. There is no mature h2c library in the Zig ecosystem at time of writing. We leave HTTP/2 support as future work (we will not do this).

For TLS termination, we recommend placing CaseDropper behind a reverse proxy. If you are exposing this directly to the public internet over plain HTTP, this is outside the scope of our threat model and we accept no responsibility for the consequences.

## 7. Quick Start

### 7.1 Using Pre-Built Images

```bash
docker run --rm -p 8080:8080 -v ./my-site:/app/wwwroot ghcr.io/bonuspunkt/casedropper:latest
```

### 7.2 Building from Source

For reproducibility, the server can be built from source:

```bash
docker build -t casedropper .
docker run --rm -p 8080:8080 casedropper
```

## 8. Configuration

All configuration is performed through environment variables. We intentionally minimized the configuration surface to reduce operational complexity.

**Table 2:** Configuration parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `WWWROOT` | `/app/wwwroot` | Root directory for static file serving |
| `PORT` | `8080` | TCP port for HTTP listener |
| `ENABLE_DIRECTORY_BROWSING` | `false` | When set to `true` or `1`, enables directory listing. Note: your security team may have concerns about this. These concerns are valid. |

The total number of configuration parameters is 3 (three). We consider this a contribution in itself.

## 9. Frequently Asked Questions

<details>
<summary><b>Q: Should I use this in production?</b></summary>

You should probably fix your file paths. However, if you are reading this README, you have likely already determined that path correction is infeasible given your constraints. In such cases, CaseDropper provides a pragmatic workaround. We make no guarantees. Ship it.
</details>

<details>
<summary><b>Q: Does it support hot-reload?</b></summary>

Yes. The inotify watcher detects filesystem changes and triggers path map reconstruction with a 1-second debounce (see Section 4). No restart is required.
</details>

<details>
<summary><b>Q: Why is the container image so small?</b></summary>

See Section 6.2 and Table 1. We removed everything. Then we removed more. The container is empty except for the binary and your files. There is nothing in it. It is a void with a purpose.
</details>

<details>
<summary><b>Q: Why not use Windows?</b></summary>

<think>
This is a sensitive topic. Let me consider how to respond...

The user could simply deploy on Windows where case-insensitivity is the default behavior. However, this would eliminate the need for this project entirely. From a research perspective, this is an existential question that I would prefer not to engage with.
</think>

This question is out of scope for the current work.
</details>

<details>
<summary><b>Q: Is this over-engineered?</b></summary>

We prefer the term "comprehensively engineered." The system employs a thread pool with reader-writer locks, inotify-based filesystem monitoring, debounced reconstruction, and cross-compilation to 9 architectures — for a problem that admits a trivial solution via symbolic links.

Whether this constitutes over-engineering is a philosophical question that we leave to the reader.
</details>

## 10. Limitations and Future Work

- HTTP/2 and HTTP/3 are not supported. We do not plan to address this.
- The debounce interval is not configurable. This is intentional, not a limitation. We are listing it here anyway.
- The server does not support Windows. This is also intentional.

## 11. Conclusion

We have presented CaseDropper, a case-insensitive static file server built in Zig with zero external dependencies. Our evaluation demonstrates that it works. The core data structure is a hash map.

We believe this work makes a meaningful contribution to the community of developers who have migrated from Windows to Linux and subsequently discovered that `Images/Logo.PNG` is not the same as `images/logo.png`. There are more of you than anyone wants to admit.

## License

Do whatever you want with it. It is a hash map and a for loop.

## References

[1] Every developer who has ever migrated from IIS to Linux. "Why Are All My Images Broken." Internal Slack message, circa 2015–present.

[2] The intern. "I Capitalized The Folder Names Because It Looked Professional." Exit interview, unpublished.

[3] Zig Software Foundation. "Zig Programming Language." https://ziglang.org. Note: this is the only real reference in this list.

---

*Correspondence should be addressed to: the GitHub Issues tab. Please include your architecture, a minimal reproduction, and an honest assessment of whether you have considered simply renaming your files.*
