-- remade by curelessdoktor optimising stuff, have fun skids.

local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local Debris = game:GetService('Debris')
local UserInputService = game:GetService('UserInputService')

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local JOINT_TEMPLATES = {
	RightShoulder = { C0 = CFrame.new(1, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), C1 = CFrame.new(-0.5, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0) },
	LeftShoulder  = { C0 = CFrame.new(-1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), C1 = CFrame.new(0.5, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0) },
	RootJoint     = { C0 = CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0), C1 = CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0) }
}

local JOINT_PROPS = { hand = {{"LimitsEnabled",true},{"UpperAngle",0},{"LowerAngle",0}}, shin = {{"LimitsEnabled",true},{"UpperAngle",0},{"LowerAngle",-75}}, foot = {{"LimitsEnabled",true},{"UpperAngle",15},{"LowerAngle",-45}} }

local rekt = {}
local BLOOD_COLOR = Color3.fromRGB(117, 0, 0)

local function unanchorPart(part)
	for _, c in ipairs(part:GetChildren()) do
		if c:IsA('Weld') or c:IsA('Motor6D') then c:Destroy() end
	end
	if part.Parent then
		for _, c in ipairs(part.Parent:GetChildren()) do
			if (c:IsA('Weld') or c:IsA('Motor6D')) and (c.Part0 == part or c.Part1 == part) then c:Destroy() end
		end
	end
end

local function applyForce(part, force, duration)
	local att = Instance.new("Attachment", part)
	local vf = Instance.new("VectorForce", part)
	vf.Attachment0 = att
	vf.Force = force
	vf.RelativeTo = Enum.ActuatorRelativeTo.World
	Debris:AddItem(vf, duration or 0.25)
	Debris:AddItem(att, duration or 0.25)
end

local function stun(ch)
	pcall(function() ch:FindFirstChildOfClass('Humanoid'):ChangeState(Enum.HumanoidStateType.Physics) end)
	for _, v in ipairs(rekt) do if v == ch then return end end
	table.insert(rekt, ch)
end

local function unstun(ch)
	for i, v in ipairs(rekt) do
		if v == ch then
			local hum = v:FindFirstChildOfClass('Humanoid')
			if hum and hum.Health > 0 then
				hum:ChangeState(Enum.HumanoidStateType.Running)
				hum.PlatformStand = false
				hum.Sit = false
				hum.Jump = true
				hum.JumpPower = 50
				hum.WalkSpeed = 16
				hum.Name = "Humanoid"
			end
			table.remove(rekt, i)
			return
		end
	end
end

local function removewelds(part)
	for _, v in ipairs(part:GetChildren()) do
		if v:IsA('Weld') then v:Destroy() end
	end
end

local function makeHinge(parent, a0, a1)
	local c = Instance.new("HingeConstraint")
	c.Attachment0 = a0
	c.Attachment1 = a1
	c.LimitsEnabled = true
	c.UpperAngle = 0
	c.LowerAngle = 0
	c.Parent = parent
end

local function bleed(frick)
	while frick.Parent and frick.Parent.Parent do
		task.spawn(function()
			local drop = Instance.new('Part', workspace)
			drop.Size = Vector3.new(0.2, 0.2, 0.2)
			drop.CFrame = frick.CFrame
			drop.Transparency = 1
			drop.Color = BLOOD_COLOR
			drop.Material = Enum.Material.SmoothPlastic
			drop.Name = "Blood"
			drop.CanCollide = false
			unanchorPart(drop)
			local att = Instance.new("Attachment", drop)
			local lv = Instance.new("LinearVelocity", drop)
			lv.Attachment0 = att
			lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
			lv.MaxForce = math.huge
			lv.RelativeTo = Enum.ActuatorRelativeTo.World
			lv.VectorVelocity = frick.CFrame.upVector * (math.random() * 2) + Vector3.new(math.random(-5, 5) / 10, 1.5, 0)
			Debris:AddItem(lv, 0.15)
			Debris:AddItem(att, 0.15)
			Debris:AddItem(drop, 1)
		end)
		task.wait()
	end
