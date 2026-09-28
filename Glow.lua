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
local glowFetchGen = 0
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
local slotsOccupied = 0
local slotsKnown = 0
local knownSlot = {}
local countedSlot = {}
local spellsByNorm = {}
local buttonsByIcon = {}
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
	if text == "" then
		return nil
	end
	if C_Spell and C_Spell.GetSpellInfo then
		local okInfo, info = pcall(C_Spell.GetSpellInfo, text)
		if okInfo and type(info) == "table" then
			local name = info.name
			if issecretvalue and issecretvalue(name) then
				name = nil
			end
			if type(name) == "string" and name ~= "" then
				return name
			end
		end
	end
	return text
end

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
	return (name:gsub("[%z\1-\127\194-\244][\128-\191]*", function(ch)
		return ACCENT_FOLD[ch] or ch
	end))
end

local function normKey(name)
	if type(name) ~= "string" or name == "" then
		return
	end
	if issecretvalue and issecretvalue(name) then
		return
	end
	local n = name:gsub("%s*%([^)]*%)%s*$", "")
	n = foldAccents(n)
	local ok, lower = pcall(string.lower, n)
	if not ok or type(lower) ~= "string" then
		return
	end
	if strtrim then
		lower = strtrim(lower)
	end
	if lower == "" then
		return
	end
	return lower
end

local function markKnown(button)
	if not button or knownSlot[button] then
		return
	end
	knownSlot[button] = true
	slotsKnown = slotsKnown + 1
end

local function noteOccupied(button)
	if not button or countedSlot[button] then
		return
	end
	countedSlot[button] = true
	slotsOccupied = slotsOccupied + 1
end

