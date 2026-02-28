-- made by doktordestrukt

local a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,Aa,Ab,Ac,Ad
a=65 b=12 c=45 d=5 e=0.032 f=10 g=0.018 h=0.22 i=2.8 j=0.08 k=0.85 l=0.22 m=18 n=38 o=42 p=0.07 q=0.2 r=1.6 s=0.04 t=0.5 u=50 v=1.2 w=0.2 x=0.4 y=0.6 z=0 A=0.015 B=0.75 C=0.08 D=-0.25 E=-0.3 F=0.06 G=45 H=5 I=1.4 J=0.3 K=1 L="rbxassetid://867743272" M="rbxassetid://685857471" N="Blood" O="BloodPuddle" P="Projectile" Q="Handle" R="Blade" S="GoreWound" T="Neon" U=0.85 V=0.22 W=0.02 X=0.75 Y=0.08 Z=0.5 Aa=0.1 Ab=16 Ac=2 Ad=0.1

local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local Config = {
	BloodColor = Color3.fromRGB(a,b,b),
	BloodColorDark = Color3.fromRGB(c,d,d),
	Material = Enum.Material[T],
	BleedInterval = e,
	MaxPuddleSize = f,
	PuddleFadeStep = g,
	PuddleFadeInterval = h,
	DropletLifetime = i,
	PuddleGrowthPerDrop = j,
	PuddleInitialSize = Vector3.new(k,V,k),
	BloodTexture = L,
	SplatSoundId = M,
	SplatVolume = Aa,
	IgnoreNames = { N, O, P, Q, R },
	IgnoreParentNames = { P },
	DamageBurstMin = m,
	DamageBurstMax = n,
	DeathBurstDroplets = o,
	DropletSizeMin = p,
	DropletSizeMax = q,
	ViscousGravity = r,
}

local function shouldIgnore(touched)
	if not touched or not touched.Parent then return true end
	for _, _n in ipairs(Config.IgnoreNames) do
		if touched.Name == _n then return true end
	end
	for _, _n in ipairs(Config.IgnoreParentNames) do
		if touched.Parent.Name == _n then return true end
	end
	if touched.Parent:FindFirstChildOfClass("Humanoid") then return true end
	if touched.Parent.Parent and touched.Parent.Parent:FindFirstChildOfClass("Humanoid") then return true end
	if touched.Parent:IsA("Tool") or touched.Parent:IsA("Accessory") then return true end
	return false
end

local function spawnDroplet(position, upVector, color, useWhite)
	local c0 = color or Config.BloodColor
	if useWhite then c0 = Color3.new(K,K,K) end
	local r0 = Config.DropletSizeMin + math.random() * (Config.DropletSizeMax - Config.DropletSizeMin)
	local size = Vector3.new(r0, r0, r0)

	local droplet = Instance.new("Part")
	droplet.Shape = Enum.PartType.Ball
	droplet.Size = size
	droplet.CFrame = CFrame.new(position)
	droplet.Transparency = K
	droplet.Color = c0
	droplet.Material = Config.Material
	droplet.Name = N
	droplet.CanCollide = false
	droplet.CanTouch = true
	droplet.Anchored = false
	droplet.Parent = Workspace

	local bf = Instance.new("BodyForce")
	bf.Force = upVector * (math.random() * J + C) + Vector3.new((math.random() - Z) * U, -Config.ViscousGravity * (U + math.random() * x), (math.random() - Z) * U)
	bf.Parent = droplet
	Debris:AddItem(bf, s)

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(z, c0),
		ColorSequenceKeypoint.new(Z, c0),
		ColorSequenceKeypoint.new(K, Config.BloodColorDark or Color3.fromRGB(G, H, H)),
	})
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(z, r0 * I),
		NumberSequenceKeypoint.new(y, r0 * Z),
		NumberSequenceKeypoint.new(K, z),
	})
	if #Config.BloodTexture > z then
		emitter.Texture = Config.BloodTexture
	end
	emitter.Lifetime = NumberRange.new(Z)
	emitter.Rate = u
	emitter.LockedToPart = true
	emitter.Speed = NumberRange.new(z, v)
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(z, w),
		NumberSequenceKeypoint.new(Z, x),
		NumberSequenceKeypoint.new(K, K),
	})
	emitter.Parent = droplet

	local destroyed = false
	local function destroy()
		if destroyed then return end
		destroyed = true
		droplet:Destroy()
	end

	droplet.Touched:Connect(function(tou)
		if destroyed then return end
		if shouldIgnore(tou) then return end
		if not tou.CanCollide and tou.Name ~= O then return end
		local pos = Vector3.new(droplet.Position.X, (tou.Position.Y + tou.Size.Y / 2) + W, droplet.Position.Z)
		destroy()

		if tou.Name == O then
			if tou.Transparency > D then
				tou.Transparency = math.max(E, tou.Transparency - F)
			end
			if tou.Size.Y < Config.MaxPuddleSize then
				local oldCf = tou.CFrame
				tou.Size = tou.Size + Vector3.new(z, Config.PuddleGrowthPerDrop, Config.PuddleGrowthPerDrop)
				tou.CFrame = oldCf
			end
			return
		end

		local puddle = Instance.new("Part")
		puddle.Shape = Enum.PartType.Block
		puddle.Size = Vector3.new(Ad, Config.PuddleInitialSize.X, Config.PuddleInitialSize.Z)
		puddle.Name = O
		puddle.Anchored = true
		puddle.CanCollide = false
		puddle.Material = Config.Material
		puddle.Color = c0
		puddle.CFrame = CFrame.new(pos) * CFrame.Angles(z, z, math.pi / Ac)
		puddle.Transparency = z
		puddle.Parent = Workspace
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Cylinder
		mesh.Scale = Vector3.new(K, K, K)
		mesh.Parent = puddle

		if #Config.SplatSoundId > z then
			local sound = Instance.new("Sound")
			sound.SoundId = Config.SplatSoundId
			sound.Volume = Config.SplatVolume
			sound.Parent = puddle
			sound:Play()
		end

		task.spawn(function()
			while puddle and puddle.Parent do
				if puddle.Transparency >= K then
					puddle:Destroy()
					break
				end
				puddle.Transparency = puddle.Transparency + Config.PuddleFadeStep
				task.wait(Config.PuddleFadeInterval)
			end
		end)
	end)

	Debris:AddItem(droplet, Config.DropletLifetime)