end

local function recurse(root, callback)
	for _, v in ipairs(root:GetChildren()) do
		callback(v)
		if #v:GetChildren() > 0 then recurse(v, callback) end
	end
end

local function getAttachment0(char, name)
	for _, child in ipairs(char:GetChildren()) do
		local att = child:FindFirstChild(name)
		if att then return att end
	end
end

local function addCollider(char, part, sizeDivisor, offY)
	if not (char:FindFirstChildOfClass('Humanoid') and char:FindFirstChildOfClass('Humanoid').Health > 0) then return end
	local col = Instance.new('Part', part)
	col.Size = part.Size / (sizeDivisor or 2)
	col.CanCollide = true
	col.Name = "Collision"
	col.Anchored = false
	col.Transparency = 1
	col.CFrame = part.CFrame
	unanchorPart(col)
	local a0 = Instance.new('Attachment', part)
	local a1 = Instance.new('Attachment', col)
	if offY then a0.Position = Vector3.new(0, offY, 0) end
	makeHinge(char, a0, a1)
end

local function ragdollJoint(char, part0, part1, attName, class, props)
	if char:FindFirstChild("RagdollConstraint" .. part1.Name) then return end
	local hrp = char:FindFirstChild('HumanoidRootPart')
	if hrp then hrp.CanCollide = false end
	recurse(char, function(v)
		if v:IsA("Attachment") and v.Parent.Name ~= "ayybleed" then
			v.Axis = Vector3.new(0, 1, 0)
			v.SecondaryAxis = Vector3.new(0, 0, 1)
			v.Rotation = Vector3.new(0, 0, 0)
		end
	end)
	local motor = part1:FindFirstChildOfClass('Motor6D')
	if motor then motor:Destroy() end
	if attName ~= "NeckAttachment" then attName = attName .. "RigAttachment" end
	local constraint = Instance.new(class .. "Constraint")
	constraint.Attachment0 = part0:FindFirstChild(attName)
	constraint.Attachment1 = part1:FindFirstChild(attName)
	constraint.Name = "RagdollConstraint" .. part1.Name
	for _, p in ipairs(props or {}) do constraint[p[1]] = p[2] end
	constraint.Parent = char
	local div = 2
	if part1.Name:lower():find("upper") then div = part1.Name:lower():find("leg") and 3 or 2.5 end
	local offY = part1.Name:lower():find("upper") and (part1.Name:lower():find("leg") and 0.01 or 0.25) or -0.1
	addCollider(char, part1, div, offY)
end

local function doHeadRagdoll(char)
	local hum = char:FindFirstChildOfClass('Humanoid')
	if hum then hum.Health = 0 end
	while char:FindFirstChildOfClass('Humanoid') and char:FindFirstChildOfClass('Humanoid').Health > 0 do task.wait() end
	local hrp = char:FindFirstChild('HumanoidRootPart')
	if hrp then hrp:Destroy() end
	Debris:AddItem(char, 10)
end

local function R6ragdollJoint(char, limbname, stunChar)
	pcall(function()
		local torso = char:FindFirstChild("Torso")
		if not torso or not char:FindFirstChild(limbname) then return end
		local data = {
			["Right Arm"] = { torsoPos = Vector3.new(1.45, 0.768, -0.009), joint = "Right Shoulder" },
			["Left Arm"]  = { torsoPos = Vector3.new(-1.45, 0.768, -0.009), joint = "Left Shoulder" },
			["Right Leg"] = { torsoPos = Vector3.new(0.45, -1.242, -0.009), joint = "Right Hip", stun = true },
			["Left Leg"]  = { torsoPos = Vector3.new(-0.45, -1.242, -0.009), joint = "Left Hip", stun = true },
		}
		local d = data[limbname]
		if not d then return end
		if d.stun and stunChar then stun(char) end
		if torso:FindFirstChild(limbname .. "RagdollConstraint") then return end
		local ta = Instance.new('Attachment', torso)
		ta.Name = limbname .. "RagdollConstraint"
		ta.Position = d.torsoPos
		ta.Axis = Vector3.new(1, 0, 0)
		ta.SecondaryAxis = Vector3.new(0, 1, 0)
		local la = Instance.new('Attachment', char[limbname])
		la.Position = Vector3.new(-0.086, 0.755, -0.007)
		la.Name = limbname .. "RagdollConstraint"
		la.Axis = Vector3.new(1, 0, 0)
		la.SecondaryAxis = Vector3.new(0, 1, 0)
		local ball = Instance.new('BallSocketConstraint', char)
		ball.Attachment0 = ta
		ball.Attachment1 = la
		addCollider(char, char[limbname], 1.5)
		if torso:FindFirstChild(d.joint) then torso[d.joint]:Destroy() end
	end)
