--[[
	Script Builder – Sandboxed server executor
	Inspired by: https://roblox.fandom.com/wiki/Script_builder#Using_a_script_builder

	- No loadstring: runs only a whitelist of safe commands (print, message, wait, part).
	- User-generated text is filtered via TextService before display (ToU compliance).
	- Pastebin content = JSON list of commands or simple line-based format.

	Place in ServerScriptService. Enable HttpService in Game Settings.
]]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")

local executeRemote = ReplicatedStorage:FindFirstChild("ExecutePastebin") or (function()
	local r = Instance.new("RemoteEvent")
	r.Name = "ExecutePastebin"
	r.Parent = ReplicatedStorage
	return r
end)()

local resultRemote = ReplicatedStorage:FindFirstChild("ExecutePastebinResult") or (function()
	local r = Instance.new("RemoteEvent")
	r.Name = "ExecutePastebinResult"
	r.Parent = ReplicatedStorage
	return r
end)()

local outputRemote = ReplicatedStorage:FindFirstChild("ScriptBuilderOutput") or (function()
	local r = Instance.new("RemoteEvent")
	r.Name = "ScriptBuilderOutput"
	r.Parent = ReplicatedStorage
	return r
end)()

-- Limits (sandbox)
local MAX_COMMANDS = 64
local MAX_PARTS = 10
local MAX_OUTPUT_LINES = 50

local function getRawUrl(input)
	input = input:gsub("%s+", "")
	local pasteId = input:match("pastebin%.com/([%w%-]+)")
	if pasteId then
		return "https://pastebin.com/raw/" .. pasteId
	end
	if input:find("pastebin%.com/raw/") then
		return input
	end
	return nil
end

-- Parse Pastebin content: JSON array of {cmd, ...} or line-based "cmd arg1 arg2"
local function parseCommands(content)
	local trimmed = content:gsub("^%s+", ""):gsub("%s+$", "")
	-- Try JSON first
	local ok, data = pcall(HttpService.JSONDecode, HttpService, trimmed)
	if ok and type(data) == "table" then
		local list = {}
		for i, entry in ipairs(data) do
			if type(entry) == "table" and type(entry.cmd) == "string" then
				list[#list + 1] = entry
			end
		end
		return #list > 0 and list or nil, #list == 0 and "No valid commands in JSON." or nil
	end
	-- Line-based: "cmd arg1 arg2 ..."
	local list = {}
	for line in (trimmed .. "\n"):gmatch("([^\r\n]+)") do
		local parts = {}
		for part in line:gmatch("%S+") do
			parts[#parts + 1] = part
		end
		if #parts > 0 then
			local cmd = parts[1]:lower()
			local args = {}
			for i = 2, #parts do
				args[#args + 1] = parts[i]
			end
			list[#list + 1] = { cmd = cmd, args = args }
		end
	end
	return #list > 0 and list or nil, #list == 0 and "No commands found. Use JSON or lines like: print Hello" or nil
end

-- Filter user text for display (ToU – filter interfaces from other people)
local function filterText(player, text)
	local success, filteredStr = pcall(function()
		local filter = TextService:FilterStringAsync(text, player.UserId)
		return filter:GetNonChatStringForUserAsync(player.UserId)
	end)
	if success and filteredStr then
		return filteredStr
	end
	return "[filter error]"
end

-- Run sandboxed commands
local function runSandbox(commands, player, sendOutput, sendResult)
	local outputLineCount = 0
	local partCount = 0
	local partsFolder = workspace:FindFirstChild("ScriptBuilderParts")
	if not partsFolder then
		partsFolder = Instance.new("Folder")
		partsFolder.Name = "ScriptBuilderParts"
		partsFolder.Parent = workspace
	end

	local function out(line)
		if outputLineCount >= MAX_OUTPUT_LINES then return end
		outputLineCount = outputLineCount + 1
		local filtered = filterText(player, tostring(line))
		sendOutput(filtered)
	end

	for i = 1, math.min(#commands, MAX_COMMANDS) do
		local c = commands[i]
		local cmd = (c.cmd or ""):lower()

		if cmd == "print" then
			local text = c.text or c[2] or (c.args and c.args[1])
			if c.args and #c.args > 0 and not text then
				text = table.concat(c.args, " ")
			end
			out(text or "")
		elseif cmd == "message" then
			local text = c.text or c[2] or (c.args and table.concat(c.args, " "))
			out(text or "")
		elseif cmd == "wait" then
			local sec = tonumber(c.seconds or c[2] or (c.args and c.args[1])) or 0
			sec = math.clamp(sec, 0, 5)
			task.wait(sec)
		elseif cmd == "part" then
			if partCount >= MAX_PARTS then
				out("[sandbox] Max parts reached.")
			else
				local w, h, d = 2, 1, 2
				if c.size and #c.size >= 3 then
					w, h, d = c.size[1], c.size[2], c.size[3]
				elseif c.args and #c.args >= 3 then
					w = tonumber(c.args[1]) or 2
					h = tonumber(c.args[2]) or 1
					d = tonumber(c.args[3]) or 2
				end
				w = math.clamp(tonumber(w) or 2, 0.5, 10)
				h = math.clamp(tonumber(h) or 1, 0.5, 10)
				d = math.clamp(tonumber(d) or 2, 0.5, 10)
				local part = Instance.new("Part")
				part.Size = Vector3.new(w, h, d)
				part.Anchored = true
				part.Position = (player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart.Position + Vector3.new(0, 3 + partCount * 2, 0)) or Vector3.new(0, 5, 0)
				if c.color and #c.color >= 3 then
					part.Color = Color3.new(c.color[1], c.color[2], c.color[3])
				end
				part.Name = "ScriptBuilder_" .. player.Name .. "_" .. partCount
				part.Parent = partsFolder
				partCount = partCount + 1
				out("Created part " .. partCount)
			end
		else
			out("[unknown command] " .. tostring(cmd))
		end
	end

	return true
end

executeRemote.OnServerEvent:Connect(function(player, pastebinUrl)
	local function sendResult(ok, msg)
		pcall(function()
			resultRemote:FireClient(player, ok, msg)
		end)
	end

	local function sendOutput(line)
		pcall(function()
			outputRemote:FireClient(player, tostring(line))
		end)
	end

	local ok, err = pcall(function()
		if type(pastebinUrl) ~= "string" or #pastebinUrl == 0 then
			sendResult(false, "No URL provided.")
			return
		end

		local rawUrl = getRawUrl(pastebinUrl)
		if not rawUrl then
			sendResult(false, "Invalid Pastebin URL. Use: https://pastebin.com/xxxxx")
			return
		end

		local success, content = pcall(function()
			return HttpService:GetAsync(rawUrl)
		end)

		if not success then
			sendResult(false, "Failed to fetch: " .. tostring(content))
			return
		end

		local commands, parseErr = parseCommands(content)
		if not commands then
			sendResult(false, parseErr or "Invalid script format.")
			return
		end

		local runOk, runErr = pcall(function()
			runSandbox(commands, player, sendOutput, sendResult)
		end)
		if not runOk then
			sendResult(false, "Runtime error: " .. tostring(runErr))
			return
		end

		sendResult(true, "Executed " .. #commands .. " command(s).")
	end)

	if not ok then
		warn("[ScriptBuilder] Server error:", err)
		sendResult(false, "Server error: " .. tostring(err))
	end
end)

print("[ScriptBuilder] Sandbox executor loaded. Commands: print, message, wait, part.")
