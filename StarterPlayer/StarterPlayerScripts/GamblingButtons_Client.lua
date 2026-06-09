-- StarterPlayer/StarterPlayerScripts/GamblingButtons_Client.lua
-- Builds clickable controls for every casino mini-game and sends bet requests to the server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotesFolder = ReplicatedStorage:WaitForChild("CasinoRemotes")
local placeBet = remotesFolder:WaitForChild("PlaceBet")
local attemptExit = remotesFolder:WaitForChild("AttemptExit")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CasinoBettingUI"
screenGui.ResetOnSpawn = false
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

local panel = Instance.new("Frame")
panel.Name = "BettingPanel"
panel.Size = UDim2.new(0.25, 0, 0.56, 0)
panel.Position = UDim2.new(0.02, 0, 0.39, 0)
panel.BackgroundColor3 = Color3.fromRGB(14, 14, 26)
panel.BackgroundTransparency = 0.03
panel.BorderSizePixel = 0
panel.Parent = screenGui
addCorner(panel, 12)
addStroke(panel, Color3.fromRGB(255, 210, 80), 2)

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -16, 0, 38)
title.Position = UDim2.new(0, 8, 0, 8)
title.BackgroundColor3 = Color3.fromRGB(45, 24, 70)
title.BorderSizePixel = 0
title.Font = Enum.Font.GothamBold
title.Text = "Gambling Games"
title.TextColor3 = Color3.fromRGB(255, 230, 120)
title.TextSize = 21
title.Parent = panel
addCorner(title, 8)

local betBox = Instance.new("TextBox")
betBox.Name = "BetAmountBox"
betBox.Size = UDim2.new(1, -16, 0, 38)
betBox.Position = UDim2.new(0, 8, 0, 54)
betBox.BackgroundColor3 = Color3.fromRGB(245, 245, 255)
betBox.BorderSizePixel = 0
betBox.ClearTextOnFocus = false
betBox.Font = Enum.Font.GothamBold
betBox.PlaceholderText = "Enter bet amount"
betBox.Text = "50"
betBox.TextColor3 = Color3.fromRGB(20, 20, 25)
betBox.TextSize = 20
betBox.Parent = panel
addCorner(betBox, 8)

local feedback = Instance.new("TextLabel")
feedback.Name = "Feedback"
feedback.Size = UDim2.new(1, -16, 0, 28)
feedback.Position = UDim2.new(0, 8, 0, 98)
feedback.BackgroundTransparency = 1
feedback.Font = Enum.Font.Gotham
feedback.Text = "Fake round money only. No Robux gambling."
feedback.TextColor3 = Color3.fromRGB(210, 210, 225)
feedback.TextSize = 13
feedback.TextWrapped = true
feedback.Parent = panel

local buttonsFrame = Instance.new("Frame")
buttonsFrame.Name = "Buttons"
buttonsFrame.Size = UDim2.new(1, -16, 1, -174)
buttonsFrame.Position = UDim2.new(0, 8, 0, 132)
buttonsFrame.BackgroundTransparency = 1
buttonsFrame.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = buttonsFrame

local function parseBet()
	local digitsOnly = tostring(betBox.Text or ""):gsub("[^%d]", "")
	local amount = tonumber(digitsOnly) or 0
	return math.floor(amount)
end

local function setFeedback(text, color)
	feedback.Text = text
	feedback.TextColor3 = color or Color3.fromRGB(210, 210, 225)
end

local function sendBet(gameName, choice)
	local betAmount = parseBet()
	if betAmount <= 0 then
		setFeedback("Enter a positive bet first.", Color3.fromRGB(255, 100, 100))
		return
	end

	betBox.Text = tostring(betAmount)
	setFeedback("Bet sent: $" .. betAmount .. " on " .. gameName .. (choice and (" " .. choice) or "") .. ".", Color3.fromRGB(120, 255, 150))
	placeBet:FireServer(gameName, betAmount, choice)
end

local buttonDefinitions = {
	{ Text = "Coin Flip Heads", Game = "CoinFlip", Choice = "Heads", Color = Color3.fromRGB(60, 115, 220) },
	{ Text = "Coin Flip Tails", Game = "CoinFlip", Choice = "Tails", Color = Color3.fromRGB(60, 115, 220) },
	{ Text = "Dice Roll", Game = "DiceRoll", Choice = nil, Color = Color3.fromRGB(170, 80, 220) },
	{ Text = "Roulette Red", Game = "Roulette", Choice = "Red", Color = Color3.fromRGB(210, 50, 55) },
	{ Text = "Roulette Black", Game = "Roulette", Choice = "Black", Color = Color3.fromRGB(40, 40, 48) },
	{ Text = "Roulette Green", Game = "Roulette", Choice = "Green", Color = Color3.fromRGB(30, 165, 80) },
	{ Text = "Slots", Game = "Slots", Choice = nil, Color = Color3.fromRGB(235, 170, 35) },
	{ Text = "Blackjack Lite", Game = "Blackjack", Choice = nil, Color = Color3.fromRGB(30, 130, 95) },
}

for index, definition in ipairs(buttonDefinitions) do
	local button = Instance.new("TextButton")
	button.Name = definition.Text:gsub("%s+", "") .. "Button"
	button.LayoutOrder = index
	button.Size = UDim2.new(1, 0, 0, 36)
	button.BackgroundColor3 = definition.Color
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	button.Font = Enum.Font.GothamBold
	button.Text = definition.Text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 17
	button.Parent = buttonsFrame
	addCorner(button, 8)
	addStroke(button, Color3.fromRGB(255, 255, 255), 1)

	button.Activated:Connect(function()
		sendBet(definition.Game, definition.Choice)
	end)
end

local exitButton = Instance.new("TextButton")
exitButton.Name = "AttemptExitButton"
exitButton.Size = UDim2.new(1, -16, 0, 36)
exitButton.Position = UDim2.new(0, 8, 1, -44)
exitButton.BackgroundColor3 = Color3.fromRGB(255, 220, 80)
exitButton.BorderSizePixel = 0
exitButton.Font = Enum.Font.GothamBold
exitButton.Text = "Attempt Exit"
exitButton.TextColor3 = Color3.fromRGB(30, 25, 15)
exitButton.TextSize = 18
exitButton.Parent = panel
addCorner(exitButton, 8)
addStroke(exitButton, Color3.fromRGB(255, 255, 255), 1)

exitButton.Activated:Connect(function()
	setFeedback("Trying the quota exit...", Color3.fromRGB(255, 230, 120))
	attemptExit:FireServer()
end)

local function connectStationPrompts()
	local stationsFolder = Workspace:WaitForChild("GamblingStations", 20)
	if not stationsFolder then
		return
	end

	for _, descendant in ipairs(stationsFolder:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") then
			descendant.Triggered:Connect(function()
				setFeedback("Station selected: " .. descendant.ObjectText .. ". Pick a bet and press a game button.", Color3.fromRGB(255, 230, 120))
			end)
		end
	end

	stationsFolder.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("ProximityPrompt") then
			descendant.Triggered:Connect(function()
				setFeedback("Station selected: " .. descendant.ObjectText .. ". Pick a bet and press a game button.", Color3.fromRGB(255, 230, 120))
			end)
		end
	end)
end

task.spawn(connectStationPrompts)
