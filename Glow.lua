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

local barSpellCount = 0
local nameOwner = {}
local badNames = {}

local function isToken(value, expected)
	if value == nil or expected == nil then
		return false
	end
	if issecretvalue and issecretvalue(value) then
		return false
	end
	local ok, same = pcall(function()
		return value == expected
	end)
	return ok and same == true
end

local function actionSpellName(slot)
	if not slot or not C_TooltipInfo or not C_TooltipInfo.GetAction then
		return nil
	end
	local ok, data = pcall(C_TooltipInfo.GetAction, slot)
	if not ok or type(data) ~= "table" or type(data.lines) ~= "table" then
		return nil
	end
	local line = data.lines[1]
	local text = line and line.leftText
	if type(text) ~= "string" or text == "" then
		return nil
	end
	if issecretvalue and issecretvalue(text) then
		return nil
	end
	text = text:gsub("%s*%([^)]*%)%s*$", "")
	if text == "" or not C_Spell or not C_Spell.GetSpellInfo then
		return nil
	end
	local okInfo, info = pcall(C_Spell.GetSpellInfo, text)
	if not okInfo or type(info) ~= "table" or not plainID(info.spellID) then
		return nil
	end
	local name = info.name
	if type(name) == "string" and name ~= "" then
		return name
	end
	return text
end

