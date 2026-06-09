-- ServerScriptService/ExitQuotaSystem.lua
-- Handles the casino exit. Players can escape only when Money >= Quota.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local remotesFolder = ReplicatedStorage:WaitForChild("CasinoRemotes")
local attemptExit = remotesFolder:WaitForChild("AttemptExit")
local gameResult = remotesFolder:WaitForChild("GameResult")
local roundStatus = remotesFolder:WaitForChild("RoundStatus")
local stateFolder = ReplicatedStorage:WaitForChild("CasinoRoundState")

local function createFallbackExitDoor()
	local door = Instance.new("Part")
	door.Name = "CasinoExitDoor"
	door.Size = Vector3.new(14, 16, 2)
	door.CFrame = CFrame.new(0, 8, -55)
	door.Anchored = true
	door.Material = Enum.Material.Neon
	door.Color = Color3.fromRGB(255, 80, 80)
	door.Parent = Workspace
	return door
end

local function getExitDoor()
	local door = Workspace:FindFirstChild("CasinoExitDoor", true)
	if door and door:IsA("BasePart") then
		return door
	end
	return createFallbackExitDoor()
end

local function getOrCreatePrompt(door)
	local prompt = door:FindFirstChild("ExitQuotaPrompt")
	if not prompt then
		for _, child in ipairs(door:GetChildren()) do
			if child:IsA("ProximityPrompt") then
				prompt = child
				break
			end
		end
	end

	if prompt and not prompt:IsA("ProximityPrompt") then
		prompt:Destroy()
		prompt = nil
	end

	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "ExitQuotaPrompt"
		prompt.ActionText = "Escape"
		prompt.ObjectText = "Quota Exit"
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.HoldDuration = 0.4
		prompt.MaxActivationDistance = 12
		prompt.RequiresLineOfSight = false
		prompt.Parent = door
	end

	prompt.Name = "ExitQuotaPrompt"

	return prompt
end

local function getStats(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return nil, nil
	end

	return leaderstats:FindFirstChild("Money"), leaderstats:FindFirstChild("Quota")
end

local function teleportToWinnerLounge(player)
	local character = player.Character
	if not character then
		return
	end

	local loungeSpawn = Workspace:FindFirstChild("WinnerLoungeSpawn", true)
	local targetCFrame = loungeSpawn and loungeSpawn:IsA("BasePart") and loungeSpawn.CFrame + Vector3.new(0, 4, 0) or CFrame.new(0, 8, -90)
	character:PivotTo(targetCFrame)
end

local function tellPlayer(player, message)
	local money = getStats(player)

	gameResult:FireClient(player, {
		Game = "Casino Exit",
		Delta = 0,
		Balance = money and money.Value or 0,
		Won = false,
		Push = true,
		Message = message,
		Details = message,
	})
end

local function tryEscape(player)
	if stateFolder:GetAttribute("RoundActive") ~= true or stateFolder:GetAttribute("Phase") ~= "Round" then
		tellPlayer(player, "The exit is locked until a round is active.")
		return
	end

	if player:GetAttribute("Escaped") == true then
		tellPlayer(player, "You already escaped. Enjoy the winner lounge!")
		return
	end

	local money, quota = getStats(player)
	if not money or not quota then
		tellPlayer(player, "Your casino stats are still loading.")
		return
	end

	if money.Value < quota.Value then
		tellPlayer(player, "You need $" .. quota.Value .. " to escape. Current money: $" .. money.Value .. ".")
		return
	end

	player:SetAttribute("Escaped", true)
	local leaderstats = player:FindFirstChild("leaderstats")
	local escapedStat = leaderstats and leaderstats:FindFirstChild("Escaped")
	if escapedStat then
		escapedStat.Value = true
	end

	teleportToWinnerLounge(player)

	local message = player.Name .. " hit the quota and escaped!"
	roundStatus:FireAllClients({
		Message = message,
		Phase = stateFolder:GetAttribute("Phase") or "Round",
		TimeLeft = stateFolder:GetAttribute("TimeLeft") or 0,
		RoundActive = true,
	})

	gameResult:FireClient(player, {
		Game = "Casino Exit",
		Delta = 0,
		Balance = money.Value,
		Won = true,
		Push = false,
		Message = "You escaped with $" .. money.Value .. "!",
		Details = "You reached the quota and made it to the winner lounge.",
	})
end

local exitDoor = getExitDoor()
local prompt = getOrCreatePrompt(exitDoor)
prompt.Triggered:Connect(tryEscape)
attemptExit.OnServerEvent:Connect(tryEscape)