end

local function bleed(sourcePart, drip, color, interval)
	interval = interval or Config.BleedInterval
	color = color or Config.BloodColor
	task.spawn(function()
		while sourcePart and sourcePart.Parent do
			local root = sourcePart:FindFirstAncestorOfClass("Model")
			local hum = root and root:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health <= z then break end
			local cf = sourcePart.CFrame
			local up = drip and -cf.UpVector or cf.UpVector
			spawnDroplet(cf.Position, up, color, false)
			task.wait(interval)
		end
	end)
end

local function attachWound(character, partName, color)
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	local part = character and character:FindFirstChild(partName)
	if not hum or not part or not part:IsA("BasePart") then return end
	color = color or Config.BloodColor

	local wound = Instance.new("Part")
	wound.Name = S
	wound.Size = Vector3.new(part.Size.X * X, Y, part.Size.Z * X)
	wound.Transparency = K
	wound.CanCollide = false
	wound.Anchored = false
	wound.Parent = character

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part
	weld.Part1 = wound
	weld.Parent = wound

	wound.CFrame = part.CFrame * CFrame.new(z, -part.Size.Y / 2, z)
	bleed(wound, true, color, Config.BleedInterval)
	return wound
end

local R6_PARTS = { "Torso", "Head", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }
local R15_PARTS = {
	"UpperTorso", "LowerTorso", "Head",
	"LeftUpperArm", "LeftLowerArm", "LeftHand",
	"RightUpperArm", "RightLowerArm", "RightHand",
	"LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
	"RightUpperLeg", "RightLowerLeg", "RightFoot",
}

local function bleedFromCharacter(character, color)
	if not character or not character:FindFirstChildOfClass("Humanoid") then return end
	color = color or Config.BloodColor
	local bodyParts = character:FindFirstChild("Torso") and R6_PARTS or R15_PARTS
	for _, _n in ipairs(bodyParts) do
		if character:FindFirstChild(_n) then
			attachWound(character, _n, color)
		end
	end
end

local function burst(position, normal, count, color)
	color = color or Config.BloodColor
	count = count or Ab
	local up = normal or Vector3.new(z, K, z)
	for _ = K, count do
		task.defer(spawnDroplet, position, up, color, false)
		task.wait(A)
	end
end

local connectedHumanoids = {}

local function connectGoreToHumanoid(humanoid)
	if not humanoid or not humanoid:IsA("Humanoid") or connectedHumanoids[humanoid] then return end
	local character = humanoid.Parent
	if not character or not character:IsA("Model") then return end
	connectedHumanoids[humanoid] = true

	humanoid.Died:Connect(function()
		local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		local head = character:FindFirstChild("Head")
		local pos = (torso or rootPart or head) and (torso or rootPart or head).Position
		if pos then burst(pos, Vector3.new(z, K, z), Config.DeathBurstDroplets) end
		if head then burst(head.Position, Vector3.new(z, K, z), math.floor(Config.DeathBurstDroplets / Ac)) end
		bleedFromCharacter(character)
	end)

	local lastHealth = humanoid.Health
	humanoid.HealthChanged:Connect(function()
		local now = humanoid.Health
		if now < lastHealth and humanoid.Health > z then
			local part = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("Head")
			if part then
				local _n = Config.DamageBurstMin + math.random(Config.DamageBurstMax - Config.DamageBurstMin + K)
				burst(part.Position, Vector3.new(z, K, z), _n)
			end
		end
		lastHealth = now
	end)
end

for _, desc in ipairs(Workspace:GetDescendants()) do
	if desc:IsA("Humanoid") then
		task.defer(connectGoreToHumanoid, desc)
	end
end
Workspace.DescendantAdded:Connect(function(desc)
	if desc:IsA("Humanoid") then
		task.defer(connectGoreToHumanoid, desc)
	end
end)
