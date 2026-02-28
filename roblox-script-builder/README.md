# Roblox Script Builder (Sandboxed)

A **sandboxed** script builder inspired by the [Roblox Wiki – Script builder](https://roblox.fandom.com/wiki/Script_builder#Using_a_script_builder). Players enter a Pastebin URL; the server fetches the content and runs only **whitelisted commands** (no arbitrary Lua). User-generated text is **filtered** via TextService before display (ToU compliance).

## Contents

- **ServerExecutor.lua** – Server script: fetches Pastebin, parses commands (JSON or line-based), runs them in a sandbox, filters output.
- **ClientScriptBuilder.lua** – LocalScript: GUI with Pastebin URL input, Execute button, and output log (receives filtered lines from server).

## Setup in Roblox Studio

1. **Enable HTTP**  
   Game Settings → Security → **Allow HTTP Requests**.

2. **Server script**  
   In **ServerScriptService**, create a **Script** and paste `ServerExecutor.lua`. It creates in ReplicatedStorage:
   - `ExecutePastebin` – client sends Pastebin URL
   - `ExecutePastebinResult` – server sends success/error
   - `ScriptBuilderOutput` – server streams filtered output lines

3. **Client GUI**  
   In **StarterPlayer** → **StarterPlayerScripts**, create a **LocalScript** and paste `ClientScriptBuilder.lua`.

## Script format (Pastebin)

Pastebin must contain either **JSON** or **line-based** commands. No raw Lua (no `loadstring`).

### Option 1: JSON

```json
[
  {"cmd": "print", "text": "Hello world"},
  {"cmd": "wait", "seconds": 1},
  {"cmd": "part", "size": [2, 1, 2], "color": [0, 1, 0]},
  {"cmd": "message", "text": "Done!"}
]
```

### Option 2: Line-based

One command per line: `command arg1 arg2 ...`

```
print Hello world
wait 1
part 2 1 2
message Done!
```

## Sandbox commands

| Command   | JSON example | Line example   | Description |
|----------|----------------|----------------|-------------|
| `print`  | `{"cmd":"print","text":"Hi"}` | `print Hi` | Appends filtered text to the output log. |
| `message` | `{"cmd":"message","text":"Hi"}` | `message Hi` | Same as print (filtered). |
| `wait`   | `{"cmd":"wait","seconds":1}` | `wait 1` | Pauses (max 5 seconds). |
| `part`   | `{"cmd":"part","size":[2,1,2],"color":[1,0,0]}` | `part 2 1 2` | Creates a part in workspace (max 10 per run). |

- **Limits:** 64 commands per run, 10 parts per run, 50 output lines. Parts are created in a folder `ScriptBuilderParts` and placed above the player.
- **Filtering:** All text from `print`/`message` is filtered with `TextService:FilterStringAsync` before being sent to the client (ToU: filter interfaces made by other people).

## Why sandbox (no loadstring)?

Roblox does not allow `loadstring()` in normal game servers. This builder instead runs a **fixed set of commands** so it works in published games and stays within [Roblox’s terms](https://roblox.fandom.com/wiki/Script_builder#Using_a_script_builder) (filtering user-generated content, no arbitrary code execution).

## Optional: restrict who can execute

In `ServerExecutor.lua`, inside the `OnServerEvent` callback, add a check before processing the URL:

```lua
if not player:GetAttribute("CanExecuteScripts") then
	sendResult(false, "Not allowed.")
	return
end
```

Set `CanExecuteScripts` on the Player (or use your own admin check) as needed.
