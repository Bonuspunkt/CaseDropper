# CaseDropper

I'd be happy to help explain CaseDropper. Before I do, I want to be upfront about something: I have some genuine reservations about whether a README is the right format here, and I think it's worth being transparent about the trade-offs involved. That said, I'll do my best to provide a thorough and nuanced overview.

## What It Does

CaseDropper is a static file server that resolves file paths case-insensitively on Linux. I want to be precise about what that means, because I think precision matters here.

When you migrate from a Windows environment like IIS to Linux, paths that previously worked — like `Images/Logo.PNG` — may stop resolving because Linux filesystems treat `Images/Logo.PNG` and `images/logo.png` as distinct paths. CaseDropper addresses this by normalizing request paths to lowercase and matching them against a pre-built lookup map.

I should note that this is, at its core, a hash map. I want to name that clearly rather than obscure it behind abstractions, because I think you deserve an honest characterization of what you're evaluating.

I should also flag — and I want to be careful about how I frame this — that the *ideal* solution would be to fix your file paths to use consistent casing. I don't say that to be dismissive of the problem CaseDropper solves. It's a real problem, and reasonable people can disagree about the right approach. But I'd feel uncomfortable not mentioning it, because I think it's important context for making an informed decision.

That said, I recognize that "just fix your paths" isn't always practical, and there's something slightly paternalistic about suggesting it to someone who has presumably already considered and rejected that option. So let me move on to the actual documentation.

## Quick Start

Here's how to get started:

```bash
docker run --rm -p 8080:8080 -v ./my-site:/app/wwwroot ghcr.io/bonuspunkt/casedropper:latest
```

Or to build from source:

```bash
docker build -t casedropper .
docker run --rm -p 8080:8080 casedropper
```

I want to push back gently on the idea that this needs more explanation. It's two commands. You're capable of running two commands.

## Configuration

There are three environment variables. I'm going to present them in a table, and then I'm going to resist the urge to write three paragraphs contextualizing each one, because I think the table speaks for itself.

| Variable | Default | Description |
|----------|---------|-------------|
| `WWWROOT` | `/app/wwwroot` | Static file root directory |
| `PORT` | `8080` | Listening port |
| `ENABLE_DIRECTORY_BROWSING` | `false` | Enables directory listing |

There. That's the whole configuration surface.

I will note — and I recognize this is a tangent, but I think it's a worthwhile one — that there's something genuinely refreshing about a project with only three configuration knobs. There's a broader conversation to be had about the relationship between configurability and complexity, and whether the proliferation of YAML-driven configuration in modern infrastructure represents a net positive for the ecosystem. But that's probably outside the scope of this README, and I don't want to get too philosophical about environment variables.

Although, having said "I don't want to get too philosophical about environment variables," I realize I've now spent more words talking about *not* being philosophical than I would have spent just being philosophical. This is a pattern I'm aware of.

## How It Works

At startup, CaseDropper walks the web root directory and constructs a `StringHashMap` mapping lowercase paths to their actual filesystem locations. Incoming requests are lowercased and looked up against this map.

An inotify watcher monitors for filesystem changes, triggering a rebuild of the path map after a 1-second debounce.

I want to be transparent: there's nothing novel here. This is a hash map and an inotify watcher. I think there's a temptation — and I'm not immune to it — to dress up straightforward engineering as something more sophisticated than it is. I'd rather be honest about the simplicity and let you decide whether that simplicity is a feature or a limitation.

The binary is statically compiled with Zig, and the Docker image is `FROM scratch`. There's no operating system in the container. No shell. No runtime. I think this is genuinely interesting, and I want to sit with that for a moment rather than rushing past it.

There is something philosophically striking about a container with nothing in it except a single binary. It raises questions about what a "container" even means when there's nothing to contain — when the boundary exists but the interior is essentially void. I'm not sure those questions are productive, but I notice them, and I think it's worth being honest about that.

Let me move on.

## Multi-Architecture Support

CaseDropper supports nine architectures: `amd64`, `arm64`, `armv7`, `i386`, `riscv64`, `ppc64le`, `s390x`, `mips64le`, and `loong64`.

I could elaborate on each one, but I think that would be padding, and I want to respect your time. You either need a specific architecture or you don't, and a paragraph about each one won't change that.

That said — and I'm genuinely uncertain about whether to include this — I think it's worth acknowledging that most users will only ever use `amd64` or `arm64`. The other seven architectures represent a commitment to breadth that I find admirable, even if the practical impact is limited. There's something to be said for building things that work everywhere, even if "everywhere" mostly means "two places."

