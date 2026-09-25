local addonName, ns = ...
local API = ns.API

ns.Physics = ns.Physics or {}

local SWING_WINDOW = 0.4
local CLIP_WINDOW = 0.4
local ENERGY_TICK = 2
local ENERGY_WAIT = 0.45
local AUTO_SHOT = 75
local ENERGY = 3

local mhAt, mhSpeed = 0, 0
local ohAt, ohSpeed = 0, 0
local shotAt, shotSpeed = 0, 0
local cachedMain, cachedOff, cachedShot = 0, 0, 0
local energyAt, lastEnergy = 0, -1
local swingIDs, clipIDs

local function buildSets()
	if swingIDs then
		return
	end
	swingIDs, clipIDs = {}, {}
	local W, H, D = ns.Spell.Warrior, ns.Spell.Hunter, ns.Spell.Druid
	for _, id in ipairs({ W.HeroicStrike, W.Cleave, H.RaptorStrike, D.Maul }) do
		if id then
			swingIDs[id] = true
		end
	end
	for _, id in ipairs({ H.AimedShot, H.MultiShot, H.Volley }) do
		if id then
			clipIDs[id] = true
		end
	end
end

local function markId(set, spellID)
	if not spellID or not set then
		return false
	end
	if set[spellID] then
		return true
	end
	local resolved = API.Resolve and API.Resolve(spellID)
	return resolved and set[resolved] or false
end

function ns.Physics.Enabled()
	return ns.db and ns.db.showPhysics ~= false
end

function ns.Physics.IsSwing(spellID)
	buildSets()
	return markId(swingIDs, spellID)
end

function ns.Physics.IsClip(spellID)
	buildSets()
	return markId(clipIDs, spellID)
end

local function plainNumber(value)
	local ok, n = pcall(function()
		local v = tonumber(value)
		if type(v) ~= "number" then
			return nil
		end
		return v + 0
	end)
	if not ok or type(n) ~= "number" then
		return nil
	end
	return n
end

local function parseSpeedText(text)
	if type(text) ~= "string" then
		return nil
	end
	local low = text:lower()
	if not (low:find("speed", 1, true) or low:find("vitesse", 1, true) or low:find("tempo", 1, true) or low:find("veloc", 1, true) or low:find("скорость", 1, true) or low:find("속도", 1, true) or low:find("速度", 1, true)) then
		return nil
	end
	local num = low:match("([%d]+[%.%,][%d]+)") or low:match("([%d]+)")
	if not num then
		return nil
	end
	local speed = plainNumber((num:gsub(",", ".")))
	if speed and speed > 0.4 and speed < 6 then
		return speed
	end
	return nil
end

local function lineSpeed(line)
	if type(line) ~= "table" then
		return nil
	end
	local left, right = line.leftText, line.rightText
	if type(left) == "string" and type(right) == "string" then
		return parseSpeedText(left .. " " .. right)
	end
	if type(left) == "string" then
		return parseSpeedText(left)
	end
	return nil
end

local function slotWeaponSpeed(slot)
	if not C_TooltipInfo or not C_TooltipInfo.GetInventoryItem then
		return nil
	end
	local ok, data = pcall(C_TooltipInfo.GetInventoryItem, "player", slot)
	if not ok or type(data) ~= "table" or type(data.lines) ~= "table" then
		return nil
	end
	for _, line in ipairs(data.lines) do
		local okLine, speed = pcall(lineSpeed, line)
		if okLine and speed then
			return speed
		end
	end
	return 0
end

local function readWeaponSpeeds()
	local main = slotWeaponSpeed(16)
	local off = slotWeaponSpeed(17)
	local shot = slotWeaponSpeed(18)
	if main and main > 0 then
		cachedMain = main
	end
	if off then
		cachedOff = off
	end
	if shot and shot > 0 then
		cachedShot = shot
	end
end

local function attackSpeeds()
	local main, off = cachedMain, cachedOff
	local offKnown = false
	if UnitAttackSpeed then
		local pack = { pcall(UnitAttackSpeed, "player") }
		if pack[1] then
			local liveMain = plainNumber(pack[2])
			local liveOff = plainNumber(pack[3])
			if liveMain and liveMain > 0.4 then
				main = liveMain
				cachedMain = liveMain
			end
			if liveOff and liveOff > 0.4 then
				off = liveOff
				cachedOff = liveOff
				offKnown = true
			elseif liveOff and pack[2] ~= nil then
				off = 0
				cachedOff = 0
				offKnown = true
			end
		end
	end
	if main <= 0.4 then
		readWeaponSpeeds()
		main, off = cachedMain, cachedOff
	elseif not offKnown and off <= 0 then
		local tipOff = slotWeaponSpeed(17)
		if tipOff and tipOff > 0 then
			off = tipOff
			cachedOff = tipOff
		end
	end
	if main <= 0.4 then
		main = 0
	end
	if off <= 0.4 then
		off = 0
	end
	return main, off
end

