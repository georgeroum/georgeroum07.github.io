#!/usr/bin/env lua

math.randomseed(os.time())

local Game = {}

Game.config = {
	startMoney = 500,
	baseCount = 8,
	pedestalCount = 6,
	stealDuration = 7,
	lockShieldBaseCooldown = 30,
	shopRefreshSeconds = 3600,
	conveyorRefreshSeconds = 25
}

Game.units = {
	-- 10 core conveyor units (Common -> Legendary)
	{ id = "griddy_grimaldo", name = "Griddy Grimaldo", rarity = "Common", price = 120, income = 1, buyHold = 5, buffs = {} },
	{ id = "antonini_spinadini", name = "Antonini Spinadini", rarity = "Common", price = 220, income = 2, buyHold = 5, buffs = { speed = 1 } },
	{ id = "harrini_airportini", name = "Harrini Airportini", rarity = "Uncommon", price = 500, income = 5, buyHold = 6, buffs = { lockCooldownMult = 0.96 } },
	{ id = "doner_kebab_nacho", name = "Donër Kebab Nacho", rarity = "Uncommon", price = 900, income = 10, buyHold = 6, buffs = { shieldCooldownMult = 0.96 } },
	{ id = "trippi_debruyni", name = "Trippi DeBruyni", rarity = "Rare", price = 1800, income = 20, buyHold = 6, buffs = { stealDefenseMult = 1.05 } },
	{ id = "frimping_ping_pong", name = "Frimping Ping Pong", rarity = "Rare", price = 3400, income = 40, buyHold = 7, buffs = { speed = 2 } },
	{ id = "courtoisini_giraffini", name = "Courtoisini Giraffini", rarity = "Epic", price = 7000, income = 80, buyHold = 7, buffs = { stealDefenseMult = 1.1 } },
	{ id = "bananini_chiellini", name = "Bananini Chiellini", rarity = "Epic", price = 14500, income = 200, buyHold = 8, buffs = { lockCooldownMult = 0.9 } },
	{ id = "laradona_lirili", name = "Laradona Lirili", rarity = "Mythic", price = 32000, income = 500, buyHold = 9, buffs = { incomeMult = 1.12, speed = 3 } },
	{ id = "el_referini_varini", name = "El Referini Varini", rarity = "Legendary", price = 78000, income = 1000, buyHold = 10, buffs = { incomeMult = 1.2, lockCooldownMult = 0.82, shieldCooldownMult = 0.82, stealDefenseMult = 1.2, speed = 4 } },

	-- Deal shop extras
	{ id = "tony_crocs", name = "Tony Crocs", rarity = "Rare", price = 4200, income = 55, buyHold = 7, buffs = { speed = 2 } },
	{ id = "mbappini_turtleini", name = "Mbappini Turtleini", rarity = "Epic", price = 9800, income = 120, buyHold = 7, buffs = { speed = 4 } },
	{ id = "robotino_haalanducci", name = "Robotino Haalanducci", rarity = "Mythic", price = 28000, income = 420, buyHold = 8, buffs = { incomeMult = 1.15 } },
	{ id = "neymarzini_guzzini", name = "Neymarzini Guzzini", rarity = "Epic", price = 16000, income = 220, buyHold = 8, buffs = { shieldCooldownMult = 0.88 } },
	{ id = "cristalalero_tralaldo", name = "Cristalalero Tralaldo", rarity = "Legendary", price = 64000, income = 900, buyHold = 10, buffs = { lockCooldownMult = 0.8, speed = 5 } },
	{ id = "messino_assassino", name = "Messino Assassino", rarity = "Legendary", price = 70000, income = 980, buyHold = 10, buffs = { incomeMult = 1.25, stealDefenseMult = 1.25 } },
	{ id = "skibidi_lewandowski", name = "Skibidi Lewandowski", rarity = "Mythic", price = 36000, income = 600, buyHold = 9, buffs = { stealDefenseMult = 1.18 } },
	{ id = "tung_tung_tung_suii", name = "Tung Tung Tung SUII", rarity = "Legendary", price = 88000, income = 1100, buyHold = 10, buffs = { incomeMult = 1.18, shieldCooldownMult = 0.78, speed = 5 } }
}

