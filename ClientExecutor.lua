--[[
	Client Executor — CLIENT (UI)
	Type Lua in the textbox and click Execute. Code runs on the SERVER (loadstring).
	Requires: ClientExecutorServer.lua in ServerScriptService + LoadStringEnabled on.

	Place as LocalScript in StarterPlayer > StarterPlayerScripts (or StarterGui).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remoteRun = ReplicatedStorage:WaitForChild("ClientExecutorRun", 10)
local remoteOutput = ReplicatedStorage:WaitForChild("ClientExecutorOutput", 5)
local remoteResult = ReplicatedStorage:WaitForChild("ClientExecutorResult", 5)

if not remoteRun or not remoteResult then
	warn("ClientExecutor: Server remotes not found. Add ClientExecutorServer.lua to ServerScriptService and enable LoadStringEnabled.")
end

-- Build GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ClientExecutorGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 480, 0, 420)
main.Position = UDim2.new(0.5, -240, 0.5, -210)
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

-- Title bar
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -24, 0, 36)
title.Position = UDim2.new(0, 12, 0, 8)
title.BackgroundTransparency = 1
title.Text = "Client Executor (Lua runs on server)"
title.TextColor3 = Color3.fromRGB(240, 240, 245)
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

-- Code label
local codeLabel = Instance.new("TextLabel")
codeLabel.Size = UDim2.new(1, -24, 0, 18)
codeLabel.Position = UDim2.new(0, 12, 0, 44)
codeLabel.BackgroundTransparency = 1
codeLabel.Text = "Code"
codeLabel.TextColor3 = Color3.fromRGB(160, 160, 170)
codeLabel.TextSize = 12
codeLabel.Font = Enum.Font.Gotham
codeLabel.TextXAlignment = Enum.TextXAlignment.Left
codeLabel.Parent = main

-- Code textbox (multiline)
local codeBox = Instance.new("TextBox")
codeBox.Name = "CodeBox"
codeBox.Size = UDim2.new(1, -24, 0, 160)
codeBox.Position = UDim2.new(0, 12, 0, 64)
codeBox.BackgroundColor3 = Color3.fromRGB(38, 38, 44)
codeBox.BorderSizePixel = 0
codeBox.PlaceholderText = "print(\"Hello\")\nlocal p = Instance.new(\"Part\")\np.Size = Vector3.new(4,1,2)\np.Parent = workspace"
codeBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 110)
codeBox.Text = ""
codeBox.TextColor3 = Color3.fromRGB(240, 240, 245)
codeBox.TextSize = 14
codeBox.Font = Enum.Font.Code
codeBox.ClearTextOnFocus = false
codeBox.MultiLine = true
codeBox.TextXAlignment = Enum.TextXAlignment.Left
codeBox.TextYAlignment = Enum.TextYAlignment.Top
codeBox.Parent = main

local codeBoxCorner = Instance.new("UICorner")
codeBoxCorner.CornerRadius = UDim.new(0, 6)
codeBoxCorner.Parent = codeBox

local codeBoxPadding = Instance.new("UIPadding")
codeBoxPadding.PaddingLeft = UDim.new(0, 10)
codeBoxPadding.PaddingRight = UDim.new(0, 10)
codeBoxPadding.PaddingTop = UDim.new(0, 8)
codeBoxPadding.PaddingBottom = UDim.new(0, 8)
codeBoxPadding.Parent = codeBox

-- Button row
local buttonRow = Instance.new("Frame")
buttonRow.Name = "ButtonRow"
buttonRow.Size = UDim2.new(1, -24, 0, 40)
buttonRow.Position = UDim2.new(0, 12, 0, 232)
buttonRow.BackgroundTransparency = 1
buttonRow.Parent = main

local executeBtn = Instance.new("TextButton")
executeBtn.Name = "Execute"
executeBtn.Size = UDim2.new(0, 140, 0, 36)
executeBtn.Position = UDim2.new(0, 0, 0, 0)
executeBtn.BackgroundColor3 = Color3.fromRGB(0, 122, 204)
executeBtn.BorderSizePixel = 0
executeBtn.Text = "Execute"
executeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
executeBtn.TextSize = 14
executeBtn.Font = Enum.Font.GothamBold
executeBtn.Parent = buttonRow

local execCorner = Instance.new("UICorner")
execCorner.CornerRadius = UDim.new(0, 8)
execCorner.Parent = executeBtn

local clearBtn = Instance.new("TextButton")
clearBtn.Name = "Clear"
clearBtn.Size = UDim2.new(0, 100, 0, 36)
clearBtn.Position = UDim2.new(0, 148, 0, 0)
clearBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 62)
clearBtn.BorderSizePixel = 0
clearBtn.Text = "Clear"
clearBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
clearBtn.TextSize = 14
clearBtn.Font = Enum.Font.Gotham
clearBtn.Parent = buttonRow

local clearCorner = Instance.new("UICorner")
clearCorner.CornerRadius = UDim.new(0, 8)
clearCorner.Parent = clearBtn

-- Output label
local outputLabel = Instance.new("TextLabel")
outputLabel.Name = "OutputLabel"
outputLabel.Size = UDim2.new(1, -24, 0, 18)
outputLabel.Position = UDim2.new(0, 12, 0, 278)
outputLabel.BackgroundTransparency = 1
outputLabel.Text = "Output"
outputLabel.TextColor3 = Color3.fromRGB(160, 160, 170)
outputLabel.TextSize = 12
outputLabel.Font = Enum.Font.Gotham
outputLabel.TextXAlignment = Enum.TextXAlignment.Left
outputLabel.Parent = main

-- Output log
local logLabel = Instance.new("TextLabel")
logLabel.Name = "Log"
logLabel.Size = UDim2.new(1, -24, 0, 110)
logLabel.Position = UDim2.new(0, 12, 0, 298)
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

-- Helpers for output
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

-- Stream print() from server
if remoteOutput then
	remoteOutput.OnClientEvent:Connect(function(line)
		appendLog(line)
	end)
end

-- Final result from server
if remoteResult then
	remoteResult.OnClientEvent:Connect(function(success, message)
		if not success then
			setLog(logLabel.Text == "Executing..." and message or logLabel.Text .. "\n" .. message, true)
		elseif logLabel.Text == "Executing..." then
			setLog("Done.")
		end
	end)
end

-- Execute button: send code to server
executeBtn.MouseButton1Click:Connect(function()
	local code = codeBox.Text
	if code:gsub("^%s+", ""):gsub("%s+$", "") == "" then
		setLog("Enter Lua code to execute.", true)
		return
	end

	if not remoteRun then
		setLog("Server not ready. Add ClientExecutorServer.lua and enable LoadStringEnabled.", true)
		return
	end

	setLog("Executing...")
	remoteRun:FireServer(code)
end)

-- Clear button: clear code box and output
clearBtn.MouseButton1Click:Connect(function()
	codeBox.Text = ""
	setLog("Output will appear here.")
end)

-- Draggable window
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
