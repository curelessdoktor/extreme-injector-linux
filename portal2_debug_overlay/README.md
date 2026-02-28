## Aperture Overlay Link (Portal 2 • Linux Mint)

**Aperture Overlay Link** is a sleek, dark‑mode Linux Mint desktop companion for Portal 2.
It gives you a minimalist, glass‑inspired control surface with a smooth attach flow and
modern toggle controls for in‑game visual debug overlays.

> Important: This project is intended for **local, single‑player testing** by mappers/modders.
> It must not be used to gain unfair advantages in online or competitive play.

### What it does today

- **Pure dark UI** with rounded, glass‑inspired panels and soft contrast
- **“Attach to Portal 2”** button that scans for the Portal 2 Linux process and shows status
- **Overlay toggles** that write state to **overlay_state.json** and broadcast over **overlay.ipc** (Unix socket)
- **Overlay drawer** (`overlay_drawer.py`): a separate window that **reads toggles** (from the JSON file or by connecting to the IPC socket) and **draws debug layers in real time** (entity names, boxes, trigger volumes, portal surfaces, etc.) using mock data. Full chain: **Controller checkbox → state file / IPC → overlay drawer turns layers on/off.**

### Overlay drawer (mod side)

The **overlay drawer** is the “mod” that:

1. **Gets game data** — Currently uses **mock** entities/positions/names (so you can see the pipeline without a Source plugin). To draw real in-game data you’d add a Source-engine mod that exports entity positions, or another data source.
2. **Draws it** — Renders outlines, text, and boxes for each layer (entity names, highlight interactives, trigger volumes, portal paths, etc.).
3. **Reads your toggles** — Either **polls overlay_state.json** or **connects to overlay.ipc** and receives state updates in real time, then turns layers on/off.

**Run the overlay drawer** (in a second terminal, with the controller running so state is being written):

```bash
cd /home/doktordestrukt/Desktop/Execute/portal2_debug_overlay
source .venv/bin/activate
python overlay_drawer.py
```

Toggle layers in the **Aperture Overlay Link** window; the overlay drawer window updates immediately (via IPC if the controller is running, else via file polling).

### Real game data: VScript + log parser + overlay renderer

To use **live data from Portal 2** instead of mock data:

1. **VScript** (`vscript/aol_data.nut`) runs in-game at 10 Hz and prints `AOL_DATA:{...}` lines to the console (player eye pos, view angles, entity list with classname, targetname, origin). See **vscript/README.md** for setup (logic_script, `con_logfile`, `AOL_Start()`).

2. **Log parser** (`game_log_parser.py`) tails the Portal 2 console log file, detects lines starting with `AOL_DATA:`, parses the JSON, and updates a **thread-safe** in-memory camera struct and entities list.

3. **Projection** (`projection.py`) projects 3D world points to 2D screen coords using camera position, view angles, configurable FOV (default 90), and screen size (Source-style, good enough for debugging).

4. **Overlay renderer** (`overlay_renderer.py`) uses the log parser and projection to draw, for each entity, a **2D rectangle** from an approximate 3D box around `origin` (constant width/height/depth; replace with real mins/maxs later). It reads overlay toggles from the controller (file/IPC) and turns layers (entity names, cube outlines, trigger volumes, etc.) on/off.

**Run the overlay renderer** (with Portal 2 running and VScript outputting to the log, and controller running so toggles are written):

```bash
python overlay_renderer.py
# Or specify log path:
python overlay_renderer.py --log /path/to/portal2_console.log --fov 90
```

### Requirements

- Linux Mint (or another modern Linux desktop)
- Python 3.9+
- A working GPU driver that can render Dear PyGui windows

Python deps (see `requirements.txt`):

- `dearpygui`, `psutil` (controller)
- `pygame` (overlay drawer; falls back to tkinter if missing)

### Setup

1. Open a terminal and go into the app folder:

```bash
cd /home/doktordestrukt/Desktop/Execute/portal2_debug_overlay
```

2. Create and activate a virtual environment, then install dependencies:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### Run the app

1. **Start Portal 2** (Linux version via Steam) and leave it running.
2. In the same terminal (with the venv active), run:

```bash
cd /home/doktordestrukt/Desktop/Execute/portal2_debug_overlay
source .venv/bin/activate   # if you closed the terminal
python main.py
```

3. In the app window:
   - Click **“Attach to Portal 2”**.
   - When it says **Connected**, use the toggles to enable/disable the overlay options.

### Implementing one overlay end-to-end

The chain is already implemented for all layers (with mock data):

1. **Controller** — Checkbox toggles (e.g. “Entity names”) → backend writes **overlay_state.json** and sends over **overlay.ipc**.
2. **Overlay drawer** — Reads state from file or IPC and draws the corresponding layer (e.g. entity name labels). Toggling in the controller turns the layer on/off in the drawer in real time.

To use **real** game data instead of mock data you would:

- Add a **Source-engine mod or plugin** that gathers entity/trigger/portal data and either:
  - Writes it to a file the overlay drawer can read, or
  - Sends it over a socket to the overlay process.
- Have the overlay drawer (or a similar tool) read that data and draw it, still using **overlay_state.json** / **overlay.ipc** for which layers are on/off.

This keeps the controller and overlay state mechanism unchanged; you only swap mock data for real data from your mod.