Game.coreUnitIds = {
	"griddy_grimaldo", "antonini_spinadini", "harrini_airportini", "doner_kebab_nacho",
	"trippi_debruyni", "frimping_ping_pong", "courtoisini_giraffini", "bananini_chiellini",
	"laradona_lirili", "el_referini_varini"
}

Game.shopUnitIds = {
	"tony_crocs", "mbappini_turtleini", "robotino_haalanducci", "neymarzini_guzzini",
	"cristalalero_tralaldo", "messino_assassino", "skibidi_lewandowski", "tung_tung_tung_suii"
}

Game.unitById = {}
for _, unit in ipairs(Game.units) do
	Game.unitById[unit.id] = unit
end

local function shallowCopy(list)
	local out = {}
	for i, v in ipairs(list) do
		out[i] = v
	end
	return out
end

local function randomChoice(list)
	return list[math.random(1, #list)]
end

local function randomUnique(list, count)
	local pool = shallowCopy(list)
	local out = {}
	for _ = 1, math.min(count, #pool) do
		local idx = math.random(1, #pool)
		table.insert(out, pool[idx])
		table.remove(pool, idx)
	end
	return out
end

local function formatMoney(n)
	n = math.floor(n or 0)
	if n >= 1000000000 then
		return string.format("%.1fb", n / 1000000000)
	elseif n >= 1000000 then
		return string.format("%.1fm", n / 1000000)
	elseif n >= 1000 then
		return string.format("%.1fk", n / 1000)
	end
	return tostring(n)
end

local function formatClock(seconds)
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = seconds % 60
	return string.format("%02d:%02d:%02d", h, m, s)
end

local function baseLocationLabel(baseId)
	if baseId == 1 then
		return "your stadium"
	end
	return "enemy stadium " .. tostring(baseId)
end

local function makeBase(id, isPlayer)
	local pedestals = {}
	for i = 1, Game.config.pedestalCount do
		pedestals[i] = false
	end
	return {
		id = id,
		owner = isPlayer and "You" or ("AI_" .. tostring(id)),
		isPlayer = isPlayer,
		money = isPlayer and Game.config.startMoney or math.random(300, 2000),
		rebirths = 0,
		pedestals = pedestals,
		locked = false,
		shielded = false,
		lockCooldown = 0,
		shieldCooldown = 0
	}
end

Game.state = {
	time = 0,
	bases = {},
	conveyorOffers = {},
	shopDeals = {},
	nextConveyorRefreshAt = Game.config.conveyorRefreshSeconds,
	nextShopRefreshAt = Game.config.shopRefreshSeconds,
	player = {
		baseId = 1,
		locationType = "base", -- base | conveyor | shop
		locationBaseId = 1,
		carriedUnit = nil,
		activeAction = nil
	}
}

for i = 1, Game.config.baseCount do
	Game.state.bases[i] = makeBase(i, i == 1)
end

local function countFilledPedestals(base)
	local count = 0
	for _, id in ipairs(base.pedestals) do
		if id then
			count = count + 1
		end
	end
	return count
end

local function findFreePedestal(base)
	for i = 1, #base.pedestals do
		if base.pedestals[i] == false then
			return i
		end
	end
	return nil
end

local function placeUnit(base, unitId, pedestalIndex)
	local idx = pedestalIndex or findFreePedestal(base)
	if not idx then
		return false
	end
	base.pedestals[idx] = unitId
	return true, idx
end

local function removeUnit(base, pedestalIndex)
	local id = base.pedestals[pedestalIndex]
	base.pedestals[pedestalIndex] = false
	return id
end

local function computeBuffs(base)
	local buffs = {
		lockCooldownMult = 1,
		shieldCooldownMult = 1,
		stealDefenseMult = 1,
		incomeMult = 1,
		speed = 0
	}

	for _, unitId in ipairs(base.pedestals) do
		if unitId then
			local unit = Game.unitById[unitId]
			if unit and unit.buffs then
				if unit.buffs.lockCooldownMult then
					buffs.lockCooldownMult = buffs.lockCooldownMult * unit.buffs.lockCooldownMult
				end
				if unit.buffs.shieldCooldownMult then
					buffs.shieldCooldownMult = buffs.shieldCooldownMult * unit.buffs.shieldCooldownMult
				end
				if unit.buffs.stealDefenseMult then
					buffs.stealDefenseMult = buffs.stealDefenseMult * unit.buffs.stealDefenseMult
				end
				if unit.buffs.incomeMult then
					buffs.incomeMult = buffs.incomeMult * unit.buffs.incomeMult
				end
				if unit.buffs.speed then
					buffs.speed = buffs.speed + unit.buffs.speed
				end
			end
		end
	end

	buffs.lockCooldownMult = math.max(0.5, math.min(1.5, buffs.lockCooldownMult))
	buffs.shieldCooldownMult = math.max(0.5, math.min(1.5, buffs.shieldCooldownMult))
	buffs.stealDefenseMult = math.max(0.7, math.min(1.8, buffs.stealDefenseMult))
	buffs.incomeMult = math.max(1, math.min(3, buffs.incomeMult))
	return buffs
end

local function computeIncome(base)
	local baseIncome = 0
	for _, unitId in ipairs(base.pedestals) do
		if unitId then
			baseIncome = baseIncome + Game.unitById[unitId].income
		end
	end
	local buffs = computeBuffs(base)
	local rebirthMult = 2 ^ (base.rebirths or 0)
	return math.floor(baseIncome * buffs.incomeMult * rebirthMult)
end

local function generateConveyorOffers()
	local offers = {}
	for i = 1, 10 do
		offers[i] = randomChoice(Game.coreUnitIds)
	end
	Game.state.conveyorOffers = offers
	Game.state.nextConveyorRefreshAt = Game.state.time + Game.config.conveyorRefreshSeconds
end

local function generateShopDeals()
	local allIds = {}
	for _, id in ipairs(Game.coreUnitIds) do
		table.insert(allIds, id)
	end
	for _, id in ipairs(Game.shopUnitIds) do
		table.insert(allIds, id)
	end

	local picks = randomUnique(allIds, 3)
	local deals = {}
	for i, id in ipairs(picks) do
		local unit = Game.unitById[id]
		local discount = math.random(58, 85) / 100
		deals[i] = {
			unitId = id,
			price = math.max(1, math.floor(unit.price * discount)),
			discountPct = math.floor((1 - discount) * 100)
		}
	end
	Game.state.shopDeals = deals
	Game.state.nextShopRefreshAt = Game.state.time + Game.config.shopRefreshSeconds
end

local function printLine(char, width)
	width = width or 64
	print(string.rep(char, width))
end

local function showHelp()
	printLine("=")
	print("BRAINROT WORLD CUP - TERMINAL EDITION")
	print("Goal: Buy meme footballers, defend your stadium, steal from enemies, rebirth.")
	printLine("-")
	print("Core commands:")
	print("  help                          - show commands")
	print("  status                        - show your match state")
	print("  units                         - list your pedestal units")
	print("  bases                         - overview of all 8 stadiums")
	print("  base <id>                     - inspect one stadium")
	print("  go home|conveyor|shop         - move to location")
	print("  go enemy <id>                 - move to enemy stadium (2..8)")
	print("  conveyor                      - show conveyor offers")
	print("  buy <slot>                    - hold-buy offer slot (5-10s)")
	print("  shop                          - show seller NPC deal inventory")
	print("  dealbuy <slot>                - hold-buy current deal")
	print("  lock                          - toggle lock (30s base cooldown)")
	print("  shield                        - toggle shield (30s base cooldown)")
	print("  steal <pedestal>              - steal from current enemy stadium")
	print("  drop                          - deliver carried unit at home")
	print("  rebirth                       - rebirth (fill all pedestals + cost)")
	print("  wait <seconds>                - advance simulation time")
	print("  cancel                        - cancel active buy/steal hold")
	print("  quit                          - exit")
	printLine("=")
end

local function currentLocationLabel()
	local p = Game.state.player
	if p.locationType == "base" then
		return baseLocationLabel(p.locationBaseId)
	end
	return p.locationType
end

local function actionIsValid(action)
	local p = Game.state.player
	if action.requiredLocationType ~= p.locationType then
		return false, "you moved away"
	end
	if action.requiredLocationBaseId and action.requiredLocationBaseId ~= p.locationBaseId then
		return false, "you moved away"
	end
	if action.type == "steal" then
		local target = Game.state.bases[action.targetBaseId]
		if not target then
			return false, "target vanished"
		end
		if target.locked then
			return false, "defender locked the stadium"
		end
		if target.shielded then
			return false, "defender activated shield"
		end
		local currentUnit = target.pedestals[action.pedestal]
		if currentUnit ~= action.unitId then
			return false, "unit was moved"
		end
	end
	return true
end

local function cancelAction(reason)
	local action = Game.state.player.activeAction
	if not action then
		print("No active action.")
		return
	end
	Game.state.player.activeAction = nil
	print(string.format("Action cancelled (%s).", reason or "cancelled"))
end

local function startAction(params)
	if Game.state.player.activeAction then
		print("Already busy: " .. Game.state.player.activeAction.label)
		return false
	end
	Game.state.player.activeAction = {
		type = params.type,
		label = params.label,
		total = params.seconds,
		remaining = params.seconds,
		requiredLocationType = params.requiredLocationType,
		requiredLocationBaseId = params.requiredLocationBaseId,
		targetBaseId = params.targetBaseId,
		pedestal = params.pedestal,
		unitId = params.unitId,
		price = params.price,
		slot = params.slot,
		onComplete = params.onComplete
	}
	print(string.format("%s started (%ds). Use 'wait %d' to progress.", params.label, params.seconds, params.seconds))
	return true
end

local function showStatus()
	local base = Game.state.bases[1]
	local income = computeIncome(base)
	local buffs = computeBuffs(base)
	local rebirthCost = 10000 * (base.rebirths + 1)

	printLine("-")
	print(string.format("Time: %s", formatClock(Game.state.time)))
	print(string.format("Location: %s", currentLocationLabel()))
	print(string.format("Money: $%s | Income: $%s/s | Rebirths: %d (x%d)", formatMoney(base.money), formatMoney(income), base.rebirths, 2 ^ base.rebirths))
	print(string.format("Lock: %s (cd:%ds) | Shield: %s (cd:%ds)", tostring(base.locked), base.lockCooldown, tostring(base.shielded), base.shieldCooldown))
	print(string.format("Pedestals filled: %d/%d | Next rebirth cost: $%s", countFilledPedestals(base), Game.config.pedestalCount, formatMoney(rebirthCost)))
	print(string.format("Buffs -> lockCD x%.2f, shieldCD x%.2f, stealDef x%.2f, income x%.2f, speed +%d", buffs.lockCooldownMult, buffs.shieldCooldownMult, buffs.stealDefenseMult, buffs.incomeMult, buffs.speed))
	if Game.state.player.carriedUnit then
		local u = Game.unitById[Game.state.player.carriedUnit]
		print("Carrying: " .. u.name)
	else
		print("Carrying: none")
	end

	local action = Game.state.player.activeAction
	if action then
		local done = action.total - action.remaining
		print(string.format("Active action: %s [%d/%d]", action.label, done, action.total))
	else
		print("Active action: none")
	end
	printLine("-")
end

local function showUnits(baseId)
	local base = Game.state.bases[baseId]
	print(string.format("Units in %s:", baseLocationLabel(baseId)))
	for i = 1, #base.pedestals do
		local id = base.pedestals[i]
		if id then
			local u = Game.unitById[id]
			print(string.format("  Pedestal %d: %s [%s] +$%d/s", i, u.name, u.rarity, u.income))
		else
			print(string.format("  Pedestal %d: (empty)", i))
		end
	end
end

local function showBases()
	printLine("-")
	for i = 1, #Game.state.bases do
		local b = Game.state.bases[i]
		local income = computeIncome(b)
		print(string.format(
			"Base %d | Owner:%-6s | Units:%d/6 | $%s | +$%s/s | Lock:%s Shield:%s",
			i, b.owner, countFilledPedestals(b), formatMoney(b.money), formatMoney(income), tostring(b.locked), tostring(b.shielded)
		))
	end
	printLine("-")
end

local function showConveyor()
	printLine("-")
	print("Central Conveyor Offers (hold-buy when at conveyor):")
	for i, unitId in ipairs(Game.state.conveyorOffers) do
		local u = Game.unitById[unitId]
		print(string.format("  [%d] %-24s %-10s  $%d  +$%d/s  hold:%ds", i, u.name, u.rarity, u.price, u.income, u.buyHold))
	end
	print(string.format("Auto refresh in %ds", math.max(0, Game.state.nextConveyorRefreshAt - Game.state.time)))
	printLine("-")
end

local function showShop()
	printLine("-")
	print("Referee Seller - Special Deals")
	for i, deal in ipairs(Game.state.shopDeals) do
		local u = Game.unitById[deal.unitId]
		print(string.format("  [%d] %-24s %-10s  DEAL $%d (%d%% off, base $%d)", i, u.name, u.rarity, deal.price, deal.discountPct, u.price))
	end
	print(string.format("New inventory in %ds", math.max(0, Game.state.nextShopRefreshAt - Game.state.time)))
	printLine("-")
end

local function buyFromConveyor(slot)
	if Game.state.player.locationType ~= "conveyor" then
		print("You must be at the central conveyor. Use: go conveyor")
		return
	end
	if slot < 1 or slot > #Game.state.conveyorOffers then
		print("Invalid slot.")
		return
	end

	local base = Game.state.bases[1]
	if not findFreePedestal(base) then
		print("Your pedestals are full.")
		return
	end

	local unitId = Game.state.conveyorOffers[slot]
	local unit = Game.unitById[unitId]
	if base.money < unit.price then
		print(string.format("Not enough money. Need $%d.", unit.price))
		return
	end

	startAction({
		type = "buy",
		label = "Buying " .. unit.name,
		seconds = math.ceil(unit.buyHold),
		requiredLocationType = "conveyor",
		price = unit.price,
		unitId = unitId,
		slot = slot,
		onComplete = function(action)
			if base.money < action.price then
				print("Buy failed at completion: money spent meanwhile.")
				return
			end
			local free = findFreePedestal(base)
			if not free then
				print("Buy failed: pedestal became full.")
				return
			end
			base.money = base.money - action.price
			placeUnit(base, action.unitId, free)
			Game.state.conveyorOffers[action.slot] = randomChoice(Game.coreUnitIds)
			local signed = Game.unitById[action.unitId]
			print(string.format("Signed %s for $%d -> placed on pedestal %d.", signed.name, action.price, free))
		end
	})
end

local function buyDeal(slot)
	if Game.state.player.locationType ~= "shop" then
		print("You must be at the shop stand. Use: go shop")
		return
	end
	if slot < 1 or slot > #Game.state.shopDeals then
		print("Invalid deal slot.")
		return
	end

	local base = Game.state.bases[1]
	if not findFreePedestal(base) then
		print("Your pedestals are full.")
		return
	end

	local deal = Game.state.shopDeals[slot]
	local unit = Game.unitById[deal.unitId]
	if base.money < deal.price then
		print(string.format("Not enough money for deal. Need $%d.", deal.price))
		return
	end

	startAction({
		type = "buy",
		label = "Buying DEAL " .. unit.name,
		seconds = math.ceil(unit.buyHold),
		requiredLocationType = "shop",
		price = deal.price,
		unitId = deal.unitId,
		slot = slot,
		onComplete = function(action)
			if base.money < action.price then
				print("Deal purchase failed at completion: money spent meanwhile.")
				return
			end
			local free = findFreePedestal(base)
			if not free then
				print("Deal purchase failed: pedestal became full.")
				return
			end
			base.money = base.money - action.price
			placeUnit(base, action.unitId, free)
			local signed = Game.unitById[action.unitId]
			print(string.format("Deal signed: %s for $%d -> pedestal %d.", signed.name, action.price, free))

			-- Replace bought deal with a fresh one.
			local pools = {}
			for _, id in ipairs(Game.coreUnitIds) do table.insert(pools, id) end
			for _, id in ipairs(Game.shopUnitIds) do table.insert(pools, id) end
			local newId = randomChoice(pools)
			local newUnit = Game.unitById[newId]
			local discount = math.random(58, 85) / 100
			Game.state.shopDeals[action.slot] = {
				unitId = newId,
				price = math.max(1, math.floor(newUnit.price * discount)),
				discountPct = math.floor((1 - discount) * 100)
			}
		end
	})
end

local function tryToggleLock()
	local base = Game.state.bases[1]
	if base.lockCooldown > 0 then
		print(string.format("Lock cooldown: %ds", base.lockCooldown))
		return
	end
	base.locked = not base.locked
	local buffs = computeBuffs(base)
	local cd = math.max(5, math.floor(Game.config.lockShieldBaseCooldown * buffs.lockCooldownMult))
	base.lockCooldown = cd
	print("Stadium lock is now: " .. tostring(base.locked) .. string.format(" (cooldown %ds)", cd))
end

local function tryToggleShield()
	local base = Game.state.bases[1]
	if base.shieldCooldown > 0 then
		print(string.format("Shield cooldown: %ds", base.shieldCooldown))
		return
	end
	base.shielded = not base.shielded
	local buffs = computeBuffs(base)
	local cd = math.max(5, math.floor(Game.config.lockShieldBaseCooldown * buffs.shieldCooldownMult))
	base.shieldCooldown = cd
	print("Stadium shield is now: " .. tostring(base.shielded) .. string.format(" (cooldown %ds)", cd))
end

local function trySteal(pedestal)
	local p = Game.state.player
	if p.carriedUnit then
		print("You are already carrying a unit.")
		return
	end
	if p.locationType ~= "base" or p.locationBaseId == 1 then
		print("You must stand in an enemy stadium. Use: go enemy <id>")
		return
	end

	local target = Game.state.bases[p.locationBaseId]
	if target.locked then
		print("Cannot steal: enemy base is locked.")
		return
	end
	if target.shielded then
		print("Cannot steal: enemy shield is active.")
		return
	end
	if pedestal < 1 or pedestal > Game.config.pedestalCount then
		print("Invalid pedestal index (1-6).")
		return
	end

	local unitId = target.pedestals[pedestal]
	if not unitId then
		print("That pedestal is empty.")
		return
	end

	local buffs = computeBuffs(target)
	local duration = math.max(5, math.min(12, math.ceil(Game.config.stealDuration * buffs.stealDefenseMult)))
	local unit = Game.unitById[unitId]

	startAction({
		type = "steal",
		label = "Stealing " .. unit.name,
		seconds = duration,
		requiredLocationType = "base",
		requiredLocationBaseId = p.locationBaseId,
		targetBaseId = p.locationBaseId,
		pedestal = pedestal,
		unitId = unitId,
		onComplete = function(action)
			local t = Game.state.bases[action.targetBaseId]
			local stillThere = t.pedestals[action.pedestal]
			if stillThere ~= action.unitId then
				print("Steal failed at completion: target no longer available.")
				return
			end
			removeUnit(t, action.pedestal)
			Game.state.player.carriedUnit = action.unitId
			local stolen = Game.unitById[action.unitId]
			print("STEAL SUCCESS: carrying " .. stolen.name .. ". Go home and use 'drop'.")
		end
	})
end

local function tryDrop()
	local p = Game.state.player
	if not p.carriedUnit then
		print("You are not carrying anything.")
		return
	end
	if p.locationType ~= "base" or p.locationBaseId ~= 1 then
		print("Return to your own stadium first: go home")
		return
	end

	local base = Game.state.bases[1]
	local free = findFreePedestal(base)
	if not free then
		print("All your pedestals are full. Cannot drop carried unit.")
		return
	end

	placeUnit(base, p.carriedUnit, free)
	local unit = Game.unitById[p.carriedUnit]
	p.carriedUnit = nil
	print(string.format("GOAL! %s placed on your pedestal %d.", unit.name, free))
end

local function tryRebirth()
	local base = Game.state.bases[1]
	if countFilledPedestals(base) < Game.config.pedestalCount then
		print("Rebirth blocked: fill all 6 pedestals first.")
		return
	end
	local cost = 10000 * (base.rebirths + 1)
	if base.money < cost then
		print(string.format("Rebirth blocked: need $%d.", cost))
		return
	end

	base.rebirths = base.rebirths + 1
	base.money = Game.config.startMoney
	for i = 1, #base.pedestals do
		base.pedestals[i] = false
	end
	Game.state.player.carriedUnit = nil
	print(string.format("REBIRTH COMPLETE! Total rebirths: %d | Income multiplier now x%d", base.rebirths, 2 ^ base.rebirths))
end

local function aiTick(base)
	local income = computeIncome(base)
	base.money = base.money + income

	-- AI lock/shield behavior.
	if math.random() < 0.12 then
		if base.lockCooldown <= 0 then
			base.locked = not base.locked
			local buffs = computeBuffs(base)
			base.lockCooldown = math.max(5, math.floor(Game.config.lockShieldBaseCooldown * buffs.lockCooldownMult))
		end
	end
	if math.random() < 0.1 then
		if base.shieldCooldown <= 0 then
			base.shielded = not base.shielded
			local buffs = computeBuffs(base)
			base.shieldCooldown = math.max(5, math.floor(Game.config.lockShieldBaseCooldown * buffs.shieldCooldownMult))
		end
	end

	-- AI buying behavior.
	if math.random() < 0.2 and findFreePedestal(base) then
		local offerId = randomChoice(Game.state.conveyorOffers)
		local offer = Game.unitById[offerId]
		if base.money >= offer.price then
			base.money = base.money - offer.price
			placeUnit(base, offerId)
		end
	end
end

local function tickOneSecond()
	local state = Game.state
	state.time = state.time + 1

	-- refresh systems
	if state.time >= state.nextConveyorRefreshAt then
		generateConveyorOffers()
		print("[Conveyor] New offer wave spawned.")
	end
	if state.time >= state.nextShopRefreshAt then
		generateShopDeals()
		print("[Shop] Seller NPC refreshed full deal inventory.")
	end

	for i, base in ipairs(state.bases) do
		if base.lockCooldown > 0 then base.lockCooldown = base.lockCooldown - 1 end
		if base.shieldCooldown > 0 then base.shieldCooldown = base.shieldCooldown - 1 end
		if base.lockCooldown < 0 then base.lockCooldown = 0 end
		if base.shieldCooldown < 0 then base.shieldCooldown = 0 end

		if i == 1 then
			base.money = base.money + computeIncome(base)
		else
			aiTick(base)
		end
	end

	local action = state.player.activeAction
	if action then
		local ok, reason = actionIsValid(action)
		if not ok then
			cancelAction(reason)
		else
			action.remaining = action.remaining - 1
			local done = action.total - action.remaining
			local pct = math.floor((done / action.total) * 100)
			print(string.format("  [%s] %d%% (%ds left)", action.label, pct, math.max(0, action.remaining)))

			if action.remaining <= 0 then
				state.player.activeAction = nil
				action.onComplete(action)
			end
		end
	end
end

local function waitSeconds(sec)
	sec = math.max(1, math.min(sec, 7200))
	for _ = 1, sec do
		tickOneSecond()
	end
	print(string.format("Advanced %ds. Current time: %s", sec, formatClock(Game.state.time)))
end

local function moveTo(args)
	local target = args[2]
	if not target then
		print("Usage: go home|conveyor|shop|enemy <id>")
		return
	end

	local p = Game.state.player
	local oldType = p.locationType
	local oldBaseId = p.locationBaseId

	if target == "home" then
		p.locationType = "base"
		p.locationBaseId = 1
	elseif target == "conveyor" then
		p.locationType = "conveyor"
		p.locationBaseId = nil
	elseif target == "shop" then
		p.locationType = "shop"
		p.locationBaseId = nil
	elseif target == "enemy" then
		local id = tonumber(args[3] or "")
		if not id or id < 2 or id > Game.config.baseCount then
			print("Enemy id must be 2..8.")
			return
		end
		p.locationType = "base"
		p.locationBaseId = id
	else
		print("Unknown move target.")
		return
	end

	local action = p.activeAction
	if action then
		local movedAway = action.requiredLocationType ~= p.locationType
		if not movedAway and action.requiredLocationBaseId then
			movedAway = action.requiredLocationBaseId ~= p.locationBaseId
		end
		if movedAway then
			cancelAction("left interaction range")
		end
	end

	if oldType ~= p.locationType or oldBaseId ~= p.locationBaseId then
		print("Moved to " .. currentLocationLabel() .. ".")
	end
end

local function inspectBase(id)
	local base = Game.state.bases[id]
	if not base then
		print("Base not found.")
		return
	end
	local income = computeIncome(base)
	printLine("-")
	print(string.format("Base %d (%s) | Money:$%s | Income:$%s/s", id, base.owner, formatMoney(base.money), formatMoney(income)))
	print(string.format("Lock:%s (cd %d) | Shield:%s (cd %d)", tostring(base.locked), base.lockCooldown, tostring(base.shielded), base.shieldCooldown))
	for i = 1, #base.pedestals do
		local unitId = base.pedestals[i]
		if unitId then
			local u = Game.unitById[unitId]
			print(string.format("  Pedestal %d -> %s [%s] +$%d/s", i, u.name, u.rarity, u.income))
		else
			print(string.format("  Pedestal %d -> (empty)", i))
		end
	end
	printLine("-")
end

local function populateInitialAIUnits()
	for i = 2, Game.config.baseCount do
		local base = Game.state.bases[i]
		local count = math.random(1, 3)
		for _ = 1, count do
			local id = randomChoice(Game.coreUnitIds)
			if findFreePedestal(base) then
				placeUnit(base, id)
			end
		end
	end
end

local function tokenize(line)
	local out = {}
	for word in string.gmatch(line, "%S+") do
		table.insert(out, word)
	end
	return out
end

local function runCommand(input)
	local args = tokenize(string.lower(input))
	local cmd = args[1]
	if not cmd then
		return true
	end

	if cmd == "help" then
		showHelp()
	elseif cmd == "status" then
		showStatus()
	elseif cmd == "units" then
		showUnits(1)
	elseif cmd == "bases" then
		showBases()
	elseif cmd == "base" then
		local id = tonumber(args[2] or "")
		if not id then
			print("Usage: base <id>")
		else
			inspectBase(id)
		end
	elseif cmd == "go" then
		moveTo(args)
	elseif cmd == "conveyor" then
		showConveyor()
	elseif cmd == "buy" then
		local slot = tonumber(args[2] or "")
		if not slot then
			print("Usage: buy <slot>")
		else
			buyFromConveyor(slot)
		end
	elseif cmd == "shop" then
		showShop()
	elseif cmd == "dealbuy" then
		local slot = tonumber(args[2] or "")
		if not slot then
			print("Usage: dealbuy <slot>")
		else
			buyDeal(slot)
		end
	elseif cmd == "lock" then
		tryToggleLock()
	elseif cmd == "shield" then
		tryToggleShield()
	elseif cmd == "steal" then
		local ped = tonumber(args[2] or "")
		if not ped then
			print("Usage: steal <pedestal 1..6>")
		else
			trySteal(ped)
		end
	elseif cmd == "drop" then
		tryDrop()
	elseif cmd == "rebirth" then
		tryRebirth()
	elseif cmd == "wait" or cmd == "tick" then
		local sec = tonumber(args[2] or "") or 1
		waitSeconds(sec)
	elseif cmd == "cancel" then
		cancelAction("manual cancel")
	elseif cmd == "quit" or cmd == "exit" then
		print("GG! Thanks for playing Brainrot World Cup terminal mode.")
		return false
	else
		print("Unknown command. Type 'help'.")
	end

	return true
end

generateConveyorOffers()
generateShopDeals()
populateInitialAIUnits()

showHelp()
print("You spawn with $500 and your own stadium (Base 1).")
print("Tip: go conveyor -> conveyor -> buy 1 -> wait 5 -> status")

while true do
	io.write("\n[", formatClock(Game.state.time), " @ ", currentLocationLabel(), "] > ")
	local line = io.read()
	if not line then
		break
	end
	local ok = runCommand(line)
	if not ok then
		break
	end
end