end

function ragdollpart(character, partname, heded)
	if heded ~= false then
		pcall(function()
			Instance.new('Attachment', character.Head).Name = "NeckAttachment"
			Instance.new('Attachment', character.Head).Position = Vector3.new(0, -0.5, 0)
		end)
	end
	if partname == "HumanoidRootPart" then partname = character:FindFirstChild('Torso') and "Torso" or "UpperTorso" end
	local R15routes = {
		RightHand = true, RightLowerArm = true, RightUpperArm = true, LeftHand = true, LeftLowerArm = true, LeftUpperArm = true,
		RightFoot = true, RightUpperLeg = true, RightLowerLeg = true, LeftFoot = true, LeftUpperLeg = true, LeftLowerLeg = true,
		Head = true, UpperTorso = true, LowerTorso = true
	}
	local hum = character:FindFirstChildOfClass('Humanoid')
	if R15routes[partname] and hum and hum.RigType == Enum.HumanoidRigType.R15 then
		if partname == "Head" or partname == "UpperTorso" or partname == "LowerTorso" then
			doHeadRagdoll(character)
		elseif partname:find("Right") or partname:find("Left") then
			local side = partname:find("Right") and "Right" or "Left"
			if partname:find("Arm") or partname:find("Hand") then
				ragdollJoint(character, character[side .. "LowerArm"], character[side .. "Hand"], side .. "Wrist", "Hinge", JOINT_PROPS.hand)
				ragdollJoint(character, character.UpperTorso, character[side .. "UpperArm"], side .. "Shoulder", "BallSocket")
				ragdollJoint(character, character[side .. "UpperArm"], character[side .. "LowerArm"], side .. "Elbow", "BallSocket")
			else
				stun(character)
				ragdollJoint(character, character[side .. "UpperLeg"], character[side .. "LowerLeg"], side .. "Knee", "Hinge", JOINT_PROPS.shin)
				ragdollJoint(character, character[side .. "LowerLeg"], character[side .. "Foot"], side .. "Ankle", "Hinge", JOINT_PROPS.foot)
				ragdollJoint(character, character.LowerTorso, character[side .. "UpperLeg"], side .. "Hip", "BallSocket")
			end
		end
		if character:FindFirstChild('HumanoidRootPart') then character.HumanoidRootPart:Destroy() end
	else
		R6ragdollJoint(character, partname, true)
	end
end

local function ragdollAllLimbs(target)
	pcall(function()
		ragdollpart(target, "Right Arm")
		ragdollpart(target, "Right Leg")
		ragdollpart(target, "Left Arm")
		ragdollpart(target, "Left Leg")
	end)
	pcall(function()
		ragdollpart(target, "RightUpperArm")
		ragdollpart(target, "RightUpperLeg")
		ragdollpart(target, "LeftUpperArm")
		ragdollpart(target, "LeftUpperLeg")
	end)
end

local function lerp(weld, startpos, endpos, t, longatend)
	for i = 1, t * 100 do
		if longatend then startpos = weld.C0 end
		weld.C0 = startpos:Lerp(endpos, i / (t * 100))
		task.wait(0.01)
	end
end

