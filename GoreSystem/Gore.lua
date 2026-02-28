--[[
	GoreSystem - Realistic Roblox blood/gore (17+)
	Inspired by droplet + puddle behaviour from Grab Knife–style systems.
	Use: require(this module), then Gore.Bleed(part) or Gore.AttachWound(character, partName)
]]

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Gore = {}

-- Configuration
Gore.Config = {
	-- Realistic dark red (can override per-call)
	BloodColor = Color3.fromRGB(90, 15, 15),
	-- Droplet spawn interval while source exists
	BleedInterval = 0.08,
	-- Max puddle size (studs) before it stops growing
	MaxPuddleSize = 6,
	-- Puddle fade step per tick
	PuddleFadeStep = 0.04,
	PuddleFadeInterval = 0.12,
	-- Droplet lifetime before cleanup
	DropletLifetime = 1.2,
	-- Blood texture (optional; use "" for solid color)
	BloodTexture = "rbxassetid://867743272",
	-- Splat sound when puddle is created
	SplatSoundId = "rbxassetid://685857471",
	SplatVolume = 0.08,
	-- Ignore list for Touched (don't create puddles on these)
	IgnoreNames = { "Blood", "BloodPuddle", "Projectile", "Handle", "Blade" },
	IgnoreParentNames = { "Projectile" },
}

-- Helpers
local function shouldIgnore(touched)
	if not touched or not touched.Parent then return true end
	for _, name in ipairs(Gore.Config.IgnoreNames) do
		if touched.Name == name then return true end
	end
	for _, name in ipairs(Gore.Config.IgnoreParentNames) do
		if touched.Parent.Name == name then return true end
	end
	if touched.Parent:FindFirstChildOfClass("Humanoid") then return true end
	if touched.Parent.Parent and touched.Parent.Parent:FindFirstChildOfClass("Humanoid") then return true end
	if touched.Parent:IsA("Tool") or touched.Parent:IsA("Accessory") then return true end
	return false
end

-- Create a single blood droplet and run its lifecycle (physics, particles, touch -> puddle)
function Gore.SpawnDroplet(position, upVector, color, useWhite)
	local c = color or Gore.Config.BloodColor
	if useWhite then c = Color3.new(1, 1, 1) end

	local thing = Instance.new("Part")
	thing.Size = Vector3.new(0.18, 0.18, 0.18)
	thing.CFrame = CFrame.new(position)
	thing.Transparency = 1
	thing.Color = c
	thing.Material = Enum.Material.SmoothPlastic
	thing.Name = "Blood"
	thing.CanCollide = false
	thing.CanTouch = true
	thing.Anchored = false
	thing:BreakJoints()
	thing.Parent = Workspace

	local bf = Instance.new("BodyForce", thing)
	bf.Force = upVector * (math.random() * 2.5 + 0.5) + Vector3.new((math.random() - 0.5) * 1.2, 1.2, (math.random() - 0.5) * 1.2)
	Debris:AddItem(bf, 0.02)

	local emitter = Instance.new("ParticleEmitter", thing)
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, c),
		ColorSequenceKeypoint.new(1, c),
	})
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.12),
		NumberSequenceKeypoint.new(1, 0.06),
	})
	if Gore.Config.BloodTexture and Gore.Config.BloodTexture ~= "" then
		emitter.Texture = Gore.Config.BloodTexture
	end
	emitter.Lifetime = NumberRange.new(0.35)
	emitter.Rate = 45
	emitter.LockedToPart = true
	emitter.Speed = NumberRange.new(0, 2)
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})

	local destroyed = false
	local function destroy()
		if destroyed then return end
		destroyed = true
		thing:Destroy()
	end

	thing.Touched:Connect(function(tou)
		if destroyed then return end
		if shouldIgnore(tou) then return end
		-- Don't puddle on non-collidable (e.g. other blood)
		if not tou.CanCollide and tou.Name ~= "BloodPuddle" then return end

		local pos = Vector3.new(thing.Position.X, (tou.Position.Y + tou.Size.Y / 2) + 0.02, thing.Position.Z)
		destroy()

		if tou.Name == "BloodPuddle" then
			-- Merge into existing puddle
			if tou.Transparency > -0.15 then
				tou.Transparency = math.max(-0.2, tou.Transparency - 0.08)
			end
			if tou.Size.X < Gore.Config.MaxPuddleSize then
				local oldCf = tou.CFrame
				tou.Size = tou.Size + Vector3.new(0.12, 0, 0.12)
				tou.CFrame = oldCf
			end
			return
		end

		-- New puddle on solid surface
		local bloodlol = Instance.new("Part")
		bloodlol.Size = Vector3.new(0.9, 0.15, 0.9)
		bloodlol.Name = "BloodPuddle"
		bloodlol.Anchored = true
		bloodlol.CanCollide = false
		bloodlol.Material = Enum.Material.SmoothPlastic
		bloodlol.Color = c
		bloodlol.CFrame = CFrame.new(pos)
		bloodlol.Transparency = 0
		bloodlol.Parent = Workspace

		local cyl = Instance.new("CylinderMesh", bloodlol)
		cyl.Scale = Vector3.new(1, 0.1, 1)

		if Gore.Config.SplatSoundId and Gore.Config.SplatSoundId ~= "" then
			local sound = Instance.new("Sound", bloodlol)
			sound.SoundId = Gore.Config.SplatSoundId
			sound.Volume = Gore.Config.SplatVolume
			sound:Play()
		end

		task.spawn(function()
			while bloodlol and bloodlol.Parent do
				if bloodlol.Transparency >= 1 then
					bloodlol:Destroy()
					break
				end
				bloodlol.Transparency = bloodlol.Transparency + Gore.Config.PuddleFadeStep
				task.wait(Gore.Config.PuddleFadeInterval)
			end
		end)
	end)

	Debris:AddItem(thing, Gore.Config.DropletLifetime)
