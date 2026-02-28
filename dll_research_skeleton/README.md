# Legacy Injection Pattern Research Skeleton

**ACADEMIC / RESEARCH USE ONLY.** This project is a minimal C++ DLL skeleton for studying historical (~2018–2022) Windows DLL injection patterns and in-process command triggers. It is **not** intended for real-world deployment, and must **not** be used to inject into protected software, games, or any process without explicit authorization. Doing so violates terms of service and anti-cheat policies and may violate computer misuse laws.

---

## Purpose

- **Document** classic vs modern injection entry points (CreateRemoteThread, manual mapping, APC) with pros/cons for detection research.
- **Provide** a non–chat-based command trigger (in-memory queue) as a low-visibility alternative to legacy chat-event hooks.
- **Implement** a minimal built-in "eval" analog (version, exit, echo only) — no full script engine or game API.
- **Build** as a modern x64 C++20 DLL (MSVC 2022+), with guidance to avoid PDB/path leakage.

No production evasion logic, no game-specific bypasses, no asset/place dumping.

---

## Project Layout

```
dll_research_skeleton/
├── CMakeLists.txt           # Build: x64, C++20, Release-friendly
├── README.md                # This file
├── include/
│   ├── research_disclaimer.h
│   ├── injection_docs.h     # Injection method documentation only
│   ├── command_trigger.h    # Abstract command source + memory queue
│   ├── command_eval.h       # Built-in command evaluation
│   └── string_obfuscation.h # Educational string masking
└── src/
    ├── dll_main.cpp         # DllMain, spawns command loop thread
    ├── injection_stub.cpp   # Placeholder (no actual injection)
    ├── command_trigger.cpp # Queue implementation + RunCommandLoop
    └── command_eval.cpp    # version / exit / echo
```

---

## Build (CMake, x64, Release)

### Prerequisites

- CMake 3.16+
- **On Windows:** MSVC 2022 (or compatible) with C++20, **x64** toolchain.
- **On Linux (cross-compile to Windows DLL):** MinGW-w64 and CMake:
  ```bash
  # Debian/Ubuntu — install x64 MinGW toolchain
  sudo apt install gcc-mingw-w64-x86-64 g++-mingw-w64-x86-64 cmake build-essential
  # Verify: x86_64-w64-mingw32-g++ --version
  ```

### Build on Windows (native MSVC)

```bat
mkdir build
cd build
cmake -G "Visual Studio 17 2022" -A x64 ..
cmake --build . --config Release
```

### Build on Linux (cross-compile → Windows DLL)

**64-bit (x64):** From the project root:

```bash
mkdir build && cd build
cmake -DCMAKE_TOOLCHAIN_FILE=../cmake/toolchain-mingw64.cmake -DCMAKE_BUILD_TYPE=Release ..
cmake --build .
```

**32-bit (x86):** Use a separate build directory and the 32-bit toolchain:

```bash
sudo apt install gcc-mingw-w64-i686 g++-mingw-w64-i686   # if not already installed
mkdir build32 && cd build32
cmake -DCMAKE_TOOLCHAIN_FILE=../cmake/toolchain-mingw32.cmake -DCMAKE_BUILD_TYPE=Release ..
cmake --build .
```

Output: in `build/` (64-bit) or `build32/` (32-bit): `libResearchDll.dll` and `TestHarness.exe`. Copy to a Windows machine to run.

### Reducing PDB / path leakage

- **Release:** Use `--config Release`; do not ship `.pdb` files if you need to avoid path/debug info leakage.
- **Linker:** To omit PDB in Release, you can add to `CMakeLists.txt` for Release only:
  - `target_link_options(ResearchDll PRIVATE $<$<CONFIG:Release>:/LTCG>)` and build with `/DEBUG:NONE` if you want no debug info at all (optional).
- **Paths:** Avoid `__FILE__` or hardcoded paths in logged strings; the skeleton uses no such strings.

### Alternative: vcxproj

Generate a Visual Studio solution from CMake (above), then open the solution and build ResearchDll as x64 Release. Ensure the project is set to **Dynamic Library (.dll)** and **Character Set: Unicode**.

---

## Loading the DLL (for testing only)

This DLL **does not inject itself** into another process. For local research:

1. **Same-process test:** Write a small console app that `LoadLibrary("ResearchDll.dll")`, then use the exported `ResearchPushCommand("echo hello")` and `ResearchRequestStop()` to drive the internal loop. Run only in an environment you control.
2. **Do not** use it as part of a loader that targets protected or third-party processes.

Exports (for test harnesses):

- `void ResearchPushCommand(const char* cmd)` — push a command into the in-memory queue.
- `void ResearchRequestStop()` — signal the command loop to exit.

---

## Injection: documentation only

Actual injection **is not implemented** in this repo. See `include/injection_docs.h` for:

- **Classic (highly monitored):** CreateRemoteThread + LoadLibrary, NtCreateThreadEx, thread context hijacking.
- **Modern (documented for study):** Manual section mapping, APC queuing to alertable threads. Pros/cons are described; no production evasion code is included.

Implementing stealth injection into protected targets is out of scope and would violate this project's intent.

---

## Command trigger (no chat hooks)

**Headless:** No Win32 overlay or GUI is included; the skeleton runs in headless mode (command loop only).

Legacy patterns that hooked in-game chat for script input are now easily detected. This skeleton uses:

- **In-memory queue:** A thread-safe queue inside the process. A test harness (or, in theory, another thread) pushes commands; the DLL's loop polls and evaluates. No chat API, no engine UI hooks.

Other low-visibility options **documented but not implemented**:

- Polling a file or named pipe.
- In-engine alternatives (e.g. invisible UI updated on a frame callback, or a BindableEvent/ValueBase used as a queue) — would require engine-specific code and are not included.

---

## Eval / "loadstring" analog

Only **built-in commands** are implemented: `version`, `exit`, `echo`. There is no generic `eval(arbitrary_string)` or script engine. Extending this to a real interpreter (e.g. Lua) would be done in a separate, controlled context and is not part of this skeleton.

---

## Ethical boundaries

- **Do not** inject this (or any loader using it) into games, anti-cheat, or DRM-protected processes.
- **Do not** use it to develop or distribute cheats or malware.
- Use only in authorized environments (e.g. your own test process, lab, or course) for understanding detection and legacy patterns.

If a requested feature would cross into production evasion or game-specific bypasses, implement only the abstract or documented alternative (e.g. trigger interface without engine hooks, or pseudo-code in comments).

---

## License / disclaimer

This code is provided for **educational and research purposes only**. The authors assume no liability for misuse. You are responsible for compliance with applicable laws and terms of service.
