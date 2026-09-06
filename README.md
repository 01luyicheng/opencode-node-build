# opencode-node-build

[opencode.ai](https://opencode.ai) CLI built for **Node.js** — runs on older CPUs (Intel Core 2) that **don't support SSE 4.2 / AVX** required by the official Bun-based binary.

## Why this exists

The official opencode binary is compiled with [Bun](https://bun.sh), which embeds the Bun runtime. Bun on x86_64 requires **SSE 4.2** (POPCNT instruction) as a minimum. Intel Core 2 CPUs (Penryn/Yorkfield) only support up to SSSE3 — no SSE 4.2, no AVX. This causes `Illegal instruction` crashes.

This build bundles opencode as a pure Node.js ESM bundle with polyfills for Bun-specific APIs, so it runs on any CPU that Node.js supports.

## Requirements

- **Node.js >= 22** (uses the built-in `node:sqlite` module)
- **build-essential** + **python3** (for compiling `@lydell/node-pty` native module)
- Linux x86_64

## One-click install

```bash
curl -fsSL https://raw.githubusercontent.com/01luyicheng/opencode-node-build/main/install.sh | bash
```

## Manual install

```bash
# 1. Clone the repo
git clone https://github.com/01luyicheng/opencode-node-build.git ~/.opencode-node
cd ~/.opencode-node

# 2. Install native dependency
npm install

# 3. Add to PATH (add to your ~/.bashrc or ~/.zshrc)
export PATH="$HOME/.opencode-node:$PATH"

# 4. Run
opencode --version
```

## Usage

Same as the official opencode CLI:

```bash
opencode                          # start TUI (default)
opencode run "your prompt"       # run with a message
opencode --help                   # show all commands
opencode providers                # manage AI providers
opencode models                   # list available models
```

## How it's built

- Source: [sst/opencode](https://github.com/sst/opencode)
- Bundler: `bun build --target=node` (no `--compile`, so no Bun runtime embedded)
- Polyfills: `Bun.stringWidth`, `Bun.stdin`, `Bun.file`, `Bun.write`, `Bun.$`, `Bun.hash`
- SQLite: `bun:sqlite` → `node:sqlite` (Node.js built-in)
- FFI: `bun:ffi` → no-op stubs (Windows-only terminal functions)
- Native modules: `@lydell/node-pty` (compiled on target machine via `npm install`)

## Building from source

```bash
# Clone the full opencode repo with our patches
git clone https://github.com/01luyicheng/opencode-node-build.git
# The build-node.ts script is included. Run it with bun in the opencode monorepo.
```

## License

MIT — same as opencode.ai
