local addonName, ns = ...
local API = ns.API

local maintNames
local weaponNames
local tokenCache = {}

function ns.InvalidateBuffCaches()
	maintNames = nil
	weaponNames = nil
	tokenCache = {}
	if ns.API and ns.API.WipeAuraScans then
		ns.API.WipeAuraScans()
	end
end

local function maintNameSet()
	if maintNames and next(maintNames) then
		return maintNames
	end
	maintNames = {}
	for id in pairs(ns.MAINTENANCE_BUFF_IDS or {}) do
		local name = API.SpellName(id)
		if name then
			maintNames[name] = true
		end
	end
	return maintNames
end

local function weaponNameSet()
	if weaponNames and next(weaponNames) then
		return weaponNames
	end
	weaponNames = {}
	for _, list in pairs(ns.WEAPON_BUFFS or {}) do
		for _, entry in ipairs(list) do
			local name = API.SpellName(entry.id)
			if name then
				weaponNames[name] = true
			end
		end
	end
	return weaponNames
end

local function stepReady(id, opt)
	if opt and opt.role and (ns.db.role or "damage") ~= opt.role then
		return false
	end
	return API.StepOk(id, opt)
end

function ns.IsMaintenanceBuff(spellID)
	if not spellID then
		return false
	end
	if ns.MAINTENANCE_BUFF_IDS and ns.MAINTENANCE_BUFF_IDS[spellID] then
		return true
	end
	local name = API.SpellName(spellID)
	return name and maintNameSet()[name] or false
end

function ns.IsWeaponBuff(spellID)
	if not spellID or (issecretvalue and issecretvalue(spellID)) then
		return false
	end
	if ns.WEAPON_BUFF_IDS and ns.WEAPON_BUFF_IDS[spellID] then
		return true
	end
	local name = API.SpellName(spellID)
	return name and weaponNameSet()[name] or false
end

