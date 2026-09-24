local addonName, ns = ...
local API = ns.API

local IMG = "Interface\\AddOns\\WoWForeverRot\\images\\"
local BARS = {
	"Action",
	"MultiBarBottomLeft",
	"MultiBarBottomRight",
	"MultiBarRight",
	"MultiBarLeft",
	"MultiBar5",
	"MultiBar6",
	"MultiBar7",
}

local spells = {}
local spellsByName = {}
local buttonSlots = {}
local rangeButtons = {}
local buttonSpells = {}
local rangeOn = {}
local damageGlowing = {}
local defenseGlowing = {}
local kickGlowing = {}
local purgeGlowing = {}
local lastSpell
local lastSpellHeal
local lastDef
local lastDefHeal
local lastKick
local lastPurge
local lastFetch = 0
local addonCache = {}

local function addonLoaded(name)
	if addonCache[name] ~= nil then
		return addonCache[name]
	end
	local loaded = false
	if C_AddOns and C_AddOns.IsAddOnLoaded then
		local ok, value = pcall(C_AddOns.IsAddOnLoaded, name)
		if ok then
			loaded = value and true or false
		end
	end
	addonCache[name] = loaded
	return loaded
end

local function spellName(spellID)
	if not spellID then
		return
	end
	local info = API.SpellInfo(spellID)
	if not info then
		return
	end
	if type(info.name) == "string" then
		return info.name
	end
	if canaccessvalue and canaccessvalue(info.name) then
		return info.name
	end
end

local function overlay(button, key, texture, r, g, b, scale, alpha)
	scale = scale or 1.25
	alpha = alpha or 0.85
	button.WFROverlays = button.WFROverlays or {}
	local frame = button.WFROverlays[key]
	if not frame then
		frame = CreateFrame("Frame", nil, button)
		frame:SetFrameStrata("MEDIUM")
		frame:SetFrameLevel((button.GetFrameLevel and button:GetFrameLevel() or 4) + 6)
		frame:SetPoint("CENTER", button, "CENTER", 0, 0)
		local tex = frame:CreateTexture(nil, "OVERLAY")
		tex:SetAllPoints(frame)
		frame.texture = tex
		frame:Hide()
		button.WFROverlays[key] = frame
	end
	local w = button.GetWidth and button:GetWidth() or 36
	local h = button.GetHeight and button:GetHeight() or 36
	if w < 8 then
		w = 36
	end
	if h < 8 then
		h = 36
	end
	frame:SetSize(w * scale, h * scale)
	frame.texture:SetTexture(texture)
	frame.texture:SetBlendMode("ADD")
	frame.texture:SetVertexColor(r, g, b, alpha)
	return frame
end

local function showDamage(button, isHeal)
	if isHeal then
		if button.WFROverlays and button.WFROverlays.next then
			button.WFROverlays.next:Hide()
		end
		overlay(button, "heal", IMG .. "skull", 0.15, 1, 0.28, 1.45, 0.95):Show()
	else
		if button.WFROverlays and button.WFROverlays.heal then
			button.WFROverlays.heal:Hide()
		end
		overlay(button, "next", IMG .. "skull", 1, 1, 1, 1.45, 0.9):Show()
	end
	damageGlowing[button] = true
end

local function hideDamage(button)
	if button.WFROverlays then
		if button.WFROverlays.next then
			button.WFROverlays.next:Hide()
		end
		if button.WFROverlays.heal then
			button.WFROverlays.heal:Hide()
		end
	end
	damageGlowing[button] = nil
end

local function showDefense(button, isHeal)
	if isHeal then
		overlay(button, "def", IMG .. "skull", 0.15, 1, 0.28, 1.45, 0.95):Show()
	else
		overlay(button, "def", IMG .. "skull", 0.2, 0.55, 1, 1.45, 0.92):Show()
	end
	defenseGlowing[button] = true
end

local function hideDefense(button)
	if button.WFROverlays and button.WFROverlays.def then
		button.WFROverlays.def:Hide()
	end
	defenseGlowing[button] = nil
end

local function showKick(button)
	overlay(button, "kick", IMG .. "lightning-interrupt", 1, 1, 0.35, 1.2, 0.75):Show()
	kickGlowing[button] = true
end

local function hideKick(button)
	if button.WFROverlays and button.WFROverlays.kick then
		button.WFROverlays.kick:Hide()
	end
	kickGlowing[button] = nil
end

local function showPurge(button)
	overlay(button, "purge", IMG .. "magiccircle-purge", 0.85, 0.35, 1, 1.2, 0.75):Show()
	purgeGlowing[button] = true
