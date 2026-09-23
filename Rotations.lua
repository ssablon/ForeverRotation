local addonName, ns = ...
local API = ns.API

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
	if not name then
		return false
	end
	for id in pairs(ns.MAINTENANCE_BUFF_IDS or {}) do
		if API.SpellName(id) == name then
			return true
		end
	end
	return false
end

function ns.IsWeaponBuff(spellID)
	if not spellID then
		return false
	end
	if ns.WEAPON_BUFF_IDS and ns.WEAPON_BUFF_IDS[spellID] then
		return true
	end
	local name = API.SpellName(spellID)
	if not name then
		return false
	end
	for _, list in pairs(ns.WEAPON_BUFFS or {}) do
		for _, entry in ipairs(list) do
			if API.SpellName(entry.id) == name then
				return true
			end
		end
	end
	return false
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
	-- Comme ConROC : le sort prêt maintenant, puis ceux qui le seront au GCD suivant.
	for _, shift in ipairs({ 0.2, 1.5, 3 }) do
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
	if #q < 3 then
		for _, step in ipairs(apl) do
			if #q >= 3 then
				break
			end
			if consider(step) and not used[step.key] and API.StepOk(step.id, step.opt, 999) then
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
	local entry = ns.WEAPON_BUFF_IDS and ns.WEAPON_BUFF_IDS[spellID]
	if not entry then
		local name = API.SpellName(spellID)
		for _, list in pairs(ns.WEAPON_BUFFS or {}) do
			for _, row in ipairs(list) do
				if API.SpellName(row.id) == name then
					entry = row
					break
				end
			end
		end
	end
	ns.weaponUntil = GetTime() + ((entry and entry.duration) or 300)
	ns.weaponDirty = false
end

function ns.ClearWeaponMemory()
	ns.weaponUntil = 0
	ns.weaponDirty = false
end

function ns.WeaponBuffRemembered()
	return GetTime() < (ns.weaponUntil or 0)
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

local function detectEntry(entry)
	if not entry then
		return false, 0
	end
	local has, remain, enchId = API.WeaponEnchant(false)
	if enchId and entryHasEnchant(entry, enchId) then
		return true, remain
	end
	local auraHas, auraRemain = API.HasWeaponBuff(entry)
	if auraHas then
		return true, auraRemain
	end
	if API.WeaponTooltipHas(entry.match) then
		return true, remain > 0 and remain or 9999
	end
	if has == true and not enchId then
		return true, remain
	end
	return false, 0
end

function ns.BuildWeapon()
	local entry, spellID = ns.SelectedWeaponBuff()
	if not entry or not spellID then
		return
	end
	local found, remain = false, 0
	for _, choice in ipairs(ns.WeaponChoices()) do
		local ok, left = detectEntry(choice)
		if ok then
			found = true
			remain = left
			if choice == entry then
				break
			end
		end
	end
	if found then
		return spellID, remain, remain > 0 and remain <= 30
	end
	if ns.WeaponBuffRemembered() then
		return spellID, remain, false
	end
	local has, _, enchId = API.WeaponEnchant(false)
	local sureMissing = has == false and (enchId == 0 or enchId == nil)
	return spellID, remain, sureMissing
end
