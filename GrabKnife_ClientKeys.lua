--[[
	Grab Knife — CLIENT KEY SENDER (for server script version)
	Put this as a LocalScript in StarterPlayerScripts.
	Only sends Q / E / F to the server when the Grab tool is equipped.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local keyEvent = ReplicatedStorage:WaitForChild("GrabKnifeKey", 10)
if not keyEvent then return end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	local key = input.KeyCode.Name:lower()
	if key ~= "q" and key ~= "e" and key ~= "f" then return end
	local char = player.Character
	if not char then return end
	local tool = char:FindFirstChild("Grab") or player.Backpack:FindFirstChild("Grab")
	if not tool or not tool:IsA("Tool") then return end
	-- Only send when Grab is equipped (in hand)
	if tool.Parent ~= char then return end
	keyEvent:FireServer(key)
end)
