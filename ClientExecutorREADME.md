# Client Executor — Run Lua in-game

Lua from the textbox is executed **on the server** using `loadstring`. The UI runs on the client and sends the code to the server.

## Setup in Roblox Studio

1. **Enable LoadStringEnabled** (required)
   - In the **Explorer**, select **ServerScriptService**.
   - In **Properties**, find **LoadStringEnabled** and set it to **true**.
   - (If you don’t see it, check under Security or your Studio version’s equivalent.)

2. **Server script**
   - In **ServerScriptService**, create a **Script**.
   - Paste the contents of **ClientExecutorServer.lua** into it.

3. **Client UI**
   - In **StarterPlayer** → **StarterPlayerScripts** (or **StarterGui**), create a **LocalScript**.
   - Paste the contents of **ClientExecutor.lua** into it.

4. Press **Play**. The executor window appears; type Lua and click **Execute**.

## Files

- **ClientExecutor.lua** — LocalScript: UI (textbox, Execute, Clear, output). Sends code to server and shows results.
- **ClientExecutorServer.lua** — Script: Receives code, runs it with `loadstring`, sends `print()` and errors back to the client.

## Notes

- Code runs **on the server** (so e.g. new Parts appear in the shared workspace).
- `print(...)` in your code is sent to the executor’s output log.
- You must turn on **LoadStringEnabled** for ServerScriptService or the server will report that loadstring is not available.
