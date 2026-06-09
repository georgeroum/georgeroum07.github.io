-- Workspace setup script / BuildCasinoMap.lua
-- Run once from ServerScriptService or the command bar to build the Gamble with Buddies casino map.

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local existingMap = Workspace:FindFirstChild("GambleWithBuddiesMap")
if existingMap then
	existingMap:Destroy()
end

local existingStations = Workspace:FindFirstChild("GamblingStations")
if existingStations then
	existingStations:Destroy()
end

local map = Instance.new("Model")
map.Name = "GambleWithBuddiesMap"
map.Parent = Workspace

local stationsFolder = Instance.new("Folder")
stationsFolder.Name = "GamblingStations"
stationsFolder.Parent = Workspace

Lighting.Brightness = 2
Lighting.ClockTime = 0
Lighting.Ambient = Color3.fromRGB(90, 55, 125)
Lighting.OutdoorAmbient = Color3.fromRGB(35, 20, 55)

local function createPart(name, size, cframe, color, material, parent, transparency)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Transparency = transparency or 0
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent or map
	return part
end

local function addPointLight(parent, color, range, brightness)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = brightness
	light.Parent = parent
	return light
end

local function addPrompt(parent, actionText, objectText)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0.15
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = parent
	return prompt
end

local function addSign(name, text, cframe, size)
	local sign = createPart(name, size or Vector3.new(18, 7, 0.5), cframe, Color3.fromRGB(18, 12, 30), Enum.Material.SmoothPlastic, map)
	local lightTrim = createPart(name .. "_NeonTrim", Vector3.new(sign.Size.X + 0.5, sign.Size.Y + 0.5, 0.25), cframe * CFrame.new(0, 0, -0.35), Color3.fromRGB(255, 215, 80), Enum.Material.Neon, map, 0.15)

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "SignText"
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 45
	surfaceGui.Parent = sign

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.Text = text
	label.TextColor3 = Color3.fromRGB(255, 235, 140)
	label.TextScaled = true
	label.TextWrapped = true
	label.Parent = surfaceGui

	addPointLight(lightTrim, Color3.fromRGB(255, 215, 80), 18, 1.2)
	return sign
end

local function createSpawn(name, cframe, color, parent)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = name
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.CFrame = cframe
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.AllowTeamChangeOnTouch = false
	spawn.Material = Enum.Material.Neon
	spawn.Color = color
	spawn.Transparency = 0.15
	spawn.Parent = parent or map
	return spawn
end

local function createChip(name, position, color)
	local chip = createPart(name, Vector3.new(1.2, 0.22, 1.2), CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)), color, Enum.Material.SmoothPlastic, map)
	chip.Shape = Enum.PartType.Cylinder
	local stripe = createPart(name .. "_Stripe", Vector3.new(1.24, 0.04, 1.24), chip.CFrame * CFrame.new(0, 0.14, 0), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, map)
	stripe.Shape = Enum.PartType.Cylinder
	return chip
end

local function createCard(name, position, rotationDegrees, text)
	local card = createPart(name, Vector3.new(2.5, 0.08, 3.5), CFrame.new(position) * CFrame.Angles(0, math.rad(rotationDegrees or 0), 0), Color3.fromRGB(245, 245, 245), Enum.Material.SmoothPlastic, map)
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Face = Enum.NormalId.Top
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 35
	surfaceGui.Parent = card

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.Text = text or "A"
	label.TextColor3 = Color3.fromRGB(180, 20, 35)
	label.TextScaled = true
	label.Parent = surfaceGui
	return card
end

local function createDice(name, position)
	local die = createPart(name, Vector3.new(2, 2, 2), CFrame.new(position), Color3.fromRGB(245, 245, 245), Enum.Material.SmoothPlastic, map)
	for index, offset in ipairs({
		Vector3.new(0, 1.02, 0),
		Vector3.new(0.55, 1.03, 0.55),
		Vector3.new(-0.55, 1.03, -0.55),
	}) do
		local pip = createPart(name .. "_Pip" .. index, Vector3.new(0.25, 0.05, 0.25), CFrame.new(position + offset), Color3.fromRGB(20, 20, 20), Enum.Material.SmoothPlastic, map)
		pip.Shape = Enum.PartType.Cylinder
	end
	return die
end

