local addonName, ns = ...
local API = ns.API

local maintNames
local weaponNames

function ns.InvalidateBuffCaches()
	maintNames = nil
	weaponNames = nil
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
	if not spellID then
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
		if not id or used[id] or used[step.key] then
			return false
		end
		local group = step.opt and (step.opt.anybuff or step.opt.anydebuff)
		if group and blocked[group] then
			return false
		end
		q[#q + 1] = id
		used[id] = true
		used[step.key] = true
		if group then
			blocked[group] = true
		end
		markHeal(id, step.opt)
		return true
	end
	local function consider(step)
		return ns.IsStepEnabled(step) and step.id and not ns.IsWeaponBuff(step.id) and not ns.IsMaintenanceBuff(step.id)
	end
	-- Comme ConROC : un passage maintenant, un second pour le GCD suivant.
	for _, shift in ipairs({ 0.2, 1.5 }) do
		if #q >= 3 then
			break
		end
		for _, step in ipairs(apl) do
			if #q >= 3 then
				break
			end
			if consider(step) and not used[step.key] and API.StepOk(step.id, step.opt, shift) then
				take(step)
			end
		end
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
	for _, entry in ipairs(list) do
		if API.Known(entry.id) and API.Ready(entry.id) and API.HasDebuffType(entry.types, "player") then
			return entry.id
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

function ns.NoteWeaponCast(spellID)
	if not ns.IsWeaponBuff(spellID) then
		return
	end
	-- Le sort vient d'être lancé : courte grâce, le temps que l'enchant apparaisse.
	-- La durée réelle vient de GetWeaponEnchantInfo, pas de ce lancement.
	ns.weaponGrace = GetTime() + 5
end

function ns.ClearWeaponMemory()
	ns.weaponGrace = 0
	ns.weaponSeenUntil = 0
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
	if API.WeaponTooltipHas(entry.match) then
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
		return
	end
	local status, remain = detectSelected(entry)
	if status == "up" then
		local hold = remain
		if not hold or hold <= 0 or hold >= 9000 then
			hold = 15
		end
		ns.weaponSeenUntil = GetTime() + hold
		ns.weaponGrace = 0
		return spellID, remain, remain > 0 and remain < 9000 and remain <= 30
	end
	if status == "missing" then
		ns.weaponSeenUntil = 0
		ns.weaponGrace = 0
		return spellID, 0, true
	end
	if GetTime() < (ns.weaponGrace or 0) then
		return spellID, 0, false
	end
	local seen = ns.weaponSeenUntil or 0
	if GetTime() < seen then
		local left = seen - GetTime()
		return spellID, left, left <= 30
	end
	return spellID, 0, true
end