local function addSpellName(name, button)
	if type(name) ~= "string" or name == "" or badNames[name] or not button then
		return
	end
	spellsByName[name] = spellsByName[name] or {}
	spellsByName[name][#spellsByName[name] + 1] = button
	local key = normKey(name)
	if key then
		spellsByNorm[key] = spellsByNorm[key] or {}
		spellsByNorm[key][#spellsByNorm[key] + 1] = button
	end
	barSpellCount = barSpellCount + 1
	markKnown(button)
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
	markKnown(button)
	if not name or badNames[name] then
		if slot then
			buttonSlots[button] = slot
		end
		return
	end
	nameOwner[name] = nameOwner[name] or id
	spellsByName[name] = spellsByName[name] or {}
	spellsByName[name][#spellsByName[name] + 1] = button
	local key = normKey(name)
	if key then
		spellsByNorm[key] = spellsByNorm[key] or {}
		spellsByNorm[key][#spellsByNorm[key] + 1] = button
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

local function plainTexture(value)
	if value == nil or value == "" or value == 0 then
		return nil
	end
	if issecretvalue and issecretvalue(value) then
		return nil
	end
	if canaccessvalue and not canaccessvalue(value) then
		return nil
	end
	if type(value) == "number" and value > 0 then
		return value
	end
	if type(value) == "string" and value ~= "" then
		return value:lower()
	end
	return nil
end

local function addIcon(key, button)
	if not key or not button then
		return
	end
	buttonsByIcon[key] = buttonsByIcon[key] or {}
	buttonsByIcon[key][#buttonsByIcon[key] + 1] = button
end

local function indexButtonIcon(button, slot)
	if not button then
		return
	end
	if slot and GetActionTexture then
		local ok, tex = pcall(GetActionTexture, slot)
		if ok then
			addIcon(plainTexture(tex), button)
		end
	end
	local icon = button.icon or button.Icon
	if not icon and button.GetName then
		icon = _G[button:GetName() .. "Icon"]
	end
	if icon and icon.GetTexture then
		local ok, tex = pcall(icon.GetTexture, icon)
		if ok then
			addIcon(plainTexture(tex), button)
		end
	end
end

local function spellIconKeys(spellID)
	local keys = {}
	local function add(value)
		local key = plainTexture(value)
		if key then
			keys[key] = true
		end
	end
	if not spellID then
		return keys
	end
	if C_Spell and C_Spell.GetSpellTexture then
		local ok, tex = pcall(C_Spell.GetSpellTexture, spellID)
		if ok then
			add(tex)
		end
	end
	if GetSpellTexture then
		local ok, tex = pcall(GetSpellTexture, spellID)
		if ok then
			add(tex)
		end
	end
	local info = API.SpellInfo(spellID)
	if type(info) == "table" then
		add(info.iconID)
		add(info.originalIconID)
	end
	return keys
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
	local macroId = actionType == "macro" and id or nil
	if macroId and GetMacroSpell then
		local ok, spellID = pcall(GetMacroSpell, macroId)
		local macroSpell = ok and plainID(spellID)
		if macroSpell then
			id = macroSpell
			actionType = "spell"
		end
	end
	if macroId and GetMacroBody then
		local okBody, body = pcall(GetMacroBody, macroId)
		if okBody and type(body) == "string" then
			for line in body:gmatch("[^\r\n]+") do
				local payload = line:match("^%s*#showtooltip%s+(.+)$") or line:match("^%s*/%S+%s+(.+)$")
				if payload then
					payload = payload:gsub("%b[]", " ")
					for token in payload:gmatch("[^,;]+") do
						token = token:gsub("^%s+", ""):gsub("%s+$", ""):gsub("^!", "")
						token = token:gsub("%s*%([^)]*%)%s*$", "")
						if token ~= "" and C_Spell and C_Spell.GetSpellInfo then
							local okInfo, info = pcall(C_Spell.GetSpellInfo, token)
							if okInfo and type(info) == "table" then
								local spellId = plainID(info.spellID)
								local spellLabel = info.name
								if issecretvalue and issecretvalue(spellLabel) then
									spellLabel = nil
								end
								if type(spellLabel) == "string" and spellLabel ~= "" then
									addSpellName(spellLabel, button)
								else
									addSpellName(token, button)
								end
								if spellId then
									addButton(spellId, button, slot)
								end
							end
						end
					end
				end
			end
		end
	end
	if slot and HasAction then
		local okHas, has = pcall(HasAction, slot)
		if okHas and has then
			noteOccupied(button)
			indexButtonIcon(button, slot)
		end
	end
	if slot then
		buttonSlots[button] = slot
		rangeButtons[button] = true
		-- Forever: never call C_TooltipInfo.GetAction here. ConROC maps bars
		-- with GetActionInfo / GetSpellInfo only — tooltips freeze camelot when
		-- many slots update after a quest turn-in.
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
	wipe(spellsByNorm)
	wipe(buttonsByIcon)
	wipe(knownSlot)
	wipe(countedSlot)
	barSpellCount = 0
	slotsOccupied = 0
	slotsKnown = 0
	lastFetch = GetTime()

	local queue = {}
	for _, bar in ipairs(BARS) do
		for i = 1, 12 do
			queue[#queue + 1] = _G[bar .. "Button" .. i]
		end
	end
	if GetNumShapeshiftForms then
		local ok, count = pcall(GetNumShapeshiftForms)
		if ok and count then
			for i = 1, count do
				queue[#queue + 1] = { stance = i, button = _G["StanceButton" .. i] }
			end
		end
	end
	if addonLoaded("Dominos") then
		for i = 1, 132 do
			queue[#queue + 1] = _G["DominosActionButton" .. i]
		end
	end
	if addonLoaded("Bartender4") then
		for i = 1, 180 do
			queue[#queue + 1] = _G["BT4Button" .. i]
		end
	end
	if addonLoaded("ElvUI") then
		for bar = 1, 10 do
			for i = 1, 12 do
				queue[#queue + 1] = _G["ElvUI_Bar" .. bar .. "Button" .. i]
			end
		end
	end

	glowFetchGen = glowFetchGen + 1
	local gen = glowFetchGen
	local idx = 1
	local function pump()
		if gen ~= glowFetchGen then
			return
		end
		local budget = 20
		while idx <= #queue and budget > 0 do
			local entry = queue[idx]
			idx = idx + 1
			budget = budget - 1
			if type(entry) == "table" and entry.stance then
				local button = entry.button
				if button and GetShapeshiftFormInfo then
					local okForm, _, _, _, spellID = pcall(function()
						return GetShapeshiftFormInfo(entry.stance)
					end)
					if okForm then
						addButton(spellID, button)
					end
				end
			else
				addStandard(entry)
			end
		end
		if idx <= #queue then
			if C_Timer and C_Timer.After then
				C_Timer.After(0, pump)
			else
				pump()
			end
		elseif ns.InvalidateTick then
			ns.InvalidateTick()
		end
	end
	pump()
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
		local key = normKey(name)
		if key then
			take(spellsByNorm[key])
		end
	end
	local icons = spellIconKeys(id)
	local more = spellIconKeys(resolved or spellID)
	for key in pairs(more) do
		icons[key] = true
	end
	for key in pairs(icons) do
		local list = buttonsByIcon[key]
		if list and #list > 0 and #list <= 4 then
			take(list)
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

function ns.SpellBarSlot(spellID)
	if not spellID then
		return nil
	end
	if lastFetch == 0 then
		ns.GlowFetch()
	end
	local list = buttonsFor(spellID)
	for _, button in ipairs(list) do
		local slot = buttonSlots[button]
		if slot then
			return slot
		end
	end
	return nil
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
		if name and spellsByName[name] and #spellsByName[name] > 0 then
			return true
		end
		local key = name and normKey(name)
		return key and spellsByNorm[key] and #spellsByNorm[key] > 0
	end
	if found(spellID) then
		return true
	end
	local resolved = API.Resolve and API.Resolve(spellID)
	if resolved and resolved ~= spellID and found(resolved) then
		return true
	end
	-- A bar scan that sometimes reads every button and sometimes does not
	-- was clearing the rotation, then bringing it back, with no cast and no target.
	return true
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
	text = text:gsub("MOUSEWHEELUP", "WU")
	text = text:gsub("MOUSEWHEELDOWN", "WD")
	text = text:gsub("[Bb][Uu][Tt][Tt][Oo][Nn](%d+)", "M%1")
	local mouse = text:match("(%d+)%s*$")
	if mouse and #text > 4 then
		local low = text:lower()
		if low:find("button", 1, true)
			or low:find("souris", 1, true)
			or low:find("mouse", 1, true)
			or low:find("maustaste", 1, true)
			or low:find("ratón", 1, true)
			or low:find("raton", 1, true)
			or low:find("мыш", 1, true)
			or low:find("마우스", 1, true)
			or low:find("鼠标", 1, true)
			or low:find("滑鼠", 1, true)
			or low:find("botão", 1, true)
			or low:find("botao", 1, true)
			or low:find("pulsante", 1, true)
			or low:find("tasto", 1, true)
		then
			local prefix = text:match("^([SCA]+)")
			if prefix and #prefix < #text then
				return prefix .. "M" .. mouse
			end
			return "M" .. mouse
		end
	end
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