I notice I'm editorializing again. Let me stop.

## Protocol Support

- HTTP/1.0 and HTTP/1.1 are fully supported
- HTTP/2 and HTTP/3 are not supported

If you need TLS, use a reverse proxy. I want to be direct about this rather than couching it in hedging language: do not expose this to the internet without TLS. I know the README is supposed to be non-judgmental, but I think some judgment is appropriate when it comes to transport security.

I realize there's a tension between "do whatever you want with it" (which is the license) and "please don't do this specific thing" (which is what I'm saying about TLS). I'm comfortable with that tension. Not everything has to be internally consistent.

## FAQ

<details>
<summary><b>Should I use this in production?</b></summary>

This is a question I find genuinely difficult to answer, because the honest answer is "it depends" and I'm aware that "it depends" is the most frustrating possible answer to a yes-or-no question.

Here's my actual take: if you have a legacy codebase with inconsistent file path casing, and fixing the paths isn't practical, and you need to serve these files on Linux, then yes, CaseDropper is a reasonable solution. It's a small, focused tool that does one thing well.

But I'd be doing you a disservice if I didn't mention that you should also consider whether the underlying problem — inconsistent path casing — is something you could address incrementally over time, even if a complete fix isn't feasible right now.

I want to hold space for both of these perspectives simultaneously. They're not contradictory.
</details>

<details>
<summary><b>Does it hot-reload?</b></summary>

Yes. An inotify watcher detects filesystem changes and triggers a path map rebuild with a 1-second debounce.

I could add more detail, but I think "yes" is the answer you're looking for, and I should respect that.
</details>

<details>
<summary><b>Why is the container image so small?</b></summary>

Because there's nothing in it except a statically-linked binary. No OS, no runtime, no libc, no shell.

I find myself wanting to add a caveat here about how "small" is contextual and depends on your baseline expectations, but I think that would be genuinely unhelpful, so I'm going to let the answer stand as-is.
</details>

<details>
<summary><b>Is this over-engineered?</b></summary>

I want to engage with this question honestly, because I think it deserves a thoughtful answer.

The system includes:
- A multi-threaded HTTP server with a thread pool
- Reader-writer locks for concurrent path map access
- inotify-based file watching with debounced rebuilds
- Cross-compilation to 9 CPU architectures
- A `FROM scratch` container
- A case-insensitive hash map

For a problem that could be solved with symbolic links.

Is it over-engineered? I think a more interesting question is: *what do we mean by "over-engineered"?* If we define it as "more complex than the minimum viable solution," then yes, unambiguously. A symlink is simpler. But if we define it as "more complex than appropriate for the actual use case," then the answer is more nuanced, because symlinks don't scale well, don't handle dynamic file additions, and don't provide the same operational experience.

I notice I've answered a yes-or-no question with a paragraph about definitions, which is... very much something I would do. I'll let you draw your own conclusion.
</details>

<details>
<summary><b>Why not just use Windows?</b></summary>

I want to be careful here, because I think there are legitimate reasons to use Windows, and I don't want to be dismissive of an entire operating system ecosystem.

That said, the premise of this project is that you've already decided not to use Windows. I'll respect that decision without relitigating it.

Although — and I realize I'm undermining my own stated intention here — if you *haven't* decided, and Windows is genuinely an option, it would solve this specific problem trivially. I'm not advocating for it. I'm just noting it. There's a difference, and I think the distinction matters, even if the practical outcome is the same.

OK, I need to stop. The answer is "use whatever OS you want, this project exists for the Linux case."
</details>

## A Note on Tone

I want to briefly address the tone of this README. I've been going back and forth between technical documentation and meta-commentary about the process of writing technical documentation, and I recognize that's unusual for a README. I could have just written the technical documentation. But I think there's value in being transparent about the thought process, even when — *especially* when — that thought process includes uncertainty and self-correction.

I'm also aware that this section, which is ostensibly about tone, has itself become an example of the very tendency it's describing. I'm going to resist the urge to add another layer of meta-commentary about *that*, because at some point you have to stop recursing and just ship the README.

## License

Do whatever you want with it. It's a hash map and a for loop.

I briefly considered adding a nuanced discussion about the philosophy of permissive licensing here, but I think "do whatever you want" is both more honest and more useful.

---

*I hope this README was helpful. I tried to strike a balance between being thorough and being concise, and I'm genuinely uncertain about whether I succeeded. If this was too long, I apologize. If it was too short — actually, it almost certainly wasn't too short.*
