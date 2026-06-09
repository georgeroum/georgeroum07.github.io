-- ServerScriptService/GamblingGames_Server.lua
-- Server-authoritative fake-currency gambling games. This script never uses Robux,
-- developer products, limited items, real money, or cash-out systems.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotesFolder = ReplicatedStorage:WaitForChild("CasinoRemotes")
local placeBet = remotesFolder:WaitForChild("PlaceBet")
local gameResult = remotesFolder:WaitForChild("GameResult")
local roundStatus = remotesFolder:WaitForChild("RoundStatus")
local stateFolder = ReplicatedStorage:WaitForChild("CasinoRoundState")

local rng = Random.new()
local betCooldowns = {}
local BET_COOLDOWN_SECONDS = 0.2

local function getMoneyValue(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	return leaderstats and leaderstats:FindFirstChild("Money")
end

local function sendResult(player, payload)
	gameResult:FireClient(player, payload)
end

local function rejectBet(player, reason)
	sendResult(player, {
		Game = "Bet Rejected",
		Delta = 0,
		Balance = (getMoneyValue(player) and getMoneyValue(player).Value) or 0,
		Won = false,
		Push = true,
		Message = reason,
		Details = reason,
	})
end

local function cleanChoice(choice)
	return string.lower(tostring(choice or ""))
end

local function coinFlip(bet, choice)
	local selected = cleanChoice(choice)
	if selected ~= "heads" and selected ~= "tails" then
		return nil, "Choose Heads or Tails for Coin Flip."
	end

	local actual = rng:NextInteger(1, 2) == 1 and "heads" or "tails"
	local won = selected == actual
	return {
		ReturnAmount = won and bet * 2 or 0,
		DisplayName = "Coin Flip",
		Details = "You picked " .. selected .. ". The coin landed " .. actual .. ".",
	}
end

local function diceRoll(bet)
	local roll = rng:NextInteger(1, 6)
	local won = roll >= 4
	return {
		ReturnAmount = won and bet * 2 or 0,
		DisplayName = "Dice Roll",
		Details = "You rolled a " .. roll .. ". Win on 4, 5, or 6.",
	}
end

local function rouletteLite(bet, choice)
	local selected = cleanChoice(choice)
	if selected ~= "red" and selected ~= "black" and selected ~= "green" then
		return nil, "Choose Red, Black, or Green for Roulette Lite."
	end

	local roll = rng:NextInteger(0, 36)
	local color
	if roll == 0 then
		color = "green"
	elseif roll % 2 == 0 then
		color = "black"
	else
		color = "red"
	end

	local multiplier = selected == "green" and 10 or 2
	local won = selected == color
	local displayChoice = string.upper(string.sub(selected, 1, 1)) .. string.sub(selected, 2)

	return {
		ReturnAmount = won and bet * multiplier or 0,
		DisplayName = displayChoice .. " Roulette",
		Details = "Roulette landed on " .. color .. " " .. roll .. ".",
	}
end

local function slots(bet)
	local weightedSymbols = {
		"Cherry", "Cherry", "Cherry",
		"Lemon", "Lemon", "Lemon",
		"Bell", "Bell",
		"Bar", "Bar",
		"Diamond",
		"Seven",
	}

	local rareSymbols = {
		Diamond = true,
		Seven = true,
	}

	local reels = {
		weightedSymbols[rng:NextInteger(1, #weightedSymbols)],
		weightedSymbols[rng:NextInteger(1, #weightedSymbols)],
		weightedSymbols[rng:NextInteger(1, #weightedSymbols)],
	}

	local payoutMultiplier = 0
	if reels[1] == reels[2] and reels[2] == reels[3] then
		payoutMultiplier = rareSymbols[reels[1]] and 15 or 5
	elseif reels[1] == reels[2] or reels[1] == reels[3] or reels[2] == reels[3] then
		payoutMultiplier = 2
	end

	return {
		ReturnAmount = bet * payoutMultiplier,
		DisplayName = "Slots",
		Details = "Reels: " .. reels[1] .. " | " .. reels[2] .. " | " .. reels[3] .. ".",
	}
end

local function blackjackLite(bet)
	local playerTotal = rng:NextInteger(12, 21)
	local dealerTotal = rng:NextInteger(12, 21)

	local returnAmount = 0
	local outcome = "Dealer wins."
	if playerTotal > dealerTotal then
		returnAmount = bet * 2
		outcome = "You beat the dealer."
	elseif playerTotal == dealerTotal then
		returnAmount = bet
		outcome = "Push. Your bet was refunded."
	end

	return {
		ReturnAmount = returnAmount,
		DisplayName = "Blackjack Lite",
		Details = "You drew " .. playerTotal .. ". Dealer drew " .. dealerTotal .. ". " .. outcome,
	}
end

local gameHandlers = {
	coinflip = coinFlip,
	diceroll = diceRoll,
	roulette = rouletteLite,
	slots = slots,
	blackjack = blackjackLite,
}

local function normalizeGameName(gameName)
	local compact = string.lower(tostring(gameName or "")):gsub("%s+", "")
	if compact == "coinflip" then
		return "coinflip"
	elseif compact == "diceroll" or compact == "dice" then
		return "diceroll"
	elseif compact == "roulettelite" or compact == "roulette" then
		return "roulette"
	elseif compact == "slots" or compact == "slot" then
		return "slots"
	elseif compact == "blackjacklite" or compact == "blackjack" then
		return "blackjack"
	end
	return nil
end

placeBet.OnServerEvent:Connect(function(player, gameName, betAmount, choice)
	if stateFolder:GetAttribute("RoundActive") ~= true or stateFolder:GetAttribute("Phase") ~= "Round" then
		rejectBet(player, "Bet rejected: the round is not active.")
		return
	end

	if player:GetAttribute("Escaped") == true then
		rejectBet(player, "Bet rejected: escaped players cannot gamble.")
		return
	end

	local money = getMoneyValue(player)
	if not money then
		rejectBet(player, "Bet rejected: money stat is not ready.")
		return
	end

	local bet = math.floor(tonumber(betAmount) or 0)
	if bet <= 0 then
		rejectBet(player, "Bet rejected: enter a positive bet.")
		return
	end

	if bet > money.Value then
		rejectBet(player, "Bet rejected: you cannot bet more than your current money.")
		return
	end

	local now = os.clock()
	if betCooldowns[player] and now - betCooldowns[player] < BET_COOLDOWN_SECONDS then
		rejectBet(player, "Bet rejected: slow down for a moment.")
		return
	end
	betCooldowns[player] = now

	local normalizedGameName = normalizeGameName(gameName)
	local handler = normalizedGameName and gameHandlers[normalizedGameName]
	if not handler then
		rejectBet(player, "Bet rejected: unknown gambling game.")
		return
	end

	local result, errorMessage = handler(bet, choice)
	if not result then
		rejectBet(player, errorMessage or "Bet rejected.")
		return
	end

	local balanceBefore = money.Value
	money.Value -= bet
	if result.ReturnAmount > 0 then
		money.Value += result.ReturnAmount
	end

	local delta = money.Value - balanceBefore
	local publicMessage
	local personalMessage

	if delta > 0 then
		publicMessage = player.Name .. " won $" .. delta .. " on " .. result.DisplayName .. "."
		personalMessage = "You won $" .. delta .. " on " .. result.DisplayName .. "!"
	elseif delta < 0 then
		publicMessage = player.Name .. " lost $" .. math.abs(delta) .. " on " .. result.DisplayName .. "."
		personalMessage = "You lost $" .. math.abs(delta) .. " on " .. result.DisplayName .. "."
	else
		publicMessage = player.Name .. " pushed on " .. result.DisplayName .. " and got their bet back."
		personalMessage = "Push on " .. result.DisplayName .. ". Your bet was refunded."
	end

	sendResult(player, {
		Game = result.DisplayName,
		Bet = bet,
		ReturnAmount = result.ReturnAmount,
		Delta = delta,
		Balance = money.Value,
		Won = delta > 0,
		Push = delta == 0,
		Message = personalMessage,
		Details = result.Details,
	})

	roundStatus:FireAllClients({
		Message = publicMessage,
		Phase = stateFolder:GetAttribute("Phase") or "Round",
		TimeLeft = stateFolder:GetAttribute("TimeLeft") or 0,
		RoundActive = true,
	})
end)

Players.PlayerRemoving:Connect(function(player)
	betCooldowns[player] = nil
end)
