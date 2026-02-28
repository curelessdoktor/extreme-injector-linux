# GoreSystem (17+)

Realistic Roblox blood/gore system inspired by droplet + puddle behaviour (e.g. Grab Knife–style). For **17+** experiences only.

## Features

- **Blood droplets** – Small physics parts with particle trail; spawn from wounds or impacts.
- **Blood puddles** – Droplets that hit the ground or walls create puddles (cylinders). Puddles merge when more droplets hit them, then fade out over time. Optional splat sound.
- **Configurable** – Blood color (default dark red), rates, puddle max size, textures, sounds.
- **Wound attachment** – Attach invisible “wound” parts to any body part (R6 and R15); they drip blood downward and follow the part (e.g. during ragdoll).
- **Full-body bleed** – Spawn wounds on all body parts (e.g. on death).
- **Burst** – One-shot spray of droplets at a point (e.g. impact or slash).
- **Humanoid integration** – Optional: bleed on death and/or small burst on damage.

## Setup

1. Put **Gore** (ModuleScript) in `ReplicatedStorage` or another place your server (and optionally client) can require it.
2. Option A: Run **Init** as a server script (child of the same container as the Gore module) to auto-connect all players: death = full body bleed, damage = small burst.
3. Option B: Require the module in your own scripts and call the API when you need gore (e.g. when a knife hits, or on custom death).

## API

```lua
local Gore = require(path.to.Gore)
```

### Config (optional)

- `Gore.Config.BloodColor` – Default `Color3.fromRGB(90, 15, 15)`.
- `Gore.Config.BleedInterval` – Seconds between droplets (default `0.08`).
- `Gore.Config.MaxPuddleSize` – Max puddle diameter in studs (default `6`).
- `Gore.Config.BloodTexture` – Particle texture (e.g. `"rbxassetid://867743272"`).
- `Gore.Config.SplatSoundId` – Sound when a new puddle forms (e.g. `"rbxassetid://685857471"`).
- `Gore.Config.IgnoreNames` / `IgnoreParentNames` – Names to ignore in `Touched` (no puddle on these).

### Functions

- **`Gore.SpawnDroplet(position, upVector, color, useWhite)`**  
  Spawns one blood droplet. `upVector` = direction of initial force. `useWhite` = use white color.

- **`Gore.Bleed(sourcePart, options)`**  
  Continuously spawns droplets from `sourcePart` while it exists (stops when humanoid is dead).  
  Options: `BloodColor`, `UseWhite`, `Interval`, `Drip` (true = drip downward).

- **`Gore.AttachWound(character, partName, options)`**  
  Attaches an invisible wound to a body part (e.g. `"Head"`, `"Torso"`, `"UpperTorso"`, `"LeftUpperArm"`). Returns the wound part or nil. Uses `Drip = true` by default.

- **`Gore.BleedFromCharacter(character, options)`**  
  Attaches wounds to all body parts (R6 or R15). Use for full-body bleed on death.

- **`Gore.Burst(position, normal, count, options)`**  
  One-shot spray of `count` droplets (default 12) at `position` in direction `normal`.

- **`Gore.ConnectHumanoid(humanoid, options)`**  
  Connects to `humanoid`:  
  - `BleedOnDeath` (default true): call `BleedFromCharacter` on death.  
  - `BleedOnDamage`: spawn a small burst when health decreases.

## Example (manual)

```lua
local Gore = require(ReplicatedStorage.Gore)

-- When something sharp hits a character's torso:
local character = target.Character
Gore.AttachWound(character, "UpperTorso", { BloodColor = Color3.fromRGB(80, 10, 10) })

-- Or one-time burst at hit position:
Gore.Burst(hitPosition, hitNormal, 8)

-- On death (if not using Init):
character:FindFirstChildOfClass("Humanoid").Died:Connect(function()
    Gore.BleedFromCharacter(character)
end)
```

## Age rating

This system is intended for **17+** experiences. Ensure your place is correctly rated and that gore is appropriate for your game.
