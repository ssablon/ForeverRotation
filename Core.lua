local addonName, ns = ...
local API = ns.API

WoWForeverRotDB = WoWForeverRotDB or {}
ns.db = WoWForeverRotDB

local function defaults()
	ns.db = WoWForeverRotDB
	if ns.db.uiVersion ~= 6 then
		ns.db.uiVersion = 6
		if ns.db.pos then
			ns.db.pos.toolbar = nil
			ns.db.pos.defense = nil
		end
	end
	if ns.db.listVersion ~= 4 then
		ns.db.listVersion = 4
		ns.db.apl = nil
		ns.db.aplDrop = nil
		ns.db.def = nil
		ns.db.defDrop = nil
		if ns.db.profiles then
			for _, p in pairs(ns.db.profiles) do
				p.apl = nil
				p.aplDrop = nil
				p.def = nil
				p.defDrop = nil
			end
		end
	end
	if ns.db.glow == nil then
		ns.db.glow = true
	end
	if ns.db.showRotation == nil then
		ns.db.showRotation = true
	end
	if ns.db.showDefense == nil then
		ns.db.showDefense = true
	end
	if ns.db.showInterrupt == nil then
		ns.db.showInterrupt = true
	end
	if ns.db.showPurge == nil then
		ns.db.showPurge = true
	end
	if ns.db.showCleanse == nil then
		ns.db.showCleanse = true
	end
	if ns.db.showWeapon == nil then
		ns.db.showWeapon = true
	end
	if ns.db.showRange == nil then
		ns.db.showRange = true
	end
	if ns.db.showModes == nil then
		ns.db.showModes = true
	end
	if ns.db.idleSeen ~= 1 then
		ns.db.idleSeen = 1
		ns.db.hideIdle = false
	elseif ns.db.hideIdle == nil then
		ns.db.hideIdle = false
	end
	if ns.db.barOnly == nil then
		ns.db.barOnly = true
	end
	if ns.db.autoProfile == nil then
		ns.db.autoProfile = true
	end
	if ns.db.cleanseGroup == nil then
		ns.db.cleanseGroup = true
	end
	if ns.db.showPhysics == nil then
		ns.db.showPhysics = true
	end
	if ns.db.soundVolume == nil then
		ns.db.soundVolume = 60
	end
	ns.db.soundVolume = tonumber(ns.db.soundVolume) or 60
	if ns.db.soundVolume < 0 then
		ns.db.soundVolume = 0
	end
	if ns.db.soundVolume > 100 then
		ns.db.soundVolume = 100
	end
	ns.db.colors = ns.db.colors or {}
	if ns.db.uiScale == nil then
		ns.db.uiScale = 1
	end
	ns.db.uiScale = ns.UIScale and ns.UIScale() or ns.db.uiScale
	if not ns.db.role then
		ns.db.role = "damage"
	end
	ns.db.role = ns.NormalizeRole(ns.db.role)
	if ns.db.autoEnemies == nil then
		ns.db.autoEnemies = 3
	end
	if ns.db.lastManualMode ~= "aoe" and ns.db.lastManualMode ~= "burst" then
		if ns.db.lastManualMode ~= "single" then
			ns.db.lastManualMode = "single"
		end
	end
	if ns.db.combatMode ~= "auto" and ns.db.combatMode ~= "single" and ns.db.combatMode ~= "aoe" and ns.db.combatMode ~= "burst" then
		ns.db.combatMode = "auto"
	end
	if not ns.db.profiles then
		ns.db.profiles = {
			pve = {
				apl = ns.db.apl,
				aplDrop = ns.db.aplDrop,
				def = ns.db.def,
				defDrop = ns.db.defDrop,
				role = ns.db.role,
				combatMode = ns.db.combatMode,
				lastManualMode = ns.db.lastManualMode,
				autoEnemies = ns.db.autoEnemies,
				weaponBuff = ns.db.weaponBuff,
			},
			pvp = {},
			custom = {},
			base = {},
		}
		ns.db.profile = "pve"
	end
	for _, key in ipairs(ns.PROFILE_ORDER) do
		ns.db.profiles[key] = ns.db.profiles[key] or {}
	end
	if not ns.ValidProfile(ns.db.profile) then
		ns.db.profile = "pve"
	end
	ns.BindProfile()
end

ns.PROFILE_ORDER = { "base", "pve", "pvp", "custom" }

