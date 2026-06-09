-- ServerScriptService/MainGameLoop_Data.lua
-- Controls round timing, player resets, quotas, escapes, and failures.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local STARTING_MONEY = 500
local QUOTA = 1500
local ROUND_TIME = 5 * 60
local INTERMISSION_TIME = 20
local END_SCREEN_TIME = 6

local remotesFolder = ReplicatedStorage:WaitForChild("CasinoRemotes")
local roundStatus = remotesFolder:WaitForChild("RoundStatus")
local stateFolder = ReplicatedStorage:WaitForChild("CasinoRoundState")

local roundNumber = 0

local function setRoundState(active, phase, timeLeft)
	stateFolder:SetAttribute("RoundActive", active)
	stateFolder:SetAttribute("Phase", phase)
	stateFolder:SetAttribute("TimeLeft", timeLeft)
	stateFolder:SetAttribute("StartingMoney", STARTING_MONEY)
	stateFolder:SetAttribute("Quota", QUOTA)
	stateFolder:SetAttribute("RoundTime", ROUND_TIME)
	stateFolder:SetAttribute("IntermissionTime", INTERMISSION_TIME)
end

local function broadcastStatus(message, phase, timeLeft)
	roundStatus:FireAllClients({
		Message = message,
		Phase = phase or stateFolder:GetAttribute("Phase") or "Waiting",
		TimeLeft = timeLeft or stateFolder:GetAttribute("TimeLeft") or 0,
		RoundActive = stateFolder:GetAttribute("RoundActive") == true,
	})
end

local function getSpawnCFrame(spawnName, fallback)
	local spawnObject = Workspace:FindFirstChild(spawnName, true)
	if spawnObject and spawnObject:IsA("BasePart") then
		return spawnObject.CFrame + Vector3.new(0, 4, 0)
	end
	return fallback
end

local function teleportPlayer(player, spawnName)
	local character = player.Character or player.CharacterAdded:Wait()
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		root = character:WaitForChild("HumanoidRootPart", 5)
	end

	if root then
		local fallback = CFrame.new(0, 8, 35)
		character:PivotTo(getSpawnCFrame(spawnName, fallback))
	end
end

local function setLeaderstat(player, statName, value)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end

	local stat = leaderstats:FindFirstChild(statName)
	if stat then
		stat.Value = value
	end
end

local function resetPlayerForRound(player)
	player:SetAttribute("StartingMoney", STARTING_MONEY)
	player:SetAttribute("Quota", QUOTA)
	player:SetAttribute("Escaped", false)
	player:SetAttribute("Failed", false)
	player:SetAttribute("RoundNumber", roundNumber)

	setLeaderstat(player, "Money", STARTING_MONEY)
	setLeaderstat(player, "ProfitLoss", 0)
	setLeaderstat(player, "Quota", QUOTA)
	setLeaderstat(player, "Escaped", false)

	task.spawn(function()
		teleportPlayer(player, "CasinoSpawn")
	end)
end

local function resetAllPlayersForRound()
	for _, player in ipairs(Players:GetPlayers()) do
		resetPlayerForRound(player)
	end
end

local function countRoundPlayers()
	local total = 0
	local escaped = 0

	for _, player in ipairs(Players:GetPlayers()) do
		if player:GetAttribute("RoundNumber") == roundNumber then
			total += 1
			if player:GetAttribute("Escaped") == true then
				escaped += 1
			end
		end
	end

	return total, escaped
end

local function markFailures()
	for _, player in ipairs(Players:GetPlayers()) do
		if player:GetAttribute("RoundNumber") == roundNumber and player:GetAttribute("Escaped") ~= true then
			player:SetAttribute("Failed", true)
			broadcastStatus(player.Name .. " failed to hit the quota before time ran out!", "RoundEnded", 0)
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	if stateFolder:GetAttribute("RoundActive") == true and stateFolder:GetAttribute("Phase") == "Round" then
		task.defer(function()
			resetPlayerForRound(player)
			broadcastStatus(player.Name .. " joined the casino mid-round.", "Round", stateFolder:GetAttribute("TimeLeft") or ROUND_TIME)
		end)
	end
end)

while true do
	setRoundState(false, "Intermission", INTERMISSION_TIME)

	for timeLeft = INTERMISSION_TIME, 1, -1 do
		setRoundState(false, "Intermission", timeLeft)
		broadcastStatus("Next round starts in " .. timeLeft .. " seconds.", "Intermission", timeLeft)
		task.wait(1)
	end

	roundNumber += 1
	setRoundState(true, "Round", ROUND_TIME)
	resetAllPlayersForRound()
	broadcastStatus("Round " .. roundNumber .. " started! Reach $" .. QUOTA .. " and escape before time runs out.", "Round", ROUND_TIME)

	local endedEarly = false
	for timeLeft = ROUND_TIME, 0, -1 do
		setRoundState(true, "Round", timeLeft)

		if timeLeft == 30 then
			broadcastStatus("30 seconds left!", "Round", timeLeft)
		else
			broadcastStatus(nil, "Round", timeLeft)
		end

		local totalPlayers, escapedPlayers = countRoundPlayers()
		if totalPlayers > 0 and escapedPlayers >= totalPlayers then
			endedEarly = true
			broadcastStatus("Everyone escaped! The casino is resetting.", "RoundEnded", timeLeft)
			break
		end

		if timeLeft <= 0 then
			break
		end

		task.wait(1)
	end

	setRoundState(false, "RoundEnded", 0)

	if not endedEarly then
		markFailures()
	end

	broadcastStatus("Round ended. The casino resets soon.", "RoundEnded", 0)
	task.wait(END_SCREEN_TIME)
end
