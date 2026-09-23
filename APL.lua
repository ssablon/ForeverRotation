local addonName, ns = ...
local S = ns.Spell

local function step(key, id, opt)
	return { key = key, id = id, opt = opt or {}, on = true }
end

function ns.IsStepEnabled(step)
	if type(step) ~= "table" then
		return false
	end
	local on = step.on
	if on == false or on == 0 or on == "0" then
		return false
	end
	return true
end

function ns.CoerceChecked(value)
	return value == true or value == 1 or value == "1"
end

local function copyList(list)
	local out = {}
	for i, s in ipairs(list) do
		out[i] = {
			key = s.key,
			id = s.id,
			opt = s.opt,
			on = ns.IsStepEnabled(s),
			racial = s.racial,
		}
	end
	return out
end

local function readableId(value)
	if type(value) ~= "number" then
		return nil
	end
	if issecretvalue and issecretvalue(value) then
		return nil
	end
	if canaccessvalue and not canaccessvalue(value) then
		return nil
	end
	return value
end

local function readableText(value)
	if type(value) ~= "string" or value == "" then
		return nil
	end
	if issecretvalue and issecretvalue(value) then
		return nil
	end
	if canaccessvalue and not canaccessvalue(value) then
		return nil
	end
	return value
end

local function listHas(list, value)
	if not list or value == nil then
		return false
	end
	for _, item in ipairs(list) do
		if item == value then
			return true
		end
	end
	return false
end

function ns.RaceId()
	local ok, _, _, raceId = pcall(UnitRace, "player")
	if ok then
		raceId = readableId(raceId)
		if raceId then
			return raceId
		end
	end
	return nil
end

function ns.Faction()
	local ok, faction = pcall(UnitFactionGroup, "player")
	if ok then
		return readableText(faction)
	end
	return nil
end

local function racialMatches(racial, race, faction)
	if racial.factions and faction and not listHas(racial.factions, faction) then
		return false
	end
	if racial.races then
		if race then
			return listHas(racial.races, race)
		end
		return ns.API.Known(racial.id)
	end
	return ns.API.Known(racial.id)
end

function ns.RacialSteps(defensiveOnly)
	local race = ns.RaceId()
	local faction = ns.Faction()
	local out = {}
	for _, racial in ipairs(ns.RACIALS) do
		if (not defensiveOnly or racial.defensive) and racialMatches(racial, race, faction) then
			out[#out + 1] = {
				key = "racial_" .. racial.key,
				id = racial.id,
				opt = racial.opt or {},
				on = racial.on and true or false,
				racial = true,
			}
		end
	end
	return out
end


function ns.ActiveSpec()
	local token = ns.ClassToken and ns.ClassToken() or ""
	local role = ns.db.role or "damage"
	if token == "DRUID" then
		local cat = ns.API.Form(S.Druid.CatForm)
		local bear = ns.API.Form(S.Druid.BearForm)
		if role == "heal" then
			return "heal"
		end
		if role == "tank" then
			return bear and "bear" or "tank"
		end
		if cat then
			return "cat"
		end
		if bear then
			return "bear"
		end
		return "damage"
	end
	return role
end

