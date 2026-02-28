# Extreme Injector v1 by curelessdoktor

Linux-only application to inject **.so** (shared object) files into running processes — the same idea as Extreme Injector for Windows/DLLs, but for Linux.

## Requirements

- Python 3.10+
- PyQt6
- gcc (to build the injector)
- x86_64 (the bundled injector is x86_64 only)

**Qt / display:** PyQt6 needs the xcb platform plugin. On Debian/Ubuntu install:

```bash
sudo apt install libxcb-cursor0
```

If the app still fails to start, try:

```bash
QT_QPA_PLATFORM=wayland python main.py
```

(or install other libxcb-* packages your distro suggests.)

## Setup

1. **Create a virtualenv and install dependencies:**

   ```bash
   cd extreme_injector
   python3 -m venv .venv
   source .venv/bin/activate   # or .venv\Scripts\activate on Windows (not needed on Linux)
   pip install -r requirements.txt
   ```

2. **Build the injector binary:**

   ```bash
   cd injector
   make
   cd ..
   ```

3. **Ptrace (required for injection):**  
   On many distros, ptrace is restricted. Allow it (until reboot):

   ```bash
   echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope
   ```

## Run

```bash
python main.py
```

Or from the project root:

```bash
python extreme_injector/main.py
```

## Usage

- **Process Name:** Click **Select** to pick a running process, or type a process name or PID.
- **Add SO:** Add one or more `.so` files to the list.
- **Enable/Disable / Remove / Clear:** Manage the list.
- **Inject:** Inject all enabled libraries into the selected process.

The injector binary is expected at `extreme_injector/injector/inject`. Use **Settings** to set a different path.

## License

The GUI is original. The injector is based on the technique from [linux-inject](https://github.com/gaffe23/linux-inject) (ptrace + `__libc_dlopen_mode`). Use responsibly and only on processes you own or are authorized to modify.
