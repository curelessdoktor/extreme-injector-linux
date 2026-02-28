--[[
	Grab Knife v2 — SERVER SCRIPT
	Put this in ServerScriptService. Runs on the server for all players.
	Also add GrabKnife_ClientKeys as a LocalScript in StarterPlayerScripts (for Q/E/F keys).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BLOOD_COLORS = { "Really red", "Bright red" }

-- Create RemoteEvent for key presses (client sends Q/E/F to server)
local keyEvent = ReplicatedStorage:FindFirstChild("GrabKnifeKey")
if not keyEvent then
	keyEvent = Instance.new("RemoteEvent")
	keyEvent.Name = "GrabKnifeKey"
	keyEvent.Parent = ReplicatedStorage
end

-- R6/R15 limb resolution
local function getLimb(character, limbKind)
	if limbKind == "RightArm" then
		return character:FindFirstChild("Right Arm") or character:FindFirstChild("RightHand")
	elseif limbKind == "LeftArm" then
		return character:FindFirstChild("Left Arm") or character:FindFirstChild("LeftHand")
	elseif limbKind == "LeftLeg" then
		return character:FindFirstChild("Left Leg") or character:FindFirstChild("LeftUpperLeg") or character:FindFirstChild("LeftLowerLeg")
	elseif limbKind == "Torso" then
		return character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
	elseif limbKind == "Head" then
		return character:FindFirstChild("Head")
	elseif limbKind == "Humanoid" then
		return character:FindFirstChild("Humanoid")
	elseif limbKind == "Neck" then
		return character:FindFirstChild("Neck")
	end
	return nil
end

local function prop(part, parent, collide, tran, ref, x, y, z, colorName, anchor)
	part.Parent = parent
	part.CanCollide = collide
	part.Transparency = tran
	part.Reflectance = ref
	part.Size = Vector3.new(x, y, z)
	part.BrickColor = BrickColor.new(colorName)
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Anchored = anchor
	part.Locked = true
	part:BreakJoints()
end

local function weld(w, p, p1, a, b, c, x, y, z)
	w.Parent = p
	w.Part0 = p
	w.Part1 = p1
	w.C1 = CFrame.Angles(a, b, c) * CFrame.new(x, y, z)
end

local function clearModeGui(playerGui)
	for _, child in ipairs(playerGui:GetChildren()) do
		if child.Name == "Modeshow" then
			child:Destroy()
		end
	end
end

local function inform(playerGui, text, delaySec)
	clearModeGui(playerGui)
	local sc = Instance.new("ScreenGui")
	sc.Name = "Modeshow"
	sc.Parent = playerGui
	sc.ResetOnSpawn = false

	local bak = Instance.new("Frame")
	bak.Parent = sc
	bak.BackgroundColor3 = Color3.new(1, 1, 1)
	bak.Size = UDim2.new(0.94, 0, 0.1, 0)
	bak.Position = UDim2.new(0.03, 0, 0.037, 0)
	bak.BorderSizePixel = 0

	local gi = Instance.new("TextLabel")
	gi.Parent = sc
	gi.Size = UDim2.new(0.92, 0, 0.09, 0)
	gi.BackgroundColor3 = Color3.new(0, 0, 0)
	gi.Position = UDim2.new(0.04, 0, 0.042, 0)
	gi.TextColor3 = Color3.new(1, 1, 1)
	gi.TextSize = 12
	gi.Font = Enum.Font.SourceSans
	gi.Text = text

	task.delay(delaySec, function()
		sc:Destroy()
	end)
end

local function bleed(part, po)
	local sx = math.random(5, 30) / 100
	local sy = math.random(5, 30) / 100
	local sz = math.random(5, 30) / 100
	local colorName = BLOOD_COLORS[math.random(1, #BLOOD_COLORS)]
	local p = Instance.new("Part")
	prop(p, part.Parent, false, 0, 0, sx, sy, sz, colorName, false)
	p.CFrame = part.CFrame * CFrame.new(math.random(-5, 5) / 10, po, math.random(-5, 5) / 10)
	p.Velocity = Vector3.new(math.random(-190, 190) / 10, math.random(-190, 190) / 10, math.random(-190, 190) / 10)
	p.RotVelocity = Vector3.new(math.random(-400, 400) / 10, math.random(-400, 400) / 10, math.random(-400, 400) / 10)
	task.delay(3, function()
		p:Destroy()
	end)
end

local function buildBricks(character)
	local bricks = character:FindFirstChild("Bricks")
	if bricks then
		bricks:Destroy()
	end

	local rarm = getLimb(character, "RightArm")
	local larm = getLimb(character, "LeftArm")
	local lleg = getLimb(character, "LeftLeg")
	local torso = getLimb(character, "Torso")
	local hum = getLimb(character, "Humanoid")
	if not (rarm and larm and lleg and torso and hum) then
		return nil
	end

	bricks = Instance.new("Model")
	bricks.Name = "Bricks"
	bricks.Parent = character

	local righthold = Instance.new("Part")
	righthold.Name = "righthold"
	prop(righthold, bricks, false, 1, 0, 1.5, 1.5, 1.5, "White", false)
	local w11 = Instance.new("Weld")
	w11.Name = "w11"
	weld(w11, rarm, righthold, 0, 0, 0, 0, 1, 0)

	local lefthold = Instance.new("Part")
	lefthold.Name = "lefthold"
	prop(lefthold, bricks, false, 1, 0, 1.5, 1.5, 1.5, "White", false)
	local w12 = Instance.new("Weld")
	w12.Name = "w12"
	weld(w12, larm, lefthold, 0, 0, 0, 0, 1, 0)

	local hold = Instance.new("Part")
	hold.Name = "hold"
	prop(hold, bricks, false, 0, 0, 0.2, 0.4, 0.7, "Really red", false)
	local oh = Instance.new("Weld")
	oh.Name = "oh"
	weld(oh, lleg, hold, -math.pi / 1.4, 0, math.rad(35), 0.55, -0.9, 0.3)

	local knife = Instance.new("Part")
	knife.Name = "knife"
	prop(knife, bricks, false, 0, 0, 0.35, 1.1, 0.5, "Really black", false)
	local orr = Instance.new("Weld")
	orr.Name = "orr"
	weld(orr, hold, knife, 0, 0, 0, 0, 0.7, 0)
	local ar = Instance.new("Weld")
	ar.Name = "ar"
	weld(ar, lefthold, nil, math.pi / 2, 0, math.pi, 0, 0, 0)

	local blade = Instance.new("Part")
	blade.Name = "blade"
	prop(blade, bricks, false, 0, 0, 0.1, 1.5, 0.4, "Medium grey", false)
	local w2 = Instance.new("Weld")
	w2.Name = "w2"
	weld(w2, knife, blade, 0, 0, 0, 0, -1.2, 0)

	local blade2 = Instance.new("Part")
	blade2.Name = "blade2"
	prop(blade2, bricks, false, 0, 0, 0.1, 0.5, 0.4, "Medium grey", false)
	local wedgeMesh = Instance.new("SpecialMesh")
	wedgeMesh.MeshType = Enum.MeshType.Wedge
	wedgeMesh.Scale = Vector3.new(0.3, 1, 1)
	wedgeMesh.Parent = blade2
	local w3 = Instance.new("Weld")
	w3.Name = "w3"
	weld(w3, blade, blade2, 0, 0, 0, 0, -1, 0)

	local rb = Instance.new("Part")
	rb.Name = "rb"
	prop(rb, bricks, false, 1, 0, 0.1, 0.1, 0.1, "White", false)
	local w13 = Instance.new("Weld")
	w13.Name = "w13"
	weld(w13, torso, rb, 0, 0, 0, -1.5, -0.5, 0)
	local lb = Instance.new("Part")
	lb.Name = "lb"
	prop(lb, bricks, false, 1, 0, 0.1, 0.1, 0.1, "White", false)
	local w14 = Instance.new("Weld")
	w14.Name = "w14"
	weld(w14, torso, lb, 0, 0, 0, 1.5, -0.5, 0)
	local rw = Instance.new("Weld")
	rw.Name = "rw"
	weld(rw, rb, nil, 0, 0, 0, 0, 0.5, 0)
	local lw = Instance.new("Weld")
	lw.Name = "lw"
	weld(lw, lb, nil, 0, 0, 0, 0, 0.5, 0)

	return bricks
end

-- Per-player state (used when server receives key press)
local playerStates = {}

local function setupTool(player)
	local tool = player:FindFirstChild("Grab")
	if not tool then
		tool = Instance.new("Tool")
		tool.Name = "Grab"
		tool.RequiresHandle = false
		tool.CanBeDropped = false

		local state = {
			selected = true,
			attacking = false,
			hurt = false,
			grabbed = nil,
			mode = "drop",
			grabweld = nil,
			platlol = nil,
			lolhum = nil,
			touchConnections = {},
		}
		playerStates[player] = state

		local function getBricks()
			local char = player.Character
			if not char then return nil end
			return char:FindFirstChild("Bricks")
		end

		local function touchCallback(h)
			if not state.hurt or state.grabbed then return end
			local root = h:FindFirstAncestorOfClass("Model")
			if not root or root == player.Character then return end
			local hu = root:FindFirstChild("Humanoid")
			local head = root:FindFirstChild("Head")
			local torz = root:FindFirstChild("Torso") or root:FindFirstChild("UpperTorso")
			if not (hu and head and torz) or hu.Health <= 0 then return end

			local bricks = getBricks()
			if not bricks then return end
			local righthold = bricks:FindFirstChild("righthold")
			local lefthold = bricks:FindFirstChild("lefthold")
			if not (righthold and lefthold) then return end

			state.grabbed = torz
			hu.PlatformStand = true
			local w = Instance.new("Weld")
			w.Part0 = righthold
			w.Part1 = torz
			w.C1 = CFrame.Angles(math.pi / 2, 0.2, 0) * CFrame.new(0.7, -0.9, -0.6)
			w.Parent = righthold
			state.grabweld = w
			state.lolhum = hu
			state.platlol = true
			hu:GetPropertyChangedSignal("PlatformStand"):Connect(function()
				if state.platlol then
					hu.PlatformStand = true
				end
			end)
		end

		local function resetArms(bricks)
			local lw = bricks:FindFirstChild("lw")
			local rw = bricks:FindFirstChild("rw")
			if lw then lw.C0 = CFrame.new(0, 0, 0); lw.Part1 = nil end
			if rw then rw.C0 = CFrame.new(0, 0, 0); rw.Part1 = nil end
		end

		local function desel(bricks)
			while state.attacking do
				task.wait(0.1)
			end
			local orr = bricks and bricks:FindFirstChild("orr")
			local ar = bricks and bricks:FindFirstChild("ar")
			local knife = bricks and bricks:FindFirstChild("knife")
			if orr then orr.Part1 = knife end
			if ar then ar.Part1 = nil end
		end

		local function selectTool()
			local bricks = getBricks()
			if not bricks then return end

			local orr = bricks:FindFirstChild("orr")
			local ar = bricks:FindFirstChild("ar")
			local knife = bricks:FindFirstChild("knife")
			local righthold = bricks:FindFirstChild("righthold")
			local lefthold = bricks:FindFirstChild("lefthold")
			local lw = bricks:FindFirstChild("lw")
			local rw = bricks:FindFirstChild("rw")
			local rarm = getLimb(player.Character, "RightArm")
			local larm = getLimb(player.Character, "LeftArm")
			local torso = getLimb(player.Character, "Torso")
			if not (orr and ar and knife and righthold and lefthold and lw and rw and rarm and larm and torso) then
				return
			end

			for _, conn in ipairs(state.touchConnections) do
				conn:Disconnect()
			end
			table.clear(state.touchConnections)
			table.insert(state.touchConnections, righthold.Touched:Connect(touchCallback))
			table.insert(state.touchConnections, lefthold.Touched:Connect(touchCallback))

			orr.Part1 = nil
			ar.Part1 = knife
		end

		local function onActivated()
			local bricks = getBricks()
			if not bricks then return end

			local orr = bricks:FindFirstChild("orr")
			local ar = bricks:FindFirstChild("ar")
			local knife = bricks:FindFirstChild("knife")
			local lw = bricks:FindFirstChild("lw")
			local rw = bricks:FindFirstChild("rw")
			local rarm = getLimb(player.Character, "RightArm")
			local larm = getLimb(player.Character, "LeftArm")
			local torso = getLimb(player.Character, "Torso")
			if not (orr and lw and rw and rarm and larm and torso) then return end

			if not state.attacking then
				state.attacking = true
				lw.Part1 = larm
				rw.Part1 = rarm
				state.hurt = true
				for i = 1, 8 do
					rw.C0 = rw.C0 * CFrame.new(-0.03, 0, -0.08) * CFrame.Angles(0.18, 0.04, 0)
					lw.C0 = lw.C0 * CFrame.new(0.06, 0, -0.06) * CFrame.Angles(0.15, -0.11, -0.05)
					task.wait(0.1)
				end
				task.wait(1)
				state.hurt = false
				if state.grabbed == nil then
					for i = 1, 4 do
						rw.C0 = rw.C0 * CFrame.new(0.06, 0, 0.16) * CFrame.Angles(-0.36, -0.08, 0)
						lw.C0 = lw.C0 * CFrame.new(-0.12, 0, 0.12) * CFrame.Angles(-0.3, 0.22, 0.05)
						task.wait(0.1)
					end
					resetArms(bricks)
					state.attacking = false
				end
			elseif not state.hurt and state.grabbed and state.mode == "drop" then
				if state.grabweld then state.grabweld:Destroy(); state.grabweld = nil end
				state.platlol = false
				state.grabbed = nil
				if state.lolhum then state.lolhum.PlatformStand = false; state.lolhum = nil end
				for i = 1, 4 do
					rw.C0 = rw.C0 * CFrame.new(0.06, 0, 0.16) * CFrame.Angles(-0.36, -0.08, 0)
					lw.C0 = lw.C0 * CFrame.new(-0.12, 0, 0.16) * CFrame.Angles(-0.3, 0.2, 0)
					task.wait(0.1)
				end
				resetArms(bricks)
				state.attacking = false
				state.platlol = nil
			elseif not state.hurt and state.grabbed and state.grabweld and state.mode == "throw" then
				state.grabweld:Destroy()
				state.grabweld = nil
				local att = Instance.new("Attachment")
				att.Parent = state.grabbed
				local vf = Instance.new("VectorForce")
				vf.Attachment0 = att
				vf.Force = torso.CFrame.LookVector * 8500 + Vector3.new(0, 7400, 0)
				vf.Parent = state.grabbed
				task.delay(0.12, function()
					vf:Destroy()
					att:Destroy()
				end)
				for i = 1, 6 do
					rw.C0 = rw.C0 * CFrame.Angles(0.35, 0, 0)
					lw.C0 = lw.C0 * CFrame.Angles(-0.18, 0, 0)
					task.wait(0.1)
				end
				for i = 1, 4 do
					rw.C0 = rw.C0 * CFrame.Angles(-0.47, 0, 0)
					lw.C0 = lw.C0 * CFrame.Angles(0.2, 0, 0)
					task.wait(0.1)
				end
				task.wait(0.2)
				state.platlol = false
				state.grabbed = nil
				if state.lolhum then state.lolhum.PlatformStand = false; state.lolhum = nil end
				for i = 1, 4 do
					rw.C0 = rw.C0 * CFrame.new(0.06, 0, 0.16) * CFrame.Angles(-0.36, -0.08, 0)
					lw.C0 = lw.C0 * CFrame.new(-0.12, 0, 0.16) * CFrame.Angles(-0.3, 0.2, 0)
					task.wait(0.1)
				end
				resetArms(bricks)
				state.attacking = false
				state.platlol = nil
			elseif not state.hurt and state.grabbed and state.lolhum and state.grabweld and state.mode == "kill" then
				for i = 1, 5 do
					lw.C0 = lw.C0 * CFrame.new(0.02, 0.12, 0.1) * CFrame.Angles(-0.05, 0, -0.03)
					task.wait(0.1)
				end
				local ne = state.grabbed:FindFirstChild("Neck")
				local duh = state.grabbed
				local duh2 = state.grabbed.Parent and state.grabbed.Parent:FindFirstChild("Head")
				local lolas = state.lolhum
				task.spawn(function()
					duh.RotVelocity = Vector3.new(math.random(-20, 20), math.random(-20, 20), math.random(-20, 20))
					for _ = 1, 60 do
						task.wait(0.1)
						if math.random(1, 9) == 1 and duh2 then
							local snd = duh2:FindFirstChild("Sound")
							if snd and snd:IsA("Sound") then
								snd.Pitch = math.random(90, 110) / 100
								snd:Play()
							end
						end
						if math.random(1, 9) < 3 then
							bleed(duh, 1)
							if duh2 then bleed(duh2, -0.5) end
						end
					end
					lolas.Health = 0
					for _ = 1, 85 do
						task.wait(0.1)
						if math.random(1, 9) == 1 and duh2 then
							local snd = duh2:FindFirstChild("Sound")
							if snd and snd:IsA("Sound") then
								snd.Pitch = math.random(90, 110) / 100
								snd:Play()
							end
						end
						if math.random(1, 9) < 3 then
							bleed(duh, 1)
							if duh2 then bleed(duh2, -0.5) end
						end
					end
				end)
				for i = 1, 3 do
					lw.C0 = lw.C0 * CFrame.new(0.02, 0.12, 0.1) * CFrame.Angles(-0.05, 0, -0.03)
					if ne then
						duh.Neck.C0 = duh.Neck.C0 * CFrame.Angles(-0.35, 0, 0)
					end
					task.wait(0.1)
				end
				if state.grabweld then state.grabweld:Destroy(); state.grabweld = nil end
				for i = 1, 4 do
					lw.C0 = lw.C0 * CFrame.new(-0.04, -0.24, -0.2) * CFrame.Angles(0.1, 0, 0.06)
					task.wait(0.1)
				end
				for i = 1, 4 do
					rw.C0 = rw.C0 * CFrame.new(0.06, 0, 0.16) * CFrame.Angles(-0.36, -0.08, 0)
					lw.C0 = lw.C0 * CFrame.new(-0.12, 0, 0.12) * CFrame.Angles(-0.3, 0.22, 0.05)
					task.wait(0.1)
				end
				resetArms(bricks)
				state.platlol = false
				state.grabbed = nil
				state.lolhum = nil
				state.attacking = false
				state.platlol = nil
			end
		end

		tool.Equipped:Connect(selectTool)
		tool.Unequipped:Connect(function()
			desel(getBricks())
		end)
		tool.Activated:Connect(onActivated)
	end

	tool.Parent = player:FindFirstChild("Backpack") or player:WaitForChild("Backpack", 10)
end

-- Key press from client (Q/E/F)
keyEvent.OnServerEvent:Connect(function(player, keyName)
	local state = playerStates[player]
	if not state then return end
	local pgui = player:FindFirstChild("PlayerGui")
	if not pgui then return end
	keyName = keyName and keyName:lower()
	if keyName == "q" then
		state.mode = "drop"
		inform(pgui, "Mode: Drop", 2)
	elseif keyName == "e" then
		state.mode = "throw"
		inform(pgui, "Mode: Throw", 2)
	elseif keyName == "f" then
		state.mode = "kill"
		inform(pgui, "Mode: Kill", 2)
	end
end)

-- Clean up state when player leaves
Players.PlayerRemoving:Connect(function(player)
	playerStates[player] = nil
end)

-- Run for each player on join + respawn
local function onCharacterAdded(player, character)
	local bricks = buildBricks(character)
	if not bricks then return end
	setupTool(player)
	inform(player:WaitForChild("PlayerGui", 5), "Grab script loaded successfully.", 2)
end

for _, player in ipairs(Players:GetPlayers()) do
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		task.spawn(onCharacterAdded, player, player.Character)
	end
end
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		task.spawn(onCharacterAdded, player, player.Character)
	end
end)
