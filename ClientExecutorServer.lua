--[[
	Client Executor — SERVER
	Runs Lua code sent by the client using loadstring (server-side only).

	REQUIRED: Enable LoadStringEnabled for ServerScriptService:
	  In Studio: Explorer → ServerScriptService → Properties → LoadStringEnabled = true
	  (Or: Game Settings → Security, if available in your Studio version.)

	Place this Script in ServerScriptService.
	Creates in ReplicatedStorage:
	  ClientExecutorRun     (RemoteEvent) — client fires with code string
	  ClientExecutorOutput (RemoteEvent) — server fires each print() line to client
	  ClientExecutorResult (RemoteEvent) — server fires (success, message) when done
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Create remotes (or use existing)
local function getOrCreate(name, className)
	local r = ReplicatedStorage:FindFirstChild(name)
	if not r then
		r = Instance.new(className)
		r.Name = name
		r.Parent = ReplicatedStorage
	end
	return r
end

local remoteRun = getOrCreate("ClientExecutorRun", "RemoteEvent")
local remoteOutput = getOrCreate("ClientExecutorOutput", "RemoteEvent")
local remoteResult = getOrCreate("ClientExecutorResult", "RemoteEvent")

-- Optional: enable loadstring at runtime if the property is writable (Studio only in some versions)
pcall(function()
	ServerScriptService.LoadStringEnabled = true
end)

remoteRun.OnServerEvent:Connect(function(player, code)
	if type(code) ~= "string" or #code > 100000 then
		remoteResult:FireClient(player, false, "Invalid or too long.")
		return
	end

	if not loadstring then
		remoteResult:FireClient(player, false, "LoadStringEnabled is off. Enable it on ServerScriptService in Studio.")
		return
	end

	local function sendOutput(line)
		remoteOutput:FireClient(player, tostring(line))
	end

	task.defer(function()
		-- Wrapper: inject custom print that sends to client (Luau has no setfenv)
		local chunk = "return function(__execPrint) "
			.. "print = function(...) local t={}; for i=1,select('#',...) do t[i]=tostring(select(i,...)) end __execPrint(table.concat(t,'\t')) end "
			.. code
			.. " end"
		local fn, err = loadstring(chunk, "ClientExecutor")
		if not fn then
			remoteResult:FireClient(player, false, "Load error: " .. tostring(err))
			return
		end

		local ok, runErr = pcall(fn, sendOutput)
		if not ok then
			sendOutput(tostring(runErr))
			remoteResult:FireClient(player, false, tostring(runErr))
		else
			remoteResult:FireClient(player, true, "Done.")
		end
	end)
end)