end

-- Continuous bleed from a part (e.g. wound surface). Stops when source is removed/destroyed.
function Gore.Bleed(sourcePart, options)
	options = options or {}
	local color = options.BloodColor or Gore.Config.BloodColor
	local useWhite = options.UseWhite == true
	local interval = options.Interval or Gore.Config.BleedInterval
	local drip = options.Drip == true -- flow downward instead of upward

	task.spawn(function()
		while sourcePart and sourcePart.Parent do
			local root = sourcePart:FindFirstAncestorOfClass("Model")
			if root and root:FindFirstChildOfClass("Humanoid") and root:FindFirstChildOfClass("Humanoid").Health <= 0 then
				break
			end
			local cf = sourcePart.CFrame
			local up = drip and -cf.UpVector or cf.UpVector
			Gore.SpawnDroplet(cf.Position, up, color, useWhite)
			task.wait(interval)
		end
	end)
end

-- Attach a wound (invisible bleed source) to a body part. Works with R6 and R15.
function Gore.AttachWound(character, partName, options)
	if not character or not character:FindFirstChildOfClass("Humanoid") then return nil end
	options = options or {}

	local part = character:FindFirstChild(partName)
	if not part or not part:IsA("BasePart") then return nil end

	local wound = Instance.new("Part")
	wound.Name = "GoreWound"
	wound.Size = Vector3.new(part.Size.X * 0.7, 0.08, part.Size.Z * 0.7)
	wound.Transparency = 1
	wound.CanCollide = false
	wound.Anchored = false
	wound:BreakJoints()
	wound.Parent = character

	-- Weld wound to body part so it follows (e.g. during ragdoll)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part
	weld.Part1 = wound
	weld.Parent = wound

	wound.CFrame = part.CFrame * CFrame.new(0, -part.Size.Y / 2, 0)

	Gore.Bleed(wound, { Drip = true, BloodColor = options.BloodColor, UseWhite = options.UseWhite })
	return wound
end

-- Spawn bleed from multiple body parts (e.g. on death or heavy damage). R6 + R15.
function Gore.BleedFromCharacter(character, options)
	if not character or not character:FindFirstChildOfClass("Humanoid") then return end
	options = options or {}

	local bodyParts = {}
	-- R6
	if character:FindFirstChild("Torso") then
		table.insert(bodyParts, "Torso")
		table.insert(bodyParts, "Head")
		table.insert(bodyParts, "Left Arm")
		table.insert(bodyParts, "Right Arm")
		table.insert(bodyParts, "Left Leg")
		table.insert(bodyParts, "Right Leg")
	else
		-- R15
		table.insert(bodyParts, "UpperTorso")
		table.insert(bodyParts, "LowerTorso")
		table.insert(bodyParts, "Head")
		table.insert(bodyParts, "LeftUpperArm")
		table.insert(bodyParts, "LeftLowerArm")
		table.insert(bodyParts, "LeftHand")
		table.insert(bodyParts, "RightUpperArm")
		table.insert(bodyParts, "RightLowerArm")
		table.insert(bodyParts, "RightHand")
		table.insert(bodyParts, "LeftUpperLeg")
		table.insert(bodyParts, "LeftLowerLeg")
		table.insert(bodyParts, "LeftFoot")
		table.insert(bodyParts, "RightUpperLeg")
		table.insert(bodyParts, "RightLowerLeg")
		table.insert(bodyParts, "RightFoot")
	end

	for _, name in ipairs(bodyParts) do
		local p = character:FindFirstChild(name)
		if p then
			Gore.AttachWound(character, name, options)
		end
	end
end

-- One-shot burst of blood at a position (e.g. impact). Count = number of droplets.
function Gore.Burst(position, normal, count, options)
	options = options or {}
	local color = options.BloodColor or Gore.Config.BloodColor
	local useWhite = options.UseWhite == true
	count = count or 12
	local up = normal or Vector3.new(0, 1, 0)
	for _ = 1, count do
		task.defer(function()
			Gore.SpawnDroplet(position, up, color, useWhite)
		end)
		task.wait(0.02)
	end
end

-- Connect to Humanoid: take damage -> small bleed at hit part; death -> full body bleed (optional).
function Gore.ConnectHumanoid(humanoid, options)
	options = options or {}
	local char = humanoid.Parent
	if not char or not char:IsA("Model") then return end

	humanoid.Died:Connect(function()
		if options.BleedOnDeath ~= false then
			Gore.BleedFromCharacter(char, options)
		end
	end)

	-- Optional: on damage, try to burst near torso/head
	if options.BleedOnDamage then
		local lastHealth = humanoid.Health
		humanoid.HealthChanged:Connect(function()
			local now = humanoid.Health
			if now < lastHealth and humanoid.Health > 0 then
				local part = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("Head")
				if part then
					Gore.Burst(part.Position, Vector3.new(0, 1, 0), 4 + math.random(4), options)
				end
			end
			lastHealth = now
		end)
	end
end

return Gore
