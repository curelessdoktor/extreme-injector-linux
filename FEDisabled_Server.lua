--[[
    FE Disabled - Server Script
    Place in: ServerScriptService

    Gives clients full authority over the server.
    Whatever the client does, the server replicates to all players.
    This recreates the behaviour of FilteringEnabled = false (pre-2018 Roblox).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

-- ─── Setup Remotes ────────────────────────────────────────────────────────────

local Remotes = Instance.new("Folder")
Remotes.Name  = "FEDisabledRemotes"
Remotes.Parent = ReplicatedStorage

local function makeRemote(name, class)
    local r       = Instance.new(class or "RemoteEvent")
    r.Name        = name
    r.Parent      = Remotes
    return r
end

local PropertyChanged   = makeRemote("PropertyChanged")   -- set a property
local InstanceCreated   = makeRemote("InstanceCreated")   -- new instance
local InstanceDestroyed = makeRemote("InstanceDestroyed") -- destroy instance
local FireMethod        = makeRemote("FireMethod")        -- call a method
local FireSound         = makeRemote("FireSound")         -- play a sound
local RequestCreate     = makeRemote("RequestCreate", "RemoteFunction") -- create + get ref back

-- ─── Property Changes ─────────────────────────────────────────────────────────

PropertyChanged.OnServerEvent:Connect(function(player, instance, property, value)
    if not instance or not instance.Parent then return end

    local ok, err = pcall(function()
        instance[property] = value
    end)

    if not ok then
        warn(("[FEDisabled] %s failed to set '%s' on %s: %s"):format(
            player.Name, tostring(property), instance:GetFullName(), tostring(err)))
    end
end)

-- ─── Instance Creation ────────────────────────────────────────────────────────
-- Clients call FireServer; server creates the real instance so it replicates to everyone.

InstanceCreated.OnServerEvent:Connect(function(player, className, parent, properties)
    if not parent then return end

    pcall(function()
        local inst = Instance.new(className)
        if properties then
            for prop, val in pairs(properties) do
                pcall(function() inst[prop] = val end)
            end
        end
        inst.Parent = parent
    end)
end)

-- RemoteFunction variant – returns the created instance so the client can keep a reference.
RequestCreate.OnServerInvoke = function(player, className, parent, properties)
    if not parent then return nil end

    local inst = nil
    pcall(function()
        inst = Instance.new(className)
        if properties then
            for prop, val in pairs(properties) do
                pcall(function() inst[prop] = val end)
            end
        end
        inst.Parent = parent
    end)
    return inst
end

-- ─── Instance Destruction ─────────────────────────────────────────────────────

InstanceDestroyed.OnServerEvent:Connect(function(player, instance)
    if instance and instance.Parent then
        pcall(function() instance:Destroy() end)
    end
end)

-- ─── Method Calls ─────────────────────────────────────────────────────────────

FireMethod.OnServerEvent:Connect(function(player, instance, method, ...)
    if not instance then return end
    pcall(function()
        instance[method](instance, ...)
    end)
end)

-- ─── Sound Playback ───────────────────────────────────────────────────────────
-- Re-broadcast to ALL clients so everyone hears sounds triggered on one client.

FireSound.OnServerEvent:Connect(function(player, sound, method)
    if not sound or not sound:IsA("Sound") then return end
    pcall(function()
        sound[method](sound)
    end)
    -- Re-fire to all other clients
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            FireSound:FireClient(p, sound, method)
        end
    end
end)

-- ─── Character Spawning ───────────────────────────────────────────────────────
-- When a player spawns, give the LocalScript their Character reference.

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        -- Nothing extra needed – character is workspace-parented so it replicates.
        print(("[FEDisabled] %s spawned."):format(player.Name))
    end)
end)

print("[FEDisabled] Server ready – client authority active. Old Roblox is back!")
