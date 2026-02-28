-- made by doktordestrukt
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local event = ReplicatedStorage:WaitForChild("GoreTestEvent", 10)
if not event then return end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.G then
		event:FireServer("damage")
	elseif input.KeyCode == Enum.KeyCode.H then
		event:FireServer("kill")
	end
end)