local function createTable(name, position, color, promptObjectText)
	local base = createPart(name, Vector3.new(16, 2, 10), CFrame.new(position), color, Enum.Material.SmoothPlastic, stationsFolder)
	base:SetAttribute("StationName", promptObjectText)
	addPrompt(base, "Play", promptObjectText)

	local top = createPart(name .. "_NeonTop", Vector3.new(16.5, 0.35, 10.5), CFrame.new(position + Vector3.new(0, 1.18, 0)), Color3.fromRGB(255, 220, 90), Enum.Material.Neon, map, 0.15)
	addPointLight(top, top.Color, 16, 1)

	local labelPart = createPart(name .. "_Label", Vector3.new(12, 0.12, 2.4), CFrame.new(position + Vector3.new(0, 1.42, -3.2)), Color3.fromRGB(18, 18, 25), Enum.Material.SmoothPlastic, map)
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Face = Enum.NormalId.Top
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 40
	surfaceGui.Parent = labelPart

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.Text = promptObjectText
	label.TextColor3 = Color3.fromRGB(255, 235, 140)
	label.TextScaled = true
	label.Parent = surfaceGui

	return base
end

-- Casino shell.
createPart("CasinoFloor", Vector3.new(160, 1, 112), CFrame.new(0, 0, 0), Color3.fromRGB(35, 20, 55), Enum.Material.SmoothPlastic, map)
createPart("CeilingGlow", Vector3.new(160, 1, 112), CFrame.new(0, 24, 0), Color3.fromRGB(90, 30, 140), Enum.Material.Neon, map, 0.45)
createPart("BackWall", Vector3.new(160, 24, 2), CFrame.new(0, 12, -56), Color3.fromRGB(35, 18, 60), Enum.Material.SmoothPlastic, map)
createPart("FrontWall", Vector3.new(160, 24, 2), CFrame.new(0, 12, 56), Color3.fromRGB(35, 18, 60), Enum.Material.SmoothPlastic, map)
createPart("LeftWall", Vector3.new(2, 24, 112), CFrame.new(-80, 12, 0), Color3.fromRGB(35, 18, 60), Enum.Material.SmoothPlastic, map)
createPart("RightWall", Vector3.new(2, 24, 112), CFrame.new(80, 12, 0), Color3.fromRGB(35, 18, 60), Enum.Material.SmoothPlastic, map)

for x = -65, 65, 26 do
	createPart("NeonWallStrip_" .. x, Vector3.new(1.2, 18, 0.8), CFrame.new(x, 12, -54.6), Color3.fromRGB(255, 55, 180), Enum.Material.Neon, map)
	createPart("FrontNeonWallStrip_" .. x, Vector3.new(1.2, 18, 0.8), CFrame.new(x, 12, 54.6), Color3.fromRGB(80, 220, 255), Enum.Material.Neon, map)
end

for z = -42, 42, 21 do
	createPart("LeftNeonWallStrip_" .. z, Vector3.new(0.8, 18, 1.2), CFrame.new(-78.6, 12, z), Color3.fromRGB(255, 210, 80), Enum.Material.Neon, map)
	createPart("RightNeonWallStrip_" .. z, Vector3.new(0.8, 18, 1.2), CFrame.new(78.6, 12, z), Color3.fromRGB(80, 255, 120), Enum.Material.Neon, map)
end

-- Spawn and entrance.
createSpawn("CasinoSpawn", CFrame.new(0, 1.1, 43), Color3.fromRGB(80, 220, 255), map)
addSign("TitleSign", "GAMBLE WITH BUDDIES\nFake round money only", CFrame.new(0, 12, 54.2), Vector3.new(34, 9, 0.5))
addSign("RulesSign", "Reach $1500 before 5:00 ends.\nUse casino games to win or lose fake money.\nEscape through the glowing quota exit.", CFrame.new(-52, 8, 54.2), Vector3.new(28, 9, 0.5))
addSign("SafetySign", "No Robux gambling.\nNo real money.\nNo cash out.\nOnly fictional in-round currency.", CFrame.new(52, 8, 54.2), Vector3.new(28, 9, 0.5))

-- Quota exit and winner lounge.
local exitDoor = createPart("CasinoExitDoor", Vector3.new(16, 17, 2), CFrame.new(0, 8.5, -54.8), Color3.fromRGB(255, 65, 75), Enum.Material.Neon, map)
addPointLight(exitDoor, Color3.fromRGB(255, 80, 80), 24, 2)
addPrompt(exitDoor, "Escape", "Quota Exit")
addSign("ExitSign", "QUOTA EXIT\n$1500 REQUIRED", CFrame.new(0, 19, -53.9), Vector3.new(24, 5.5, 0.5))

createPart("WinnerLoungeFloor", Vector3.new(70, 1, 38), CFrame.new(0, 0, -88), Color3.fromRGB(20, 70, 45), Enum.Material.SmoothPlastic, map)
createPart("WinnerLoungeBackWall", Vector3.new(70, 16, 2), CFrame.new(0, 8, -108), Color3.fromRGB(18, 80, 50), Enum.Material.SmoothPlastic, map)
createPart("WinnerLoungeNeon", Vector3.new(64, 1, 1), CFrame.new(0, 14, -107), Color3.fromRGB(80, 255, 120), Enum.Material.Neon, map)
createSpawn("WinnerLoungeSpawn", CFrame.new(0, 1.1, -87), Color3.fromRGB(80, 255, 120), map)
addSign("WinnerLoungeSign", "WINNER LOUNGE\nYou escaped the casino!", CFrame.new(0, 9, -106.8), Vector3.new(30, 7, 0.5))

