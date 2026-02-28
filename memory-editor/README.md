# Memory Editor

A cross-platform memory editor/scanner application similar to Cheat Engine, built with **Tauri v2**, **React**, **TypeScript**, **Tailwind CSS**, and **shadcn/ui**. Optimized for Linux with support for Windows and macOS.

## Features

- **Process list** – Browse running processes (name + PID), filter, attach to a process
- **Memory scanner** – Scan types: 4/8-byte int, float, double, UTF-8/UTF-16 string, byte array (AoB)
  - Conditions: Exact value, Increased/Decreased/Changed/Unchanged value, Bigger than, Smaller than
  - First scan and Next scan; value input supports hex (`0x`), decimal, and float
- **Address list** – Add addresses from scan results, live-updating values, freeze (lock) values, edit value
- **Memory viewer** – Hex + ASCII view, goto address
- **Pointer scanner** – Simple pointer scan (find pointers to a given address)

## Prerequisites

### Linux

- **Rust**: [rustup](https://rustup.rs/) (`curl --proto '=https' --tlsv1.2 -sSf https://sh.rust-lang.org/install.sh | sh`)
- **Tauri (Linux)**: WebKitGTK and related dev packages, e.g.:
  - **Debian/Ubuntu**: `sudo apt install libwebkit2gtk-4.1-dev libgtk-3-dev librsvg2-dev`
  - **Fedora**: `sudo dnf install webkit2gtk4.1-devel gtk3-devel librsvg2-devel`
  - **Arch**: `sudo pacman -S webkit2gtk-4.1 gtk3 librsvg`
- **Node.js** 18+ and npm

### Permissions (Linux)

- To **attach** to another process and read/write its memory you need either:
  - Run this app as **root**, or
  - Run as the **same user** as the target process and allow ptrace:
    - `echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope`
- Listing processes only needs read access to `/proc`.

### Windows / macOS

Process list and memory read/write are implemented for **Linux only** in this repo. For Windows/macOS you would add platform-specific code (e.g. `windows-sys` / Win32 APIs, or macOS `task_for_pid` / `vm_read`/`vm_write`).

## Build & Run

```bash
cd memory-editor
npm install
npm run tauri dev
```

For a production build:

```bash
npm run tauri build
```

Artifacts will be under `src-tauri/target/release/` (e.g. `.deb`, binary, or platform-specific installer).

## Project structure

```
memory-editor/
├── src/                    # React frontend
│   ├── components/         # ProcessList, Scanner, AddressList, MemoryViewer, ui/
│   ├── hooks/              # useToast
│   ├── lib/                # utils (cn)
│   ├── App.tsx
│   └── main.tsx
├── src-tauri/              # Rust backend
│   ├── src/
│   │   ├── lib.rs          # Tauri commands
│   │   ├── process.rs      # Process list, attach/detach
│   │   ├── memory.rs       # Read/write memory, memory regions
│   │   ├── scanner.rs      # First/next scan logic
│   │   └── main.rs
│   ├── Cargo.toml
│   └── tauri.conf.json
├── package.json
├── tailwind.config.js
└── vite.config.ts
```

## Keyboard shortcuts

- **Ctrl+F** – First scan
- **Ctrl+N** – Next scan

## Security notes

- No auto-attach; user must explicitly select a process and attach.
- On Linux, ptrace and `/proc` access are required; the app shows clear error messages when attach fails (e.g. permission denied, ptrace_scope).
- Use with care: modifying process memory can crash applications or violate terms of use.

## License

MIT.
