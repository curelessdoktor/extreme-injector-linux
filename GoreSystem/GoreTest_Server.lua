-- made by doktordestrukt
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local eventName = "GoreTestEvent"
local event = ReplicatedStorage:FindFirstChild(eventName)
if not event then
	event = Instance.new("RemoteEvent")
	event.Name = eventName
	event.Parent = ReplicatedStorage
end

event.OnServerEvent:Connect(function(player, action)
	if not player or not player.Character then return end
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	if action == "damage" then
		humanoid:TakeDamage(25)
	elseif action == "kill" then
		humanoid.Health = 0
	end
end)
