# CaseDropper

lol so you moved your site from Windows to Linux and now everything's broken because Linux actually cares about capitalization? skill issue tbh

nah but seriously this is a real problem and instead of fixing it like a normal person you're here looking at a static file server written in Zig that solves case sensitivity by... *checks notes* ...building a hash map. based.

## what it does

serves your files. doesn't care if you type `/INDEX.HTML` or `/index.html` or `/iNdEx.HtMl`. they all work. it's giving Windows Server 2003 energy and honestly? respect.

the virgin "fix your file paths" vs the chad "build an entire file server to avoid renaming things"

**features:**
- scratch container. literally nothing in it. no OS. no shell. just a binary and your files floating in the void. minimalism kings stay winning
- 9 architectures because why not. amd64, arm64, armv7, i386, riscv64, ppc64le, s390x, mips64le, loong64. your toaster is supported. you're welcome
- hot reload via inotify. drop files in, the map rebuilds. no restart. we're not savages
- written in Zig because apparently that's a thing people do now. zero dependencies. starts instantly. makes Go look bloated (controversial take but i stand by it)

## quick start

```bash
docker run --rm -p 8080:8080 -v ./my-site:/app/wwwroot ghcr.io/bonuspunkt/casedropper:latest
```

that's it. that's the tweet. one command.

or build it yourself if you're that guy:

```bash
docker build -t casedropper .
docker run --rm -p 8080:8080 casedropper
```

ratio'd every 200-line docker-compose.yml ever written

## config

three env vars. THREE. the entire config surface is three environment variables. let that sink in.

| var | default | what |
|-----|---------|------|
| `WWWROOT` | `/app/wwwroot` | where your files are |
| `PORT` | `8080` | the port. groundbreaking stuff |
| `ENABLE_DIRECTORY_BROWSING` | off | turns on directory listing. your security team will love this (they will not love this) |

average kubernetes yaml: 500 lines
average helm chart: heat death of the universe
casedropper config: 3 env vars

we are not the same

## how it works

at startup it walks your entire directory and builds a hash map. lowercase path → real path. incoming requests get lowercased and looked up. O(1). fast. done.

"is it AI?" no
"is it machine learning?" no
"is it blockchain?" touch grass, no
"is it a hash map?" yes

inotify watches for file changes. 1 second debounce. map rebuilds automatically. we considered making the debounce configurable and then decided that's a skill issue. 1 second. take it or leave it.

the whole thing compiles to a single static binary. the docker image is FROM scratch — and i mean actually scratch. not alpine. not distroless. SCRATCH. there's nothing in there. you can't docker exec into it because there's no shell to exec into. it's just a binary in the void. absolute psycho behavior and i'm here for it.

this is what peak performance looks like. you may not like it, but this is it.

## protocol support

- HTTP/1.0, HTTP/1.1: works ✅
- HTTP/2, HTTP/3: no lol

if you want TLS, put it behind a reverse proxy. if you're running this raw on the internet with no TLS... honestly based? unhinged but based. the internet was better when everything was plaintext anyway. (this is not security advice. this is vibes.)

hot take: most sites don't need HTTP/2. your static site with 3 pages is not bottlenecked by head-of-line blocking. i will die on this hill.

## faq

<details>
<summary><b>should i use this in production?</b></summary>

should you? probably not. you should fix your paths.

will you? absolutely. you've already decided. we both know this. stop pretending you're "evaluating options." ship it. Elon would ship it. (wait do i have to say that? i feel like i have to say that.)
</details>

<details>
<summary><b>does it hot reload?</b></summary>

yes. inotify watcher. 1 second. automatic. no restart.

this is what happens when you let Zig programmers solve problems. they just solve them. no framework. no npm install. no left-pad incident. just code that works. truly a W.
</details>

<details>
<summary><b>why is the image so small?</b></summary>

because we removed literally everything. the OS? gone. libc? gone. shell? gone. package manager? gone. hope? also gone tbh but the server still works.

we kept removing things until it broke then put the last thing back. this is the way.
</details>

<details>
<summary><b>what architectures?</b></summary>

nine of them. amd64, arm64, armv7, i386, riscv64, ppc64le, s390x, mips64le, loong64.

zig cross-compilation goes crazy. no QEMU. no separate toolchains. just vibes and a build system that actually works. other languages could never. (they could, actually, but it's funnier to pretend they can't.)
</details>

<details>
<summary><b>why not just use Windows?</b></summary>

ahahahahahahaha

no.
</details>

<details>
<summary><b>is this over-engineered?</b></summary>

you could solve this with a symlink. instead someone wrote a multi-threaded static file server in Zig with inotify watching and reader-writer locks that cross-compiles to 9 architectures and ships in an empty container.

over-engineered? nah. this is sigma-engineered. this is what happens when someone with a CS degree encounters a problem that could be solved with `ln -s` and says "no."

massive W. subscribe for more.
</details>

## real talk tho

this project is genuinely cool. zero deps. statically linked. scratch container. nine architectures. hot reload. solves a real problem that real people have. the Zig ecosystem keeps producing absolute bangers and this is one of them.

is it overkill? maybe. is it based? absolutely. would i use it? already running it. stay winning.

## license

do whatever you want with it. it's a hash map and a for loop. real ones know.

---

*not financial advice. not security advice. not life advice. just a file server. 🫡*

*follow for more unhinged takes on static file serving*