local function grow(weld, part, endSize, endPos, t)
	local startC1, startSize = weld.C1, part.Size
	local parent = weld.Parent
	for i = 1, t * 100 do
		weld.C1 = startC1:Lerp(endPos, i / (t * 100))
		part.Size = startSize:Lerp(endSize, i / (t * 100))
		weld.Parent = parent
		task.wait(0.01)
	end
end

local function restoreArms(char)
	pcall(function()
		if JOINT_TEMPLATES.RightShoulder and char:FindFirstChild('Right Arm') and char:FindFirstChild('Torso') then
			local t = JOINT_TEMPLATES.RightShoulder
			local m = Instance.new('Motor6D')
			m.Name = "Right Shoulder"
			m.C0 = t.C0
			m.C1 = t.C1
			m.Part0 = char.Torso
			m.Part1 = char["Right Arm"]
			m.Parent = char.Torso
		end
	end)
	pcall(function()
		if JOINT_TEMPLATES.LeftShoulder and char:FindFirstChild('Left Arm') and char:FindFirstChild('Torso') then
			local t = JOINT_TEMPLATES.LeftShoulder
			local m = Instance.new('Motor6D')
			m.Name = "Left Shoulder"
			m.C0 = t.C0
			m.C1 = t.C1
			m.Part0 = char.Torso
			m.Part1 = char["Left Arm"]
			m.Parent = char.Torso
		end
	end)
	pcall(function()
		if JOINT_TEMPLATES.RootJoint and char:FindFirstChild('Torso') and char:FindFirstChild('HumanoidRootPart') then
			local t = JOINT_TEMPLATES.RootJoint
			local m = Instance.new('Motor6D')
			m.Name = "RootJoint"
			m.C0 = t.C0
			m.C1 = t.C1
			m.Part0 = char.HumanoidRootPart
			m.Part1 = char.Torso
			m.Parent = char.HumanoidRootPart
		end
	end)
end

local function makeWeld(parent, p0, p1, c0)
	local w = Instance.new('Weld', parent)
	w.Part0 = p0
	w.Part1 = p1
	if c0 then w.C0 = c0 end
	return w
end

local function makeTrail(handle)
	local a1 = Instance.new("Attachment", handle)
	a1.Visible = false
	a1.Position = Vector3.new(5, 0, 0)
	local a2 = Instance.new("Attachment", handle)
	a2.Visible = false
	a2.Position = Vector3.new(1, 0, 0)
	local trail = Instance.new("Trail", handle)
	trail.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1))
	trail.LightEmission = 0.25
	trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 1) })
	trail.Lifetime = 0.1
	trail.MinLength = 0.05
	trail.Attachment0 = a1
	trail.Attachment1 = a2
	return trail, a1, a2
end

