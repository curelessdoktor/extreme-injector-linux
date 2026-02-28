# rbxterm — Roblox cheat terminal (Linux)

External, console-style cheat tool for **Sober** (Roblox player) and **Vinegar** (Roblox Studio) on Linux. Works with native and Flatpak. No injection, no LD_PRELOAD, no kernel drivers. Uses `process_vm_readv`/`process_vm_writev` or `/proc/pid/mem` with pread/pwrite.

**Offsets target:** Roblox version ~df7528517c6849f7 (early 2026). Update offsets in `offsets.hpp` if your build differs.

## Build

```bash
cd rbxterm
g++ -std=c++20 -O2 -o rbxterm main.cpp memory_utils.cpp roblox_utils.cpp -pthread
```

Or with clang:

```bash
clang++ -std=c++20 -O2 -o rbxterm main.cpp memory_utils.cpp roblox_utils.cpp -pthread
```

## Run

1. Start **Sober** (player) or **Vinegar** (Studio); join a game or open a place.
2. Run the terminal:
   ```bash
   ./rbxterm
   ```
3. In the prompt, run `attach` or `findroblox` to find and attach (auto-picks largest process). If multiple run, use `list` then `attach <pid>`.
4. Use `help` or `?` for commands.

**Permissions:** Reading/writing another process’s memory usually requires one of:

- Same user and `ptrace_scope` relaxed:
  ```bash
  echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope
  ```
- Or give the binary ptrace capability:
  ```bash
  sudo setcap cap_sys_ptrace+ep ./rbxterm
  ```

## Warnings

- **Use an alt account.** Memory edits can be detected; this is for learning/RE only.
- **Detection risk** exists even with external reads/writes (e.g. WalkSpeed, teleport, noclip).
- Offsets change with Roblox updates; keep `offsets.hpp` in sync with your client version.

## Commands (overview)

| Command | Description |
|--------|-------------|
| `attach` / `findroblox` | Find and attach to Roblox process |
| `detach` | Release process |
| `status` | Show PID, base, DataModel, VisualEngine |
| `getwalkspeed` / `setwalkspeed <f>` | Read/write Humanoid.WalkSpeed |
| `getpos` / `setpos x y z` | Read position / teleport |
| `infjump` | High JumpPower |
| `noclip` | CanCollide = false on character parts |
| `godmode` | MaxHealth/Health very high |
| `fov <float>` | Camera FOV |
| `esp` | List nearby players with distance/health |
| `readinstance <addr> <off>` | Read u64/float at addr+off |
| `writefloat <addr> <value>` | Write float |
| `readstring <addr>` | Read Roblox string object |
| `findchild <parent_addr> <name>` | Find child instance by name |
| `tree <addr> [depth]` | Print instance tree |
| `clear` | Clear screen |
| `help` / `?` | Command list |
| `exit` / `quit` | Exit |

## Layout

- `main.cpp` — Terminal loop, ANSI colors, command dispatch.
- `memory_utils.h` / `memory_utils.cpp` — Process find, attach, read/write (process_vm_* and /proc/pid/mem).
- `roblox_utils.h` / `roblox_utils.cpp` — Pointer chains (FakeDataModel → DataModel), LocalPlayer, Character, Humanoid, children, strings, tree.
- `offsets.hpp` — Roblox offsets (single header).

History is stored in a vector; full up/down navigation would require raw terminal mode (stub in place).
