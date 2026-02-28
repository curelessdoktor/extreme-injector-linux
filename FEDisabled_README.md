# FE Disabled – Old Roblox Replication System

Recreates the **FilteringEnabled = false** (pre-2018) behaviour where anything
a client does is immediately reflected on the server and seen by all players.

---

## Setup

| File | Where to place it in Roblox Studio |
|------|-------------------------------------|
| `FEDisabled_Server.lua` | `ServerScriptService` → rename to `FEDisabled_Server` (Script) |
| `FEDisabled_Client.lua` | `StarterPlayerScripts` → rename to `FEDisabled_Client` (LocalScript) |

That's it. Hit **Play** and both scripts will handshake automatically.

---

## What it does automatically

| Behaviour | How |
|-----------|-----|
| CFrame / Position changes on any BasePart | Heartbeat diff → `PropertyChanged` remote |
| Appearance changes (Color, Transparency, Material, etc.) | `GetPropertyChangedSignal` listeners |
| Sound, Light, Particle property changes | Same signal listeners |
| Re-parenting / renaming | Parent & Name signal listeners |
| Character movement | Tracked on spawn via `CharacterAdded` |

Everything tracked in Workspace is watched. When a value changes on your client
the server is told immediately and applies the same change, which Roblox then
replicates to every other connected client.

---

## `_G.FEDisabled` API

Access from **any LocalScript** after the client script has loaded:

```lua
local FE = _G.FEDisabled   -- or just use _G.FEDisabled directly
```

### Create a part everyone sees
```lua
local part = _G.FEDisabled.new("Part", workspace, {
    Size       = Vector3.new(4, 4, 4),
    Anchored   = true,
    BrickColor = BrickColor.new("Bright red"),
    Material   = Enum.Material.SmoothPlastic,
})
```

### Set a property for all players
```lua
_G.FEDisabled.set(part, "Transparency", 0.5)
_G.FEDisabled.set(part, "BrickColor", BrickColor.new("Cyan"))
```

### Destroy an instance for everyone
```lua
_G.FEDisabled.destroy(part)
```

### Call a method for everyone
```lua
-- Deal damage via Humanoid
_G.FEDisabled.call(humanoid, "TakeDamage", 10)

-- Fire a BodyVelocity or any method
_G.FEDisabled.call(bodyVelocity, "Destroy")
```

### Play / Stop a Sound for all players
```lua
_G.FEDisabled.playSound(workspace.MySound)
_G.FEDisabled.stopSound(workspace.MySound)
```

---

## Example – old-school tool script

```lua
-- LocalScript inside a Tool
local tool    = script.Parent
local FE      = _G.FEDisabled

tool.Activated:Connect(function()
    -- Create a fireball part that EVERYONE sees
    local ball = FE.new("Part", workspace, {
        Shape      = Enum.PartType.Ball,
        Size       = Vector3.new(2, 2, 2),
        BrickColor = BrickColor.new("Bright orange"),
        Material   = Enum.Material.Neon,
        CFrame     = tool.Handle.CFrame * CFrame.new(0, 0, -3),
    })

    -- Add fire effect
    FE.new("Fire", ball, { Heat = 20, Size = 5 })

    -- Destroy after 3 seconds
    task.delay(3, function()
        FE.destroy(ball)
    end)
end)
```

---

## Tracked property list

The client auto-watches the following properties. Any others can be replicated
manually with `_G.FEDisabled.set()`.

| Class | Properties watched |
|-------|--------------------|
| `BasePart` | CFrame (heartbeat), Size, Color, BrickColor, Material, Transparency, Reflectance, CastShadow, Anchored, CanCollide, CanTouch, Massless |
| `Decal / Texture` | Texture, Transparency, Color3 |
| `SpecialMesh` | MeshType, MeshId, TextureId, Scale, Offset |
| `Sound` | SoundId, Volume, PlaybackSpeed, Looped |
| `PointLight / SpotLight / SurfaceLight` | Brightness, Color, Range, Angle, Enabled |
| `Smoke / Fire / Sparkles` | Color, Density, Heat, Size, Enabled, etc. |
| `GUI elements` | Text, TextColor3, Image, BackgroundColor3, etc. |
| All instances | Name, Parent |

---

## Notes

- **Security**: This intentionally gives clients full authority. Do **not** use
  in a competitive game – exploiters will be able to manipulate anything.
  This is designed for sandbox / creative / nostalgia servers.
- **Bandwidth**: CFrame sync only fires when position/rotation actually changes
  by more than 0.001 studs to avoid flooding the server.
- **Instance creation**: Always use `_G.FEDisabled.new()` when you want a part
  to appear for everyone. `Instance.new()` alone only creates locally.