function ns.ValidProfile(key)
	return key == "base" or key == "pve" or key == "pvp" or key == "custom"
end

function ns.ProfileKey()
	local key = ns.db and ns.db.profile
	if ns.ValidProfile(key) then
		return key
	end
	return "pve"
end

function ns.FlushProfile()
	if not ns.db then
		return
	end
	ns.db.profiles = ns.db.profiles or {}
	local key = ns.ProfileKey()
	local p = ns.db.profiles[key] or {}
	ns.db.profiles[key] = p
	p.apl = ns.db.apl
	p.aplDrop = ns.db.aplDrop
	p.def = ns.db.def
	p.defDrop = ns.db.defDrop
	p.role = ns.db.role
	p.combatMode = ns.db.combatMode
	p.lastManualMode = ns.db.lastManualMode
	p.autoEnemies = ns.db.autoEnemies
	p.weaponBuff = ns.db.weaponBuff
end

function ns.BindProfile()
	ns.db.profiles = ns.db.profiles or {}
	local key = ns.ProfileKey()
	ns.db.profile = key
	ns.db.profiles[key] = ns.db.profiles[key] or {}
	local p = ns.db.profiles[key]
	ns.db.apl = p.apl
	ns.db.aplDrop = p.aplDrop
	ns.db.def = p.def
	ns.db.defDrop = p.defDrop
	ns.db.role = ns.NormalizeRole(p.role)
	local mode = p.combatMode or "auto"
	if mode ~= "auto" and mode ~= "single" and mode ~= "aoe" and mode ~= "burst" then
		mode = "auto"
	end
	ns.db.combatMode = mode
	ns.db.lastManualMode = p.lastManualMode or "single"
	ns.db.autoEnemies = tonumber(p.autoEnemies) or 3
	ns.db.weaponBuff = p.weaponBuff
end

function ns.SetProfile(key)
	if not ns.ValidProfile(key) then
		return
	end
	if ns.ProfileKey() == key and ns.db.profiles and ns.db.profiles[key] then
		ns.BindProfile()
		return
	end
	ns.FlushProfile()
	ns.db.profile = key
	ns.BindProfile()
	if ns.InvalidateAPLCache then
		ns.InvalidateAPLCache()
	end
	if ns.UI and ns.UI.RefreshRoles then
		ns.UI.RefreshRoles()
	end
	if ns.UI and ns.UI.RefreshModes then
		ns.UI.RefreshModes()
	end
	if ns.RefreshOptions then
		ns.RefreshOptions()
	end
	if ns.Tick then
		ns.Tick()
	end
end

function ns.CycleProfile()
	local current = ns.ProfileKey()
	local nextKey = ns.PROFILE_ORDER[1]
	for i, key in ipairs(ns.PROFILE_ORDER) do
		if key == current then
			nextKey = ns.PROFILE_ORDER[i + 1] or ns.PROFILE_ORDER[1]
			break
		end
	end
	ns.SetProfile(nextKey)
end

function ns.ResetCurrentProfile()
	ns.db.apl = nil
	ns.db.aplDrop = nil
	ns.db.def = nil
	ns.db.defDrop = nil
	ns.db.weaponBuff = nil
	ns.db.autoEnemies = 3
	ns.db.lastManualMode = "single"
	ns.db.combatMode = "auto"
	ns.db.role = ns.NormalizeRole(nil)
	ns.FlushProfile()
	ns.BindProfile()
	if ns.InvalidateAPLCache then
		ns.InvalidateAPLCache()
	end
	if ns.UI and ns.UI.RefreshRoles then
		ns.UI.RefreshRoles()
	end
	if ns.UI and ns.UI.RefreshModes then
		ns.UI.RefreshModes()
	end
	if ns.RefreshOptions then
		ns.RefreshOptions()
	end
	if ns.Tick then
		ns.Tick()
	end
	print("|cff66ccffWoW Forever Rot|r: " .. ns.T("OPT_RESET_ALL_DONE"))
end

function ns.ResetAll()
	ns.ResetCurrentProfile()
end

