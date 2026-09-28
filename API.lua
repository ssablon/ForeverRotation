local addonName, ns = ...
ns.API = ns.API or {}

local function readable(value)
	if value == nil then
		return false
	end
	if issecretvalue and issecretvalue(value) then
		return false
	end
	if canaccessvalue and not canaccessvalue(value) then
		return false
	end
	return true
end

local function safe(value, fallback)
	if readable(value) then
		return value
	end
	return fallback
end

function ns.API.SpellInfo(spellID)
	if not spellID or not C_Spell or not C_Spell.GetSpellInfo then
		return nil
	end
	local ok, info = pcall(C_Spell.GetSpellInfo, spellID)
	if ok and type(info) == "table" then
		return info
	end
	return nil
end

local function junkSpellName(name)
	if type(name) ~= "string" then
		return true
	end
	local upper = name:upper()
	return upper:find("TEST", 1, true)
		or upper:find("(OLD)", 1, true)
		or upper:find("(PT)", 1, true)
end

local function spellIdFromName(name)
	name = safe(name, nil)
	if type(name) ~= "string" or name == "" or junkSpellName(name) then
		return nil
	end
	if C_Spell and C_Spell.GetSpellInfo then
		local ok, info = pcall(C_Spell.GetSpellInfo, name)
		if ok and type(info) == "table" then
			local id = safe(info.spellID, nil)
			local got = safe(info.name, nil)
			if type(id) == "number" and (not got or got == name) and not junkSpellName(got or name) then
				return id
			end
		end
	end
	if GetSpellInfo then
		local ok, gotName, _, _, _, _, id = pcall(GetSpellInfo, name)
		if ok and type(id) == "number" and readable(id) and (not gotName or gotName == name) then
			return id
		end
	end
	return nil
end

local cachedBanks

