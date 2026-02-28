--[[
    FE Disabled - LocalScript
    Place in: StarterPlayerScripts

    Monitors client-side changes and replicates them to the server so that
    all players see the same thing. This recreates FilteringEnabled = false.

    ─── How to use ───────────────────────────────────────────────────────────────
    Use the global `FEDisabled` table for replicated operations:

        -- Create a part everyone sees:
        local part = FEDisabled.new("Part", workspace, { Size = Vector3.new(4,4,4), Anchored = true })

        -- Change a property on an existing instance:
        FEDisabled.set(part, "BrickColor", BrickColor.new("Bright red"))

        -- Destroy an instance for everyone:
        FEDisabled.destroy(part)

        -- Call a method for everyone (e.g. :Play() on a Sound):
        FEDisabled.call(sound, "Play")

    Any edits you make to Workspace parts directly are ALSO auto-synced via the
    property watcher below.
    ──────────────────────────────────────────────────────────────────────────────
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local Players           = game:GetService("Players")

local player = Players.LocalPlayer

-- ─── Wait for Server Remotes ──────────────────────────────────────────────────

local Remotes = ReplicatedStorage:WaitForChild("FEDisabledRemotes", 15)
assert(Remotes, "[FEDisabled] Could not find FEDisabledRemotes – is the Server script in ServerScriptService?")

local PropertyChanged   = Remotes:WaitForChild("PropertyChanged")
local InstanceCreated   = Remotes:WaitForChild("InstanceCreated")
local InstanceDestroyed = Remotes:WaitForChild("InstanceDestroyed")
local FireMethod        = Remotes:WaitForChild("FireMethod")
local FireSound         = Remotes:WaitForChild("FireSound")
local RequestCreate     = Remotes:WaitForChild("RequestCreate")

-- ─── Properties to Auto-Track ─────────────────────────────────────────────────
-- Changes to these properties on existing workspace instances are automatically
-- sent to the server so they replicate to all players.

local WATCH_PROPS = {
    BasePart = {
        "Size", "Color", "BrickColor", "Material",
        "Transparency", "Reflectance", "CastShadow",
        "Anchored", "CanCollide", "CanTouch", "Massless",
        "LocalTransparencyModifier",
    },
    Decal        = { "Texture", "Transparency", "Color3" },
    Texture      = { "Texture", "Transparency" },
    SpecialMesh  = { "MeshType", "MeshId", "TextureId", "Scale", "Offset" },
    Sound        = { "SoundId", "Volume", "PlaybackSpeed", "Looped" },
    PointLight   = { "Brightness", "Color", "Range", "Enabled" },
    SpotLight    = { "Brightness", "Color", "Range", "Angle", "Enabled" },
    SurfaceLight = { "Brightness", "Color", "Range", "Angle", "Enabled" },
    Smoke        = { "Color", "Density", "RiseVelocity", "Enabled" },
    Fire         = { "Color", "SecondaryColor", "Heat", "Size", "Enabled" },
    Sparkles     = { "SparkleColor", "Enabled" },
    BillboardGui = { "Size", "StudsOffset", "Enabled" },
    TextLabel    = { "Text", "TextColor3", "TextSize", "Font", "BackgroundColor3", "BackgroundTransparency" },
    TextButton   = { "Text", "TextColor3", "TextSize", "Font" },
    ImageLabel   = { "Image", "ImageColor3", "ImageTransparency" },
}

-- ─── Internal State ───────────────────────────────────────────────────────────

local tracked    = {}   -- [instance] = true
local connMap    = {}   -- [instance] = { RBXScriptConnection, ... }
local lastCFrame = {}   -- [BasePart]  = CFrame  (for heartbeat diff)

-- ─── Helpers ──────────────────────────────────────────────────────────────────

local function safeSend(instance, property, value)
    PropertyChanged:FireServer(instance, property, value)
end

local function getWatchProps(instance)
    local out = {}
    for className, props in pairs(WATCH_PROPS) do
        if instance:IsA(className) then
            for _, p in ipairs(props) do
                out[#out + 1] = p
            end
        end
    end
    return out
end

-- ─── Track a Single Instance ──────────────────────────────────────────────────

local function trackInstance(instance)
    if tracked[instance] then return end
    tracked[instance] = true

    local conns = {}
    connMap[instance] = conns

    -- Watch declared properties via GetPropertyChangedSignal
    for _, prop in ipairs(getWatchProps(instance)) do
        local ok, conn = pcall(function()
            return instance:GetPropertyChangedSignal(prop):Connect(function()
                local ok2, val = pcall(function() return instance[prop] end)
                if ok2 then safeSend(instance, prop, val) end
            end)
        end)
        if ok then conns[#conns + 1] = conn end
    end

    -- Seed last-known CFrame for BaseParts
    if instance:IsA("BasePart") then
        local ok, cf = pcall(function() return instance.CFrame end)
        if ok then lastCFrame[instance] = cf end
    end

    -- Watch Parent changes (re-parenting replicates to server)
    local ok, conn = pcall(function()
        return instance:GetPropertyChangedSignal("Parent"):Connect(function()
            local ok2, parent = pcall(function() return instance.Parent end)
            if ok2 and parent then
                safeSend(instance, "Parent", parent)
            end
        end)
    end)
    if ok then conns[#conns + 1] = conn end

    -- Watch Name changes
    local ok2, conn2 = pcall(function()
        return instance:GetPropertyChangedSignal("Name"):Connect(function()
            local ok3, name = pcall(function() return instance.Name end)
            if ok3 then safeSend(instance, "Name", name) end
        end)
    end)
    if ok2 then conns[#conns + 1] = conn2 end
end

local function untrackInstance(instance)
    if not tracked[instance] then return end
    tracked[instance] = nil
    lastCFrame[instance] = nil
    if connMap[instance] then
        for _, c in ipairs(connMap[instance]) do pcall(function() c:Disconnect() end) end
        connMap[instance] = nil
    end
end

-- ─── Recursively Track All Descendants ───────────────────────────────────────

local function trackTree(root)
    for _, desc in ipairs(root:GetDescendants()) do
        pcall(trackInstance, desc)
    end
    root.DescendantAdded:Connect(function(inst)
        pcall(trackInstance, inst)
    end)
    root.DescendantRemoving:Connect(function(inst)
        pcall(untrackInstance, inst)
    end)
end

-- ─── CFrame Sync via Heartbeat ────────────────────────────────────────────────
-- Only fires when CFrame actually changes, keeping bandwidth reasonable.

local CFRAME_THRESHOLD = 0.001 -- studs; ignore sub-millimetre jitter

RunService.Heartbeat:Connect(function()
    for inst in pairs(tracked) do
        if inst:IsA("BasePart") and inst.Parent then
            local ok, cf = pcall(function() return inst.CFrame end)
            if ok then
                local prev = lastCFrame[inst]
                if prev == nil or (cf.Position - prev.Position).Magnitude > CFRAME_THRESHOLD
                        or math.abs(cf:ToEulerAnglesXYZ()) ~= math.abs((prev):ToEulerAnglesXYZ()) then
                    lastCFrame[inst] = cf
                    PropertyChanged:FireServer(inst, "CFrame", cf)
                end
            end
        end
    end
end)

-- ─── Initialise ───────────────────────────────────────────────────────────────

trackTree(workspace)

-- Track character on spawn
local function trackCharacter(char)
    trackTree(char)
end

player.CharacterAdded:Connect(trackCharacter)
if player.Character then
    trackCharacter(player.Character)
end

-- ─── Server → Client Sound Playback ──────────────────────────────────────────
-- When another client plays a sound, the server re-fires here.

FireSound.OnClientEvent:Connect(function(sound, method)
    if sound and sound:IsA("Sound") then
        pcall(function() sound[method](sound) end)
    end
end)

-- ─── Public API ───────────────────────────────────────────────────────────────
--[[
    _G.FEDisabled  –  use these functions so your LocalScripts work like
                      server scripts and replicate everything automatically.
]]

local FEDisabled = {}

--[[
    FEDisabled.new(className, parent, properties?)
    Creates an instance on the SERVER so all players see it.
    Returns the server-created instance reference.

    Example:
        local part = FEDisabled.new("Part", workspace, {
            Size     = Vector3.new(4, 4, 4),
            Anchored = true,
            BrickColor = BrickColor.new("Bright red"),
        })
]]
function FEDisabled.new(className, parent, properties)
    -- Ask server to create; get back the real replicated instance.
    local inst = RequestCreate:InvokeServer(className, parent or workspace, properties or {})
    return inst
end

--[[
    FEDisabled.set(instance, property, value)
    Sets a property on the server (replicates to all).
]]
function FEDisabled.set(instance, property, value)
    pcall(function() instance[property] = value end)      -- local preview
    PropertyChanged:FireServer(instance, property, value)  -- server + all clients
end

--[[
    FEDisabled.destroy(instance)
    Destroys an instance for everyone.
]]
function FEDisabled.destroy(instance)
    InstanceDestroyed:FireServer(instance)
    pcall(function() instance:Destroy() end)
end

--[[
    FEDisabled.call(instance, method, ...)
    Calls a method on the server (e.g. Sound:Play(), Humanoid:TakeDamage(10)).
]]
function FEDisabled.call(instance, method, ...)
    FireMethod:FireServer(instance, method, ...)
    pcall(function() instance[method](instance, ...) end)
end

--[[
    FEDisabled.playSound(sound)
    Plays a Sound for ALL players.
]]
function FEDisabled.playSound(sound)
    FireSound:FireServer(sound, "Play")
    pcall(function() sound:Play() end)
end

--[[
    FEDisabled.stopSound(sound)
    Stops a Sound for ALL players.
]]
function FEDisabled.stopSound(sound)
    FireSound:FireServer(sound, "Stop")
    pcall(function() sound:Stop() end)
end

-- Expose globally so any other LocalScript can access it
_G.FEDisabled = FEDisabled

print("[FEDisabled] Client ready – you are now running in FilteringDisabled mode. Old Roblox is back!")