end

local function hidePurge(button)
	if button.WFROverlays and button.WFROverlays.purge then
		button.WFROverlays.purge:Hide()
	end
	purgeGlowing[button] = nil
end

local function addButton(spellID, button, slot)
	if not spellID or not button then
		return
	end
	if type(spellID) == "number" then
		spells[spellID] = spells[spellID] or {}
		spells[spellID][#spells[spellID] + 1] = button
	end
	local name = spellName(spellID)
	if name then
		spellsByName[name] = spellsByName[name] or {}
		spellsByName[name][#spellsByName[name] + 1] = button
	end
	if slot then
		buttonSlots[button] = slot
	end
end

local function actionSlot(button)
	if not button then
		return
	end
	local slot
	if button.GetAttribute then
		local ok, value = pcall(button.GetAttribute, button, "action")
		if ok and value and value ~= 0 then
			slot = value
		end
	end
	if (not slot or slot == 0) and button.GetPagedID then
		local ok, value = pcall(button.GetPagedID, button)
		if ok and value and value ~= 0 then
			slot = value
		end
	end
	if (not slot or slot == 0) and button.CalculateAction then
		local ok, value = pcall(button.CalculateAction, button)
		if ok and value and value ~= 0 then
			slot = value
		end
	end
	if (not slot or slot == 0) and button.action and button.action ~= 0 then
		slot = button.action
	end
	return slot
end

local function addStandard(button)
	if not button then
		return
	end
	local okType, attrType = pcall(function()
		return button:GetAttribute("type")
	end)
	local slot = actionSlot(button)
	local actionType, id = attrType, nil
	if attrType == "action" or (not attrType and slot) then
		if slot and HasAction then
			local okHas, has = pcall(HasAction, slot)
			if okHas and has then
				local okInfo, t, actionID = pcall(GetActionInfo, slot)
				if okInfo then
					actionType, id = t, actionID
				end
			end
		end
	elseif attrType == "spell" then
		local ok, value = pcall(button.GetAttribute, button, "spell")
		if ok then
			id = value
		end
	elseif attrType == "macro" then
		local ok, value = pcall(button.GetAttribute, button, "macro")
		if ok then
			id = value
		end
	end
	if actionType == "macro" and id and GetMacroSpell then
		local ok, spellID = pcall(GetMacroSpell, id)
		if ok then
			id = spellID
			actionType = "spell"
		end
	end
	if slot then
		buttonSlots[button] = slot
		rangeButtons[button] = true
	end
	if actionType == "spell" and id then
		local info = API.SpellInfo(id)
		local spellID = info and info.spellID or id
		buttonSpells[button] = spellID
		addButton(spellID, button, slot)
		rangeButtons[button] = true
	elseif id then
		buttonSpells[button] = id
		addButton(id, button, slot)
		rangeButtons[button] = true
	end
end

function ns.GlowInvalidate()
	lastSpell = nil
	lastSpellHeal = nil
	lastDef = nil
	lastDefHeal = nil
	lastKick = nil
	lastPurge = nil
end

function ns.GlowFetch(force)
	if not force and lastFetch > 0 and (GetTime() - lastFetch) < 2 then
		return
	end
	wipe(spells)
	wipe(spellsByName)
	wipe(buttonSlots)
	wipe(rangeButtons)
	wipe(buttonSpells)
	lastFetch = GetTime()
	for _, bar in ipairs(BARS) do
		for i = 1, 12 do
			addStandard(_G[bar .. "Button" .. i])
		end
	end
	if GetNumShapeshiftForms then
		local ok, count = pcall(GetNumShapeshiftForms)
		if ok and count then
			for i = 1, count do
				local button = _G["StanceButton" .. i]
				if button and GetShapeshiftFormInfo then
					local okForm, _, _, _, spellID = pcall(function()
						return GetShapeshiftFormInfo(i)
					end)
					if okForm then
						addButton(spellID, button)
					end
				end
			end
		end
	end
	if addonLoaded("Dominos") then
		for i = 1, 132 do
			addStandard(_G["DominosActionButton" .. i])
		end
	end
	if addonLoaded("Bartender4") then
		for i = 1, 180 do
			addStandard(_G["BT4Button" .. i])
		end
	end
	if addonLoaded("ElvUI") then
		for bar = 1, 10 do
			for i = 1, 12 do
				addStandard(_G["ElvUI_Bar" .. bar .. "Button" .. i])
			end
		end
	end
end

local function buttonsFor(spellID)
	local out, seen = {}, {}
	local function take(list)
		if not list then
			return
		end
		for _, button in ipairs(list) do
			if button and not seen[button] then
				seen[button] = true
				out[#out + 1] = button
			end
		end
	end
	if type(spellID) == "number" then
		take(spells[spellID])
	end
	local name = spellName(spellID)
	if name then
		take(spellsByName[name])
	end
	if #out > 0 then
		return out
	end
	if C_ActionBar and C_ActionBar.FindSpellActionButtons then
		local ok, slots = pcall(C_ActionBar.FindSpellActionButtons, spellID)
		if ok and type(slots) == "table" then
			for _, slot in pairs(slots) do
				for button, btnSlot in pairs(buttonSlots) do
					if btnSlot == slot and not seen[button] then
						seen[button] = true
						out[#out + 1] = button
					end
				end
			end
		end
	end
	return out
end

function ns.GlowClear()
	for button in pairs(damageGlowing) do
		hideDamage(button)
	end
	wipe(damageGlowing)
	lastSpell = nil
	lastSpellHeal = nil
end

function ns.GlowClearDef()
	for button in pairs(defenseGlowing) do
		hideDefense(button)
	end
	wipe(defenseGlowing)
	lastDef = nil
	lastDefHeal = nil
end

local function isHealSpell(spellID)
	if ns.queueHeal and ns.queueHeal[spellID] then
		return true
	end
	return ns.API.IsHealSpell and ns.API.IsHealSpell(spellID)
end

local function apply(spellID, isDef)
	if not spellID then
		if isDef then
			ns.GlowClearDef()
		else
			ns.GlowClear()
		end
		return
	end
	local heal = isHealSpell(spellID)
	if isDef and spellID == lastDef and lastDefHeal == heal and next(defenseGlowing) then
		return
	end
	if not isDef and spellID == lastSpell and lastSpellHeal == heal and next(damageGlowing) then
		return
	end
	local list = buttonsFor(spellID)
	if isDef then
		ns.GlowClearDef()
		lastDef = spellID
		lastDefHeal = heal
		for _, button in ipairs(list) do
			showDefense(button, heal)
		end
	else
		ns.GlowClear()
		lastSpell = spellID
		lastSpellHeal = heal
		for _, button in ipairs(list) do
			showDamage(button, heal)
		end
	end
end

function ns.GlowSpell(spellID)
	if ns.db.glow == false or ns.db.showRotation == false then
		ns.GlowClear()
		return
	end
	apply(spellID, false)
end

function ns.GlowDef(spellID)
	if ns.db.glow == false or ns.db.showDefense == false then
		ns.GlowClearDef()
		return
	end
	apply(spellID, true)
end

local function applyExtra(spellID, lastKey, glowing, show, clear)
	if not spellID then
		clear()
		return
	end
	if lastKey[1] == spellID and next(glowing) then
		return
	end
	local list = buttonsFor(spellID)
	clear()
	lastKey[1] = spellID
	for _, button in ipairs(list) do
		show(button)
	end
end

function ns.GlowClearKick()
	for button in pairs(kickGlowing) do
		hideKick(button)
	end
	wipe(kickGlowing)
	lastKick = nil
end

function ns.GlowClearPurge()
	for button in pairs(purgeGlowing) do
		hidePurge(button)
	end
	wipe(purgeGlowing)
	lastPurge = nil
end

function ns.GlowInterrupt(spellID)
	applyExtra(spellID, { lastKick }, kickGlowing, showKick, ns.GlowClearKick)
	if spellID then
		lastKick = spellID
	end
end

function ns.GlowPurge(spellID)
	applyExtra(spellID, { lastPurge }, purgeGlowing, showPurge, ns.GlowClearPurge)
	if spellID then
		lastPurge = spellID
	end
end

local cleanseGlowing, weaponGlowing = {}, {}
local lastCleanse, lastWeapon

local function showCleanse(button)
	overlay(button, "cleanse", "Interface\\Buttons\\UI-ActionButton-Border", 0.35, 1, 0.45, 1.2, 0.8):Show()
	cleanseGlowing[button] = true
end

local function hideCleanse(button)
	if button.WFROverlays and button.WFROverlays.cleanse then
		button.WFROverlays.cleanse:Hide()
	end
	cleanseGlowing[button] = nil
end

local function showWeapon(button)
	overlay(button, "weapon", IMG .. "skull", 1, 0.12, 0.08, 1.45, 0.95):Show()
	weaponGlowing[button] = true
end

local function hideWeapon(button)
	if button.WFROverlays and button.WFROverlays.weapon then
		button.WFROverlays.weapon:Hide()
	end
	weaponGlowing[button] = nil
end

function ns.GlowClearCleanse()
	for button in pairs(cleanseGlowing) do
		hideCleanse(button)
	end
	wipe(cleanseGlowing)
	lastCleanse = nil
end

function ns.GlowClearWeapon()
	for button in pairs(weaponGlowing) do
		hideWeapon(button)
	end
	wipe(weaponGlowing)
	lastWeapon = nil
end

function ns.GlowCleanse(spellID)
	applyExtra(spellID, { lastCleanse }, cleanseGlowing, showCleanse, ns.GlowClearCleanse)
	if spellID then
		lastCleanse = spellID
	end
end

function ns.GlowWeapon(spellID)
	applyExtra(spellID, { lastWeapon }, weaponGlowing, showWeapon, ns.GlowClearWeapon)
	if spellID then
		lastWeapon = spellID
	end
end

local function readableFlag(value)
	if value == true or value == 1 then
		if issecretvalue and issecretvalue(value) then
			return nil
		end
		return true
	end
	if value == false or value == 0 then
		if issecretvalue and issecretvalue(value) then
			return nil
		end
		return false
	end
	return nil
end

local function ensureRangeFilter(button)
	if button.WFRRange then
		return button.WFRRange
	end
	local frame = CreateFrame("Frame", nil, button)
	frame:SetAllPoints(button)
	frame:SetFrameLevel((button.GetFrameLevel and button:GetFrameLevel() or 4) + 5)
	local tex = frame:CreateTexture(nil, "OVERLAY")
	tex:SetAllPoints()
	tex:SetTexture("Interface\\Buttons\\WHITE8x8")
	tex:SetBlendMode("BLEND")
	tex:SetVertexColor(0.88, 0.06, 0.06, 0.42)
	frame:Hide()
	button.WFRRange = frame
	return frame
end

local function isHealGlow(spellID)
	if not spellID then
		return false
	end
	if ns.queueHeal and ns.queueHeal[spellID] then
		return true
	end
	return ns.API.IsHealSpell and ns.API.IsHealSpell(spellID)
end

local function spellInRangeOn(spellID, unit)
	if not spellID or not unit then
		return nil
	end
	if C_Spell and C_Spell.IsSpellInRange then
		local ok, result = pcall(C_Spell.IsSpellInRange, spellID, unit)
		if ok then
			local flag = readableFlag(result)
			if flag ~= nil then
				return flag
			end
		end
	end
	if IsSpellInRange then
		local name = spellName(spellID)
		if name then
			local ok, result = pcall(IsSpellInRange, name, unit)
			if ok then
				return readableFlag(result)
			end
		end
	end
	return nil
end

local function actionInRange(button)
	local spellID = buttonSpells[button]
	if isHealGlow(spellID) then
		local unit = ns.API.HealRangeUnit and ns.API.HealRangeUnit() or "player"
		return spellInRangeOn(spellID, unit)
	end
	local slot = buttonSlots[button]
	if slot and ActionHasRange then
		local okHas, hasRange = pcall(ActionHasRange, slot)
		if okHas and readableFlag(hasRange) == false then
			return nil
		end
	end
	if slot and IsActionInRange then
		local ok, result = pcall(IsActionInRange, slot)
		if ok then
			local flag = readableFlag(result)
			if flag ~= nil then
				return flag
			end
		end
	end
	return spellInRangeOn(spellID, "target")
end

function ns.RangeClear()
	for button in pairs(rangeOn) do
		if button.WFRRange then
			button.WFRRange:Hide()
		end
	end
	wipe(rangeOn)
end

local function collectGlowing(seen)
	local function take(set)
		for button in pairs(set) do
			if button then
				seen[button] = true
			end
		end
	end
	take(damageGlowing)
	take(defenseGlowing)
	take(kickGlowing)
	take(purgeGlowing)
	take(cleanseGlowing)
	take(weaponGlowing)
end

function ns.RangeUpdate()
	local glowing = {}
	collectGlowing(glowing)
	if not next(glowing) then
		ns.RangeClear()
		return
	end
	local seen = {}
	for button in pairs(glowing) do
		if button.IsShown and button:IsShown() then
			seen[button] = true
			local flag = actionInRange(button)
			local filter = ensureRangeFilter(button)
			if flag == false then
				filter:Show()
				rangeOn[button] = true
			else
				filter:Hide()
				rangeOn[button] = nil
			end
		end
	end
	for button in pairs(rangeOn) do
		if not seen[button] then
			if button.WFRRange then
				button.WFRRange:Hide()
			end
			rangeOn[button] = nil
		end
	end
end
