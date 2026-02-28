--[[
	Script Builder GUI (Client)
	Inspired by: https://roblox.fandom.com/wiki/Script_builder#Using_a_script_builder

	Place in StarterPlayerScripts. Listens for ExecutePastebinResult and ScriptBuilderOutput
	(filtered script output from the sandbox).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local executeRemote = ReplicatedStorage:WaitForChild("ExecutePastebin", 5)
local resultRemote = ReplicatedStorage:WaitForChild("ExecutePastebinResult", 10)
local outputRemote = ReplicatedStorage:WaitForChild("ScriptBuilderOutput", 5)
if not executeRemote then
	warn("ScriptBuilder: ExecutePastebin RemoteEvent not found in ReplicatedStorage.")
	return
end

-- Build GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ScriptBuilderGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 420, 0, 280)
main.Position = UDim2.new(0.5, -210, 0.5, -140)
main.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
main.BorderSizePixel = 0
main.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = main

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(60, 60, 70)
stroke.Thickness = 1
stroke.Parent = main

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -24, 0, 36)
title.Position = UDim2.new(0, 12, 0, 8)
title.BackgroundTransparency = 1
title.Text = "Script Builder"
title.TextColor3 = Color3.fromRGB(240, 240, 245)
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

-- Toggle button (show/hide)
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "Toggle"
toggleBtn.Size = UDim2.new(0, 80, 0, 28)
toggleBtn.Position = UDim2.new(1, -92, 0, 10)
toggleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
toggleBtn.BorderSizePixel = 0
toggleBtn.Text = "Hide"
toggleBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
toggleBtn.TextSize = 14
toggleBtn.Font = Enum.Font.Gotham
toggleBtn.Parent = main
local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 6)
toggleCorner.Parent = toggleBtn

-- Input label
local inputLabel = Instance.new("TextLabel")
inputLabel.Size = UDim2.new(1, -24, 0, 20)
inputLabel.Position = UDim2.new(0, 12, 0, 52)
inputLabel.BackgroundTransparency = 1
inputLabel.Text = "Pastebin URL"
inputLabel.TextColor3 = Color3.fromRGB(160, 160, 170)
inputLabel.TextSize = 12
inputLabel.Font = Enum.Font.Gotham
inputLabel.TextXAlignment = Enum.TextXAlignment.Left
inputLabel.Parent = main

-- URL input
local inputBox = Instance.new("TextBox")
inputBox.Name = "Input"
inputBox.Size = UDim2.new(1, -24, 0, 38)
inputBox.Position = UDim2.new(0, 12, 0, 74)
inputBox.BackgroundColor3 = Color3.fromRGB(38, 38, 44)
inputBox.BorderSizePixel = 0
inputBox.PlaceholderText = "https://pastebin.com/xxxxx"
inputBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 110)
inputBox.Text = ""
inputBox.TextColor3 = Color3.fromRGB(240, 240, 245)
inputBox.TextSize = 14
inputBox.Font = Enum.Font.Gotham
inputBox.ClearTextOnFocus = false
inputBox.Parent = main
local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 6)
inputCorner.Parent = inputBox
local inputPadding = Instance.new("UIPadding")
inputPadding.PaddingLeft = UDim.new(0, 10)
inputPadding.PaddingRight = UDim.new(0, 10)
inputPadding.Parent = inputBox

-- Execute button
local executeBtn = Instance.new("TextButton")
executeBtn.Name = "Execute"
executeBtn.Size = UDim2.new(1, -24, 0, 44)
executeBtn.Position = UDim2.new(0, 12, 0, 122)
executeBtn.BackgroundColor3 = Color3.fromRGB(0, 122, 204)
executeBtn.BorderSizePixel = 0
executeBtn.Text = "Execute"
executeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
executeBtn.TextSize = 16
executeBtn.Font = Enum.Font.GothamBold
executeBtn.Parent = main
local execCorner = Instance.new("UICorner")
execCorner.CornerRadius = UDim.new(0, 8)
execCorner.Parent = executeBtn

-- Log / output
local logLabel = Instance.new("TextLabel")
logLabel.Name = "Log"
logLabel.Size = UDim2.new(1, -24, 0, 100)
logLabel.Position = UDim2.new(0, 12, 0, 176)
logLabel.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
logLabel.BorderSizePixel = 0
logLabel.Text = "Output will appear here."
logLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
logLabel.TextSize = 12
logLabel.Font = Enum.Font.Code
logLabel.TextXAlignment = Enum.TextXAlignment.Left
logLabel.TextYAlignment = Enum.TextYAlignment.Top
logLabel.TextWrapped = true
logLabel.Parent = main
local logCorner = Instance.new("UICorner")
logCorner.CornerRadius = UDim.new(0, 6)
logCorner.Parent = logLabel
local logPadding = Instance.new("UIPadding")
logPadding.PaddingLeft = UDim.new(0, 10)
logPadding.PaddingRight = UDim.new(0, 10)
logPadding.PaddingTop = UDim.new(0, 8)
logPadding.PaddingBottom = UDim.new(0, 8)
logPadding.Parent = logLabel

local function setLog(text, isError)
	logLabel.Text = text
	logLabel.TextColor3 = isError and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(180, 180, 190)
end

local function appendLog(line)
	if logLabel.Text == "Output will appear here." or logLabel.Text == "Executing..." then
		logLabel.Text = tostring(line)
	else
		logLabel.Text = logLabel.Text .. "\n" .. tostring(line)
	end
	logLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
end

-- Streamed output from sandbox (filtered on server)
if outputRemote then
	outputRemote.OnClientEvent:Connect(function(line)
		appendLog(line)
	end)
end

-- Execute on button click
local executing = false
executeBtn.MouseButton1Click:Connect(function()
	local url = inputBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
	if url == "" then
		setLog("Enter a Pastebin URL.", true)
		return
	end
	if executing then
		setLog("Please wait...", true)
		return
	end
	executing = true
	setLog("Executing...")
	logLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
	executeRemote:FireServer(url)
	task.delay(15, function()
		if executing then
			executing = false
			setLog("No response from server (timeout). Check: 1) HttpService enabled in Game Settings 2) Server script in ServerScriptService 3) Output for errors.", true)
		end
	end)
end)

-- Listen for result from server
resultRemote.OnClientEvent:Connect(function(success, message)
	executing = false
	if success then
		appendLog("--- " .. tostring(message))
	else
		setLog(logLabel.Text == "Executing..." and message or logLabel.Text .. "\n--- Error: " .. tostring(message), true)
	end
end)

-- Toggle show/hide
local visible = true
toggleBtn.MouseButton1Click:Connect(function()
	visible = not visible
	main.Visible = visible
	toggleBtn.Text = visible and "Hide" or "Show"
end)

-- Make draggable
local dragging, dragStart, startPos
main.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = main.Position
	end
end)
main.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)
game:GetService("UserInputService").InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

screenGui.Parent = playerGui
