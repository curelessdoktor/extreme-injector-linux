--[[
	GoreSystem init (ServerScriptService or Server script)
	Require the Gore module and optionally enable auto bleed-on-death for all players.
]]
local Players = game:GetService("Players")
local Gore = script.Parent:FindFirstChild("Gore")
if not Gore then
	Gore = require(script.Parent.Gore)
else
	Gore = require(Gore)
end

-- Optional: when a character spawns, connect gore (death = full body bleed, optional damage burst)
local function onCharacterAdded(character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid then
		Gore.ConnectHumanoid(humanoid, {
			BleedOnDeath = true,
			BleedOnDamage = true, -- small burst when taking damage
		})
	end
end

for _, player in ipairs(Players:GetPlayers()) do
	if player.Character then
		task.spawn(onCharacterAdded, player.Character)
	end
	player.CharacterAdded:Connect(onCharacterAdded)
end

-- Export for other scripts
return Gore
