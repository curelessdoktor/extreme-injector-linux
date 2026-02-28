# Full instructions: how to run Aperture Overlay Link

Everything runs on **Linux Mint** (or any Linux desktop). You need **Python 3.9+** and **Portal 2** (Linux) installed via Steam.

---

## 1. One-time setup

Open a terminal and run:

```bash
cd /home/doktordestrukt/Desktop/Execute/portal2_debug_overlay
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Leave this terminal open (or remember to `cd` into the folder and `source .venv/bin/activate` whenever you open a new terminal for the app).

---

## 2. Option A: Controller + overlay (mock data)

No Portal 2 or VScript needed. You get the controller UI and a second window that draws **mock** entities/layers; toggles turn layers on/off in real time.

### Step 1 — Start the controller

In a terminal:

```bash
cd /home/doktordestrukt/Desktop/Execute/portal2_debug_overlay
source .venv/bin/activate
python main.py
```

- Optional: start **Portal 2** and click **“Attach to Portal 2”** in the app (for “Connected” status).  
- The overlay works even if you don’t attach; toggles still control the drawer.

### Step 2 — Start the overlay drawer

In a **second** terminal:

```bash
cd /home/doktordestrukt/Desktop/Execute/portal2_debug_overlay
source .venv/bin/activate
python overlay_drawer.py
```

A second window opens. Toggle checkboxes in the **Aperture Overlay Link** window (e.g. “Entity names”, “Trigger volumes”); the overlay window updates immediately.

---

## 3. Option B: Controller + real game data (VScript + log + overlay renderer)

You need **Portal 2** running with the VScript outputting data to a **console log file**, then the **controller** and **overlay renderer** running.

### Step 1 — Enable console logging in Portal 2

So the game writes console output to a file:

1. In Steam: **Library → Portal 2 → right‑click → Properties → Launch Options**.  
2. Add:
   ```text
   -condebug
   ```
   (Or in-game, open the console with `~` and run once: `con_logfile portal2_console.log`.)

The log is usually written to:

- `~/.steam/steam/steamapps/common/Portal 2/portal2/console.log`  
  or  
- `~/.steam/steam/steamapps/common/Portal 2/portal2/portal2_console.log`  
  depending on `con_logfile` and game version.

### Step 2 — Run the VScript in Portal 2

The script `vscript/aol_data.nut` must run in your map so it prints `AOL_DATA:{...}` every 0.1 s.

**If you have a custom map:**

1. Copy `portal2_debug_overlay/vscript/aol_data.nut` into your map’s script folder (or where your map loads VScripts from).
2. In Hammer (or your map), add a **logic_script** entity and set its **VScript file** to `aol_data.nut`.
3. Start the loop once:
   - From another script’s `OnMapSpawn`: call `AOL_Start()`, or  
   - In-game, open console (`~`) and run:  
     ```text
     script AOL_Start
     ```

**If you’re on a stock map** (no logic_script):

- You can’t inject the script into stock maps. Use a custom map or a mod that loads the script and calls `AOL_Start()`.

### Step 3 — Start the controller

Same as Option A:

```bash
cd /home/doktordestrukt/Desktop/Execute/portal2_debug_overlay
source .venv/bin/activate
python main.py
```

Optional: start Portal 2 first and click **“Attach to Portal 2”**.

### Step 4 — Start the overlay renderer

In a **second** terminal:

```bash
cd /home/doktordestrukt/Desktop/Execute/portal2_debug_overlay
source .venv/bin/activate
python overlay_renderer.py
```

If your log is **not** at the default path, set it explicitly:

```bash
python overlay_renderer.py --log /path/to/portal2_console.log
```

Optional:

```bash
python overlay_renderer.py --log /path/to/portal2_console.log --fov 90 --width 1920 --height 1080
```

The overlay renderer window shows **live** camera and entities from the game log: entity boxes and (if toggled) names. Toggle layers in the **Aperture Overlay Link** window; the renderer turns those layers on/off.

---

## 4. Quick reference

| What you want | Run |
|---------------|-----|
| **Controller only** | `python main.py` |
| **Controller + mock overlay** | Terminal 1: `python main.py` → Terminal 2: `python overlay_drawer.py` |
| **Controller + real game overlay** | Enable `con_logfile` / `-condebug`, run VScript in map (`AOL_Start`), then Terminal 1: `python main.py` → Terminal 2: `python overlay_renderer.py` (add `--log ...` if needed) |

Always from the project folder with the venv active:

```bash
cd /home/doktordestrukt/Desktop/Execute/portal2_debug_overlay
source .venv/bin/activate
```

Then run the command from the table above.