function ns.SpecList(classFile)
	classFile = classFile or (ns.ClassToken and ns.ClassToken())
	if classFile == "DRUID" then
		return { "damage", "cat", "bear", "heal", "tank" }
	end
	local pack = ns.APLDefaults[classFile]
	if pack then
		local list, seen = {}, {}
		for _, role in ipairs(ns.CLASS_ROLES[classFile] or { "damage" }) do
			if pack[role] and not seen[role] then
				list[#list + 1] = role
				seen[role] = true
			end
		end
		for spec in pairs(pack) do
			if not seen[spec] then
				list[#list + 1] = spec
				seen[spec] = true
			end
		end
		if #list > 0 then
			return list
		end
	end
	return ns.CLASS_ROLES[classFile] or { "damage" }
end

function ns.CombatMode()
	local mode = ns.db and ns.db.combatMode or "auto"
	if mode == "auto" or mode == "aoe" or mode == "burst" or mode == "single" then
		return mode
	end
	return "auto"
end

function ns.ResolveCombatMode()
	local mode = ns.CombatMode()
	if mode ~= "auto" then
		return mode
	end
	local need = tonumber(ns.db and ns.db.autoEnemies) or 3
	if need < 2 then
		need = 2
	end
	if ns.API.EnemyCount() >= need then
		return "aoe"
	end
	return "auto"
end

local function specPack(classFile, spec)
	local pack = ns.APLDefaults[classFile]
	return pack and (pack[spec] or pack.damage or pack.caster or pack.range)
end

local function modePack(classFile, spec, mode)
	local pack = ns.APLModes[classFile]
	if not pack then
		return nil
	end
	local specModes = pack[spec] or pack.damage or pack.caster or pack.range
	return specModes and specModes[mode]
end

local VALID_MODES = { auto = true, single = true, aoe = true, burst = true }

local function validMode(mode)
	if type(mode) == "string" and VALID_MODES[mode] then
		return mode
	end
	return nil
end

local function isModeBucket(saved)
	return type(saved) == "table" and (saved.auto ~= nil or saved.single ~= nil or saved.aoe ~= nil or saved.burst ~= nil) and saved[1] == nil
end

local function savedForMode(saved, mode)
	if not saved then
		return nil
	end
	if isModeBucket(saved) then
		local rows = saved[mode]
		return type(rows) == "table" and rows or nil
	end
	if mode == "single" then
		return saved
	end
	return nil
end

local function ensureModeBucket(classFile, spec)
	ns.db.apl = ns.db.apl or {}
	ns.db.apl[classFile] = ns.db.apl[classFile] or {}
	local current = ns.db.apl[classFile][spec]
	if isModeBucket(current) then
		return current
	end
	local legacy = type(current) == "table" and current[1] and current or nil
	ns.db.apl[classFile][spec] = { single = legacy }
	return ns.db.apl[classFile][spec]
end

local function defaultsFor(classFile, spec, mode)
	mode = mode or ns.CombatMode()
	local list
	if mode ~= "single" and mode ~= "auto" then
		list = modePack(classFile, spec, mode)
	end
	if not list then
		list = specPack(classFile, spec) or {}
	end
	local out = copyList(list)
	for _, racial in ipairs(ns.RacialSteps()) do
		out[#out + 1] = racial
	end
	return out
end

local function dropRoot(kind)
	if kind == "def" then
		return ns.db.defDrop
	end
	return ns.db.aplDrop
end

local function dropMap(kind, classFile, spec, mode)
	local root = dropRoot(kind)
	if not root or not root[classFile] or not root[classFile][spec] then
		return nil
	end
	if kind == "def" then
		return root[classFile][spec]
	end
	local modeDrop = root[classFile][spec][mode or "single"]
	if type(modeDrop) == "table" then
		return modeDrop
	end
	return nil
end

local function setDropped(kind, classFile, spec, mode, key, yes)
	local store = kind == "def" and "defDrop" or "aplDrop"
	ns.db[store] = ns.db[store] or {}
	ns.db[store][classFile] = ns.db[store][classFile] or {}
	ns.db[store][classFile][spec] = ns.db[store][classFile][spec] or {}
	if kind == "def" then
		ns.db[store][classFile][spec][key] = yes and true or nil
		return
	end
	mode = mode or "single"
	ns.db[store][classFile][spec][mode] = ns.db[store][classFile][spec][mode] or {}
	ns.db[store][classFile][spec][mode][key] = yes and true or nil
end

local function clearDropped(kind, classFile, spec, mode)
	local root = dropRoot(kind)
	if not root or not root[classFile] or not root[classFile][spec] then
		return
	end
	if kind == "def" then
		root[classFile][spec] = nil
		return
	end
	root[classFile][spec][mode or "single"] = nil
end

local function sameSpell(a, b)
	if not a or not b then
		return false
	end
	if a == b then
		return true
	end
	local na, nb = ns.API.SpellName(a), ns.API.SpellName(b)
	return na and nb and na == nb
end

local function customKey(spellID)
	local name = ns.API.SpellName(spellID)
	if name and name ~= "" then
		return "custom_" .. name:gsub("%s+", "")
	end
	if type(spellID) == "number" then
		return "custom_" .. tostring(spellID)
	end
	return "custom_spell"
end

local function skipCombatOnly(id, skipMaint)
	if ns.IsWeaponBuff and ns.IsWeaponBuff(id) then
		return true
	end
	return skipMaint and ns.IsMaintenanceBuff and ns.IsMaintenanceBuff(id)
end

local function mergeSteps(defaults, saved, dropped, skipMaint)
	dropped = dropped or {}
	if not saved then
		if not next(dropped) then
			return defaults
		end
		local out = {}
		for _, def in ipairs(defaults) do
			if not dropped[def.key] and not skipCombatOnly(def.id, skipMaint) then
				out[#out + 1] = {
					key = def.key,
					id = def.id,
					opt = def.opt,
					on = ns.IsStepEnabled(def),
					racial = def.racial,
				}
			end
		end
		return out
	end
	local byKey = {}
	for _, s in ipairs(defaults) do
		if not skipCombatOnly(s.id, skipMaint) then
			byKey[s.key] = s
		end
	end
	local out, seen = {}, {}
	for _, row in ipairs(saved) do
		if type(row) == "table" and row.key and not dropped[row.key] then
			local def = byKey[row.key]
			if def then
				out[#out + 1] = {
					key = def.key,
					id = def.id,
					opt = def.opt,
					on = ns.IsStepEnabled(row),
					racial = def.racial,
				}
				seen[row.key] = true
			elseif (row.id or row.custom) and not skipCombatOnly(row.id, skipMaint) then
				local opt = row.opt or {}
				if ns.API.IsHelpful and ns.API.IsHelpful(row.id, opt) and not opt.heal then
					local copy = {}
					for k, v in pairs(opt) do
						copy[k] = v
					end
					copy.heal = true
					opt = copy
				end
				out[#out + 1] = {
					key = row.key,
					id = row.id,
					opt = opt,
					on = ns.IsStepEnabled(row),
					custom = true,
				}
				seen[row.key] = true
			end
		end
	end
	for _, def in ipairs(defaults) do
		if not seen[def.key] and not dropped[def.key] and not skipCombatOnly(def.id, skipMaint) then
			local dup = false
			for _, row in ipairs(out) do
				if sameSpell(row.id, def.id) then
					dup = true
					break
				end
			end
			if not dup then
				out[#out + 1] = {
					key = def.key,
					id = def.id,
					opt = def.opt,
					on = ns.IsStepEnabled(def),
					racial = def.racial,
				}
			end
		end
	end
	return out
end

local function packRows(steps)
	local rows = {}
	for _, s in ipairs(steps) do
		rows[#rows + 1] = {
			key = s.key,
			on = ns.IsStepEnabled(s) and 1 or 0,
			id = s.custom and s.id or nil,
			custom = s.custom or nil,
		}
	end
	return rows
end

function ns.GetAPL(classFile, spec, mode)
	classFile = classFile or (ns.ClassToken and ns.ClassToken()) or ""
	spec = spec or ns.ActiveSpec()
	mode = validMode(mode) or ns.ResolveCombatMode()
	local defaults = defaultsFor(classFile, spec, mode)
	local savedRoot = ns.db.apl and ns.db.apl[classFile] and ns.db.apl[classFile][spec]
	local saved = savedForMode(savedRoot, mode)
	local dropped = dropMap("apl", classFile, spec, mode)
	if not saved and not (dropped and next(dropped)) then
		return defaults
	end
	return mergeSteps(defaults, saved, dropped, true)
end

function ns.SaveAPL(steps, classFile, spec, mode)
	classFile = classFile or (ns.ClassToken and ns.ClassToken()) or ""
	spec = spec or ns.ActiveSpec()
	mode = validMode(mode)
	if not mode or type(steps) ~= "table" then
		return
	end
	local bucket = ensureModeBucket(classFile, spec)
	bucket[mode] = packRows(steps)
	if ns.Tick then
		ns.Tick()
	end
end

function ns.ResetAPL(classFile, spec, mode)
	classFile = classFile or (ns.ClassToken and ns.ClassToken()) or ""
	spec = spec or ns.ActiveSpec()
	mode = validMode(mode)
	if not mode then
		return
	end
	local bucket = ns.db.apl and ns.db.apl[classFile] and ns.db.apl[classFile][spec]
	if not bucket then
		if ns.Tick then
			ns.Tick()
		end
		return
	end
	if isModeBucket(bucket) then
		bucket[mode] = nil
	elseif mode == "single" then
		ns.db.apl[classFile][spec] = nil
	end
	clearDropped("apl", classFile, spec, mode)
	if ns.Tick then
		ns.Tick()
	end
end

function ns.MoveAPL(index, delta, classFile, spec, mode)
	mode = validMode(mode)
	if not mode then
		return
	end
	local steps = ns.GetAPL(classFile, spec, mode)
	local dest = index + delta
	if dest < 1 or dest > #steps then
		return
	end
	steps[index], steps[dest] = steps[dest], steps[index]
	ns.SaveAPL(steps, classFile, spec, mode)
end

function ns.SetAPLEnabled(key, enabled, classFile, spec, mode)
	mode = validMode(mode)
	if not mode then
		return
	end
	local steps = ns.GetAPL(classFile, spec, mode)
	for _, s in ipairs(steps) do
		if s.key == key then
			s.on = ns.CoerceChecked(enabled)
			break
		end
	end
	ns.SaveAPL(steps, classFile, spec, mode)
end

function ns.RemoveAPL(key, classFile, spec, mode)
	classFile = classFile or (ns.ClassToken and ns.ClassToken()) or ""
	spec = spec or ns.ActiveSpec()
	mode = validMode(mode)
	if not mode then
		return
	end
	local steps = ns.GetAPL(classFile, spec, mode)
	local out = {}
	for _, s in ipairs(steps) do
		if s.key ~= key then
			out[#out + 1] = s
		end
	end
	if not key:find("^custom_", 1, false) then
		setDropped("apl", classFile, spec, mode, key, true)
	end
	ns.SaveAPL(out, classFile, spec, mode)
end

function ns.AddAPL(spellID, classFile, spec, mode, atIndex)
	if not spellID then
		return false
	end
	if ns.IsMaintenanceBuff and ns.IsMaintenanceBuff(spellID) then
		return false
	end
	classFile = classFile or (ns.ClassToken and ns.ClassToken()) or ""
	spec = spec or ns.ActiveSpec()
	mode = validMode(mode)
	if not mode then
		return false
	end
	local steps = ns.GetAPL(classFile, spec, mode)
	for _, s in ipairs(steps) do
		if sameSpell(s.id, spellID) then
			return false
		end
	end
	local defaults = defaultsFor(classFile, spec, mode)
	local matched
	for _, def in ipairs(defaults) do
		if sameSpell(def.id, spellID) then
			matched = def
			break
		end
	end
	local step
	if matched then
		setDropped("apl", classFile, spec, mode, matched.key, false)
		step = {
			key = matched.key,
			id = matched.id,
			opt = matched.opt,
			on = true,
			racial = matched.racial,
		}
	else
		step = {
			key = customKey(spellID),
			id = spellID,
			opt = (ns.API.IsHelpful and ns.API.IsHelpful(spellID)) and { heal = true } or {},
			on = true,
			custom = true,
		}
	end
	setDropped("apl", classFile, spec, mode, step.key, false)
	if atIndex and atIndex >= 1 and atIndex <= #steps then
		table.insert(steps, atIndex, step)
	else
		steps[#steps + 1] = step
	end
	ns.SaveAPL(steps, classFile, spec, mode)
	return true
end

local function defDefaultsFor(classFile, spec)
	local pack = ns.DefDefaults[classFile]
	local list = pack and (pack[spec] or pack.damage or pack.caster or pack.range) or {}
	local out = copyList(list)
	for _, racial in ipairs(ns.RacialSteps(true)) do
		out[#out + 1] = racial
	end
	return out
end

function ns.GetDef(classFile, spec)
	classFile = classFile or (ns.ClassToken and ns.ClassToken()) or ""
	spec = spec or ns.ActiveSpec()
	local saved = ns.db.def and ns.db.def[classFile] and ns.db.def[classFile][spec]
	local dropped = dropMap("def", classFile, spec)
	if not saved and not (dropped and next(dropped)) then
		return defDefaultsFor(classFile, spec)
	end
	return mergeSteps(defDefaultsFor(classFile, spec), saved, dropped)
end

function ns.SaveDef(steps, classFile, spec)
	classFile = classFile or (ns.ClassToken and ns.ClassToken()) or ""
	spec = spec or ns.ActiveSpec()
	ns.db.def = ns.db.def or {}
	ns.db.def[classFile] = ns.db.def[classFile] or {}
	ns.db.def[classFile][spec] = packRows(steps)
	if ns.Tick then
		ns.Tick()
	end
end

function ns.ResetDef(classFile, spec)
	classFile = classFile or (ns.ClassToken and ns.ClassToken()) or ""
	spec = spec or ns.ActiveSpec()
	if ns.db.def and ns.db.def[classFile] then
		ns.db.def[classFile][spec] = nil
	end
	clearDropped("def", classFile, spec)
	if ns.Tick then
		ns.Tick()
	end
end

function ns.MoveDef(index, delta, classFile, spec)
	local steps = ns.GetDef(classFile, spec)
	local dest = index + delta
	if dest < 1 or dest > #steps then
		return
	end
	steps[index], steps[dest] = steps[dest], steps[index]
	ns.SaveDef(steps, classFile, spec)
end

function ns.SetDefEnabled(key, enabled, classFile, spec)
	local steps = ns.GetDef(classFile, spec)
	for _, s in ipairs(steps) do
		if s.key == key then
			s.on = ns.CoerceChecked(enabled)
			break
		end
	end
	ns.SaveDef(steps, classFile, spec)
end

function ns.RemoveDef(key, classFile, spec)
	classFile = classFile or (ns.ClassToken and ns.ClassToken()) or ""
	spec = spec or ns.ActiveSpec()
	local steps = ns.GetDef(classFile, spec)
	local out = {}
	for _, s in ipairs(steps) do
		if s.key ~= key then
			out[#out + 1] = s
		end
	end
	if not key:find("^custom_", 1, false) then
		setDropped("def", classFile, spec, nil, key, true)
	end
	ns.SaveDef(out, classFile, spec)
end

function ns.AddDef(spellID, classFile, spec, atIndex)
	if not spellID then
		return false
	end
	classFile = classFile or (ns.ClassToken and ns.ClassToken()) or ""
	spec = spec or ns.ActiveSpec()
	local steps = ns.GetDef(classFile, spec)
	for _, s in ipairs(steps) do
		if sameSpell(s.id, spellID) then
			return false
		end
	end
	local defaults = defDefaultsFor(classFile, spec)
	local matched
	for _, def in ipairs(defaults) do
		if sameSpell(def.id, spellID) then
			matched = def
			break
		end
	end
	local step
	if matched then
		setDropped("def", classFile, spec, nil, matched.key, false)
		step = {
			key = matched.key,
			id = matched.id,
			opt = matched.opt,
			on = true,
			racial = matched.racial,
		}
	else
		step = {
			key = customKey(spellID),
			id = spellID,
			opt = { combat = true },
			on = true,
			custom = true,
		}
	end
	setDropped("def", classFile, spec, nil, step.key, false)
	if atIndex and atIndex >= 1 and atIndex <= #steps then
		table.insert(steps, atIndex, step)
	else
		steps[#steps + 1] = step
	end
	ns.SaveDef(steps, classFile, spec)
	return true
end
