-- ServerScriptService/CasinoStats_Leaderboard.lua
-- Creates leaderstats and broadcasts live money/profit/quota data to all clients.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local REMOTE_FOLDER_NAME = "CasinoRemotes"
local STATE_FOLDER_NAME = "CasinoRoundState"

local DEFAULT_STARTING_MONEY = 500
local DEFAULT_QUOTA = 1500

local remotesFolder = ReplicatedStorage:WaitForChild(REMOTE_FOLDER_NAME)
local updateUI = remotesFolder:WaitForChild("UpdateUI")
local stateFolder = ReplicatedStorage:WaitForChild(STATE_FOLDER_NAME)

local connectionsByPlayer = {}
local broadcastQueued = false

local function formatPlayerEntry(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local money = leaderstats and leaderstats:FindFirstChild("Money")
	local profitLoss = leaderstats and leaderstats:FindFirstChild("ProfitLoss")
	local quota = leaderstats and leaderstats:FindFirstChild("Quota")
	local escaped = leaderstats and leaderstats:FindFirstChild("Escaped")

	return {
		UserId = player.UserId,
		Name = player.Name,
		DisplayName = player.DisplayName,
		Money = money and money.Value or 0,
		ProfitLoss = profitLoss and profitLoss.Value or 0,
		Quota = quota and quota.Value or DEFAULT_QUOTA,
		Escaped = escaped and escaped.Value or false,
	}
end

local function buildSnapshot(forPlayer)
	local leaderboard = {}
	for _, player in ipairs(Players:GetPlayers()) do
		table.insert(leaderboard, formatPlayerEntry(player))
	end

	table.sort(leaderboard, function(a, b)
		if a.Escaped ~= b.Escaped then
			return a.Escaped
		end
		if a.ProfitLoss ~= b.ProfitLoss then
			return a.ProfitLoss > b.ProfitLoss
		end
		return a.Money > b.Money
	end)

	local playerStats = forPlayer and formatPlayerEntry(forPlayer) or nil

	return {
		Player = playerStats,
		Leaderboard = leaderboard,
		RoundActive = stateFolder:GetAttribute("RoundActive") == true,
		Phase = stateFolder:GetAttribute("Phase") or "Waiting",
		TimeLeft = stateFolder:GetAttribute("TimeLeft") or 0,
		StartingMoney = stateFolder:GetAttribute("StartingMoney") or DEFAULT_STARTING_MONEY,
		Quota = stateFolder:GetAttribute("Quota") or DEFAULT_QUOTA,
	}
end

local function sendSnapshot(player)
	if player.Parent == Players then
		updateUI:FireClient(player, buildSnapshot(player))
	end
end

local function broadcastSnapshots()
	for _, player in ipairs(Players:GetPlayers()) do
		sendSnapshot(player)
	end
end

local function queueBroadcast()
	if broadcastQueued then
		return
	end

	broadcastQueued = true
	task.defer(function()
		broadcastQueued = false
		broadcastSnapshots()
	end)
end

local function getOrCreateValue(parent, className, name, defaultValue)
	local value = parent:FindFirstChild(name)
	if value and not value:IsA(className) then
		value:Destroy()
		value = nil
	end

	if not value then
		value = Instance.new(className)
		value.Name = name
		value.Value = defaultValue
		value.Parent = parent
	end

	return value
end

local function syncDerivedStats(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end

	local money = leaderstats:FindFirstChild("Money")
	local profitLoss = leaderstats:FindFirstChild("ProfitLoss")
	local quota = leaderstats:FindFirstChild("Quota")
	local escaped = leaderstats:FindFirstChild("Escaped")

	local startingMoney = player:GetAttribute("StartingMoney") or stateFolder:GetAttribute("StartingMoney") or DEFAULT_STARTING_MONEY
	local playerQuota = player:GetAttribute("Quota") or stateFolder:GetAttribute("Quota") or DEFAULT_QUOTA
	local escapedValue = player:GetAttribute("Escaped") == true

	if money and profitLoss then
		local newProfitLoss = money.Value - startingMoney
		if profitLoss.Value ~= newProfitLoss then
			profitLoss.Value = newProfitLoss
		end
	end

	if quota and quota.Value ~= playerQuota then
		quota.Value = playerQuota
	end

	if escaped and escaped.Value ~= escapedValue then
		escaped.Value = escapedValue
	end
end

local function trackConnection(player, connection)
	connectionsByPlayer[player] = connectionsByPlayer[player] or {}
	table.insert(connectionsByPlayer[player], connection)
end

local function setupLeaderstats(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local startingMoney = player:GetAttribute("StartingMoney") or stateFolder:GetAttribute("StartingMoney") or DEFAULT_STARTING_MONEY
	local quotaAmount = player:GetAttribute("Quota") or stateFolder:GetAttribute("Quota") or DEFAULT_QUOTA

	local money = getOrCreateValue(leaderstats, "IntValue", "Money", startingMoney)
	local profitLoss = getOrCreateValue(leaderstats, "IntValue", "ProfitLoss", money.Value - startingMoney)
	getOrCreateValue(leaderstats, "IntValue", "Quota", quotaAmount)
	getOrCreateValue(leaderstats, "BoolValue", "Escaped", player:GetAttribute("Escaped") == true)

	local function changed()
		syncDerivedStats(player)
		queueBroadcast()
	end

	trackConnection(player, money.Changed:Connect(changed))
	trackConnection(player, profitLoss.Changed:Connect(queueBroadcast))
	trackConnection(player, player:GetAttributeChangedSignal("StartingMoney"):Connect(changed))
	trackConnection(player, player:GetAttributeChangedSignal("Quota"):Connect(changed))
	trackConnection(player, player:GetAttributeChangedSignal("Escaped"):Connect(changed))
	trackConnection(player, stateFolder:GetAttributeChangedSignal("TimeLeft"):Connect(function()
		sendSnapshot(player)
	end))
	trackConnection(player, stateFolder:GetAttributeChangedSignal("Phase"):Connect(function()
		sendSnapshot(player)
	end))

	syncDerivedStats(player)
	sendSnapshot(player)
	queueBroadcast()
end

Players.PlayerAdded:Connect(setupLeaderstats)

Players.PlayerRemoving:Connect(function(player)
	local connections = connectionsByPlayer[player]
	if connections then
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
	end
	connectionsByPlayer[player] = nil
	queueBroadcast()
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(setupLeaderstats, player)
end
