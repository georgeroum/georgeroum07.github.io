-- StarterPlayer/StarterPlayerScripts/CasinoUI_Client.lua
-- Builds the main Gamble with Buddies UI and keeps it synced with server data.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotesFolder = ReplicatedStorage:WaitForChild("CasinoRemotes")
local updateUI = remotesFolder:WaitForChild("UpdateUI")
local gameResult = remotesFolder:WaitForChild("GameResult")
local roundStatus = remotesFolder:WaitForChild("RoundStatus")
local stateFolder = ReplicatedStorage:WaitForChild("CasinoRoundState")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CasinoUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local function addCorner(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = instance
end

local function addStroke(instance, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness or 1
	stroke.Transparency = 0.25
	stroke.Parent = instance
end

local function makeLabel(name, parent, size, position, text, textSize, color, backgroundColor)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundColor3 = backgroundColor or Color3.fromRGB(20, 20, 30)
	label.BackgroundTransparency = 0.08
	label.BorderSizePixel = 0
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.TextSize = textSize or 22
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = parent
	addCorner(label, 8)
	addStroke(label, Color3.fromRGB(255, 210, 80), 1)
	return label
end

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(0.66, 0, 0, 64)
topBar.Position = UDim2.new(0.02, 0, 0.02, 0)
topBar.BackgroundTransparency = 1
topBar.Parent = screenGui

local moneyLabel = makeLabel("MoneyLabel", topBar, UDim2.new(0.24, -6, 1, 0), UDim2.new(0, 0, 0, 0), "Money: $0", 22, Color3.fromRGB(80, 255, 120))
local quotaLabel = makeLabel("QuotaLabel", topBar, UDim2.new(0.24, -6, 1, 0), UDim2.new(0.25, 0, 0, 0), "Quota: $1500", 22, Color3.fromRGB(255, 225, 90))
local profitLabel = makeLabel("ProfitLabel", topBar, UDim2.new(0.24, -6, 1, 0), UDim2.new(0.5, 0, 0, 0), "P/L: $0", 22, Color3.fromRGB(255, 255, 255))
local timerLabel = makeLabel("TimerLabel", topBar, UDim2.new(0.24, -6, 1, 0), UDim2.new(0.75, 0, 0, 0), "05:00", 24, Color3.fromRGB(255, 255, 255))

local statusLabel = makeLabel(
	"StatusLabel",
	screenGui,
	UDim2.new(0.66, 0, 0, 44),
	UDim2.new(0.02, 0, 0.105, 0),
	"Welcome to Gamble with Buddies. Hit the quota, then escape!",
	19,
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(45, 25, 75)
)
statusLabel.TextWrapped = true

local resultPopup = makeLabel(
	"ResultPopup",
	screenGui,
	UDim2.new(0.42, 0, 0, 86),
	UDim2.new(0.29, 0, 0.21, 0),
	"",
	24,
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(25, 25, 35)
)
resultPopup.Visible = false
resultPopup.TextWrapped = true
resultPopup.ZIndex = 10

local leaderboardPanel = Instance.new("Frame")
leaderboardPanel.Name = "LeaderboardPanel"
leaderboardPanel.Size = UDim2.new(0.27, 0, 0.72, 0)
leaderboardPanel.Position = UDim2.new(0.715, 0, 0.14, 0)
leaderboardPanel.BackgroundColor3 = Color3.fromRGB(12, 12, 22)
leaderboardPanel.BackgroundTransparency = 0.04
leaderboardPanel.BorderSizePixel = 0
leaderboardPanel.Parent = screenGui
addCorner(leaderboardPanel, 12)
addStroke(leaderboardPanel, Color3.fromRGB(255, 210, 80), 2)

local leaderboardTitle = makeLabel(
	"LeaderboardTitle",
	leaderboardPanel,
	UDim2.new(1, -16, 0, 44),
	UDim2.new(0, 8, 0, 8),
	"Profit / Loss",
	22,
	Color3.fromRGB(255, 230, 120),
	Color3.fromRGB(35, 20, 55)
)

local rowsFrame = Instance.new("Frame")
rowsFrame.Name = "Rows"
rowsFrame.Size = UDim2.new(1, -16, 1, -64)
rowsFrame.Position = UDim2.new(0, 8, 0, 56)
rowsFrame.BackgroundTransparency = 1
rowsFrame.Parent = leaderboardPanel

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = rowsFrame

local lastPopupToken = 0
local latestLeaderboard = {}

local function formatMoney(amount)
	return "$" .. tostring(math.floor(tonumber(amount) or 0))
end

local function formatProfit(amount)
	amount = math.floor(tonumber(amount) or 0)
	if amount > 0 then
		return "+$" .. amount
	elseif amount < 0 then
		return "-$" .. math.abs(amount)
	end
	return "$0"
end

local function formatTime(seconds)
	seconds = math.max(0, math.floor(tonumber(seconds) or 0))
	local minutes = math.floor(seconds / 60)
	local remainingSeconds = seconds % 60
	return string.format("%02d:%02d", minutes, remainingSeconds)
end

local function profitColor(amount)
	amount = tonumber(amount) or 0
	if amount > 0 then
		return Color3.fromRGB(80, 255, 120)
	elseif amount < 0 then
		return Color3.fromRGB(255, 90, 90)
	end
	return Color3.fromRGB(235, 235, 235)
end

local function getLocalStat(statName)
	local leaderstats = player:FindFirstChild("leaderstats")
	local stat = leaderstats and leaderstats:FindFirstChild(statName)
	return stat and stat.Value or 0
end

local function updateLocalCounters(stats)
	local money = stats and stats.Money or getLocalStat("Money")
	local quota = stats and stats.Quota or getLocalStat("Quota")
	local profitLoss = stats and stats.ProfitLoss or getLocalStat("ProfitLoss")

	moneyLabel.Text = "Money: " .. formatMoney(money)
	quotaLabel.Text = "Quota: " .. formatMoney(quota)
	profitLabel.Text = "P/L: " .. formatProfit(profitLoss)
	profitLabel.TextColor3 = profitColor(profitLoss)
end

local function createLeaderboardRow(entry, index)
	local row = Instance.new("Frame")
	row.Name = "Row_" .. tostring(entry.UserId or index)
	row.LayoutOrder = index
	row.Size = UDim2.new(1, 0, 0, 48)
	row.BackgroundColor3 = entry.Escaped and Color3.fromRGB(18, 75, 45) or Color3.fromRGB(28, 28, 42)
	row.BackgroundTransparency = 0.08
	row.BorderSizePixel = 0
	row.Parent = rowsFrame
	addCorner(row, 8)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(0.46, -4, 1, 0)
	nameLabel.Position = UDim2.new(0, 8, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = (entry.Escaped and "[ESC] " or "") .. tostring(entry.DisplayName or entry.Name or "Player")
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 16
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = row

	local moneyText = Instance.new("TextLabel")
	moneyText.Name = "Money"
	moneyText.Size = UDim2.new(0.27, -4, 1, 0)
	moneyText.Position = UDim2.new(0.46, 0, 0, 0)
	moneyText.BackgroundTransparency = 1
	moneyText.Font = Enum.Font.Gotham
	moneyText.Text = formatMoney(entry.Money)
	moneyText.TextColor3 = Color3.fromRGB(255, 225, 90)
	moneyText.TextSize = 15
	moneyText.TextXAlignment = Enum.TextXAlignment.Right
	moneyText.Parent = row

	local profitText = Instance.new("TextLabel")
	profitText.Name = "Profit"
	profitText.Size = UDim2.new(0.27, -8, 1, 0)
	profitText.Position = UDim2.new(0.73, 0, 0, 0)
	profitText.BackgroundTransparency = 1
	profitText.Font = Enum.Font.GothamBold
	profitText.Text = formatProfit(entry.ProfitLoss)
	profitText.TextColor3 = profitColor(entry.ProfitLoss)
	profitText.TextSize = 16
	profitText.TextXAlignment = Enum.TextXAlignment.Right
	profitText.Parent = row
end

local function updateLeaderboard(entries)
	latestLeaderboard = entries or latestLeaderboard or {}

	for _, child in ipairs(rowsFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	for index, entry in ipairs(latestLeaderboard) do
		createLeaderboardRow(entry, index)
	end
end

local function showResult(message, details, won, push)
	lastPopupToken += 1
	local token = lastPopupToken

	resultPopup.Text = tostring(message or "") .. (details and details ~= "" and ("\n" .. tostring(details)) or "")
	if push then
		resultPopup.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
	elseif won then
		resultPopup.BackgroundColor3 = Color3.fromRGB(20, 90, 45)
	else
		resultPopup.BackgroundColor3 = Color3.fromRGB(95, 25, 30)
	end
	resultPopup.TextTransparency = 0
	resultPopup.BackgroundTransparency = 0.04
	resultPopup.Visible = true

	task.delay(3, function()
		if token ~= lastPopupToken then
			return
		end
		local tween = TweenService:Create(resultPopup, TweenInfo.new(0.35), {
			TextTransparency = 1,
			BackgroundTransparency = 1,
		})
		tween:Play()
		tween.Completed:Wait()
		if token == lastPopupToken then
			resultPopup.Visible = false
		end
	end)
end

local function connectStatUpdates()
	local leaderstats = player:WaitForChild("leaderstats", 10)
	if not leaderstats then
		return
	end

	for _, statName in ipairs({ "Money", "ProfitLoss", "Quota", "Escaped" }) do
		local stat = leaderstats:WaitForChild(statName, 10)
		if stat then
			stat.Changed:Connect(function()
				updateLocalCounters()
			end)
		end
	end

	updateLocalCounters()
end

updateUI.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then
		return
	end

	updateLocalCounters(payload.Player)
	if payload.TimeLeft ~= nil then
		timerLabel.Text = formatTime(payload.TimeLeft)
	end
	if payload.Phase then
		leaderboardTitle.Text = "Profit / Loss - " .. tostring(payload.Phase)
	end
	if payload.Leaderboard then
		updateLeaderboard(payload.Leaderboard)
	end
end)

roundStatus.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then
		return
	end

	if payload.TimeLeft ~= nil then
		timerLabel.Text = formatTime(payload.TimeLeft)
	end
	if payload.Message and payload.Message ~= "" then
		statusLabel.Text = payload.Message
	end
	if payload.Phase then
		leaderboardTitle.Text = "Profit / Loss - " .. tostring(payload.Phase)
	end
end)

gameResult.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then
		return
	end

	showResult(payload.Message, payload.Details, payload.Won, payload.Push)
	updateLocalCounters()
end)

stateFolder:GetAttributeChangedSignal("TimeLeft"):Connect(function()
	timerLabel.Text = formatTime(stateFolder:GetAttribute("TimeLeft") or 0)
end)

task.spawn(connectStatUpdates)
timerLabel.Text = formatTime(stateFolder:GetAttribute("TimeLeft") or 0)
updateLocalCounters()
