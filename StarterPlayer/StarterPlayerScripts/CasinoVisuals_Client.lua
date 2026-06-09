-- StarterPlayer/StarterPlayerScripts/CasinoVisuals_Client.lua
-- Adds client-side flashes, money popups, timer warnings, exit glow, and leaderboard row tweens.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotesFolder = ReplicatedStorage:WaitForChild("CasinoRemotes")
local gameResult = remotesFolder:WaitForChild("GameResult")
local roundStatus = remotesFolder:WaitForChild("RoundStatus")
local stateFolder = ReplicatedStorage:WaitForChild("CasinoRoundState")

local visualsGui = Instance.new("ScreenGui")
visualsGui.Name = "CasinoVisuals"
visualsGui.ResetOnSpawn = false
visualsGui.IgnoreGuiInset = true
visualsGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
visualsGui.Parent = playerGui

local flashFrame = Instance.new("Frame")
flashFrame.Name = "WinLossFlash"
flashFrame.Size = UDim2.new(1, 0, 1, 0)
flashFrame.Position = UDim2.new(0, 0, 0, 0)
flashFrame.BackgroundTransparency = 1
flashFrame.BorderSizePixel = 0
flashFrame.ZIndex = 100
flashFrame.Parent = visualsGui

local popupLayer = Instance.new("Frame")
popupLayer.Name = "MoneyPopupLayer"
popupLayer.Size = UDim2.new(1, 0, 1, 0)
popupLayer.BackgroundTransparency = 1
popupLayer.ZIndex = 101
popupLayer.Parent = visualsGui

local exitHighlight
local warningTween

local function formatDelta(delta)
	delta = math.floor(tonumber(delta) or 0)
	if delta > 0 then
		return "+$" .. delta
	elseif delta < 0 then
		return "-$" .. math.abs(delta)
	end
	return "$0"
end

local function flash(color)
	flashFrame.BackgroundColor3 = color
	flashFrame.BackgroundTransparency = 0.55
	TweenService:Create(flashFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1,
	}):Play()
end

local function spawnMoneyPopup(delta)
	if delta == 0 then
		return
	end

	local label = Instance.new("TextLabel")
	label.Name = "FloatingMoney"
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Size = UDim2.new(0, 240, 0, 56)
	label.Position = UDim2.new(0.5, math.random(-140, 140), 0.5, math.random(-40, 60))
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.Text = formatDelta(delta)
	label.TextColor3 = delta > 0 and Color3.fromRGB(90, 255, 130) or Color3.fromRGB(255, 95, 95)
	label.TextStrokeTransparency = 0.25
	label.TextScaled = true
	label.ZIndex = 102
	label.Parent = popupLayer

	local tween = TweenService:Create(label, TweenInfo.new(1.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(label.Position.X.Scale, label.Position.X.Offset, label.Position.Y.Scale - 0.14, label.Position.Y.Offset),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})
	tween:Play()
	tween.Completed:Connect(function()
		label:Destroy()
	end)
end

local function getMainTimerLabel()
	local casinoUi = playerGui:FindFirstChild("CasinoUI")
	return casinoUi and casinoUi:FindFirstChild("TimerLabel", true)
end

local function updateTimerWarning(timeLeft)
	local timerLabel = getMainTimerLabel()
	if not timerLabel then
		return
	end

	if timeLeft > 0 and timeLeft <= 30 then
		timerLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
		if not warningTween or warningTween.PlaybackState ~= Enum.PlaybackState.Playing then
			timerLabel.TextSize = 28
			warningTween = TweenService:Create(timerLabel, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true), {
				TextSize = 34,
			})
			warningTween:Play()
		end
	else
		if warningTween then
			warningTween:Cancel()
			warningTween = nil
		end
		timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		timerLabel.TextSize = 24
	end
end

local function getLeaderstats()
	return player:FindFirstChild("leaderstats")
end

local function canEscape()
	local leaderstats = getLeaderstats()
	if not leaderstats then
		return false
	end

	local money = leaderstats:FindFirstChild("Money")
	local quota = leaderstats:FindFirstChild("Quota")
	local escaped = leaderstats:FindFirstChild("Escaped")
	local roundActive = stateFolder:GetAttribute("RoundActive") == true

	return roundActive
		and money
		and quota
		and escaped
		and escaped.Value == false
		and money.Value >= quota.Value
end

local function updateExitGlow()
	if exitHighlight then
		exitHighlight.Enabled = canEscape()
	end
end

local function findExitDoor()
	local door = Workspace:FindFirstChild("CasinoExitDoor", true)
	if door and door:IsA("BasePart") then
		return door
	end
	return nil
end

local function setupExitGlow()
	local door
	for _ = 1, 60 do
		door = findExitDoor()
		if door then
			break
		end
		task.wait(0.5)
	end

	if not door then
		return
	end

	exitHighlight = door:FindFirstChild("QuotaReadyHighlight")
	if exitHighlight and not exitHighlight:IsA("Highlight") then
		exitHighlight:Destroy()
		exitHighlight = nil
	end

	if not exitHighlight then
		exitHighlight = Instance.new("Highlight")
		exitHighlight.Name = "QuotaReadyHighlight"
		exitHighlight.FillColor = Color3.fromRGB(80, 255, 120)
		exitHighlight.OutlineColor = Color3.fromRGB(255, 255, 160)
		exitHighlight.FillTransparency = 0.45
		exitHighlight.OutlineTransparency = 0
		exitHighlight.Enabled = false
		exitHighlight.Parent = door
	end

	updateExitGlow()
end

local function connectLeaderstatSignals()
	local leaderstats = player:WaitForChild("leaderstats", 20)
	if not leaderstats then
		return
	end

	for _, statName in ipairs({ "Money", "Quota", "Escaped" }) do
		local stat = leaderstats:WaitForChild(statName, 10)
		if stat then
			stat.Changed:Connect(updateExitGlow)
		end
	end

	updateExitGlow()
end

local function tweenLeaderboardRow(row)
	if not row:IsA("Frame") then
		return
	end

	row.BackgroundTransparency = 0.35
	TweenService:Create(row, TweenInfo.new(0.25), {
		BackgroundTransparency = 0.08,
	}):Play()
end

local function setupLeaderboardTweens()
	local casinoUi = playerGui:WaitForChild("CasinoUI", 20)
	if not casinoUi then
		return
	end

	local rows = casinoUi:FindFirstChild("Rows", true)
	if not rows then
		return
	end

	rows.ChildAdded:Connect(tweenLeaderboardRow)
	for _, child in ipairs(rows:GetChildren()) do
		tweenLeaderboardRow(child)
	end
end

gameResult.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then
		return
	end

	local delta = tonumber(payload.Delta) or 0
	if delta > 0 then
		flash(Color3.fromRGB(0, 255, 80))
		spawnMoneyPopup(delta)
	elseif delta < 0 then
		flash(Color3.fromRGB(255, 0, 40))
		spawnMoneyPopup(delta)
	end
end)

roundStatus.OnClientEvent:Connect(function(payload)
	if typeof(payload) == "table" and payload.TimeLeft ~= nil then
		updateTimerWarning(payload.TimeLeft)
	end
end)

stateFolder:GetAttributeChangedSignal("TimeLeft"):Connect(function()
	updateTimerWarning(stateFolder:GetAttribute("TimeLeft") or 0)
end)

stateFolder:GetAttributeChangedSignal("RoundActive"):Connect(updateExitGlow)

task.spawn(setupExitGlow)
task.spawn(connectLeaderstatSignals)
task.spawn(setupLeaderboardTweens)