local function addSpellName(name, button)
	if type(name) ~= "string" or name == "" or badNames[name] or not button then
		return
	end
	spellsByName[name] = spellsByName[name] or {}
	spellsByName[name][#spellsByName[name] + 1] = button
	barSpellCount = barSpellCount + 1
end

local function plainID(value)
	if value == nil or value == 0 or value == "" then
		return nil
	end
	if issecretvalue and issecretvalue(value) then
		return nil
	end
	if canaccessvalue and not canaccessvalue(value) then
		return nil
	end
	local ok, n = pcall(function()
		local v = tonumber(value)
		if type(v) ~= "number" then
			return nil
		end
		return v + 0
	end)
	if ok and type(n) == "number" and n > 0 then
		return n
	end
	return nil
end

local function spellName(spellID)
	spellID = plainID(spellID)
	if not spellID then
		return
	end
	local info = API.SpellInfo(spellID)
	local name = info and info.name
	if type(name) ~= "string" or name == "" then
		return
	end
	if issecretvalue and issecretvalue(name) then
		return
	end
	return name
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
		local r, g, b = ns.Color("heal")
		overlay(button, "heal", IMG .. "skull", r, g, b, 1.45, 0.95):Show()
	else
		if button.WFROverlays and button.WFROverlays.heal then
			button.WFROverlays.heal:Hide()
		end
		local r, g, b = ns.Color("next")
		overlay(button, "next", IMG .. "skull", r, g, b, 1.45, 0.9):Show()
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
		local r, g, b = ns.Color("heal")
		overlay(button, "def", IMG .. "skull", r, g, b, 1.45, 0.95):Show()
	else
		local r, g, b = ns.Color("def")
		overlay(button, "def", IMG .. "skull", r, g, b, 1.45, 0.92):Show()
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
	local id = plainID(spellID)
	if not id or not button then
		return
	end
	spells[id] = spells[id] or {}
	spells[id][#spells[id] + 1] = button
	buttonSpells[button] = id
	local name = spellName(id)
	if not name or badNames[name] then
		return
	end
	if nameOwner[name] and nameOwner[name] ~= id then
		badNames[name] = true
		spellsByName[name] = nil
		nameOwner[name] = nil
		return
	end
	nameOwner[name] = id
	spellsByName[name] = spellsByName[name] or {}
	spellsByName[name][#spellsByName[name] + 1] = button
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
				local okInfo, t, actionID, _, spellFromAction = pcall(GetActionInfo, slot)
				if okInfo and isToken(t, "spell") then
					actionType = "spell"
					id = plainID(spellFromAction) or plainID(actionID)
				elseif okInfo and isToken(t, "macro") then
					actionType, id = "macro", actionID
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
		local tipName = actionSpellName(slot)
		if tipName then
			addSpellName(tipName, button)
		end
	end
	if actionType == "spell" and id then
		local info = API.SpellInfo(id)
		local spellID = plainID(info and info.spellID) or plainID(id)
		addButton(spellID, button, slot)
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
	wipe(nameOwner)
	wipe(badNames)
	barSpellCount = 0
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
	local id = plainID(spellID)
	local resolved = API.Resolve and plainID(API.Resolve(spellID))
	if id then
		take(spells[id])
	end
	if resolved and resolved ~= id then
		take(spells[resolved])
	end
	local name = spellName(id) or spellName(resolved)
	if name and not badNames[name] then
		take(spellsByName[name])
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
	local r, g, b = ns.Color("weapon")
	overlay(button, "weapon", IMG .. "skull", r, g, b, 1.45, 0.95):Show()
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
	frame:SetFrameLevel((button.GetFrameLevel and button:GetFrameLevel() or 4) + 8)
	local tex = frame:CreateTexture(nil, "OVERLAY")
	tex:SetAllPoints()
	tex:SetTexture("Interface\\Buttons\\WHITE8x8")
	tex:SetBlendMode("BLEND")
	frame.texture = tex
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

local function rangeUnitFor(spellID)
	if not spellID then
		return "target"
	end
	if isHealGlow(spellID) then
		return ns.API.HealRangeUnit and ns.API.HealRangeUnit() or "player"
	end
	if ns.API.IsHelpful and ns.API.IsHelpful(spellID) and not (ns.API.IsHarmful and ns.API.IsHarmful(spellID)) then
		return ns.API.HealRangeUnit and ns.API.HealRangeUnit() or "player"
	end
	return "target"
end

function ns.SpellInRange(spellID, slot)
	if slot and IsActionInRange then
		local ok, result = pcall(IsActionInRange, slot)
		if ok then
			local flag = readableFlag(result)
			if flag ~= nil then
				return flag
			end
		end
	end
	if not spellID then
		return nil
	end
	local unit = rangeUnitFor(spellID)
	local flag = spellInRangeOn(spellID, unit)
	if flag ~= nil then
		return flag
	end
	if unit ~= "target" then
		flag = spellInRangeOn(spellID, "target")
		if flag ~= nil then
			return flag
		end
	end
	if slot and IsActionInRange then
		local ok, result = pcall(IsActionInRange, slot)
		if ok then
			return readableFlag(result)
		end
	end
	return nil
end

local function actionInRange(button)
	return ns.SpellInRange(buttonSpells[button], buttonSlots[button])
end

function ns.RangeClear()
	for button in pairs(rangeOn) do
		if button.WFRRange then
			button.WFRRange:Hide()
		end
	end
	wipe(rangeOn)
end

function ns.RangeUpdate()
	if lastFetch == 0 then
		ns.GlowFetch()
	end
	local seen = {}
	for button in pairs(rangeButtons) do
		if button and button.IsShown and button:IsShown() then
			seen[button] = true
			local flag = actionInRange(button)
			local filter = ensureRangeFilter(button)
			if flag == false then
				if filter.texture then
					local r, g, b = ns.Color("range")
					filter.texture:SetVertexColor(r, g, b, 0.42)
				end
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

function ns.SpellOnBar(spellID)
	if not spellID then
		return false
	end
	if lastFetch == 0 then
		ns.GlowFetch()
	end
	local function found(id)
		if not id then
			return false
		end
		if spells[id] and #spells[id] > 0 then
			return true
		end
		local name = spellName(id)
		return name and spellsByName[name] and #spellsByName[name] > 0
	end
	if found(spellID) then
		return true
	end
	local resolved = API.Resolve and API.Resolve(spellID)
	if resolved and resolved ~= spellID and found(resolved) then
		return true
	end
	if not next(spells) and not next(spellsByName) then
		return true
	end
	if barSpellCount == 0 then
		return true
	end
	return false
end

local function slotCommand(slot)
	slot = tonumber(slot)
	if not slot then
		return
	end
	if slot >= 1 and slot <= 12 then
		return "ACTIONBUTTON" .. slot
	end
	local bars = {
		{ 25, 36, "MULTIACTIONBAR3BUTTON" },
		{ 37, 48, "MULTIACTIONBAR4BUTTON" },
		{ 49, 60, "MULTIACTIONBAR2BUTTON" },
		{ 61, 72, "MULTIACTIONBAR1BUTTON" },
		{ 73, 84, "MULTIACTIONBAR5BUTTON" },
		{ 85, 96, "MULTIACTIONBAR6BUTTON" },
		{ 97, 108, "MULTIACTIONBAR7BUTTON" },
	}
	for _, row in ipairs(bars) do
		if slot >= row[1] and slot <= row[2] then
			return row[3] .. (slot - row[1] + 1)
		end
	end
end

local function shortKey(text)
	if type(text) ~= "string" or text == "" then
		return ""
	end
	text = text:gsub("SHIFT%-", "S")
	text = text:gsub("CTRL%-", "C")
	text = text:gsub("ALT%-", "A")
	text = text:gsub("STRG%-", "C")
	return text
end

function ns.SpellBinding(spellID)
	if not spellID then
		return ""
	end
	if lastFetch == 0 then
		ns.GlowFetch()
	end
	local list = buttonsFor(spellID)
	for _, button in ipairs(list) do
		local hot = button.HotKey
		if hot and hot.GetText then
			local text = hot:GetText()
			if type(text) == "string" and text ~= "" and text ~= RANGE_INDICATOR and text ~= "●" then
				return shortKey(text)
			end
		end
		local cmd = slotCommand(buttonSlots[button])
		if cmd and GetBindingKey then
			local ok, key = pcall(GetBindingKey, cmd)
			if ok and type(key) == "string" and key ~= "" then
				if GetBindingText then
					local okText, pretty = pcall(GetBindingText, key)
					if okText and type(pretty) == "string" and pretty ~= "" then
						return shortKey(pretty)
					end
				end
				return shortKey(key)
			end
		end
	end
	return ""
end
