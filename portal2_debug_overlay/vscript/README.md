# AOL VScript (Portal 2)

Singleplayer Squirrel script that runs at 10 Hz and prints JSON with:

- `player_eye_pos` (x, y, z)
- `player_view_angles` (pitch, yaw, roll)
- `entities`: list of `{ classname, targetname, origin [x,y,z] }`

Each line is prefixed with **AOL_DATA:** so the Python app can parse it from the game log.

## Setup in Portal 2

1. **Enable console log to file** (in game console or add to launch options):
   ```
   con_logfile portal2_console.log
   ```
   The log is usually written to your Portal 2 `portal2` folder (e.g. under Steam install).

2. **Run the script in your map**
   - Add a **logic_script** entity.
   - Set its **VScript file** to `aol_data.nut` (or copy the script into your map’s scripts).
   - Start the tick loop once: either from another script’s `OnMapSpawn` with `AOL_Start()`, or from the game console:
     ```
     script AOL_Start
     ```
   - The script will re-fire itself every 0.1 s (10 Hz) via `EntFireByHandle(self, "RunScriptCode", "AOL_Tick()", 0.1, null, null)`.

3. **Point the Python overlay at the log**
   - Use `game_log_parser.py` with the path to `portal2_console.log` (or whatever you set in `con_logfile`).
   - `overlay_renderer.py` uses a default log path under `~/.steam/steam/steamapps/common/Portal 2/portal2/console.log`; override with `--log /path/to/portal2_console.log`.

## File

- **aol_data.nut** – Entry point: `AOL_Start()` begins the timer; `AOL_Tick()` gathers player + entities and prints one `AOL_DATA:{...}` line.
