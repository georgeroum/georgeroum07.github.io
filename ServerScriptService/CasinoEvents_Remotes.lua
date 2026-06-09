-- ServerScriptService/CasinoEvents_Remotes.lua
-- Creates shared remotes and replicated round state for Gamble with Buddies.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local REMOTE_FOLDER_NAME = "CasinoRemotes"
local STATE_FOLDER_NAME = "CasinoRoundState"

local remoteNames = {
	"UpdateUI",
	"PlaceBet",
	"GameResult",
	"RoundStatus",
	"AttemptExit",
}

local remotesFolder = ReplicatedStorage:FindFirstChild(REMOTE_FOLDER_NAME)
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = REMOTE_FOLDER_NAME
	remotesFolder.Parent = ReplicatedStorage
end

for _, remoteName in ipairs(remoteNames) do
	local existing = remotesFolder:FindFirstChild(remoteName)
	if existing and not existing:IsA("RemoteEvent") then
		existing:Destroy()
		existing = nil
	end

	if not existing then
		local remote = Instance.new("RemoteEvent")
		remote.Name = remoteName
		remote.Parent = remotesFolder
	end
end

local stateFolder = ReplicatedStorage:FindFirstChild(STATE_FOLDER_NAME)
if not stateFolder then
	stateFolder = Instance.new("Folder")
	stateFolder.Name = STATE_FOLDER_NAME
	stateFolder.Parent = ReplicatedStorage
end

local defaultAttributes = {
	RoundActive = false,
	Phase = "Waiting",
	TimeLeft = 0,
	StartingMoney = 500,
	Quota = 1500,
	RoundTime = 300,
	IntermissionTime = 20,
}

for attributeName, defaultValue in pairs(defaultAttributes) do
	if stateFolder:GetAttribute(attributeName) == nil then
		stateFolder:SetAttribute(attributeName, defaultValue)
	end
end

print("Gamble with Buddies remotes and round state are ready.")