local function rangedSpeed()
	if UnitRangedDamage then
		local ok, speed = pcall(UnitRangedDamage, "player")
		speed = ok and plainNumber(speed)
		if speed and speed > 0.4 then
			cachedShot = speed
			return speed
		end
	end
	if cachedShot <= 0.4 then
		local tip = slotWeaponSpeed(18)
		if tip and tip > 0 then
			cachedShot = tip
		end
	end
	if cachedShot > 0.4 then
		return cachedShot
	end
	return 0
end

local function spellIsOn(spellID)
	if IsCurrentSpell then
		local ok, on = pcall(IsCurrentSpell, spellID)
		if ok and on == true then
			return true
		end
	end
	if IsAutoRepeatSpell then
		local ok, on = pcall(IsAutoRepeatSpell, spellID)
		if ok and on == true then
			return true
		end
	end
	return false
end

local function restartIfDue(at, speed, live)
	if live <= 0 then
		return 0, 0
	end
	local now = GetTime()
	if at <= 0 or speed <= 0 or now >= at + speed then
		return now, live
	end
	if math.abs(speed - live) > 0.05 then
		local elapsed = now - at
		local progress = elapsed / speed
		if progress < 0 then
			progress = 0
		end
		if progress > 1 then
			progress = 1
		end
		return now - progress * live, live
	end
	return at, speed
end

local function ensureLive()
	if spellIsOn(6603) then
		local main, off = attackSpeeds()
		mhAt, mhSpeed = restartIfDue(mhAt, mhSpeed, main)
		ohAt, ohSpeed = restartIfDue(ohAt, ohSpeed, off)
	end
	if spellIsOn(AUTO_SHOT) then
		local speed = rangedSpeed()
		if speed <= 0 then
			speed = 2.8
		end
		shotAt, shotSpeed = restartIfDue(shotAt, shotSpeed, speed)
	end
end

local function rescale(at, oldSpeed, newSpeed)
	if at <= 0 or oldSpeed <= 0 or newSpeed <= 0 then
		return at, newSpeed
	end
	local elapsed = GetTime() - at
	local progress = elapsed / oldSpeed
	if progress < 0 then
		progress = 0
	end
	if progress > 1 then
		progress = 1
	end
	return GetTime() - progress * newSpeed, newSpeed
end

local function refreshSpeeds()
	local main, off = attackSpeeds()
	if main > 0 then
		mhAt, mhSpeed = rescale(mhAt, mhSpeed, main)
	end
	if off > 0 then
		ohAt, ohSpeed = rescale(ohAt, ohSpeed, off)
	else
		ohAt, ohSpeed = 0, 0
	end
end

local function noteHand(hand)
	local main, off = attackSpeeds()
	if hand ~= "off" and main > 0 then
		mhSpeed = main
		mhAt = GetTime()
	end
	if hand ~= "main" and off > 0 then
		ohSpeed = off
		ohAt = GetTime()
	end
	if hand ~= "main" and off <= 0 then
		ohAt, ohSpeed = 0, 0
	end
end

function ns.Physics.NoteSwing(hand)
	noteHand(hand)
end

function ns.Physics.NoteShot()
	local speed = rangedSpeed()
	if speed <= 0 then
		speed = 3
	end
	shotSpeed = speed
	shotAt = GetTime()
end

function ns.Physics.NoteEnergy(current)
	current = plainNumber(current)
	if not current then
		return
	end
	if lastEnergy >= 0 and current > lastEnergy then
		energyAt = GetTime()
	end
	lastEnergy = current
end

local function handRemain(at, speed)
	if at <= 0 or speed <= 0 then
		return nil, 0
	end
	local elapsed = GetTime() - at
	if elapsed > speed + 0.5 then
		return nil, 0
	end
	return math.max(0, speed - elapsed), speed
end

local function shotRemain()
	return handRemain(shotAt, shotSpeed)
end

local function energyTickRemain()
	if energyAt <= 0 then
		return nil
	end
	local elapsed = GetTime() - energyAt
	if elapsed < 0 then
		return ENERGY_TICK
	end
	return ENERGY_TICK - (elapsed % ENERGY_TICK)
end

function ns.Physics.SwingWindow()
	local left = handRemain(mhAt, mhSpeed)
	if left == nil then
		return true
	end
	return left <= SWING_WINDOW
end

function ns.Physics.WouldClip()
	local left = shotRemain()
	if left == nil then
		return false
	end
	return left > 0.08 and left <= CLIP_WINDOW
end

local function spellEnergyCost(spellID)
	local id = (API.Resolve and API.Resolve(spellID)) or spellID
	if not id or not C_Spell or not C_Spell.GetSpellPowerCost then
		return 0
	end
	local ok, costs = pcall(C_Spell.GetSpellPowerCost, id)
	if not ok or type(costs) ~= "table" then
		return 0
	end
	for _, cost in ipairs(costs) do
		if type(cost) == "table" then
			local needed = plainNumber(cost.cost)
			local ptype = plainNumber(cost.type)
			if needed and needed > 0 and ptype == ENERGY then
				return needed
			end
		end
	end
	return 0