-- Gambling stations.
local coinTable = createTable("CoinFlipTable", Vector3.new(-48, 1, 18), Color3.fromRGB(40, 90, 180), "Coin Flip Table")
createChip("CoinFlipChipA", Vector3.new(-51, 3, 17), Color3.fromRGB(255, 210, 80))
createChip("CoinFlipChipB", Vector3.new(-48, 3, 18.5), Color3.fromRGB(80, 220, 255))
createPart("GiantCoin", Vector3.new(4, 0.35, 4), CFrame.new(-44, 3.2, 18) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 220, 95), Enum.Material.Metal, map).Shape = Enum.PartType.Cylinder

local diceTable = createTable("DiceTable", Vector3.new(0, 1, 18), Color3.fromRGB(110, 45, 175), "Dice Table")
createDice("DecorDiceA", Vector3.new(-2.5, 3.1, 18))
createDice("DecorDiceB", Vector3.new(2.5, 3.1, 18))

local rouletteTable = createTable("RouletteTable", Vector3.new(48, 1, 18), Color3.fromRGB(30, 120, 80), "Roulette Table")
local wheel = createPart("RouletteWheel", Vector3.new(7, 0.4, 7), CFrame.new(48, 3, 18) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(25, 25, 30), Enum.Material.SmoothPlastic, map)
wheel.Shape = Enum.PartType.Cylinder
createPart("RouletteGreenPocket", Vector3.new(2, 0.45, 2), CFrame.new(48, 3.3, 18), Color3.fromRGB(25, 180, 75), Enum.Material.Neon, map).Shape = Enum.PartType.Cylinder

local slotsBase = createPart("SlotsMachineArea", Vector3.new(24, 2, 10), CFrame.new(-28, 1, -22), Color3.fromRGB(115, 60, 25), Enum.Material.SmoothPlastic, stationsFolder)
slotsBase:SetAttribute("StationName", "Slots")
addPrompt(slotsBase, "Play", "Slots")
for offset = -7, 7, 7 do
	local machine = createPart("SlotMachine_" .. offset, Vector3.new(5, 10, 4), CFrame.new(-28 + offset, 6, -22), Color3.fromRGB(170, 35, 70), Enum.Material.SmoothPlastic, map)
	createPart("SlotScreen_" .. offset, Vector3.new(4, 3, 0.3), CFrame.new(-28 + offset, 7, -19.8), Color3.fromRGB(255, 225, 90), Enum.Material.Neon, map)
	createPart("SlotLever_" .. offset, Vector3.new(0.35, 4, 0.35), CFrame.new(-25.6 + offset, 6, -20), Color3.fromRGB(230, 230, 230), Enum.Material.Metal, map)
	addPointLight(machine, Color3.fromRGB(255, 90, 130), 12, 1)
end
addSign("SlotsSign", "SLOTS\n2 match = 2x\n3 common = 5x\n3 rare = 15x", CFrame.new(-28, 13, -17.5), Vector3.new(24, 6, 0.5))

local blackjackTable = createTable("BlackjackTable", Vector3.new(28, 1, -22), Color3.fromRGB(25, 110, 65), "Blackjack Lite")
createCard("BlackjackCardA", Vector3.new(25, 3.1, -23), -10, "K")
createCard("BlackjackCardB", Vector3.new(28, 3.1, -22.5), 12, "A")
createCard("BlackjackCardC", Vector3.new(31, 3.1, -23), 6, "9")

-- Central decorations and lighting.
for i = 1, 18 do
	local angle = (math.pi * 2 / 18) * i
	local radius = 18
	local x = math.cos(angle) * radius
	local z = math.sin(angle) * radius - 3
	createChip("CenterChip_" .. i, Vector3.new(x, 1.2, z), i % 2 == 0 and Color3.fromRGB(255, 55, 90) or Color3.fromRGB(80, 220, 255))
end

local chandelier = createPart("NeonChandelier", Vector3.new(28, 1, 28), CFrame.new(0, 21, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 210, 80), Enum.Material.Neon, map, 0.15)
chandelier.Shape = Enum.PartType.Cylinder
addPointLight(chandelier, Color3.fromRGB(255, 210, 100), 70, 3.5)

addSign("ChaosSign", "Watch the leaderboard.\nCheer wins. Laugh at losses.\nEscape before the clock hits zero.", CFrame.new(0, 8, 0) * CFrame.Angles(0, math.rad(180), 0), Vector3.new(28, 7, 0.5))

print("Gamble with Buddies casino map built successfully.")