local function bookBanks()
	if cachedBanks then
		return cachedBanks
	end
	local banks = {}
	if Enum and Enum.SpellBookSpellBank then
		banks[#banks + 1] = Enum.SpellBookSpellBank.Player
		banks[#banks + 1] = Enum.SpellBookSpellBank.Pet
	end
	if BOOKTYPE_SPELL then
		banks[#banks + 1] = BOOKTYPE_SPELL
	end
	if BOOKTYPE_PET then
		banks[#banks + 1] = BOOKTYPE_PET
	end
	banks[#banks + 1] = 0
	banks[#banks + 1] = 1
	banks[#banks + 1] = "spell"
	banks[#banks + 1] = "pet"
	cachedBanks = banks
	return banks
end

local function readBookItem(index, bank)
	if index == nil or bank == nil then
		return nil, nil
	end
	if C_SpellBook and C_SpellBook.GetSpellBookItemInfo then
		local ok, info = pcall(C_SpellBook.GetSpellBookItemInfo, index, bank)
		if ok and type(info) == "table" then
			return safe(info.name, nil), safe(info.spellID, nil)
		end
	end
	if C_SpellBook and C_SpellBook.GetSpellBookItemName then
		local ok, name = pcall(C_SpellBook.GetSpellBookItemName, index, bank)
		if ok then
			return safe(name, nil), nil
		end
	end
	if GetSpellBookItemName then
		local ok, name = pcall(GetSpellBookItemName, index, bank)
		if ok then
			return safe(name, nil), nil
		end
	end
	return nil, nil
end

-- Forever FR lab often drops accents (Eclair vs Éclair). Fold so Resolve
-- matches the spellbook for every class spell and racial by name.
local ACCENT_FOLD = {
	["à"] = "a", ["á"] = "a", ["â"] = "a", ["ã"] = "a", ["ä"] = "a", ["å"] = "a",
	["À"] = "a", ["Á"] = "a", ["Â"] = "a", ["Ã"] = "a", ["Ä"] = "a", ["Å"] = "a",
	["è"] = "e", ["é"] = "e", ["ê"] = "e", ["ë"] = "e",
	["È"] = "e", ["É"] = "e", ["Ê"] = "e", ["Ë"] = "e",
	["ì"] = "i", ["í"] = "i", ["î"] = "i", ["ï"] = "i",
	["Ì"] = "i", ["Í"] = "i", ["Î"] = "i", ["Ï"] = "i",
	["ò"] = "o", ["ó"] = "o", ["ô"] = "o", ["õ"] = "o", ["ö"] = "o",
	["Ò"] = "o", ["Ó"] = "o", ["Ô"] = "o", ["Õ"] = "o", ["Ö"] = "o",
	["ù"] = "u", ["ú"] = "u", ["û"] = "u", ["ü"] = "u",
	["Ù"] = "u", ["Ú"] = "u", ["Û"] = "u", ["Ü"] = "u",
	["ý"] = "y", ["ÿ"] = "y", ["Ý"] = "y",
	["ç"] = "c", ["Ç"] = "c",
	["ñ"] = "n", ["Ñ"] = "n",
	["œ"] = "oe", ["Œ"] = "oe",
	["æ"] = "ae", ["Æ"] = "ae",
}

local function foldAccents(name)
	if type(name) ~= "string" or name == "" then
		return name
	end
	return (name:gsub("[%z\1-\127\194-\244][\128-\191]*", function(ch)
		return ACCENT_FOLD[ch] or ch
	end))
end

local function normSpellName(name)
	name = safe(name, nil)
	if type(name) ~= "string" or name == "" then
		return nil
	end
	name = foldAccents(name):lower()
	name = name:gsub("%s*%([^%)]*%)", "")
	name = name:gsub("%s*rank%s*%d+", "")
	name = name:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
	return name
end

local function findPlayerSpellByName(name)
	name = safe(name, nil)
	if type(name) ~= "string" or name == "" then
		return nil
	end
	local want = normSpellName(name)
	if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines then
		local okNum, num = pcall(C_SpellBook.GetNumSpellBookSkillLines)
		if okNum and type(num) == "number" then
			for line = 1, num do
				local okLine, lineInfo = pcall(C_SpellBook.GetSpellBookSkillLineInfo, line)
				if okLine and type(lineInfo) == "table" then
					local off = tonumber(lineInfo.itemIndexOffset) or 0
					local count = tonumber(lineInfo.numSpellBookItems) or 0
					for i = off + 1, off + count do
						for _, bank in ipairs(bookBanks()) do
							local bookName, bookId = readBookItem(i, bank)
							if type(bookId) == "number" and not junkSpellName(bookName) and (bookName == name or normSpellName(bookName) == want) then
								return bookId
							end
						end
					end
				end
			end
		end
	end
	for i = 1, 400 do
		for _, bank in ipairs(bookBanks()) do
			local bookName, bookId = readBookItem(i, bank)
			if type(bookId) == "number" and not junkSpellName(bookName) and (bookName == name or normSpellName(bookName) == want) then
				return bookId
			end
		end
	end
	return nil
end

local function acceptSpellId(id, expectedName)
	if type(id) ~= "number" or not readable(id) or junkSpellName(ns.API.SpellName(id) or "") then
		return nil
	end
	if expectedName then
		local got = ns.API.SpellName(id)
		if got and got ~= expectedName then
			return nil
		end
	end
	return id
end

function ns.API.ResolveFromName(name)
	if type(name) ~= "string" or name == "" or junkSpellName(name) then
		return nil
	end
	return findPlayerSpellByName(name) or spellIdFromName(name)
end

function ns.API.CursorSpell()
	if not GetCursorInfo then
		return nil
	end
	local ok, kind, arg1, arg2 = pcall(GetCursorInfo)
	if not ok then
		return nil
	end
	local kindText = safe(kind, nil)
	if type(kindText) == "string" then
		kindText = kindText:lower()
	end
	if kindText and kindText ~= "spell" and kindText ~= "spellid" then
		return nil
	end

	local name, slotId
	local banks = bookBanks()
	if arg2 ~= nil then
		table.insert(banks, 1, arg2)
	end
	for _, bank in ipairs(banks) do
		local bookName, bookId = readBookItem(arg1, bank)
		if bookName or bookId then
			name = bookName or name
			slotId = acceptSpellId(bookId, bookName) or slotId
			if name then
				break
			end
		end
	end

	if name then
		return findPlayerSpellByName(name) or slotId or spellIdFromName(name)
	end

	if type(arg1) == "number" and readable(arg1) then
		local guessed = ns.API.SpellName(arg1)
		if guessed and not junkSpellName(guessed) then
			if IsPlayerSpell then
				local okKnown, known = pcall(IsPlayerSpell, arg1)
				if okKnown and known then
					return arg1
				end
			end
			return findPlayerSpellByName(guessed) or arg1
		end
	end

	local info = ns.API.SpellInfo(arg1)
	if info then
		local infoName = safe(info.name, nil)
		if infoName then
			return findPlayerSpellByName(infoName) or acceptSpellId(safe(info.spellID, nil), infoName)
		end
	end
	return nil
end

local enemyCountAt, enemyCountVal = 0, 0

function ns.API.EnemyCount()
	local now = GetTime()
	if enemyCountAt > 0 and (now - enemyCountAt) < 0.3 then
		return enemyCountVal
	end
	local count = 0
	local function hostile(unit)
		local okEx, exists = pcall(UnitExists, unit)
		if not okEx or not exists then
			return false
		end
		local okDead, dead = pcall(UnitIsDead, unit)
		if okDead and dead then
			return false
		end
		local okAtk, atk = pcall(UnitCanAttack, "player", unit)
		if okAtk and atk then
			return true
		end
		local okR, react = pcall(UnitReaction, "player", unit)
		return okR and type(react) == "number" and react <= 4
	end
	local function inFight(unit)
		local okC, combat = pcall(UnitAffectingCombat, unit)
		if okC and combat then
			return true
		end
		local okP, pcombat = pcall(UnitAffectingCombat, "player")
		return not (okP and pcombat)
	end
	for i = 1, 40 do
		local unit = "nameplate" .. i
		if hostile(unit) and inFight(unit) then
			count = count + 1
		end
	end
	if count < 1 and hostile("target") then
		count = 1
	end
	enemyCountAt = now
	enemyCountVal = count
	return count
end

function ns.API.SpellName(spellID)
	local info = ns.API.SpellInfo(spellID)
	return info and safe(info.name, nil)
end

local HINT_LOCALES = { "enUS", "frFR", "deDE", "esES", "esMX", "ruRU", "zhCN", "zhTW", "ptBR", "itIT", "koKR" }

local function pushHintName(out, seen, name)
	if type(name) == "table" then
		for i = 1, #name do
			pushHintName(out, seen, name[i])
		end
		return
	end
	if type(name) == "string" and name ~= "" and not seen[name] then
		seen[name] = true
		out[#out + 1] = name
	end
end

local function hintLocale()
	local loc = GetLocale and GetLocale() or "enUS"
	if loc == "enGB" then
		return "enUS"
	end
	return loc
end

function ns.API.HintNames(...)
	local out, seen = {}, {}
	for n = 1, select("#", ...) do
		local spellID = select(n, ...)
		local pack = spellID and ns.SPELL_NAME_HINT and ns.SPELL_NAME_HINT[spellID]
		if type(pack) == "string" then
			pushHintName(out, seen, pack)
		elseif type(pack) == "table" then
			local loc = hintLocale()
			pushHintName(out, seen, pack[loc])
			if loc == "esES" then
				pushHintName(out, seen, pack.esMX)
			elseif loc == "esMX" then
				pushHintName(out, seen, pack.esES)
			end
			for i = 1, #HINT_LOCALES do
				local code = HINT_LOCALES[i]
				if code ~= loc then
					pushHintName(out, seen, pack[code])
				end
			end
			for i = 1, #pack do
				pushHintName(out, seen, pack[i])
			end
		end
	end
	return out
end

function ns.API.HintName(spellID)
	local pack = spellID and ns.SPELL_NAME_HINT and ns.SPELL_NAME_HINT[spellID]
	if type(pack) == "string" then
		return pack
	end
	if type(pack) ~= "table" then
		return nil
	end
	local loc = hintLocale()
	if ns.db and ns.db.locale and ns.db.locale ~= "" and ns.db.locale ~= "auto" then
		loc = ns.db.locale
		if loc == "enGB" then
			loc = "enUS"
		end
	end
	local hit = pack[loc] or pack.enUS or pack[1]
	if type(hit) == "table" then
		return hit[1]
	end
	return hit
end

function ns.API.SpellLabel(spellID)
	return ns.API.SpellName(spellID) or ns.API.HintName(spellID)
end

function ns.API.SpellIcon(spellID)
	local info = ns.API.SpellInfo(spellID)
	if not info then
		return nil
	end
	local icon = info.originalIconID or info.iconID or info.icon
	if readable(icon) then
		return icon
	end
	return nil
end

local resolveCache = {}
local healNames
local auraScans = {}
local predict
local heldHarmful = {}
local heldHarmfulGuid

function ns.API.WipeAuraScans()
	wipe(auraScans)
end

function ns.API.WipeAuraScan(unit)
	if not unit then
		wipe(auraScans)
		return
	end
	local prefix = unit .. "\0"
	for key in pairs(auraScans) do
		if strsub(key, 1, #prefix) == prefix then
			auraScans[key] = nil
		end
	end
end

function ns.API.InvalidateSpells(full)
	if full then
		wipe(resolveCache)
	else
		for id, resolved in pairs(resolveCache) do
			if not resolved then
				resolveCache[id] = nil
			end
		end
	end
	wipe(auraScans)
	healNames = nil
	if ns.InvalidateBuffCaches then
		ns.InvalidateBuffCaches()
	end
	if ns.InvalidateAPLCache then
		ns.InvalidateAPLCache()
	end
end

local function playerKnows(id)
	if not id then
		return false
	end
	if IsPlayerSpell then
		local ok, known = pcall(IsPlayerSpell, id)
		if ok and known then
			return true
		end
	end
	if IsSpellKnownOrOverridesKnown then
		local ok, known = pcall(IsSpellKnownOrOverridesKnown, id)
		if ok and known then
			return true
		end
	end
	if IsSpellKnown then
		local ok, known = pcall(IsSpellKnown, id)
		if ok and known then
			return true
		end
	end
	if C_SpellBook then
		if C_SpellBook.IsSpellInSpellBook then
			local ok, known = pcall(C_SpellBook.IsSpellInSpellBook, id)
			if ok and known then
				return true
			end
		end
		if C_SpellBook.FindSpellBookSlotForSpell then
			local ok, slot = pcall(C_SpellBook.FindSpellBookSlotForSpell, id)
			if ok and slot then
				return true
			end
		end
	end
	return false
end

function ns.API.Resolve(spellID)
	if not spellID then
		return nil
	end
	local cached = resolveCache[spellID]
	if cached ~= nil then
		return cached or nil
	end
	local id = spellID
	if C_Spell and C_Spell.GetOverrideSpell then
		local ok, over = pcall(C_Spell.GetOverrideSpell, spellID)
		if ok and type(over) == "number" and readable(over) then
			id = over
		end
	end
	if playerKnows(id) then
		resolveCache[spellID] = id
		return id
	end
	if id ~= spellID and playerKnows(spellID) then
		resolveCache[spellID] = spellID
		return spellID
	end
	local names = { ns.API.SpellName(id) or ns.API.SpellName(spellID) }
	local hints = ns.API.HintNames(spellID, id)
	for i = 1, #hints do
		names[#names + 1] = hints[i]
	end
	for i = 1, #names do
		local name = names[i]
		if type(name) == "string" and name ~= "" then
			local fromName = spellIdFromName(name)
			if fromName and playerKnows(fromName) then
				resolveCache[spellID] = fromName
				return fromName
			end
			local bookId = findPlayerSpellByName(name)
			if bookId then
				resolveCache[spellID] = bookId
				return bookId
			end
		end
	end
	resolveCache[spellID] = false
	return nil
end

function ns.API.Known(spellID)
	return ns.API.Resolve(spellID) ~= nil
end

local cdUntil = {}
local cdKnown = {}
local holdUntil = {}

local function cdKey(spellID)
	local name = ns.API.SpellName(spellID)
	if type(name) == "string" and name ~= "" then
		local n = strlower(name)
		n = n:gsub("%s*%([^%)]*%)", "")
		if strtrim then
			n = strtrim(n)
		end
		if n ~= "" then
			return n
		end
	end
	return "id:" .. tostring(spellID)
end

local function parseBaseCooldown(cd, gcd)
	cd = tonumber(safe(cd, nil))
	gcd = tonumber(safe(gcd, nil))
	if not cd or cd <= 0 then
		return 0
	end
	if cd < 500 then
		local gcdSec = gcd and gcd < 500 and gcd or 1.5
		if cd <= gcdSec + 0.05 or cd <= 1.5 then
			return 0
		end
		return cd
	end
	local gcdMs = gcd or 1500
	if cd <= gcdMs + 50 then
		return 0
	end
	return cd / 1000
end

local function baseCooldownSec(spellID)
	if GetSpellBaseCooldown then
		local ok, cd, gcd = pcall(GetSpellBaseCooldown, spellID)
		if ok then
			local sec = parseBaseCooldown(cd, gcd)
			if sec > 0 then
				return sec
			end
		end
	end
	if C_Spell and C_Spell.GetSpellBaseCooldown then
		local ok, cd, gcd = pcall(C_Spell.GetSpellBaseCooldown, spellID)
		if ok then
			if type(cd) == "table" then
				local sec = parseBaseCooldown(cd.duration or cd.cooldown, cd.gcd)
				if sec > 0 then
					return sec
				end
			else
				local sec = parseBaseCooldown(cd, gcd)
				if sec > 0 then
					return sec
				end
			end
		end
	end
	return 0
end

local function groupOf(spellID)
	local groups = ns.COOLDOWN_GROUPS
	if not groups then
		return nil
	end
	local castName = ns.API.SpellName(spellID)
	for _, group in ipairs(groups) do
		for _, id in ipairs(group.ids) do
			if id == spellID or (castName and ns.API.SpellName(id) == castName) then
				return group
			end
		end
	end
end

local function fallbackSeconds(spellID)
	local map = ns.COOLDOWNS
	if map and map[spellID] then
		return map[spellID]
	end
	local group = groupOf(spellID)
	if group and group.seconds then
		return group.seconds
	end
	local name = ns.API.SpellName(spellID)
	if map and name then
		for id, seconds in pairs(map) do
			if ns.API.SpellName(id) == name then
				return seconds
			end
		end
	end
	return 0
end

function ns.API.SpellCooldownSec(spellID)
	spellID = ns.API.Resolve(spellID) or spellID
	if not spellID then
		return 0
	end
	local sec = baseCooldownSec(spellID)
	if sec and sec > 0.2 then
		return sec
	end
	return fallbackSeconds(spellID) or 0
end

function ns.API.IsFallback(opt)
	opt = opt or {}
	return opt.filler == true or opt.swing == true
end

-- A filler listed first must yield to these when they are pressable.
-- Nukes without a cooldown (Starfire, Ice Lance, Swipe) stay list-order.
-- Auto-appended racials never steal a filler higher in the list.
function ns.API.IsRotationAction(spellID, opt, isRacial)
	if isRacial then
		return false
	end
	opt = opt or {}
	if ns.API.IsFallback(opt) then
		return false
	end
	if opt.heal or opt.nodebuff or opt.nobuff or opt.needbuff or opt.needdebuff then
		return true
	end
	if opt.proc or opt.usable or opt.comboMin then
		return true
	end
	if opt.nopet or opt.pet or opt.nocombat then
		return true
	end
	if opt.hp or opt.manaMax or opt.hpMin then
		return true
	end
	if opt.anybuff or opt.anydebuff then
		return true
	end
	local sec = ns.API.SpellCooldownSec(spellID)
	return sec and sec > 0.2
end

local function markCooldown(spellID, seconds)
	if not seconds or seconds <= 0.2 then
		return
	end
	local exp = GetTime() + seconds
	cdUntil[cdKey(spellID)] = exp
	cdUntil["id:" .. tostring(spellID)] = exp
	local group = groupOf(spellID)
	if not group then
		return
	end
	local groupExp = GetTime() + math.max(seconds, group.seconds or 0)
	for _, id in ipairs(group.ids) do
		cdUntil[cdKey(id)] = groupExp
		cdUntil["id:" .. tostring(id)] = groupExp
	end
end

function ns.API.NoteSpellCast(spellID)
	ns.API.lastCastAt = GetTime()
	if spellID == nil or (issecretvalue and issecretvalue(spellID)) then
		return
	end
	local key = cdKey(spellID)
	local seconds = baseCooldownSec(spellID)
	if seconds <= 0 and cdKnown[key] and cdKnown[key] > 1.5 then
		seconds = cdKnown[key]
	end
	if seconds <= 0 then
		seconds = fallbackSeconds(spellID)
	end
	markCooldown(spellID, seconds)
	local hold = ns.API.HoldSeconds(spellID)
	if hold and hold > 0 then
		ns.API.NoteSpellHold(spellID, hold)
	end
end

-- Re-suggest delay after cast (DoT / HoT / snare). Independent from real CD.
function ns.API.HoldSeconds(spellID)
	local resolved = ns.API.Resolve(spellID) or spellID
	if not resolved then
		return 0
	end
	local function fromStep(step)
		if not step or not step.id then
			return nil
		end
		local sid = ns.API.Resolve(step.id) or step.id
		if sid ~= resolved and step.id ~= spellID and step.id ~= resolved then
			return nil
		end
		if step.opt and step.opt.hold ~= nil then
			return tonumber(step.opt.hold) or 0
		end
		return nil
	end
	if ns.GetAPL then
		local apl = ns.GetAPL()
		for i = 1, #(apl or {}) do
			local hit = fromStep(apl[i])
			if hit ~= nil then
				return math.max(0, hit)
			end
		end
	end
	if ns.GetDef then
		local def = ns.GetDef()
		for i = 1, #(def or {}) do
			local hit = fromStep(def[i])
			if hit ~= nil then
				return math.max(0, hit)
			end
		end
	end
	if ns.SPELL_HOLD then
		local h = ns.SPELL_HOLD[resolved] or ns.SPELL_HOLD[spellID]
		if type(h) == "number" then
			return math.max(0, h)
		end
	end
	return 0
end

-- Target DoT / snare / mark holds bind to the mob GUID so a new target
-- (or a dead one) can be marked again. Self HoTs / Slice and Dice stay global.
local function holdTargetGuid()
	local ok, guid = pcall(UnitGUID, "target")
	if ok and readable(guid) and type(guid) == "string" then
		return guid
	end
	return nil
end

local function holdBindsToTarget(spellID)
	if ns.API.IsHelpful(spellID) and not ns.API.IsHarmful(spellID) then
		return false
	end
	return ns.API.IsHarmful(spellID) == true
end

local function unitIsDead(unit)
	if UnitIsDeadOrGhost then
		local ok, dead = pcall(UnitIsDeadOrGhost, unit)
		if ok and dead == true then
			return true
		end
		if ok and dead == false then
			return false
		end
	end
	if UnitIsDead then
		local ok, dead = pcall(UnitIsDead, unit)
		if ok and dead == true then
			return true
		end
	end
	return false
end

local function writeHold(spellID, exp, guid)
	local entry = { exp = exp, guid = guid }
	holdUntil[cdKey(spellID)] = entry
	holdUntil["id:" .. tostring(spellID)] = entry
	local resolved = ns.API.Resolve(spellID)
	if resolved and resolved ~= spellID then
		holdUntil[cdKey(resolved)] = entry
		holdUntil["id:" .. tostring(resolved)] = entry
	end
end

local function clearHoldKeys(spellID)
	holdUntil[cdKey(spellID)] = nil
	holdUntil["id:" .. tostring(spellID)] = nil
	local resolved = ns.API.Resolve(spellID)
	if resolved and resolved ~= spellID then
		holdUntil[cdKey(resolved)] = nil
		holdUntil["id:" .. tostring(resolved)] = nil
	end
end

local function clearTargetBoundHolds()
	for key, entry in pairs(holdUntil) do
		if type(entry) == "number" then
			holdUntil[key] = nil
		elseif type(entry) == "table" and entry.guid ~= "self" then
			holdUntil[key] = nil
		end
	end
end

function ns.API.NoteSpellHold(spellID, seconds)
	seconds = tonumber(seconds)
	if not spellID or not seconds or seconds <= 0 then
		return
	end
	local exp = GetTime() + seconds
	local guid = "self"
	if holdBindsToTarget(spellID) then
		guid = holdTargetGuid() or false
	end
	writeHold(spellID, exp, guid)
end

function ns.API.HoldRemain(spellID)
	if not spellID then
		return 0
	end
	local entry = holdUntil[cdKey(spellID)] or holdUntil["id:" .. tostring(spellID)]
	if not entry then
		local resolved = ns.API.Resolve(spellID)
		if resolved then
			entry = holdUntil[cdKey(resolved)] or holdUntil["id:" .. tostring(resolved)]
		end
	end
	if not entry then
		return 0
	end
	-- Legacy plain number = old global hold; keep time-only behaviour.
	local exp, guid
	if type(entry) == "number" then
		exp = entry
		guid = "self"
	elseif type(entry) == "table" then
		exp = entry.exp
		guid = entry.guid
	else
		clearHoldKeys(spellID)
		return 0
	end
	if not exp then
		clearHoldKeys(spellID)
		return 0
	end
	if guid ~= "self" then
		-- Bound to a mob: new target, no target, or dead sticky target → re-suggest.
		if guid == false or guid == nil then
			clearHoldKeys(spellID)
			return 0
		end
		local cur = holdTargetGuid()
		if not cur or cur ~= guid or unitIsDead("target") then
			clearHoldKeys(spellID)
			return 0
		end
	end
	local remain = exp - GetTime()
	if remain <= 0 then
		clearHoldKeys(spellID)
		return 0
	end
	return remain
end

local function trackedRemain(spellID)
	local exp = cdUntil[cdKey(spellID)] or cdUntil["id:" .. tostring(spellID)]
	if not exp then
		return 0
	end
	local remain = exp - GetTime()
	if remain <= 0 then
		cdUntil[cdKey(spellID)] = nil
		cdUntil["id:" .. tostring(spellID)] = nil
		return 0
	end
	return remain
end

local function readSpellCooldown(spellID)
	if not spellID or not C_Spell or not C_Spell.GetSpellCooldown then
		return 0, 0, true
	end
	local ok, info = pcall(C_Spell.GetSpellCooldown, spellID)
	if not ok or type(info) ~= "table" then
		return 0, 0, true
	end
	local start = info.startTime or info.start
	local duration = info.duration
	if (start ~= nil and not readable(start)) or (duration ~= nil and not readable(duration)) then
		return 0, 0, true
	end
	start = tonumber(start) or 0
	duration = tonumber(duration) or 0
	local remain = duration - (GetTime() - start)
	if remain < 0 then
		remain = 0
	end
	if duration > 0 and duration <= 1.51 then
		return 0, duration, false
	end
	return remain, duration, false
end

function ns.API.Cooldown(spellID)
	spellID = ns.API.Resolve(spellID) or spellID
	if not spellID then
		return 0, 0
	end
	local apiRemain, apiDuration, secret = readSpellCooldown(spellID)
	local key = cdKey(spellID)
	if not secret and apiDuration and apiDuration > 1.51 then
		cdKnown[key] = apiDuration
	end
	local tracked = trackedRemain(spellID)
	if predict then
		local pred = predict.cd[cdKey(spellID)] or predict.cd["id:" .. tostring(spellID)]
		if pred then
			local predRemain = pred - GetTime()
			if predRemain > tracked then
				tracked = predRemain
			end
		end
	end
	if tracked > 0.2 then
		return tracked, apiDuration > 0 and apiDuration or tracked
	end
	if secret then
		return 0, 0
	end
	return apiRemain, apiDuration
end

local function unitExists(unit)
	if not unit then
		return false
	end
	local ok, exists = pcall(UnitExists, unit)
	return ok and exists and true or false
end

local function unitFriendly(unit)
	if not unitExists(unit) then
		return false
	end
	local okDead, dead = pcall(UnitIsDead, unit)
	if okDead and dead then
		return false
	end
	local okAtk, atk = pcall(UnitCanAttack, "player", unit)
	if okAtk and readable(atk) and atk then
		return false
	end
	if okAtk and not readable(atk) then
		return false
	end
	local okR, react = pcall(UnitReaction, "player", unit)
	if okR and readable(react) and type(react) == "number" then
		return react > 4
	end
	if okAtk and readable(atk) and not atk then
		return true
	end
	return false
end

local function healNameSet()
	if healNames and next(healNames) then
		return healNames
	end
	healNames = {}
	for id in pairs(ns.HEAL_SPELL_IDS or {}) do
		local name = ns.API.SpellName(id)
		if name then
			healNames[name] = true
		end
	end
	return healNames
end

function ns.API.IsHelpful(spellID, opt)
	if opt and opt.heal then
		return true
	end
	local id = ns.API.Resolve(spellID) or spellID
	if ns.HEAL_SPELL_IDS and ((id and ns.HEAL_SPELL_IDS[id]) or (spellID and ns.HEAL_SPELL_IDS[spellID])) then
		return true
	end
	local name = ns.API.SpellName(id) or ns.API.SpellName(spellID)
	if name and healNameSet()[name] then
		return true
	end
	if C_Spell and C_Spell.IsSpellHelpful then
		local ok, helpful = pcall(C_Spell.IsSpellHelpful, id)
		if ok and helpful == true then
			return true
		end
	end
	if IsHelpfulSpell then
		local ok, helpful = pcall(IsHelpfulSpell, id)
		if ok and helpful == true then
			return true
		end
	end
	return false
end

function ns.API.IsHealSpell(spellID, opt)
	if opt and opt.heal then
		return true
	end
	if not spellID then
		return false
	end
	if ns.IsMaintenanceBuff and ns.IsMaintenanceBuff(spellID) then
		return false
	end
	if ns.IsWeaponBuff and ns.IsWeaponBuff(spellID) then
		return false
	end
	local id = ns.API.Resolve(spellID) or spellID
	if ns.HEAL_SPELL_IDS and ((id and ns.HEAL_SPELL_IDS[id]) or ns.HEAL_SPELL_IDS[spellID]) then
		return true
	end
	local name = ns.API.SpellName(id) or ns.API.SpellName(spellID)
	if name and healNameSet()[name] then
		return true
	end
	return false
end

function ns.API.IsHarmful(spellID)
	local id = ns.API.Resolve(spellID) or spellID
	if C_Spell and C_Spell.IsSpellHarmful then
		local ok, harmful = pcall(C_Spell.IsSpellHarmful, id)
		if ok and harmful == true then
			return true
		end
	end
	if IsHarmfulSpell then
		local ok, harmful = pcall(IsHarmfulSpell, id)
		if ok and harmful == true then
			return true
		end
	end
	return false
end

local function numberOrNil(value)
	value = safe(value, nil)
	if type(value) == "number" and value == value then
		return value
	end
	return nil
end

function ns.API.SpellMaxRange(spellID)
	local id = ns.API.Resolve(spellID) or spellID
	if not id then
		return nil
	end
	local info = ns.API.SpellInfo(id)
	if info then
		local maxR = numberOrNil(info.maxRange)
		if maxR ~= nil then
			return maxR
		end
	end
	if GetSpellInfo then
		local ok, _, _, _, _, minR, maxR = pcall(GetSpellInfo, id)
		if ok then
			maxR = numberOrNil(maxR)
			if maxR == nil then
				maxR = numberOrNil(minR)
			end
			if maxR ~= nil then
				return maxR
			end
		end
	end
	return nil
end

local function interactInRange(unit, index)
	if not CheckInteractDistance then
		return nil
	end
	local ok, result = pcall(CheckInteractDistance, unit, index)
	if not ok then
		return nil
	end
	result = safe(result, nil)
	if result == true or result == 1 then
		return true
	end
	if result == false or result == 0 then
		return false
	end
	return nil
end

function ns.API.TargetRangeBand(unit)
	unit = unit or "target"
	if not unitExists(unit) then
		return nil, nil
	end
	if UnitDistanceSquared then
		local ok, distSq = pcall(UnitDistanceSquared, unit)
		if ok then
			distSq = numberOrNil(distSq)
			if distSq and distSq >= 0 then
				local yards = math.sqrt(distSq)
				return yards, yards
			end
		end
	end
	-- Classic: 3 ~10 yd (duel), 2 ~11 yd (trade), 1 ~28 yd (inspect).
	local close = interactInRange(unit, 3)
	if close == nil then
		close = interactInRange(unit, 2)
	end
	local inspect = interactInRange(unit, 1)
	if close == true then
		return 0, 11
	end
	if inspect == true then
		return 11, 28
	end
	if inspect == false then
		return 28, 100
	end
	return nil, nil
end

local function rangeUnitFor(spellID, opt)
	opt = opt or {}
	if opt.heal or (ns.API.IsHelpful(spellID, opt) and not ns.API.IsHarmful(spellID)) then
		if ns.API.HealRangeUnit then
			return ns.API.HealRangeUnit(opt)
		end
		return "player"
	end
	return "target"
end

function ns.API.NeedsRange(spellID, opt)
	opt = opt or {}
	if opt.nopet or opt.nocombat then
		return false
	end
	local id = ns.API.Resolve(spellID) or spellID
	if opt.heal then
		local unit = rangeUnitFor(id, opt)
		return unit ~= "player"
	end
	if opt.hostile then
		return true
	end
	if ns.API.IsHarmful(id) then
		return true
	end
	return false
end

-- "none" = no check, "in" / "out" / "unknown".
-- Unknown is never treated as in-range for the first HUD slot.
function ns.API.RangeState(spellID, opt)
	opt = opt or {}
	local id = ns.API.Resolve(spellID) or spellID
	if not id or not ns.API.NeedsRange(id, opt) then
		return "none"
	end
	local unit = rangeUnitFor(id, opt)
	if not unitExists(unit) then
		return "out"
	end
	local slot = ns.SpellBarSlot and ns.SpellBarSlot(id)
	local flag
	if ns.SpellInRange then
		flag = ns.SpellInRange(id, slot)
	end
	if flag == true then
		return "in"
	end
	if flag == false then
		return "out"
	end
	local maxR = ns.API.SpellMaxRange(id)
	if maxR == 0 and ns.API.IsHarmful(id) then
		maxR = 5
	end
	local minY, maxY = ns.API.TargetRangeBand(unit)
	if minY and maxR and minY >= maxR then
		return "out"
	end
	if maxY and maxR and maxY <= maxR then
		return "in"
	end
	return "unknown"
end

-- mode: "in" (slot 1), "notOut" (unknown allowed), "any" (lookahead / OOR).
function ns.API.InSpellRange(spellID, opt, mode)
	mode = mode or "in"
	local state = ns.API.RangeState(spellID, opt)
	if state == "none" or state == "in" then
		return true
	end
	if state == "out" then
		return mode == "any"
	end
	return mode ~= "in"
end

function ns.API.HealUnit(opt)
	opt = opt or {}
	if opt.unit and unitExists(opt.unit) then
		return opt.unit
	end
	for _, unit in ipairs({ "mouseover", "target", "focus", "targettarget" }) do
		if unitFriendly(unit) then
			return unit
		end
	end
	return "player"
end

function ns.API.HealHealth(opt)
	opt = opt or {}
	if opt.unit and unitExists(opt.unit) then
		return ns.API.Health(opt.unit)
	end
	for _, unit in ipairs({ "mouseover", "target", "focus" }) do
		if unitFriendly(unit) then
			return ns.API.Health(unit)
		end
	end
	local _, hp = ns.API.LowestFriendly()
	return hp
end

function ns.API.HealRangeUnit(opt)
	opt = opt or {}
	if opt.unit and unitExists(opt.unit) then
		return opt.unit
	end
	for _, unit in ipairs({ "mouseover", "target", "focus", "targettarget" }) do
		if unitFriendly(unit) then
			return unit
		end
	end
	local unit = ns.API.LowestFriendly()
	return unit or "player"
end

function ns.API.LowestFriendly()
	local best, bestHp = "player", ns.API.Health("player")
	local units = {
		"player",
		"mouseover",
		"target",
		"focus",
		"targettarget",
		"pet",
		"party1",
		"party2",
		"party3",
		"party4",
	}
	for _, unit in ipairs(units) do
		if unitFriendly(unit) then
			local hp = ns.API.Health(unit)
			if hp < bestHp then
				best, bestHp = unit, hp
			end
		end
	end
	return best, bestHp
end

local function hasResources(id)
	if C_Spell and C_Spell.GetSpellPowerCost then
		local ok, costs = pcall(C_Spell.GetSpellPowerCost, id)
		if ok and type(costs) == "table" then
			for _, cost in ipairs(costs) do
				if type(cost) == "table" then
					local needed = tonumber(safe(cost.cost, nil))
					local ptype = tonumber(safe(cost.type, nil)) or 0
					if needed and needed > 0 then
						local cur = safe(UnitPower("player", ptype), nil)
						if type(cur) == "number" and cur < needed then
							return false
						end
					end
				end
			end
		end
	end
	return true
end

local function readUsable(fn, id)
	if not fn then
		return nil, nil
	end
	local ok, usable, noMana = pcall(fn, id)
	if not ok then
		return nil, nil
	end
	return safe(usable, nil), safe(noMana, nil)
end

function ns.API.Ready(spellID, opt, ignoreCooldown)
	local id = ns.API.Resolve(spellID)
	if not id then
		return false
	end
	if not ignoreCooldown then
		local remain = ns.API.Cooldown(id)
		if remain > 0.2 then
			return false
		end
	end
	local helpfulOnly = ns.API.IsHelpful(id, opt) and not ns.API.IsHarmful(id)
	local usable, noMana = readUsable(C_Spell and C_Spell.IsSpellUsable, id)
	if usable == nil and noMana == nil then
		usable, noMana = readUsable(IsUsableSpell, id)
	end
	if noMana == true then
		return false
	end
	if usable == true then
		return true
	end
	if helpfulOnly then
		return hasResources(id)
	end
	-- Camelot marks other spells unusable during a cast or GCD. Fillers
	-- already bypass this; shocks and DoTs must still enter the lookahead.
	if usable == false then
		if ns.API.CastRemain() > 0 then
			return hasResources(id)
		end
		local last = ns.API.lastCastAt
		if last and (GetTime() - last) < 1.55 then
			return hasResources(id)
		end
		return false
	end
	return hasResources(id)
end

function ns.API.StepOk(spellID, opt, timeShift)
	spellID = ns.API.Resolve(spellID) or spellID
	if not spellID or not ns.API.Known(spellID) then
		return false
	end
	opt = opt or {}
	local gate = tonumber(timeShift) or 0.2
	if gate < 0.2 then
		gate = 0.2
	end
	-- Player/configurable reapply delay (Frostbolt chill, DoTs, HoTs…).
	local holdLeft = ns.API.HoldRemain(spellID)
	if holdLeft > gate then
		return false
	end
	if opt.hostile and not ns.API.Hostile() then
		return false
	end
	local helpful = ns.API.IsHelpful(spellID, opt)
	local auraUnit = helpful and ns.API.HealUnit(opt) or "player"
	if opt.nobuff then
		local buffUnit = "player"
		if opt.heal then
			buffUnit = opt.unit or auraUnit
		end
		if ns.API.HasAura(spellID, buffUnit, "HELPFUL") then
			return false
		end
	end
	if opt.nodebuff then
		local debuff = opt.nodebuff == true and spellID or opt.nodebuff
		local debuffUnit = opt.unit or (helpful and auraUnit or "target")
		if ns.API.HasAura(debuff, debuffUnit, "HARMFUL") then
			return false
		end
	end
	local needHp = opt.hp
	if not needHp and (opt.heal or ns.API.IsHealSpell(spellID, opt)) then
		needHp = 99
	end
	if needHp then
		local hp
		if opt.unit then
			hp = ns.API.Health(opt.unit)
		elseif helpful or opt.heal then
			hp = ns.API.HealHealth(opt)
		else
			hp = ns.API.Health("player")
		end
		if hp > needHp then
			return false
		end
	end
	if opt.form and not ns.API.Form(opt.form) then
		return false
	end
	if opt.noform and ns.API.Form(opt.noform) then
		return false
	end
	if opt.combat and not ns.API.InCombat() then
		return false
	end
	if opt.comboMin and ns.API.Combo() < opt.comboMin then
		return false
	end
	if opt.pet and not unitExists("pet") then
		return false
	end
	if opt.nopet and unitExists("pet") then
		return false
	end
	if opt.nocombat and ns.API.InCombat() then
		return false
	end
	if opt.needbuff and not ns.API.HasAura(opt.needbuff, "player", "HELPFUL") then
		return false
	end
	-- require / requireAny are NOT used to hide list spells. List order is
	-- authoritative: if the player put Frostbolt above Fireball, Frostbolt wins
	-- when it is known and ready. School gating lived here before and skipped
	-- fillers the player had explicitly ordered.
	if opt.needdebuff and not ns.API.HasAura(opt.needdebuff, opt.unit or "target", "HARMFUL") then
		return false
	end
	if opt.proc or opt.usable then
		local usable = readUsable(C_Spell and C_Spell.IsSpellUsable, spellID)
		if usable == nil then
			usable = readUsable(IsUsableSpell, spellID)
		end
		if usable ~= true then
			-- Procs stay strict. Positional spells (Backstab, Exorcism) follow
			-- the same GCD/cast window as Ready(), so they still enter slot 2–3.
			if opt.proc then
				return false
			end
			if ns.API.CastRemain() <= 0 then
				local last = ns.API.lastCastAt
				if not last or (GetTime() - last) >= 1.55 then
					return false
				end
			end
		end
	end
	if opt.manaMax then
		local okCur, current = pcall(UnitPower, "player", 0)
		local okMax, maxp = pcall(UnitPowerMax, "player", 0)
		if not okCur or not okMax or not readable(current) or not readable(maxp) or maxp <= 0 or (current / maxp) * 100 > opt.manaMax then
			return false
		end
	end
	if opt.hpMin then
		local hp = ns.API.Health(opt.unit or "player")
		if hp < opt.hpMin then
			return false
		end
	end
	if opt.anybuff then
		for _, other in ipairs(opt.anybuff) do
			if ns.API.HasAura(other, "player", "HELPFUL") then
				return false
			end
		end
	end
	if opt.anydebuff then
		for _, other in ipairs(opt.anydebuff) do
			if ns.API.HasAura(other, opt.unit or "target", "HARMFUL") then
				return false
			end
		end
	end
	local remain = ns.API.Cooldown(spellID)
	if ns.API.CastingSpell(spellID) then
		remain = 0
	else
		local castLeft = ns.API.CastRemain()
		if castLeft > 0 and remain > 0 and remain <= castLeft + 0.45 then
			remain = 0
		end
	end
	if not opt.swing and remain > gate then
		return false
	end
	if opt.ready == false then
		return true
	end
	if ns.Physics and ns.Physics.IsClip and ns.Physics.IsClip(spellID) and ns.Physics.WouldClip and ns.Physics.WouldClip() then
		return false
	end
	if ns.API.Ready(spellID, opt, true) or opt.filler == true or opt.swing == true then
		return true
	end
	-- Out of range is still a queue candidate for slots 2–3. Slot 1
	-- requires RangeState "in" separately. IsSpellUsable is false when OOR.
	if hasResources(spellID) and ns.API.RangeState then
		local reach = ns.API.RangeState(spellID, opt)
		if reach == "out" or reach == "unknown" then
			return true
		end
	end
	if ns.Physics and ns.Physics.EnergySoon and ns.Physics.EnergySoon(spellID) then
		return true
	end
	return false
end

local function auraRemain(aura)
	if not aura then
		return 0
	end
	local exp = safe(aura.expirationTime, nil)
	if exp and exp > 0 then
		local remain = exp - GetTime()
		if remain < 0 then
			remain = 0
		end
		return remain
	end
	return 9999
end

-- Familles de buffs exclusifs. Un sceau actif (quel que soit son ID de rang)
-- compte pour tous les sceaux : le client Forever masque souvent l'ID d'aura
-- dès qu'une cible est sélectionnée.
local AURA_FAMILIES = {
	{ key = "seal", tokens = { "sceau", "seal", "siegel", "sello", "sigillo", "печать" } },
	{ key = "blessing", tokens = { "bénédiction", "benediction", "blessing", "segen", "bendición", "benedizione", "bênção", "благословен" } },
	{ key = "palaura", tokens = { "aura" } },
	{ key = "aspect", tokens = { "aspect" } },
	{ key = "magearmor", tokens = { "ice armor", "frost armor", "mage armor", "armure de givre", "armure de glace", "armure du mage", "eisrüstung", "frostrüstung", "magierrüstung" } },
	{ key = "lockarmor", tokens = { "demon skin", "demon armor", "peau de démon", "armure démoniaque", "dämonenhaut", "dämonenrüstung" } },
}

local heldNames = {}
local heldFamilies = {}
local buffCastAt = {}

local FAMILY_SECONDS = {
	seal = 30,
	blessing = 300,
	palaura = 1800,
	aspect = 1800,
	magearmor = 1800,
	lockarmor = 1800,
}

local function normName(name)
	local n = strlower(name)
	n = n:gsub("%s*%([^%)]*%)", "")
	n = strtrim(n)
	return n
end

local function rawCombo()
	if not GetComboPoints then
		return 0
	end
	local ok, points = pcall(GetComboPoints, "player", "target")
	if ok and type(points) == "number" then
		return points
	end
	return 0
end

function ns.API.PredictBegin()
	predict = { debuffs = {}, buffs = {}, cd = {}, usedBuffs = {}, combo = rawCombo(), taken = 0 }
end

function ns.API.PredictEnd()
	predict = nil
end

local function predictMarkDebuff(spellID)
	if not predict or not spellID then
		return
	end
	predict.debuffs[spellID] = true
	local name = ns.API.SpellName(spellID)
	if type(name) == "string" and name ~= "" then
		predict.debuffs[normName(name)] = true
	end
end

local function predictMarkBuff(spellID)
	if not predict or not spellID then
		return
	end
	predict.buffs[spellID] = true
	local name = ns.API.SpellName(spellID)
	if type(name) == "string" and name ~= "" then
		predict.buffs[normName(name)] = true
	end
end

local function isComboBuilder(spellID)
	local builders = ns.COMBO_BUILDERS
	if not builders or not spellID then
		return false
	end
	if builders[spellID] then
		return true
	end
	local name = ns.API.SpellName(spellID)
	if type(name) ~= "string" or name == "" then
		return false
	end
	for id in pairs(builders) do
		if ns.API.SpellName(id) == name then
			return true
		end
	end
	return false
end

function ns.API.PredictConsume(spellID, opt)
	if not predict then
		return
	end
	spellID = ns.API.Resolve(spellID) or spellID
	opt = opt or {}
	predict.taken = (predict.taken or 0) + 1
	if opt.nodebuff then
		local debuff = opt.nodebuff == true and spellID or opt.nodebuff
		predictMarkDebuff(debuff)
		predictMarkDebuff(spellID)
	end
	if type(opt.anydebuff) == "table" then
		for _, id in ipairs(opt.anydebuff) do
			predictMarkDebuff(id)
		end
	end
	if opt.needdebuff then
		predictMarkDebuff(opt.needdebuff)
	end
	if opt.nobuff then
		predictMarkBuff(spellID)
	end
	if type(opt.anybuff) == "table" then
		for _, id in ipairs(opt.anybuff) do
			predictMarkBuff(id)
		end
	end
	if opt.needbuff then
		predict.usedBuffs[opt.needbuff] = true
		local name = ns.API.SpellName(opt.needbuff)
		if type(name) == "string" and name ~= "" then
			predict.usedBuffs[normName(name)] = true
		end
	end
	if opt.comboMin then
		predict.combo = 0
	elseif isComboBuilder(spellID) then
		predict.combo = math.min(5, (predict.combo or 0) + 1)
	end
	if opt.filler == true or opt.swing == true then
		return
	end
	local seconds = ns.API.SpellCooldownSec(spellID)
	if not seconds or seconds <= 0.2 then
		return
	end
	local exp = GetTime() + seconds
	predict.cd[cdKey(spellID)] = exp
	predict.cd["id:" .. tostring(spellID)] = exp
	local group = groupOf(spellID)
	if not group then
		return
	end
	for _, id in ipairs(group.ids) do
		predict.cd[cdKey(id)] = exp
		predict.cd["id:" .. tostring(id)] = exp
	end
end

local function targetGuid()
	local ok, guid = pcall(UnitGUID, "target")
	if ok and readable(guid) and type(guid) == "string" then
		return guid
	end
	return nil
end

function ns.API.ClearTargetDebuffs()
	wipe(heldHarmful)
	heldHarmfulGuid = nil
	clearTargetBoundHolds()
end

function ns.API.NoteTargetDebuff(spellID)
	if spellID == nil or (issecretvalue and issecretvalue(spellID)) then
		return
	end
	local okExists, exists = pcall(UnitExists, "target")
	if not okExists or not exists then
		return
	end
	local guid = targetGuid()
	if heldHarmfulGuid and guid and heldHarmfulGuid ~= guid then
		wipe(heldHarmful)
	end
	heldHarmfulGuid = guid
	local name = ns.API.SpellName(spellID)
	local exp = GetTime() + 18
	if type(name) == "string" and name ~= "" then
		heldHarmful[normName(name)] = exp
	end
	if type(spellID) == "number" then
		heldHarmful["id:" .. tostring(spellID)] = exp
		local resolved = ns.API.Resolve(spellID)
		if resolved and resolved ~= spellID then
			heldHarmful["id:" .. tostring(resolved)] = exp
		end
	end
end

local function heldHarmfulAura(spellID)
	local now = GetTime()
	if type(spellID) == "number" then
		local exp = heldHarmful["id:" .. tostring(spellID)]
		if exp and now < exp then
			return true
		end
	end
	local name = ns.API.SpellName(spellID)
	if type(name) ~= "string" or name == "" then
		return false
	end
	local exp = heldHarmful[normName(name)]
	return exp and now < exp or false
end

local function familyOf(name)
	if type(name) ~= "string" or name == "" then
		return nil
	end
	local n = normName(name)
	for _, family in ipairs(AURA_FAMILIES) do
		for _, token in ipairs(family.tokens) do
			if n:find(token, 1, true) then
				return family.key
			end
		end
	end
end

local function auraIdentity(aura)
	if type(aura) ~= "table" then
		return nil, nil, false
	end
	local auraID = safe(aura.spellId, nil)
	local auraName = safe(aura.name, nil)
	local hidden = (aura.spellId ~= nil and auraID == nil) or (aura.name ~= nil and auraName == nil)
	if not hidden and auraID == nil and auraName == nil then
		hidden = true
	end
	return auraID, auraName, hidden
end

local function rememberAura(spellID, auraName, remain, fromCast)
	local name = auraName or ns.API.SpellName(spellID)
	if type(name) ~= "string" or name == "" then
		return
	end
	local key = normName(name)
	local family = familyOf(name)
	local seconds = (family and FAMILY_SECONDS[family]) or 30
	local exp
	if remain and remain > 0 and remain < 9000 then
		exp = GetTime() + remain
	elseif fromCast or not heldNames[key] or heldNames[key] <= GetTime() then
		exp = GetTime() + seconds
	end
	if exp then
		heldNames[key] = exp
		if family then
			heldFamilies[family] = exp
		end
	end
	if fromCast then
		buffCastAt[key] = GetTime()
		if family then
			buffCastAt[family] = GetTime()
		end
	end
end

function ns.API.NoteSelfBuff(spellID)
	if spellID == nil or (issecretvalue and issecretvalue(spellID)) then
		return
	end
	rememberAura(spellID, nil, nil, true)
end

local function heldAura(spellID, wantName)
	local name = wantName or ns.API.SpellName(spellID)
	if type(name) ~= "string" or name == "" then
		return false
	end
	local now = GetTime()
	local exp = heldNames[normName(name)]
	if exp and now < exp then
		return true
	end
	local family = familyOf(name)
	exp = family and heldFamilies[family]
	return exp and now < exp or false
end

local function releaseAura(spellID, wantName, familiesSeen)
	local name = wantName or ns.API.SpellName(spellID)
	if type(name) ~= "string" or name == "" then
		return
	end
	local key = normName(name)
	local stamped = buffCastAt[key]
	if stamped and (GetTime() - stamped) < 1 then
		return
	end
	heldNames[key] = nil
	local family = familyOf(name)
	if family and not (familiesSeen and familiesSeen[family]) then
		local famStamp = buffCastAt[family]
		if not famStamp or (GetTime() - famStamp) >= 1 then
			heldFamilies[family] = nil
		end
	end
end

local function scanUnitAuras(unit, filter)
	local now = GetTime()
	local key = (unit or "") .. "\0" .. (filter or "")
	local hit = auraScans[key]
	if hit and (now - hit.t) < 0.2 then
		return hit
	end
	local scan = {
		t = now,
		unit = unit,
		filter = filter,
		names = {},
		ids = {},
		families = {},
		unreadable = false,
	}
	auraScans[key] = scan
	if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex then
		scan.unreadable = true
		return scan
	end
	for i = 1, 40 do
		local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, filter)
		if not ok then
			scan.unreadable = true
			break
		end
		if not aura then
			if i == 1 and (next(heldNames) or next(heldFamilies)) then
				local busy = ns.API.InCombat and ns.API.InCombat()
				if not busy then
					local okE, exists = pcall(UnitExists, "target")
					busy = okE and exists and true or false
				end
				if busy then
					scan.unreadable = true
				end
			end
			break
		end
		local auraID, auraName, hidden = auraIdentity(aura)
		if hidden then
			scan.unreadable = true
		else
			if auraID then
				scan.ids[auraID] = aura
			end
			if auraName then
				scan.names[normName(auraName)] = aura
				local family = familyOf(auraName)
				if family then
					scan.families[family] = aura
				end
			end
		end
	end
	return scan
end

local function auraBySpellName(unit, name, filter)
	if type(name) ~= "string" or name == "" or not C_UnitAuras then
		return nil
	end
	if C_UnitAuras.GetAuraDataBySpellName then
		local ok, aura = pcall(C_UnitAuras.GetAuraDataBySpellName, unit, name, filter)
		if ok and type(aura) == "table" then
			return aura
		end
	end
	if AuraUtil and AuraUtil.FindAuraByName then
		local ok, auraName, _, _, _, _, _, _, _, auraID = pcall(AuraUtil.FindAuraByName, name, unit, filter)
		if ok and (auraName or auraID) then
			return { name = auraName, spellId = auraID }
		end
	end
end

function ns.API.HasAura(spellID, unit, filter)
	unit = unit or "player"
	filter = filter or "HELPFUL"
	if predict then
		local resolved = ns.API.Resolve(spellID) or spellID
		local name = ns.API.SpellName(resolved or spellID)
		local key = type(name) == "string" and name ~= "" and normName(name) or nil
		if filter == "HELPFUL" and unit == "player" then
			if (resolved and predict.usedBuffs[resolved]) or (spellID and predict.usedBuffs[spellID]) or (key and predict.usedBuffs[key]) then
				return false, 0
			end
		end
		if filter == "HARMFUL" and (unit == "target" or unit == "") then
			if (resolved and predict.debuffs[resolved]) or (spellID and predict.debuffs[spellID]) or (key and predict.debuffs[key]) then
				return true, 9999
			end
		end
		if filter == "HELPFUL" and unit == "player" then
			if (resolved and predict.buffs[resolved]) or (spellID and predict.buffs[spellID]) or (key and predict.buffs[key]) then
				return true, 9999
			end
		end
	end
	local found, remain, unreadable, familiesSeen = ns.API.FindAura(spellID, unit, filter)
	local selfBuff = unit == "player" and filter == "HELPFUL"
	local targetHarm = unit == "target" and filter == "HARMFUL"
	if targetHarm then
		local guid = targetGuid()
		if heldHarmfulGuid and guid and heldHarmfulGuid ~= guid then
			wipe(heldHarmful)
			heldHarmfulGuid = guid
		end
	end
	if found then
		if selfBuff then
			rememberAura(spellID, nil, remain, false)
		end
		if targetHarm then
			ns.API.NoteTargetDebuff(spellID)
		end
		return true, remain
	end
	if selfBuff and unreadable and heldAura(spellID) then
		return true, 9999
	end
	if targetHarm and unreadable and heldHarmfulAura(spellID) then
		return true, 9999
	end
	if selfBuff and not unreadable then
		releaseAura(spellID, nil, familiesSeen)
	end
	return false, 0
end

function ns.API.FindAura(spellID, unit, filter)
	if not spellID then
		return false, 0, false, nil
	end
	unit = unit or "player"
	filter = filter or "HELPFUL"
	local resolved = ns.API.Resolve(spellID)
	local wantName = ns.API.SpellName(resolved or spellID) or ns.API.SpellName(spellID)
	local wantKey = type(wantName) == "string" and normName(wantName) or nil
	local wantFamily = familyOf(wantName)

	if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID and unit == "player" then
		for _, id in ipairs({ resolved, spellID }) do
			if id then
				local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, id)
				if ok and type(aura) == "table" then
					return true, auraRemain(aura), false, nil
				end
			end
		end
	end

	if wantName then
		local named = auraBySpellName(unit, wantName, filter)
		if named then
			local _, _, hidden = auraIdentity(named)
			if not hidden then
				return true, auraRemain(named), false, nil
			end
		end
	end

	local scan = scanUnitAuras(unit, filter)
	if wantKey and scan.names[wantKey] then
		return true, auraRemain(scan.names[wantKey]), false, scan.families
	end
	if resolved and scan.ids[resolved] then
		return true, auraRemain(scan.ids[resolved]), false, scan.families
	end
	if spellID and scan.ids[spellID] then
		return true, auraRemain(scan.ids[spellID]), false, scan.families
	end
	if wantFamily and scan.families[wantFamily] then
		return true, auraRemain(scan.families[wantFamily]), false, scan.families
	end
	return false, 0, scan.unreadable, scan.families
end

function ns.API.HasWeaponBuff(entry)
	if not entry then
		return false, 0
	end
	local ids = { entry.id }
	if entry.ranks then
		for _, id in ipairs(entry.ranks) do
			ids[#ids + 1] = id
		end
	end
	for _, id in ipairs(ids) do
		local found, remain = ns.API.FindAura(id, "player", "HELPFUL")
		if found then
			return true, remain
		end
	end
	return false, 0
end

function ns.API.Hostile()
	if not UnitExists("target") then
		return false
	end
	local dead = UnitIsDead("target")
	if readable(dead) and dead then
		return false
	end
	local reaction = UnitReaction("player", "target")
	if not readable(reaction) then
		return true
	end
	return reaction <= 4
end

function ns.API.Health(unit)
	unit = unit or "player"
	local health = safe(UnitHealth(unit), nil)
	local max = safe(UnitHealthMax(unit), nil)
	if not health or not max or max <= 0 then
		return 100
	end
	return (health / max) * 100
end

function ns.API.InCombat()
	local ok, combat = pcall(UnitAffectingCombat, "player")
	if ok and readable(combat) then
		return combat and true or false
	end
	return ok and combat and true or false
end

local EAT_AURA = {
	food = true,
	drink = true,
	nourriture = true,
	boisson = true,
	essen = true,
	trinken = true,
	comida = true,
	bebida = true,
}

function ns.API.IsEating()
	if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex then
		return false
	end
	for i = 1, 40 do
		local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
		if not ok or not aura then
			break
		end
		local name = safe(aura.name, nil)
		if name then
			if EAT_AURA[strlower(name)] then
				return true
			end
		end
	end
	return false
end

function ns.API.ShouldHideIdle()
	if not ns.db or ns.db.hideIdle ~= true then
		return false
	end
	local function yes(fn, ...)
		if type(fn) ~= "function" then
			return false
		end
		local ok, value = pcall(fn, ...)
		return ok and value == true
	end
	if yes(UnitIsDeadOrGhost, "player") or yes(UnitOnTaxi, "player") or yes(IsMounted) then
		return true
	end
	if ns.API.IsEating() == true then
		return true
	end
	if not ns.API.InCombat() and yes(IsResting) then
		return true
	end
	return false
end

function ns.API.UnitFriendly(unit)
	return unitFriendly(unit)
end

function ns.API.CastRemain()
	local function remain(fn)
		if not fn then
			return 0
		end
		local ok, name, _, _, _, endTime = pcall(fn, "player")
		if not ok or name == nil then
			return 0
		end
		if issecretvalue and issecretvalue(name) then
			return 0
		end
		endTime = tonumber(safe(endTime, nil))
		if not endTime then
			return 0
		end
		if endTime > 100000 then
			endTime = endTime / 1000
		end
		local left = endTime - GetTime()
		if left < 0 then
			return 0
		end
		return left
	end
	local cast = remain(UnitCastingInfo)
	if cast > 0 then
		return cast
	end
	return remain(UnitChannelInfo)
end

function ns.API.CastingSpell(spellID)
	local name = ns.API.SpellName(spellID)
	if type(name) ~= "string" or name == "" then
		return false
	end
	local function same(fn)
		if not fn then
			return false
		end
		local ok, castName = pcall(fn, "player")
		if not ok or type(castName) ~= "string" or castName == "" then
			return false
		end
		if issecretvalue and issecretvalue(castName) then
			return false
		end
		return castName == name
	end
	return same(UnitCastingInfo) or same(UnitChannelInfo)
end

function ns.API.TargetCasting()
	if not UnitExists("target") then
		return false
	end
	local function peek(fn)
		if not fn then
			return false, nil
		end
		local ok, name, _, _, _, _, extraA, extraB = pcall(fn, "target")
		if not ok or name == nil then
			return false, nil
		end
		local notKick = extraB
		if fn == UnitChannelInfo then
			notKick = extraA
		end
		if readable(notKick) and notKick then
			return false, true
		end
		return true, false
	end
	local casting = peek(UnitCastingInfo)
	if casting then
		return true
	end
	casting = peek(UnitChannelInfo)
	if casting then
		return true
	end
	return ns.API.castTarget == true
end

function ns.API.TargetCastProgress()
	if not UnitExists or not UnitExists("target") then
		return nil
	end
	local function millis(value)
		if not readable(value) then
			return nil
		end
		local ok, n = pcall(function()
			local v = tonumber(value)
			if type(v) ~= "number" then
				return nil
			end
			return v + 0
		end)
		if ok and type(n) == "number" then
			return n
		end
		return nil
	end
	local function slice(fn, channel)
		if type(fn) ~= "function" then
			return nil
		end
		local pack = { pcall(fn, "target") }
		if not pack[1] or not readable(pack[2]) then
			return nil
		end
		local notKick = channel and pack[8] or pack[9]
		if readable(notKick) and notKick then
			return nil
		end
		local startMS = millis(pack[5])
		local endMS = millis(pack[6])
		if not startMS or not endMS or endMS <= startMS then
			return nil
		end
		local span = endMS - startMS
		local progress = ((GetTime() * 1000) - startMS) / span
		if progress < 0 then
			progress = 0
		end
		if progress > 1 then
			progress = 1
		end
		return progress
	end
	local cast = slice(UnitCastingInfo, false)
	if cast then
		return cast
	end
	return slice(UnitChannelInfo, true)
end

function ns.API.Purgable(stealableOnly)
	if not UnitExists("target") or not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex then
		return false
	end
	for i = 1, 40 do
		local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, "target", i, "HELPFUL")
		if not ok or not aura then
			break
		end
		if stealableOnly then
			if readable(aura.isStealable) and aura.isStealable then
				return true
			end
		else
			if readable(aura.isStealable) and aura.isStealable then
				return true
			end
			local dispel = safe(aura.dispelName, nil)
			if dispel == "Magic" then
				return true
			end
		end
	end
	return false
end

function ns.API.HasDebuffType(types, unit)
	if not types or not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex then
		return false
	end
	if unit and unit ~= "player" and not unitFriendly(unit) then
		return false
	end
	unit = unit or "player"
	local want = {}
	for _, name in ipairs(types) do
		want[name] = true
	end
	for i = 1, 40 do
		local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, "HARMFUL")
		if not ok or not aura then
			break
		end
		local dispel = safe(aura.dispelName, nil)
		if dispel and want[dispel] then
			return true
		end
	end
	return false
end

local function asNumber(value)
	if readable(value) and type(value) == "number" then
		return value
	end
	local ok, n = pcall(tonumber, value)
	if ok and type(n) == "number" then
		return n
	end
	return nil
end

local function pickField(t, key, index)
	if type(t) ~= "table" then
		return nil
	end
	if t[key] ~= nil then
		return t[key]
	end
	return t[index]
end

local function interpretEnchant(has, remainRaw, enchRaw)
	if type(has) == "table" then
		local t = has
		has = pickField(t, "hasMainHandEnchant", 1)
		remainRaw = pickField(t, "mainHandExpiration", 2)
		enchRaw = pickField(t, "mainHandEnchantID", 4)
	end
	local remain = asNumber(remainRaw)
	local enchId = asNumber(enchRaw)
	if remain then
		if remain > 10000 then
			remain = remain / 1000
		end
	else
		remain = 0
	end
	if enchId and enchId > 0 then
		return true, remain > 0 and remain or 9999, enchId
	end
	if type(has) == "table" then
		return nil, 0, nil
	end
	if readable(has) then
		if has then
			return true, remain > 0 and remain or 9999, nil
		end
		return false, 0, 0
	end
	return nil, 0, nil
end

local function readWeaponEnchant(offhand)
	local packs = {}
	local function push(ok, a, b, c, d, e, f, g, h)
		if ok then
			packs[#packs + 1] = { a, b, c, d, e, f, g, h }
		end
	end
	if GetWeaponEnchantInfo then
		push(pcall(GetWeaponEnchantInfo))
	end
	if C_Item and C_Item.GetWeaponEnchantInfo then
		push(pcall(C_Item.GetWeaponEnchantInfo))
	end
	local bestHas, bestRemain, bestId
	local sawFalse = false
	local sawUnknown = false
	for _, src in ipairs(packs) do
		local has, remain, enchId
		if type(src[1]) == "table" then
			local t = src[1]
			if offhand then
				has, remain, enchId = interpretEnchant(pickField(t, "hasOffHandEnchant", 5), pickField(t, "offHandExpiration", 6), pickField(t, "offHandEnchantID", 8))
			else
				has, remain, enchId = interpretEnchant(t)
			end
		elseif offhand then
			has, remain, enchId = interpretEnchant(src[5], src[6], src[8])
		else
			has, remain, enchId = interpretEnchant(src[1], src[2], src[4])
		end
		if has == true then
			return true, remain, enchId
		end
		if has == false then
			sawFalse = true
		else
			sawUnknown = true
			if bestHas == nil then
				bestHas, bestRemain, bestId = has, remain, enchId
			end
		end
	end
	if sawUnknown then
		return bestHas, bestRemain or 0, bestId
	end
	if sawFalse then
		return false, 0, 0
	end
	return bestHas, bestRemain or 0, bestId
end

function ns.API.WeaponEnchant(offhand)
	return readWeaponEnchant(offhand and true or false)
end

local tooltipCacheAt = 0
local tooltipCacheTexts

local function collectWeaponTooltipTexts()
	local now = GetTime()
	if tooltipCacheTexts and (now - tooltipCacheAt) < 1 then
		return tooltipCacheTexts
	end
	local texts = {}
	local function readSlot(slot)
		if not C_TooltipInfo or not C_TooltipInfo.GetInventoryItem then
			return
		end
		local ok, data = pcall(C_TooltipInfo.GetInventoryItem, "player", slot)
		if ok and type(data) == "table" and data.lines then
			for _, line in ipairs(data.lines) do
				local text = safe(line.leftText, nil)
				if text then
					texts[#texts + 1] = strlower(text)
				end
			end
		end
	end
	readSlot(16)
	readSlot(17)
	tooltipCacheAt = now
	tooltipCacheTexts = texts
	return texts
end

function ns.API.ClearWeaponTooltipCache()
	tooltipCacheAt = 0
	tooltipCacheTexts = nil
end

function ns.API.WeaponTooltipHas(tokens)
	if not tokens or #tokens == 0 then
		return false
	end
	local texts = collectWeaponTooltipTexts()
	if #texts == 0 then
		return false
	end
	for _, text in ipairs(texts) do
		for _, token in ipairs(tokens) do
			if type(token) == "string" and token ~= "" and text:find(token, 1, true) then
				return true
			end
		end
	end
	return false
end

function ns.API.Form(spellID)
	return ns.API.HasAura(spellID, "player", "HELPFUL")
end

function ns.API.Combo()
	if predict and predict.combo ~= nil then
		return predict.combo
	end
	return rawCombo()
end

function ns.API.Power(kind)
	local map = { Mana = 0, Rage = 1, Focus = 2, Energy = 3 }
	local token = map[kind] or 0
	local current = safe(UnitPower("player", token), 0) or 0
	local max = safe(UnitPowerMax("player", token), 1) or 1
	return current, max
end

function ns.API.Add(queue, spellID, opt)
	spellID = ns.API.Resolve(spellID) or spellID
	if not spellID or #queue >= 3 then
		return
	end
	for i = 1, #queue do
		if queue[i] == spellID then
			return
		end
	end
	if ns.API.StepOk(spellID, opt) then
		queue[#queue + 1] = spellID
	end
end