end

function ns.Physics.EnergySoon(spellID)
	local cost = spellEnergyCost(spellID)
	if cost <= 0 then
		return false
	end
	local ok, cur = pcall(UnitPower, "player", ENERGY)
	cur = ok and plainNumber(cur)
	if not cur then
		return false
	end
	if cur >= cost then
		return false
	end
	if cur + 20 < cost then
		return false
	end
	local tick = energyTickRemain()
	return tick ~= nil and tick <= ENERGY_WAIT
end

function ns.Physics.Blocks(spellID)
	if not ns.Physics.Enabled() or not spellID then
		return false
	end
	if ns.Physics.IsClip(spellID) and ns.Physics.WouldClip() then
		return true
	end
	if ns.Physics.IsSwing(spellID) and not ns.Physics.SwingWindow() then
		return true
	end
	return false
end

local function addBar(bars, kind, left, speed, window, label)
	if not left or speed <= 0 then
		return
	end
	bars[#bars + 1] = {
		kind = kind,
		progress = 1 - (left / speed),
		hot = left <= window,
		label = label,
	}
end

function ns.Physics.Status()
	if not ns.Physics.Enabled() then
		return
	end
	ensureLive()
	local bars = {}
	local token = ns.ClassToken and ns.ClassToken()
	local role = ns.db and ns.db.role
	if token == "HUNTER" and role ~= "melee" then
		local left, speed = shotRemain()
		addBar(bars, "shot", left, speed, CLIP_WINDOW, ns.T("PHYS_SHOT"))
	end
	local mhLeft, mhSp = handRemain(mhAt, mhSpeed)
	addBar(bars, "swing", mhLeft, mhSp, SWING_WINDOW, ns.T("PHYS_SWING"))
	local ohLeft, ohSp = handRemain(ohAt, ohSpeed)
	addBar(bars, "offhand", ohLeft, ohSp, SWING_WINDOW, ns.T("PHYS_OFFHAND"))
	if token == "ROGUE" or (token == "DRUID" and role ~= "tank" and role ~= "heal") then
		local ok, cur = pcall(UnitPower, "player", ENERGY)
		if ok and type(cur) == "number" then
			local tick = energyTickRemain() or ENERGY_TICK
			bars[#bars + 1] = {
				kind = "energy",
				progress = 1 - (tick / ENERGY_TICK),
				hot = tick <= ENERGY_WAIT,
				label = ns.T("PHYS_ENERGY"),
			}
		end
	end
	if #bars == 0 then
		return
	end
	return {
		bars = bars,
		progress = bars[1].progress,
		hot = bars[1].hot,
		kind = bars[1].kind,
		label = bars[1].label,
	}
end

local function clearSwings()
	mhAt, mhSpeed, ohAt, ohSpeed = 0, 0, 0, 0
end

local frame = CreateFrame("Frame")
pcall(frame.RegisterEvent, frame, "PLAYER_REGEN_ENABLED")
pcall(frame.RegisterEvent, frame, "PLAYER_ENTER_COMBAT")
pcall(frame.RegisterEvent, frame, "PLAYER_LEAVE_COMBAT")
pcall(frame.RegisterEvent, frame, "UNIT_ATTACK")
pcall(frame.RegisterEvent, frame, "UNIT_ATTACK_SPEED")
pcall(frame.RegisterEvent, frame, "UNIT_POWER_UPDATE")
pcall(frame.RegisterEvent, frame, "UNIT_SPELLCAST_SUCCEEDED")
pcall(frame.RegisterEvent, frame, "PLAYER_EQUIPMENT_CHANGED")

frame:SetScript("OnEvent", function(_, event, unit, _, spellID)
	if event == "PLAYER_REGEN_ENABLED" then
		clearSwings()
		shotAt = 0
		return
	end
	if event == "PLAYER_LEAVE_COMBAT" then
		clearSwings()
		return
	end
	if event == "PLAYER_ENTER_COMBAT" then
		noteHand()
		if ns.ClassToken and ns.ClassToken() == "HUNTER" then
			ns.Physics.NoteShot()
		end
		return
	end
	if event == "UNIT_ATTACK" and unit == "player" then
		noteHand()
		return
	end
	if event == "UNIT_ATTACK_SPEED" and (not unit or unit == "player") then
		refreshSpeeds()
		return
	end
	if event == "PLAYER_EQUIPMENT_CHANGED" then
		readWeaponSpeeds()
		refreshSpeeds()
		return
	end
	if event == "UNIT_POWER_UPDATE" and unit == "player" then
		local ok, cur = pcall(UnitPower, "player", ENERGY)
		if ok then
			ns.Physics.NoteEnergy(cur)
		end
		return
	end
	if event == "UNIT_SPELLCAST_SUCCEEDED" and unit == "player" then
		local id = tonumber(spellID)
		if id == AUTO_SHOT then
			ns.Physics.NoteShot()
		elseif ns.Physics.IsSwing(id) then
			noteHand("main")
		end
	end
end)
