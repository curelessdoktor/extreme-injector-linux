# Unity Mono Lab — Educational Reverse Engineering Skeleton

**Strictly for offline, single-player analysis in a controlled VM.** Historical technique reconstruction for studying DLL injection and runtime modification in legacy Unity Mono games (early 2010s, 64-bit, no anti-cheat). No multiplayer, no ToS violations.

## Target

- Hypothetical 64-bit Unity Mono game (e.g. simple indie horror).
- No anti-cheat; DX11 renderer.

## Features

1. **Manual mapping–friendly DLL**
   - Minimal `DllMain` (no `LoadLibrary`-style work in the loader path).
   - Real initialization on a background thread (avoids loader lock, reduces signature surface).

2. **ImGui overlay (DX11 Present hook)**
   - Mod menu: **God Mode**, **Speed Hack x2**, **No Clip**, **ESP Toggle**.
   - Hotkey: **Insert** to show/hide.
   - Generic “Demo Mod Menu” styling.

3. **Code executor / REPL**
   - Text input for short C# / Mono snippets.
   - Execute button → dynamic evaluation via Mono bridge (stub + educational notes).
   - Command history, Clear, output console (pcall-style success/error).

4. **Memory manipulation (educational offsets)**
   - Player health → 9999 (god mode).
   - Movement speed multiplier.
   - Position (noclip/teleport) via input fields.
   - All offsets are placeholders; replace with RE-derived values.

## Technical

- **Build:** x64 C++, MSVC 2022+, static CRT (`/MT`), CMake.
- **Stack:** ImGui + DirectX 11 hook (MinHook on `IDXGISwapChain::Present`).
- **Mono:** Detection / domain attachment example (commented, educational).
- **Strings:** XOR encryption for literals (see `include/string_encrypt.hpp`).
- **Process/modules:** Generic module enumeration; no hardcoded process names.

## Project layout

```
unity_mono_lab/
├── CMakeLists.txt
├── README.md
├── include/
│   ├── common.hpp
│   ├── hook_dx11.hpp
│   ├── memory_patches.hpp
│   ├── mono_bridge.hpp
│   ├── module_enum.hpp
│   ├── overlay_menu.hpp
│   └── string_encrypt.hpp
└── src/
    ├── dll_main.cpp      # DllMain + background thread, ImGui init in Present
    ├── hook_dx11.cpp     # MinHook on Present
    ├── overlay_menu.cpp  # ImGui mod menu + code executor UI
    ├── mono_bridge.cpp   # Mono module find + eval stub
    ├── memory_patches.cpp
    └── module_enum.cpp
```

## Build (Windows, x64, MSVC)

```bash
cd unity_mono_lab
cmake -B build -G "Visual Studio 17 2022" -A x64
cmake --build build --config Release
```

Output: `build/Release/UnityMonoLab.dll`.

### Cross-compile from Linux (MinGW-w64)

To build the Windows DLL on a Linux host (e.g. you’re on Linux, target is a Windows VM):

```bash
cd unity_mono_lab
cmake -B build-win -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_TOOLCHAIN_FILE="$(pwd)/cmake/linux-mingw-w64-x64.cmake"
cmake --build build-win
```

Requires: `g++-mingw-w64-x86-64`, `mingw-w64-x86-64-dev`. Output: `build-win/libUnityMonoLab.dll` (and a copy at `UnityMonoLab.dll` in the project root if you ran the copy step).

Use **static CRT** so the DLL is more manual-mapping friendly; CMake sets `MSVC_RUNTIME_LIBRARY` accordingly.

## Usage (educational only)

1. Run your **offline** Unity Mono target in a controlled VM.
2. Inject `UnityMonoLab.dll` via your chosen method (e.g. test harness with `LoadLibrary`, or a manual mapper).
3. Press **Insert** to open the overlay.
4. Toggle mods; use the code executor with the Mono stub (see comments in `mono_bridge.cpp` for extending to real `mono_compile_string` / `mono_runtime_invoke`).
5. Set `MemoryPatches_SetBase` and RE-derived offsets for your target (see `memory_patches.hpp` / `.cpp`).

## Disclaimer

For **education and historical technique study only**, in an environment you control. Do not use on live games, multiplayer, or in ways that violate ToS or law.