function ns.BuildQueue()
	local q = {}
	ns.queueHeal = {}
	if not ns.GetAPL then
		return q
	end
	local apl = ns.GetAPL()
	local used = {}
	local blocked = {}
	local function markHeal(id, opt)
		if not id or not (API.IsHealSpell and API.IsHealSpell(id, opt)) then
			return
		end
		ns.queueHeal[id] = true
		local resolved = API.Resolve and API.Resolve(id)
		if resolved then
			ns.queueHeal[resolved] = true
		end
	end
	local function take(step)
		local id = (API.Resolve and API.Resolve(step.id)) or step.id
		if not id then
			return false
		end
		local opt = step.opt or {}
		local canRepeat = opt.filler == true or opt.swing == true
		if not canRepeat and (used[id] or used[step.key]) then
			return false
		end
		local group = opt.anybuff or opt.anydebuff
		if group and blocked[group] then
			return false
		end
		q[#q + 1] = id
		if not canRepeat then
			used[id] = true
			used[step.key] = true
		end
		if group then
			blocked[group] = true
		end
		markHeal(id, opt)
		return true
	end
	local function onBar(id)
		if ns.db.barOnly == false then
			return true
		end
		if ns.SpellOnBar then
			return ns.SpellOnBar(id)
		end
		return true
	end
	local function consider(step)
		return ns.IsStepEnabled(step) and step.id and not ns.IsWeaponBuff(step.id) and not ns.IsMaintenanceBuff(step.id) and onBar(step.id)
	end
	-- ConROC: pick the first valid step, assume it was pressed, restart from the top.
	if API.PredictBegin then
		API.PredictBegin()
	end
	local shift = 0.2
	if API.CastRemain then
		local left = API.CastRemain()
		if left > shift then
			shift = left
		end
	end
	for _ = 1, 3 do
		local taken = false
		for _, step in ipairs(apl) do
			if consider(step) and API.StepOk(step.id, step.opt, shift) then
				if take(step) then
					if API.PredictConsume then
						API.PredictConsume(step.id, step.opt)
					end
					taken = true
					break
				end
			end
		end
		if not taken then
			break
		end
	end
	if API.PredictEnd then
		API.PredictEnd()
	end
	local healFirst = false
	for _, id in ipairs(q) do
		if ns.queueHeal[id] then
			healFirst = true
			break
		end
	end
	if not healFirst then
		for _, step in ipairs(apl) do
			if consider(step) and API.IsHealSpell and API.IsHealSpell(step.id, step.opt) and API.StepOk(step.id, step.opt, 0.2) then
				local id = (API.Resolve and API.Resolve(step.id)) or step.id
				if id then
					for i = #q, 1, -1 do
						if q[i] == id then
							table.remove(q, i)
						end
					end
					table.insert(q, 1, id)
					while #q > 3 do
						q[#q] = nil
					end
					markHeal(id, step.opt)
				end
				break
			end
		end
	end
	return q
end

function ns.BuildDefense()
	if not ns.GetDef then
		return
	end
	for _, step in ipairs(ns.GetDef()) do
		if ns.IsStepEnabled(step) and stepReady(step.id, step.opt) then
			return (API.Resolve and API.Resolve(step.id)) or step.id
		end
	end
end

function ns.BuildInterrupt()
	local token = ns.ClassToken and ns.ClassToken()
	local id = token and ns.INTERRUPTS[token]
	if not id or not API.Ready(id) then
		return
	end
	if not API.Hostile() or not API.TargetCasting() then
		return
	end
	return id
end

function ns.BuildPurge()
	local token = ns.ClassToken and ns.ClassToken()
	local id = token and ns.PURGES[token]
	if not id or not API.Ready(id) then
		return
	end
	if not API.Hostile() then
		return
	end
	if not API.Purgable(token == "MAGE") then
		return
	end
	return id
end

function ns.BuildCleanse()
	local token = ns.ClassToken and ns.ClassToken()
	local list = token and ns.CLEANSE[token]
	if not list then
		return
	end
	local units = { "player" }
	if ns.db.cleanseGroup ~= false then
		for _, unit in ipairs({ "mouseover", "target", "focus", "party1", "party2", "party3", "party4" }) do
			units[#units + 1] = unit
		end
	end
	for _, entry in ipairs(list) do
		if API.Known(entry.id) and API.Ready(entry.id) then
			for _, unit in ipairs(units) do
				if API.HasDebuffType(entry.types, unit) then
					return entry.id
				end
			end
		end
	end
end

function ns.WeaponChoices()
	local token = ns.ClassToken and ns.ClassToken()
	return token and ns.WEAPON_BUFFS[token] or {}
end

local function knownWeaponID(entry)
	if not entry then
		return
	end
	if API.Known(entry.id) then
		return entry.id
	end
	if entry.ranks then
		for i = #entry.ranks, 1, -1 do
			local id = entry.ranks[i]
			if API.Known(id) then
				return id
			end
		end
	end
	return entry.id
end

function ns.SelectedWeaponBuff()
	local choices = ns.WeaponChoices()
	if #choices == 0 then
		return
	end
	local key = ns.db.weaponBuff
	for _, entry in ipairs(choices) do
		if entry.key == key then
			return entry, knownWeaponID(entry)
		end
	end
	for _, entry in ipairs(choices) do
		if knownWeaponID(entry) and API.Known(knownWeaponID(entry)) then
			return entry, knownWeaponID(entry)
		end
	end
	return choices[1], knownWeaponID(choices[1])
end

local function rememberWeaponApply(entry)
	if not entry then
		return
	end
	local now = GetTime()
	ns.weaponGrace = now + 3
	ns.weaponCastAt = now
	ns.weaponSeenUntil = now + (entry.duration or 3600)
	ns.weaponRecheckDrop = nil
end

local function entryMatchesName(entry, name)
	if not entry or type(name) ~= "string" or name == "" then
		return false
	end
	local lower = strlower(name)
	if entry.match then
		for _, token in ipairs(entry.match) do
			if type(token) == "string" and token ~= "" and lower:find(token, 1, true) then
				return true
			end
		end
	end
	local ids = { entry.id }
	if entry.ranks then
		for _, id in ipairs(entry.ranks) do
			ids[#ids + 1] = id
		end
	end
	for _, id in ipairs(ids) do
		local spellName = API.SpellName(id)
		if type(spellName) == "string" and strlower(spellName) == lower then
			return true
		end
	end
	return false
end

function ns.NoteWeaponCast(spellID, spellName)
	local entry
	if spellID and not (issecretvalue and issecretvalue(spellID)) then
		entry = ns.WEAPON_BUFF_IDS and ns.WEAPON_BUFF_IDS[spellID]
		if not entry and ns.IsWeaponBuff(spellID) then
			entry = select(1, ns.SelectedWeaponBuff())
		end
	end
	if not entry and type(spellName) == "string" then
		for _, choice in ipairs(ns.WeaponChoices() or {}) do
			if entryMatchesName(choice, spellName) then
				entry = choice
				break
			end
		end
	end
	if not entry and ns.weaponNeedLast then
		entry = select(1, ns.SelectedWeaponBuff())
	end
	if not entry then
		return
	end
	rememberWeaponApply(entry)
	if ns.API and ns.API.ClearWeaponTooltipCache then
		ns.API.ClearWeaponTooltipCache()
	end
end

function ns.NoteWeaponEnchantChanged()
	local entry = select(1, ns.SelectedWeaponBuff())
	if not entry then
		return
	end
	local now = GetTime()
	if ns.weaponNeedLast then
		rememberWeaponApply(entry)
		return
	end
	if now < (ns.weaponGrace or 0) or ((ns.weaponCastAt or 0) > 0 and (now - ns.weaponCastAt) < 8) then
		return
	end
	ns.weaponRecheckDrop = true
end

function ns.ClearWeaponMemory()
	ns.weaponGrace = 0
	ns.weaponSeenUntil = 0
	ns.weaponCastAt = 0
	ns.weaponRecheckDrop = nil
end

local function entryHasEnchant(entry, enchId)
	if not entry or not enchId or enchId == 0 then
		return false
	end
	if ns.WEAPON_ENCHANT_IDS and ns.WEAPON_ENCHANT_IDS[enchId] == entry then
		return true
	end
	if entry.enchants then
		for _, id in ipairs(entry.enchants) do
			if id == enchId then
				return true
			end
		end
	end
	return false
end

local function handState(entry, offhand)
	local has, remain, enchId = API.WeaponEnchant(offhand)
	if has == true then
		if enchId and enchId > 0 and ns.WEAPON_ENCHANT_IDS and ns.WEAPON_ENCHANT_IDS[enchId] and not entryHasEnchant(entry, enchId) then
			return "other", 0
		end
		return "up", remain
	end
	if has == false then
		return "no", 0
	end
	return "unknown", 0
end

local function weaponMatchTokens(entry)
	if entry and tokenCache[entry] then
		return tokenCache[entry]
	end
	local tokens, seen = {}, {}
	local function add(token)
		if type(token) ~= "string" or token == "" then
			return
		end
		local key = strlower(token)
		if seen[key] then
			return
		end
		seen[key] = true
		tokens[#tokens + 1] = key
	end
	if entry.match then
		for _, token in ipairs(entry.match) do
			add(token)
		end
	end
	local ids = { entry.id }
	if entry.ranks then
		for _, id in ipairs(entry.ranks) do
			ids[#ids + 1] = id
		end
	end
	for _, id in ipairs(ids) do
		add(API.SpellName(id))
		if API.HintNames then
			for _, name in ipairs(API.HintNames(id)) do
				add(name)
			end
		end
	end
	if entry then
		tokenCache[entry] = tokens
	end
	return tokens
end

local function detectSelected(entry)
	local auraOn, auraRemain = API.HasWeaponBuff(entry)
	if auraOn then
		return "up", auraRemain
	end
	local main, mainLeft = handState(entry, false)
	local off, offLeft = handState(entry, true)
	if main == "up" or off == "up" then
		return "up", main == "up" and mainLeft or offLeft
	end
	if API.WeaponTooltipHas(weaponMatchTokens(entry)) then
		return "up", 9999
	end
	if main == "no" and (off == "no" or off == "other") then
		return "missing", 0
	end
	if off == "no" and (main == "no" or main == "other") then
		return "missing", 0
	end
	if (main == "other" or off == "other") and main ~= "unknown" and off ~= "unknown" then
		return "missing", 0
	end
	return "unknown", 0
end

function ns.BuildWeapon()
	local entry, spellID = ns.SelectedWeaponBuff()
	if not entry or not spellID then
		ns.weaponNeedLast = nil
		return
	end
	local status, remain = detectSelected(entry)
	if status == "up" then
		ns.weaponRecheckDrop = nil
		local hold = remain
		if not hold or hold <= 0 or hold >= 9000 then
			hold = entry.duration or 3600
		end
		ns.weaponSeenUntil = GetTime() + hold
		ns.weaponGrace = 0
		local need = remain > 0 and remain < 9000 and remain <= 30
		ns.weaponNeedLast = need
		return spellID, remain, need
	end
	if ns.weaponRecheckDrop then
		ns.weaponRecheckDrop = nil
		if status ~= "up" then
			ns.weaponSeenUntil = 0
			ns.weaponGrace = 0
			ns.weaponNeedLast = true
			return spellID, 0, true
		end
	end
	local now = GetTime()
	if status == "missing" then
		if now < (ns.weaponGrace or 0) or now < (ns.weaponSeenUntil or 0) then
			local left = math.max((ns.weaponSeenUntil or 0) - now, 0)
			local need = left > 0 and left <= 30
			ns.weaponNeedLast = need
			return spellID, left, need
		end
		ns.weaponSeenUntil = 0
		ns.weaponGrace = 0
		ns.weaponNeedLast = true
		return spellID, 0, true
	end
	if now < (ns.weaponGrace or 0) then
		ns.weaponNeedLast = false
		return spellID, 0, false
	end
	local seen = ns.weaponSeenUntil or 0
	if now < seen then
		local left = seen - now
		local need = left <= 30
		ns.weaponNeedLast = need
		return spellID, left, need
	end
	ns.weaponNeedLast = true
	return spellID, 0, true
end