function spawned()
	local usable = true
	local working = false
	local equipped = false
	local char = player.Character
	local grabbing = false
	local grabbed = nil
	local grabweld = nil

	if not char then return end
	while not char:FindFirstChildOfClass('Humanoid') or not char:FindFirstChild('Head') do task.wait() end

	local handle = Instance.new("Part", char)
	handle.Color = Color3.fromRGB(17, 17, 17)
	handle.Material = Enum.Material.Metal
	handle.CanCollide = false
	handle.Shape = Enum.PartType.Cylinder
	handle.Size = Vector3.new(1.1, 0.3, 0.3)
	handle.Name = "handle"
	for _, surf in ipairs({ "Back", "Bottom", "Front", "Left", "Right", "Top" }) do
		handle[surf .. "Surface"] = Enum.SurfaceType.SmoothNoOutlines
	end

	local hweld = makeWeld(char.Torso, char.Torso, handle, CFrame.new(1, -0.8, 0) * CFrame.Angles(0, math.rad(90), 0))

	local function getrid()
		if grabbed then
			unstun(grabbed)
			grabbed = nil
			if grabweld then grabweld:Destroy() end
		end
		for _, ree in ipairs(handle:GetChildren()) do
			if ree:IsA('BasePart') then
				ree:Destroy()
			else
				ree:Remove()
			end
		end
	end

	local function equip()
		equipped = true
		working = true
		local rs = char.Torso:FindFirstChild("Right Shoulder")
		if rs then rs:Destroy() end
		local weld = makeWeld(char.Torso, char["Right Arm"], char.Torso, CFrame.new(-1.5, 0, 0))
		lerp(weld, weld.C0, CFrame.new(-1.3, -0.5, 0) * CFrame.Angles(0, 0, math.rad(15)), 0.12, true)
		task.wait(0.1)
		hweld.Part0 = char["Right Arm"]
		hweld.C0 = CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(-180), math.rad(-90), 0)
		lerp(weld, weld.C0, CFrame.new(-1.5, 0, 0), 0.08)
		weld:Destroy()
		restoreArms(char)
		local function mkp(isWedge, name, size, color, mat, shape)
			local p = isWedge and Instance.new("WedgePart") or Instance.new("Part")
			p.Name = name
			p.Parent = handle
			p.Material = mat or Enum.Material.SmoothPlastic
			p.Size = size
			p.Anchored = false
			if not isWedge then p.Friction = 0.3 end
			p.Color = color
			if shape then p.Shape = shape end
			for _, s in ipairs({ "Top", "Bottom", "Left", "Right", "Front", "Back" }) do
				p[s .. "Surface"] = Enum.SurfaceType.SmoothNoOutlines
			end
			unanchorPart(p)
			return p
		end
		local pom = mkp(false, "cap", Vector3.new(0.32, 0.32, 0.32), Color3.fromRGB(17, 17, 17), nil, Enum.PartType.Ball)
		local pomw = makeWeld(pom, pom, handle)
		pomw.C0 = CFrame.new(-0.43, 0, 0)
		grow(pomw, pom, Vector3.new(0.32, 0.32, 0.32), CFrame.new(-0.43, 0, 0), 0.1)
		local grip = mkp(false, "cap", Vector3.new(0.25, 0.1, 0.25), Color3.fromRGB(17, 17, 17), nil, Enum.PartType.Cylinder)
		local gripw = makeWeld(grip, grip, handle)
		gripw.C0 = CFrame.new(-0.02, 0, 0) * CFrame.Angles(0, 0, math.rad(90))
		task.spawn(function() grow(gripw, grip, Vector3.new(0.25, 0.8, 0.25), CFrame.new(-0.02, 0, 0) * CFrame.Angles(0, 0, math.rad(90)), 0.09) end)
		local tc = mkp(false, "cap", Vector3.new(0.3, 0.3, 0.3), Color3.fromRGB(17, 17, 17), nil, Enum.PartType.Ball)
		local tcw = makeWeld(tc, tc, handle)
		tcw.C0 = CFrame.new(0.38, 0, 0)
		grow(tcw, tc, Vector3.new(0.3, 0.3, 0.3), CFrame.new(0.38, 0, 0), 0.1)
		local obj4 = mkp(false, "blade", Vector3.new(0.23, 0.1, 0.1), Color3.fromRGB(99, 95, 98), Enum.Material.Metal)
		local w4 = makeWeld(obj4, obj4, handle)
		w4.C0 = CFrame.new(0, -0.535, 0) * CFrame.Angles(0, 0, math.rad(90))
		task.spawn(function() grow(w4, obj4, Vector3.new(0.23, 1.35, 0.1), CFrame.new(0.57, 0, 0), 0.09) end)
		local obj5 = mkp(false, "blade", Vector3.new(0.1, 0.1, 0.05), Color3.fromRGB(236, 218, 190), Enum.Material.Metal)
		local w5 = makeWeld(obj5, obj5, obj4)
		w5.C0 = CFrame.new(0.09, 0, 0)
		grow(w5, obj5, Vector3.new(0.1, 1.35, 0.05), CFrame.new(0.09, 0, 0), 0.09)
		local obj3 = Instance.new("WedgePart")
		obj3.Name = "blade"
		obj3.Parent = handle
		for _, s in ipairs({ "Top", "Bottom", "Left", "Right", "Front", "Back" }) do obj3[s .. "Surface"] = Enum.SurfaceType.SmoothNoOutlines end
		obj3.Material = Enum.Material.Metal
		obj3.Size = Vector3.new(0.1, 0, 0.23)
		obj3.Anchored = false
		obj3.Color = Color3.fromRGB(99, 95, 98)
		unanchorPart(obj3)
		local w6 = makeWeld(obj3, obj3, obj4, CFrame.new(0, -0.675, 0) * CFrame.Angles(0, math.rad(270), 0))
		task.spawn(function() grow(w6, obj3, Vector3.new(0.1, 0.3, 0.23), CFrame.new(0, 0.15, 0), 0.05) end)
		task.spawn(function()
			local bladeParts = { obj4, obj5, obj3 }
			local origColors = { Color3.fromRGB(99, 95, 98), Color3.fromRGB(236, 218, 190), Color3.fromRGB(99, 95, 98) }
			local hotRed = Color3.fromRGB(255, 70, 15)
			for i, p in ipairs(bladeParts) do p.Color = hotRed end
			local pe = Instance.new("ParticleEmitter", obj4)
			pe.Color = ColorSequence.new(Color3.fromRGB(255, 40, 0), Color3.fromRGB(255, 120, 30))
			pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(0.5, 0.35), NumberSequenceKeypoint.new(1, 0) })
			pe.Lifetime = NumberRange.new(0.25, 0.5)
			pe.Rate = 120
			pe.Speed = NumberRange.new(4, 12)
			pe.SpreadAngle = Vector2.new(180, 180)
			pe.LightEmission = 1
			pe.LightInfluence = 0.4
			pe.Texture = "rbxassetid://243660364"
			task.delay(0.5, function()
				pe.Enabled = false
				Debris:AddItem(pe, 0.6)
			end)
			for step = 1, 25 do
				task.wait(0.02)
				for i, p in ipairs(bladeParts) do
					if p and p.Parent then p.Color = hotRed:Lerp(origColors[i], step / 25) end
				end
			end
		end)
		working = false
	end

	local function unequip()
		getrid()
		equipped = false
		working = true
		local rs = char.Torso:FindFirstChild("Right Shoulder")
		if rs then rs:Destroy() end
		local weld = makeWeld(char.Torso, char["Right Arm"], char.Torso, CFrame.new(-1.5, 0, 0))
		lerp(weld, weld.C0, CFrame.new(-1.3, -0.5, 0) * CFrame.Angles(0, 0, math.rad(15)), 0.12, true)
		hweld.Part0 = char.Torso
		hweld.C0 = CFrame.new(1, -0.8, 0) * CFrame.Angles(0, math.rad(90), 0)
		lerp(weld, weld.C0, CFrame.new(-1.5, 0, 0), 0.08, true)
		weld:Destroy()
		restoreArms(char)
		working = false
	end

	handle.ChildAdded:Connect(function(child)
		if child:IsA('BasePart') then
			child.Touched:Connect(function(hit)
				if not hit.Parent then return end
				if grabbing and grabbed == nil then
					local hum = hit.Parent:FindFirstChildOfClass('Humanoid')
					if hum and hum.Health > 0 and hit.Parent ~= char then
						grabbed = hit.Parent
						stun(grabbed)
						local gw = Instance.new("Weld", char.Torso)
						gw.Part0 = char.Torso
						pcall(function() gw.Part1 = grabbed.Torso end)
						pcall(function() gw.Part1 = grabbed.UpperTorso end)
						gw.C0 = CFrame.new(-0.45, 0, -1)
						grabweld = gw
					end
				end
			end)
		end
	end)

	local function makeArmWelds()
		local rweld = makeWeld(char["Right Arm"], char.Torso, char["Right Arm"], CFrame.new(1.5, 0, 0))
		local lweld = makeWeld(char["Left Arm"], char.Torso, char["Left Arm"], CFrame.new(-1.5, 0, 0))
		return rweld, lweld
	end

	local function makeTorsoWeld()
		return makeWeld(char.HumanoidRootPart, char.HumanoidRootPart, char.Torso)
	end

	local function makeKnifeTrail()
		local t, a1, a2 = makeTrail(handle)
		a1.Position = Vector3.new(2, 0, 0)
		a2.Position = Vector3.new(-0.3, 0, 0)
		t.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.75), NumberSequenceKeypoint.new(1, 1) })
		return t, a1, a2
	end

	local function cleanupWelds(rweld, lweld, tweld)
		pcall(function() rweld:Remove() end)
		pcall(function() lweld:Remove() end)
		pcall(function() tweld:Remove() end)
		restoreArms(char)
	end

	local function grab()
		working = true
		pcall(function()
			local rweld, lweld = makeArmWelds()
			local trail, a1, a2 = makeKnifeTrail()
			task.spawn(function()
				lerp(hweld, hweld.C0, CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(-90), 0, 0), 0.07)
				lerp(hweld, hweld.C0, CFrame.new(0, -1, 0) * CFrame.Angles(0, math.rad(90), 0), 0.07)
			end)
			task.spawn(function() lerp(rweld, rweld.C0, CFrame.new(2, 0.5, 0) * CFrame.Angles(0, 0, math.rad(90)), 0.08) end)
			lerp(lweld, lweld.C0, CFrame.new(-2, 0.5, 0) * CFrame.Angles(0, 0, math.rad(-90)), 0.08)
			task.wait(0.15)
			grabbing = true
			task.spawn(function() lerp(rweld, rweld.C0, CFrame.new(1, 0.7, -0.75) * CFrame.Angles(0, math.rad(95), math.rad(105)), 0.08) end)
			lerp(lweld, lweld.C0, CFrame.new(-1.25, 0.7, -0.75) * CFrame.Angles(0, math.rad(-140), math.rad(-105)), 0.08)
			a1:Remove()
			a2:Remove()
			trail:Remove()
			task.wait(0.3)
			grabbing = false
			if grabbed == nil then
				task.spawn(function() lerp(rweld, rweld.C0, CFrame.new(1.5, 0, 0), 0.08) end)
				task.spawn(function() lerp(hweld, hweld.C0, CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(-180), math.rad(-90), 0), 0.08) end)
				lerp(lweld, lweld.C0, CFrame.new(-1.5, 0, 0), 0.08)
				lweld:Remove()
				rweld:Remove()
				restoreArms(char)
			end
		end)
		working = false
	end

	local function release()
		working = true
		pcall(function()
			unstun(grabbed)
			grabbed = nil
			grabweld:Destroy()
			removewelds(char["Right Arm"])
			removewelds(char["Left Arm"])
			local rweld = makeWeld(char["Right Arm"], char.Torso, char["Right Arm"], CFrame.new(1, 0.7, -0.75) * CFrame.Angles(0, math.rad(95), math.rad(105)))
			local lweld = makeWeld(char["Left Arm"], char.Torso, char["Left Arm"], CFrame.new(-1.25, 0.7, -0.75) * CFrame.Angles(0, math.rad(-140), math.rad(-105)))
			task.spawn(function() lerp(rweld, rweld.C0, CFrame.new(1.5, 0, 0), 0.08) end)
			task.spawn(function() lerp(hweld, hweld.C0, CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(-180), math.rad(-90), 0), 0.08) end)
			lerp(lweld, lweld.C0, CFrame.new(-1.5, 0, 0), 0.08)
			lweld:Remove()
			rweld:Remove()
			restoreArms(char)
		end)
		working = false
	end

	local function kill()
		working = true
		pcall(function()
			local rweld = char["Right Arm"]:FindFirstChild("Weld")
			local lweld = char["Left Arm"]:FindFirstChild("Weld")
			local tweld = makeTorsoWeld()
			local ks = Instance.new("Sound", grabbed.Head)
			ks.SoundId = "rbxassetid://150315649"
			ks.PlaybackSpeed = math.random(9, 12) / 10
			local ts = Instance.new("Sound", char.Head)
			ts.SoundId = "rbxassetid://711753382"
			ts.PlaybackSpeed = 0.75
			pcall(function() grabbed.HumanoidRootPart:Destroy() end)
			lerp(rweld, rweld.C0, CFrame.new(0.5, 0.7, -0.7) * CFrame.Angles(0, math.rad(100), math.rad(105)), 0.1)
			task.wait(0.2)
			lerp(rweld, rweld.C0, CFrame.new(2, 0.5, 0) * CFrame.Angles(0, 0, math.rad(90)), 0.04)
			ks:Play()
			local ab = Instance.new('Part', grabbed)
			ab.Size = Vector3.new(0.2, 0.2, 0.2)
			ab.Color = BLOOD_COLOR
			ab.Material = Enum.Material.SmoothPlastic
			ab.Name = "ayybleed"
			ab.CanCollide = false
			ab.Transparency = 0.5
			ab.CFrame = grabbed.Head.CFrame
			unanchorPart(ab)
			local a1 = Instance.new('Attachment', ab)
			a1.Position = Vector3.new(-0.55, 0, 0)
			a1.Orientation = Vector3.new(90, 0, -90)
			local a0 = Instance.new('Attachment')
			pcall(function() a0.Parent = grabbed.Torso end)
			pcall(function() a0.Parent = grabbed.UpperTorso end)
			pcall(function() makeHinge(grabbed:FindFirstChild('Torso') or grabbed:FindFirstChild('UpperTorso'), a0, a1) end)
			task.spawn(function() bleed(ab) end)
			task.wait(0.2)
			grabweld:Remove()
			ts:Play()
			local tvPart = grabbed:FindFirstChild("Torso") or grabbed:FindFirstChild("UpperTorso")
			if tvPart then
				local tvAtt = Instance.new("Attachment", tvPart)
				local tvF = Instance.new("VectorForce", tvPart)
				tvF.Attachment0 = tvAtt
				tvF.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
				tvF.Force = Vector3.new(0, 3000, -1000)
				task.delay(0.15, function() tvF:Destroy() tvAtt:Destroy() end)
			end
			lerp(lweld, lweld.C0, CFrame.new(-1.3, 0.7, -1) * CFrame.Angles(0, math.rad(-70), math.rad(-105)), 0.04)
			ragdollAllLimbs(grabbed)
			task.wait(0.15)
			task.spawn(function() lerp(lweld, lweld.C0, CFrame.new(-1.5, 0, 0), 0.08) end)
			task.spawn(function() lerp(rweld, rweld.C0, CFrame.new(1.5, 0, 0), 0.08) end)
			lerp(tweld, tweld.C0, CFrame.new(0, 0, 0), 0.08)
			cleanupWelds(rweld, lweld, tweld)
			task.spawn(function()
				local victim = grabbed
				for _ = 1, 20 do
					pcall(function()
						local h = victim:FindFirstChildOfClass('Humanoid')
						if h and h.Health > 0 then h.Health = h.Health - 4.9 end
					end)
					task.wait(0.2)
				end
				pcall(function() ragdollpart(victim, "Head") end)
			end)
			grabbed = nil
		end)
		working = false
	end

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
		if input.KeyCode ~= Enum.KeyCode.Z then return end
		if usable and not working then
			if not equipped then
				equip()
			else
				unequip()
			end
		end
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		if usable and not working and equipped then
			if grabbed == nil then
				grab()
			else
				kill()
			end
		end
	end)
end

spawned()
player.CharacterAdded:Connect(spawned)

RunService.Heartbeat:Connect(function()
	for i = #rekt, 1, -1 do
		local v = rekt[i]
		if v and v.Parent then
			local hum = v:FindFirstChildOfClass('Humanoid')
			if hum and hum.Health > 0 then
				hum.PlatformStand = true
				hum.Sit = false
				hum.JumpPower = 0
				hum.WalkSpeed = 0
			else
				table.remove(rekt, i)
			end
		else
			table.remove(rekt, i)
		end
	end
end)