function ns.ConfirmResetAll()
	if type(StaticPopupDialogs) ~= "table" or type(StaticPopup_Show) ~= "function" then
		ns.ResetAll()
		return
	end
	StaticPopupDialogs.WOWFOREVERROT_RESET_ALL = {
		text = ns.T("OPT_RESET_ALL_CONFIRM"),
		button1 = YES or OKAY or "OK",
		button2 = NO or CANCEL or "No",
		OnAccept = function()
			ns.ResetAll()
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
	StaticPopup_Show("WOWFOREVERROT_RESET_ALL")
end

function ns.NormalizeRole(role)
	local token = ns.ClassToken()
	if ns.RoleAllowed(role) then
		return role
	end
	if token == "SHAMAN" and role == "damage" then
		return "caster"
	end
	if token == "HUNTER" and role == "damage" then
		return "range"
	end
	if token == "DRUID" and role == "damage" then
		return "hybrid"
	end
	local roles = token and ns.CLASS_ROLES[token] or { "damage" }
	return roles[1]
end

function ns.ClassToken()
	local ok, localized, classFile, classId = pcall(UnitClass, "player")
	if ok and type(classFile) == "string" then
		local upOk, upper = pcall(string.upper, classFile)
		if upOk then
			return upper, classId, localized
		end
	end
	if UnitClassBase then
		local okBase, base = pcall(UnitClassBase, "player")
		if okBase and type(base) == "string" then
			return base:upper(), classId, localized
		end
	end
	return nil, classId, localized
end

function ns.RoleAllowed(role)
	local token = ns.ClassToken()
	local roles = token and ns.CLASS_ROLES[token] or { "damage" }
	for _, allowed in ipairs(roles) do
		if allowed == role then
			return true
		end
	end
	return false
end

function ns.SetRole(role)
	role = ns.NormalizeRole(role)
	if not ns.RoleAllowed(role) then
		return
	end
	ns.db.role = role
	if ns.FlushProfile then
		ns.FlushProfile()
	end
	if ns.UI and ns.UI.RefreshRoles then
		ns.UI.RefreshRoles()
	end
	ns.Tick()
end

function ns.SetCombatMode(mode)
	if mode ~= "auto" and mode ~= "aoe" and mode ~= "burst" then
		mode = "single"
	end
	if mode ~= "auto" then
		ns.db.lastManualMode = mode
	end
	ns.db.combatMode = mode
	if ns.FlushProfile then
		ns.FlushProfile()
	end
	if ns.InvalidateAPLCache then
		ns.InvalidateAPLCache()
	end
	if ns.UI and ns.UI.RefreshModes then
		ns.UI.RefreshModes()
	end
	if ns.UI.options and ns.RefreshOptions then
		ns.RefreshOptions()
	end
	ns.Tick()
end

function ns.ToggleAuto()
	if (ns.db.combatMode or "auto") == "auto" then
		ns.SetCombatMode(ns.db.lastManualMode or "single")
		return
	end
	ns.SetCombatMode("auto")
end

function ns.CycleCombatMode()
	local order = { "single", "aoe", "burst" }
	local current = ns.db.combatMode
	if current == "auto" then
		current = ns.db.lastManualMode or "single"
	end
	local nextMode = order[1]
	for i, mode in ipairs(order) do
		if mode == current then
			nextMode = order[i + 1] or order[1]
			break
		end
	end
	ns.SetCombatMode(nextMode)
end

function ns.CycleRole()
	local token = ns.ClassToken()
	local order = token and ns.CLASS_ROLES[token] or { "damage" }
	local current = ns.db.role or "damage"
	local nextRole = order[1]
	for i, role in ipairs(order) do
		if role == current then
			nextRole = order[i + 1] or order[1]
			break
		end
	end
	ns.SetRole(nextRole)
end

local lastTickSig
local lastRangeAt = 0

local function flagBit(value)
	return value ~= false and "1" or "0"
end

function ns.InvalidateTick()
	lastTickSig = nil
end

function ns.ApplyFeatureFlags()
	if ns.UI and ns.UI.SetLocked then
		ns.UI.SetLocked(ns.db.locked == true)
	end
	local idle = ns.API.ShouldHideIdle and ns.API.ShouldHideIdle()
	if ns.UI then
		if ns.UI.root then
			ns.UI.root:SetShown(ns.db.showRotation ~= false and not idle)
		end
		if ns.UI.defense then
			ns.UI.defense:SetShown(ns.db.showDefense ~= false and not idle)
		end
		if ns.UI.interrupt then
			ns.UI.interrupt:SetShown(ns.db.showInterrupt ~= false and not idle)
		end
		if ns.UI.purge then
			ns.UI.purge:SetShown(ns.db.showPurge ~= false and not idle)
		end
		if ns.UI.cleanse then
			ns.UI.cleanse:SetShown(ns.db.showCleanse ~= false and not idle)
		end
		if ns.UI.weapon then
			ns.UI.weapon:SetShown(ns.db.showWeapon ~= false and not idle)
		end
		if ns.UI.RefreshModes then
			ns.UI.RefreshModes()
		end
	end
	if ns.db.glow == false or ns.db.showRotation == false then
		if ns.GlowClear then
			ns.GlowClear()
		end
	end
	if ns.db.glow == false or ns.db.showDefense == false then
		if ns.GlowClearDef then
			ns.GlowClearDef()
		end
	end
	if ns.db.showInterrupt == false and ns.GlowClearKick then
		ns.GlowClearKick()
	end
	if ns.db.showPurge == false and ns.GlowClearPurge then
		ns.GlowClearPurge()
	end
	if ns.db.showCleanse == false and ns.GlowClearCleanse then
		ns.GlowClearCleanse()
	end
	if ns.db.showWeapon == false and ns.GlowClearWeapon then
		ns.GlowClearWeapon()
	end
	if ns.db.showRange == false and ns.RangeClear then
		ns.RangeClear()
	end
	lastTickSig = nil
	if ns.Tick then
		ns.Tick()
	end
	if ns.db.showRange ~= false and ns.RangeUpdate then
		ns.RangeUpdate()
	end
end

local lastAlertKick, lastAlertCleanse, lastAlertWeapon

local function playAlert(kind)
	local vol = tonumber(ns.db and ns.db.soundVolume) or 0
	if vol <= 0 then
		return
	end
	local kit
	if vol < 34 then
		kit = (SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON) or 856
	elseif vol < 67 then
		kit = (SOUNDKIT and SOUNDKIT.MAP_PING) or 5274
	else
		kit = (SOUNDKIT and SOUNDKIT.READY_CHECK) or 8960
	end
	pcall(PlaySound, kit, "Master", true)
end

function ns.ApplyAutoProfile()
	if not ns.db or ns.db.autoProfile == false or not ns.SetProfile then
		return
	end
	local itype
	if GetInstanceInfo then
		local ok, _, instanceType = pcall(GetInstanceInfo)
		if ok then
			itype = instanceType
		end
	end
	local want
	if itype == "pvp" or itype == "arena" then
		want = "pvp"
	elseif itype == "party" or itype == "raid" then
		want = "pve"
	end
	if want then
		if ns.ProfileKey() ~= want then
			if not ns.db.autoProfileFrom then
				ns.db.autoProfileFrom = ns.ProfileKey()
			end
			ns.SetProfile(want)
		end
		return
	end
	local from = ns.db.autoProfileFrom
	if from and ns.ValidProfile(from) and ns.ProfileKey() ~= from then
		ns.db.autoProfileFrom = nil
		ns.SetProfile(from)
		return
	end
	ns.db.autoProfileFrom = nil
end

function ns.Tick()
	if not ns.UI or not ns.UI.root then
		return
	end
	local idle = ns.API.ShouldHideIdle and ns.API.ShouldHideIdle()
	local queue = (ns.db.showRotation ~= false and not idle) and ns.BuildQueue() or {}
	local defense = (ns.db.showDefense ~= false and not idle) and ns.BuildDefense() or nil
	local interrupt = (ns.db.showInterrupt ~= false and not idle) and ns.BuildInterrupt() or nil
	local purge = (ns.db.showPurge ~= false and not idle) and ns.BuildPurge() or nil
	local cleanse = (ns.db.showCleanse ~= false and not idle) and ns.BuildCleanse() or nil
	local weapon, weaponNeed
	if ns.db.showWeapon ~= false and not idle then
		weapon, _, weaponNeed = ns.BuildWeapon()
	end
	if idle then
		lastAlertKick, lastAlertCleanse, lastAlertWeapon = nil, nil, nil
	else
		if interrupt and interrupt ~= lastAlertKick then
			playAlert("kick")
		end
		lastAlertKick = interrupt
		if cleanse and cleanse ~= lastAlertCleanse then
			playAlert("cleanse")
		end
		lastAlertCleanse = cleanse
		if weaponNeed and weapon and weapon ~= lastAlertWeapon then
			playAlert("weapon")
		end
		if not weaponNeed then
			lastAlertWeapon = nil
		else
			lastAlertWeapon = weapon
		end
	end
	local sig = (queue[1] or 0) .. ":" .. (queue[2] or 0) .. ":" .. (queue[3] or 0) .. ":" .. (defense or 0) .. ":" .. (interrupt or 0) .. ":" .. (purge or 0) .. ":" .. (cleanse or 0) .. ":" .. (weapon or 0) .. ":" .. (weaponNeed and 1 or 0) .. ":" .. flagBit(ns.db.showRotation) .. flagBit(ns.db.showDefense) .. flagBit(ns.db.showInterrupt) .. flagBit(ns.db.showPurge) .. flagBit(ns.db.showCleanse) .. flagBit(ns.db.showWeapon) .. flagBit(ns.db.glow) .. flagBit(ns.db.showModes) .. flagBit(ns.db.showRange) .. (ns.db.locked == true and "1" or "0") .. flagBit(not idle)
	if sig ~= lastTickSig then
		lastTickSig = sig
		ns.UI.Update(queue, defense, interrupt, purge, cleanse, weapon, weaponNeed)
		if ns.GlowSpell then
			ns.GlowSpell(ns.db.showRotation ~= false and queue[1] or nil)
		end
		if ns.GlowDef then
			ns.GlowDef(defense)
		end
		if ns.GlowInterrupt then
			ns.GlowInterrupt(interrupt)
		end
		if ns.GlowPurge then
			ns.GlowPurge(purge)
		end
		if ns.GlowCleanse then
			ns.GlowCleanse(cleanse)
		end
		if ns.GlowWeapon then
			ns.GlowWeapon(weaponNeed and weapon or nil)
		end
	end
	local now = GetTime()
	if ns.db.showRange ~= false then
		if now - lastRangeAt >= 0.25 and ns.RangeUpdate then
			lastRangeAt = now
			ns.RangeUpdate()
		end
	elseif ns.RangeClear then
		ns.RangeClear()
	end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
frame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
frame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
pcall(frame.RegisterEvent, frame, "WEAPON_ENCHANT_CHANGED")
pcall(frame.RegisterEvent, frame, "LEARNED_SPELL_IN_TAB")
pcall(frame.RegisterEvent, frame, "PLAYER_TALENT_UPDATE")
pcall(frame.RegisterEvent, frame, "PLAYER_LOGOUT")
pcall(frame.RegisterEvent, frame, "PLAYER_DEAD")
pcall(frame.RegisterEvent, frame, "PLAYER_ALIVE")
pcall(frame.RegisterEvent, frame, "PLAYER_UNGHOST")
pcall(frame.RegisterEvent, frame, "PLAYER_UPDATE_RESTING")
pcall(frame.RegisterEvent, frame, "PLAYER_MOUNT_DISPLAY_CHANGED")
pcall(frame.RegisterEvent, frame, "ZONE_CHANGED_NEW_AREA")

local ticker
local booted
local spellsPending
local barsPending

local function startTicker()
	if ticker then
		return
	end
	if C_Timer and C_Timer.NewTicker then
		ticker = C_Timer.NewTicker(0.2, function()
			ns.Tick()
		end)
		return
	end
	frame:SetScript("OnUpdate", function(self, elapsed)
		self.acc = (self.acc or 0) + elapsed
		if self.acc < 0.2 then
			return
		end
		self.acc = 0
		ns.Tick()
	end)
end

local function stopTicker()
	if ticker then
		ticker:Cancel()
		ticker = nil
	end
	frame:SetScript("OnUpdate", nil)
end

local function flushSpells()
	spellsPending = nil
	if ns.API and ns.API.InvalidateSpells then
		ns.API.InvalidateSpells()
	end
	ns.Tick()
end

local function flushBars()
	barsPending = nil
	if ns.GlowFetch then
		ns.GlowFetch(true)
	end
	if ns.GlowInvalidate then
		ns.GlowInvalidate()
	end
end

frame:SetScript("OnEvent", function(_, event, unit, _, spellID)
	if event == "PLAYER_LOGOUT" then
		stopTicker()
		if ns.FlushProfile then
			ns.FlushProfile()
		end
		return
	end
	if event == "LEARNED_SPELL_IN_TAB" or event == "PLAYER_TALENT_UPDATE" then
		if spellsPending then
			return
		end
		spellsPending = true
		if C_Timer and C_Timer.After then
			C_Timer.After(0.5, flushSpells)
		else
			flushSpells()
		end
		return
	end
	if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
		defaults()
		if not booted then
			booted = true
			if ns.API and ns.API.InvalidateSpells then
				ns.API.InvalidateSpells()
			end
			local okCreate, errCreate = pcall(ns.UI.Create)
			if not okCreate then
				print("|cff66ccffWoW Forever Rot|r: " .. tostring(errCreate))
			end
			if ns.CreateMinimap then
				local okMini, errMini = pcall(ns.CreateMinimap)
				if not okMini then
					print("|cff66ccffWoW Forever Rot|r: " .. tostring(errMini))
				end
			end
			if ns.GlowFetch then
				ns.GlowFetch(true)
			end
			startTicker()
		end
		if ns.ApplyAutoProfile then
			ns.ApplyAutoProfile()
		end
		if event == "PLAYER_LOGIN" then
			local token, _, localized = ns.ClassToken()
			print("|cff66ccffWoW Forever Rot|r: " .. ns.T("INIT"))
			print("|cff66ccffWoW Forever Rot|r: " .. format(ns.T("MODULE"), localized or token or "?"))
		end
		ns.Tick()
	elseif event == "ZONE_CHANGED_NEW_AREA" then
		if ns.ApplyAutoProfile then
			ns.ApplyAutoProfile()
		end
	elseif event == "PLAYER_DEAD" or event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" or event == "PLAYER_UPDATE_RESTING" or event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
		lastTickSig = nil
		ns.Tick()
	elseif event == "PLAYER_TARGET_CHANGED" then
		ns.API.castTarget = false
		ns.Tick()
	elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
		if unit == "player" then
			if ns.API and ns.API.NoteSelfBuff then
				ns.API.NoteSelfBuff(spellID)
			end
			if ns.API and ns.API.NoteSpellCast then
				ns.API.NoteSpellCast(spellID)
			end
			if ns.NoteWeaponCast then
				ns.NoteWeaponCast(spellID)
			end
		end
	elseif event == "PLAYER_EQUIPMENT_CHANGED" or event == "WEAPON_ENCHANT_CHANGED" then
		if event == "PLAYER_EQUIPMENT_CHANGED" and ns.ClearWeaponMemory then
			ns.ClearWeaponMemory()
		elseif event == "WEAPON_ENCHANT_CHANGED" then
			ns.weaponSeenUntil = 0
		end
	elseif event == "ACTIONBAR_SLOT_CHANGED" or event == "ACTIONBAR_PAGE_CHANGED" or event == "UPDATE_SHAPESHIFT_FORM" then
		if barsPending then
			return
		end
		barsPending = true
		if C_Timer and C_Timer.After then
			C_Timer.After(0.5, flushBars)
		else
			flushBars()
		end
	end
end)

SLASH_WFR1 = "/wfr"
SLASH_WFR2 = "/foreverrot"
SlashCmdList.WFR = function(msg)
	msg = strtrim(strlower(msg or ""))
	if msg == "unlock" then
		ns.UI.SetLocked(false)
		print("|cff66ccffWoW Forever Rot|r: " .. ns.T("UNLOCKED"))
	elseif msg == "lock" then
		ns.UI.SetLocked(true)
		print("|cff66ccffWoW Forever Rot|r: " .. ns.T("LOCKED"))
	elseif msg == "reset" then
		ns.db.pos = nil
		ns.db.point = nil
		ns.UI.ApplyPosition()
	elseif msg == "resetall" then
		ns.ConfirmResetAll()
	elseif msg == "role" then
		ns.CycleRole()
	elseif msg == "mode" then
		ns.CycleCombatMode()
	elseif msg == "profile" then
		ns.CycleProfile()
	elseif msg == "jce" or msg == "pve" then
		ns.SetProfile("pve")
	elseif msg == "jcj" or msg == "pvp" then
		ns.SetProfile("pvp")
	elseif msg == "base" then
		ns.SetProfile("base")
	elseif msg == "custom" or msg == "customs" then
		ns.SetProfile("custom")
	elseif msg == "menu" or msg == "options" or msg == "opt" then
		ns.ToggleOptions()
	else
		print("|cff66ccffWoW Forever Rot|r: " .. ns.T("HELP"))
	end
end
