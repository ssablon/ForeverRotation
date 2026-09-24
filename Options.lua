local addonName, ns = ...
local API = ns.API
local IMG = "Interface\\AddOns\\WoWForeverRot\\images\\"

local editSpec
local editMode
local listKind = "apl"

local function bindSimpleTip(frame, title, desc)
	frame:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine(title, 1, 0.82, 0)
		if desc then
			GameTooltip:AddLine(desc, 1, 1, 1, true)
		end
		GameTooltip:Show()
	end)
	frame:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
end

local function makeListBtn(parent, width, label)
	local btn = CreateFrame("Button", nil, parent)
	btn:SetSize(width, 18)
	btn:SetNormalFontObject("GameFontHighlightSmall")
	btn:SetText(label)
	local ntex = btn:CreateTexture(nil, "BACKGROUND")
	ntex:SetTexture(IMG .. "buttonUp")
	ntex:SetTexCoord(0, 0.625, 0, 0.6875)
	ntex:SetAllPoints()
	ntex:SetVertexColor(0.83, 0.63, 0.09, 0.9)
	btn:SetNormalTexture(ntex)
	local htex = btn:CreateTexture(nil, "HIGHLIGHT")
	htex:SetTexture(IMG .. "buttonHighlight")
	htex:SetTexCoord(0, 0.625, 0, 0.6875)
	htex:SetAllPoints()
	btn:SetHighlightTexture(htex)
	local ptex = btn:CreateTexture(nil, "BACKGROUND")
	ptex:SetTexture(IMG .. "buttonDown")
	ptex:SetTexCoord(0, 0.625, 0, 0.6875)
	ptex:SetAllPoints()
	ptex:SetVertexColor(0.83, 0.63, 0.09, 1)
	btn:SetPushedTexture(ptex)
	return btn
end

local function modeLabel(mode)
	return ns.T("MODE_" .. (mode or "single"):upper())
end

local function specLabel(spec)
	if spec == "cat" then
		return ns.T("SPEC_CAT")
	end
	if spec == "bear" then
		return ns.T("SPEC_BEAR")
	end
	if spec == "damage" and ns.ClassToken and ns.ClassToken() == "DRUID" then
		return ns.T("SPEC_CASTER")
	end
	return ns.T("ROLE_" .. spec:upper()) or spec
end

local function ensureOptions()
	if ns.UI.options then
		return ns.UI.options
	end
	local frame = CreateFrame("Frame", "WoWForeverRotOptions", UIParent, "BackdropTemplate")
	frame:SetSize(500, 560)
	frame:SetPoint("CENTER", UIParent, "CENTER", 260, 40)
	frame:SetFrameStrata("HIGH")
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 8,
		edgeSize = 14,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	frame:SetBackdropColor(0.05, 0.05, 0.05, 0.94)
	frame:SetBackdropBorderColor(0.83, 0.63, 0.09, 1)
	frame:Hide()
	tinsert(UISpecialFrames, "WoWForeverRotOptions")

	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOP", frame, "TOP", 0, -12)
	title:SetText(ns.T("OPTIONS_TITLE"))

	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 2, 2)

	local function tabBtn(name, text, x)
		local btn = CreateFrame("Button", name, frame, "UIPanelButtonTemplate")
		btn:SetSize(100, 22)
		btn:SetPoint("TOPLEFT", frame, "TOPLEFT", x, -36)
		btn:SetText(text)
		return btn
	end

	local generalTab = tabBtn("WoWForeverRotTabGeneral", ns.T("TAB_GENERAL"), 16)
	local rotTab = tabBtn("WoWForeverRotTabRot", ns.T("TAB_ROTATION"), 122)
	local defTab = tabBtn("WoWForeverRotTabDef", ns.T("TAB_DEFENSE"), 228)
	local extraTab = tabBtn("WoWForeverRotTabExtra", ns.T("TAB_EXTRA"), 334)

	frame.profileButtons = {}
	for i, key in ipairs({ "base", "pve", "pvp", "custom" }) do
		local btn = CreateFrame("Button", "WoWForeverRotProfileEdit" .. i, frame, "UIPanelButtonTemplate")
		btn:SetSize(88, 20)
		btn:SetPoint("TOPLEFT", 16 + (i - 1) * 92, -62)
		btn.profile = key
		btn:SetScript("OnClick", function(self)
			if ns.SetProfile then
				ns.SetProfile(self.profile)
			end
		end)
		frame.profileButtons[i] = btn
	end

	local general = CreateFrame("Frame", nil, frame)
	general:SetPoint("TOPLEFT", 12, -88)
	general:SetPoint("BOTTOMRIGHT", -12, 12)

	local rotation = CreateFrame("Frame", nil, frame)
	rotation:SetPoint("TOPLEFT", 12, -88)
	rotation:SetPoint("BOTTOMRIGHT", -12, 12)
	rotation:Hide()
	local extra = CreateFrame("Frame", nil, frame)
	extra:SetPoint("TOPLEFT", 12, -88)
	extra:SetPoint("BOTTOMRIGHT", -12, 12)
	extra:Hide()
	frame.general = general
	frame.rotation = rotation
	frame.extra = extra

	local function featureOn(key)
		if key == "locked" then
			return ns.db.locked == true
		end
		return ns.db[key] ~= false
	end

	local function check(parent, key, label, y, x)
		local box = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
		box:SetPoint("TOPLEFT", x or 8, y)
		box:SetHitRectInsets(0, -220, -2, -2)
		local text = box.Text or box:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		text:SetPoint("LEFT", box, "RIGHT", 4, 0)
		text:SetWidth(210)
		text:SetJustifyH("LEFT")
		text:SetText(label)
		box.Text = text
		box:SetScript("OnClick", function(self)
			local on = not featureOn(key)
			self:SetChecked(on)
			ns.db[key] = on
			if ns.ApplyFeatureFlags then
				ns.ApplyFeatureFlags()
			elseif ns.Tick then
				ns.Tick()
			end
		end)
		box.dbKey = key
		return box
	end

	local feat = general:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	feat:SetPoint("TOPLEFT", 12, -4)
	feat:SetText(ns.T("OPT_FEATURES"))

	frame.optLock = check(general, "locked", ns.T("OPT_LOCK"), -24)
	frame.optRotation = check(general, "showRotation", ns.T("OPT_ROTATION"), -52)
	frame.optGlow = check(general, "glow", ns.T("OPT_GLOW"), -80)
	frame.optRange = check(general, "showRange", ns.T("OPT_RANGE"), -108)
	frame.optModes = check(general, "showModes", ns.T("OPT_MODES"), -136)

	frame.optDef = check(general, "showDefense", ns.T("OPT_DEFENSE"), -24, 250)
	frame.optKick = check(general, "showInterrupt", ns.T("OPT_INTERRUPT"), -52, 250)
	frame.optPurge = check(general, "showPurge", ns.T("OPT_PURGE"), -80, 250)
	frame.optCleanse = check(general, "showCleanse", ns.T("OPT_CLEANSE"), -108, 250)
	frame.optWeapon = check(general, "showWeapon", ns.T("OPT_WEAPON"), -136, 250)

	local wlabel = general:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	wlabel:SetPoint("TOPLEFT", 16, -180)
	wlabel:SetText(ns.T("OPT_WEAPON_PICK"))
	frame.weaponLabel = wlabel
	frame.weaponBoxes = {}

	local scaleLabel = general:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	scaleLabel:SetPoint("TOPLEFT", 16, -340)
	frame.scaleLabel = scaleLabel

	local scaleLess = CreateFrame("Button", nil, general, "UIPanelButtonTemplate")
	scaleLess:SetSize(22, 20)
	scaleLess:SetPoint("LEFT", scaleLabel, "RIGHT", 10, 0)
	scaleLess:SetText("-")
	scaleLess:SetScript("OnClick", function()
		ns.SetUIScale((ns.UIScale and ns.UIScale() or 1) - 0.1)
	end)

	local scaleMore = CreateFrame("Button", nil, general, "UIPanelButtonTemplate")
	scaleMore:SetSize(22, 20)
	scaleMore:SetPoint("LEFT", scaleLess, "RIGHT", 6, 0)
	scaleMore:SetText("+")
	scaleMore:SetScript("OnClick", function()
		ns.SetUIScale((ns.UIScale and ns.UIScale() or 1) + 0.1)
	end)
	frame.scaleLess = scaleLess
	frame.scaleMore = scaleMore

	local resetPos = CreateFrame("Button", nil, general, "UIPanelButtonTemplate")
	resetPos:SetSize(180, 22)
	resetPos:SetPoint("TOPLEFT", 12, -400)
	resetPos:SetText(ns.T("OPT_RESET_POS"))
	resetPos:SetScript("OnClick", function()
		ns.db.pos = nil
		ns.UI.ApplyPosition()
	end)

	local resetAll = CreateFrame("Button", nil, general, "UIPanelButtonTemplate")
	resetAll:SetSize(220, 22)
	resetAll:SetPoint("LEFT", resetPos, "RIGHT", 8, 0)
	resetAll:SetText(ns.T("OPT_RESET_ALL"))
	resetAll:SetScript("OnClick", function()
		ns.ConfirmResetAll()
	end)

	local hint = general:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	hint:SetPoint("TOPLEFT", 12, -432)
	hint:SetWidth(450)
	hint:SetJustifyH("LEFT")
	hint:SetText(ns.T("OPT_HINT"))

	local specText = rotation:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	specText:SetPoint("TOPLEFT", 8, -2)
	frame.specText = specText

	frame.specButtons = {}
	for i = 1, 5 do
		local btn = CreateFrame("Button", "WoWForeverRotSpec" .. i, rotation, "UIPanelButtonTemplate")
		btn:SetSize(78, 20)
		btn:SetPoint("TOPLEFT", 8 + (i - 1) * 84, -22)
		btn:SetScript("OnClick", function(self)
			if self.spec then
				editSpec = self.spec
				ns.RefreshOptions()
			end
		end)
		btn:Hide()
		frame.specButtons[i] = btn
	end

	frame.modeButtons = {}
	for i, mode in ipairs({ "auto", "single", "aoe", "burst" }) do
		local btn = CreateFrame("Button", "WoWForeverRotModeEdit" .. i, rotation, "UIPanelButtonTemplate")
		btn:SetSize(72, 20)
		btn:SetPoint("TOPLEFT", 8 + (i - 1) * 76, -46)
		btn.mode = mode
		btn:SetScript("OnClick", function(self)
			editMode = self.mode
			ns.RefreshOptions()
			local header = ns.UI.options and ns.UI.options.modeHeaders and ns.UI.options.modeHeaders[self.mode]
			local scroll = ns.UI.options and ns.UI.options.aplScroll
			if header and scroll and header._scrollY then
				scroll:SetVerticalScroll(header._scrollY)
			end
		end)
		frame.modeButtons[i] = btn
	end

	local autoHint = rotation:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	autoHint:SetPoint("TOPLEFT", 8, -68)
	autoHint:SetWidth(360)
	autoHint:SetJustifyH("LEFT")
	frame.autoHint = autoHint

	local autoLess = CreateFrame("Button", nil, rotation, "UIPanelButtonTemplate")
	autoLess:SetSize(22, 18)
	autoLess:SetPoint("TOPRIGHT", rotation, "TOPRIGHT", -54, -66)
	autoLess:SetText("-")
	autoLess:SetScript("OnClick", function()
		local n = tonumber(ns.db.autoEnemies) or 3
		ns.db.autoEnemies = math.max(2, n - 1)
		if ns.FlushProfile then
			ns.FlushProfile()
		end
		ns.RefreshOptions()
		if ns.Tick then
			ns.Tick()
		end
	end)
	frame.autoLess = autoLess

	local autoMore = CreateFrame("Button", nil, rotation, "UIPanelButtonTemplate")
	autoMore:SetSize(22, 18)
	autoMore:SetPoint("TOPRIGHT", rotation, "TOPRIGHT", -8, -66)
	autoMore:SetText("+")
	autoMore:SetScript("OnClick", function()
		local n = tonumber(ns.db.autoEnemies) or 3
		ns.db.autoEnemies = math.min(8, n + 1)
		if ns.FlushProfile then
			ns.FlushProfile()
		end
		ns.RefreshOptions()
		if ns.Tick then
			ns.Tick()
		end
	end)
	frame.autoMore = autoMore

	local autoCount = rotation:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	autoCount:SetPoint("RIGHT", autoLess, "LEFT", -6, 0)
	frame.autoCount = autoCount

	local resetApl = CreateFrame("Button", nil, rotation, "UIPanelButtonTemplate")
	resetApl:SetSize(120, 20)
	resetApl:SetPoint("TOPRIGHT", rotation, "TOPRIGHT", -8, -22)
	resetApl:SetText(ns.T("OPT_RESET_APL"))
	frame.resetApl = resetApl
	resetApl:SetScript("OnClick", function()
		if listKind == "def" then
			ns.ResetDef(nil, editSpec)
		else
			ns.ResetAPL(nil, editSpec, editMode)
		end
		ns.RefreshOptions()
	end)

	local scroll = CreateFrame("ScrollFrame", "WoWForeverRotAPLScroll", rotation, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", 4, -90)
	scroll:SetPoint("BOTTOMRIGHT", -28, 4)
	local child = CreateFrame("Frame", nil, scroll)
	child:SetSize(430, 10)
	scroll:SetScrollChild(child)
	frame.aplScroll = scroll
	frame.aplChild = child
	frame.aplRows = {}
	frame.modeHeaders = {}
	frame.modeDrops = {}

	local function makeDropZone(name)
		local addBtn = CreateFrame("Button", name, child, "BackdropTemplate")
		addBtn:SetSize(390, 32)
		addBtn:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8x8",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true,
			tileSize = 8,
			edgeSize = 12,
			insets = { left = 3, right = 3, top = 3, bottom = 3 },
		})
		addBtn:SetBackdropColor(0.04, 0.08, 0.05, 0.9)
		addBtn:SetBackdropBorderColor(0.83, 0.63, 0.09, 0.85)
		local addText = addBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		addText:SetPoint("CENTER")
		addText:SetText(ns.T("OPT_ADD_SPELL"))
		addBtn.label = addText
		addBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		addBtn:SetScript("OnReceiveDrag", function(self)
			ns.DropSpellOnList(nil, self.mode)
		end)
		addBtn:SetScript("OnMouseUp", function(self)
			if ns.API.CursorSpell and ns.API.CursorSpell() then
				ns.DropSpellOnList(nil, self.mode)
			end
		end)
		addBtn:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:AddLine(ns.T("OPT_ADD_SPELL"), 1, 0.82, 0)
			GameTooltip:AddLine(ns.T("OPT_DROP_SPELL"), 1, 1, 1, true)
			GameTooltip:Show()
		end)
		addBtn:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
		addBtn:Hide()
		return addBtn
	end

	frame.addSpell = makeDropZone("WoWForeverRotAddSpell")
	for _, mode in ipairs({ "auto", "single", "aoe", "burst" }) do
		local header = CreateFrame("Frame", nil, child)
		header:SetSize(420, 22)
		local text = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		text:SetPoint("LEFT", 4, 0)
		header.label = text
		local reset = CreateFrame("Button", nil, header, "UIPanelButtonTemplate")
		reset:SetSize(80, 18)
		reset:SetPoint("RIGHT", 0, 0)
		reset:SetText(ns.T("OPT_RESET_APL"))
		reset:SetScript("OnClick", function(self)
			if self.mode then
				ns.ResetAPL(nil, editSpec, self.mode)
				ns.RefreshOptions()
			end
		end)
		header.reset = reset
		header:Hide()
		frame.modeHeaders[mode] = header
		local drop = makeDropZone("WoWForeverRotAddSpell_" .. mode)
		drop.mode = mode
		frame.modeDrops[mode] = drop
	end

	local function pickColor(key)
		local r, g, b = ns.Color(key)
		local function apply(nr, ng, nb)
			ns.db.colors = ns.db.colors or {}
			ns.db.colors[key] = { nr, ng, nb }
			if ns.GlowInvalidate then
				ns.GlowInvalidate()
			end
			if ns.ApplyFeatureFlags then
				ns.ApplyFeatureFlags()
			end
			ns.RefreshOptions()
		end
		if ColorPickerFrame and ColorPickerFrame.SetupColorPickerAndShow then
			ColorPickerFrame:SetupColorPickerAndShow({
				r = r,
				g = g,
				b = b,
				hasOpacity = false,
				swatchFunc = function()
					local cr, cg, cb = ColorPickerFrame:GetColorRGB()
					apply(cr, cg, cb)
				end,
				cancelFunc = function()
					apply(r, g, b)
				end,
			})
		elseif ColorPickerFrame then
			ColorPickerFrame.func = function()
				local cr, cg, cb = ColorPickerFrame:GetColorRGB()
				apply(cr, cg, cb)
			end
			ColorPickerFrame.cancelFunc = function()
				apply(r, g, b)
			end
			if ColorPickerFrame.SetColorRGB then
				ColorPickerFrame:SetColorRGB(r, g, b)
			end
			ColorPickerFrame:Show()
		end
	end

	frame.optHideIdle = check(extra, "hideIdle", ns.T("OPT_HIDE_IDLE"), -4)
	frame.optBarOnly = check(extra, "barOnly", ns.T("OPT_BAR_ONLY"), -32)
	frame.optAutoProfile = check(extra, "autoProfile", ns.T("OPT_AUTO_PROFILE"), -60)
	frame.optCleanseGroup = check(extra, "cleanseGroup", ns.T("OPT_CLEANSE_GROUP"), -88)
	for _, box in ipairs({ frame.optHideIdle, frame.optBarOnly, frame.optAutoProfile, frame.optCleanseGroup }) do
		if box.Text then
			box.Text:SetWidth(420)
		end
		box:SetHitRectInsets(0, -400, -2, -2)
	end

	local colorTitle = extra:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	colorTitle:SetPoint("TOPLEFT", 12, -124)
	colorTitle:SetText(ns.T("OPT_COLORS"))

	frame.colorButtons = {}
	local colorKeys = { "next", "heal", "def", "weapon", "range" }
	local colorLabels = { "OPT_COLOR_NEXT", "OPT_COLOR_HEAL", "OPT_COLOR_DEF", "OPT_COLOR_WEAPON", "OPT_COLOR_RANGE" }
	for i, key in ipairs(colorKeys) do
		local btn = CreateFrame("Button", nil, extra, "BackdropTemplate")
		btn:SetSize(22, 22)
		btn:SetPoint("TOPLEFT", 16 + (i - 1) * 90, -148)
		btn:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8x8",
			edgeFile = "Interface\\Buttons\\WHITE8x8",
			edgeSize = 1,
		})
		btn.colorKey = key
		btn:SetScript("OnClick", function()
			pickColor(key)
		end)
		local label = extra:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		label:SetPoint("LEFT", btn, "RIGHT", 4, 0)
		label:SetText(ns.T(colorLabels[i]))
		frame.colorButtons[i] = btn
	end

	local soundLabel = extra:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	soundLabel:SetPoint("TOPLEFT", 16, -186)
	frame.soundLabel = soundLabel

	local soundLess = CreateFrame("Button", nil, extra, "UIPanelButtonTemplate")
	soundLess:SetSize(22, 20)
	soundLess:SetPoint("LEFT", soundLabel, "RIGHT", 10, 0)
	soundLess:SetText("-")
	soundLess:SetScript("OnClick", function()
		ns.db.soundVolume = math.max(0, (tonumber(ns.db.soundVolume) or 60) - 10)
		ns.RefreshOptions()
	end)
	local soundMore = CreateFrame("Button", nil, extra, "UIPanelButtonTemplate")
	soundMore:SetSize(22, 20)
	soundMore:SetPoint("LEFT", soundLess, "RIGHT", 6, 0)
	soundMore:SetText("+")
	soundMore:SetScript("OnClick", function()
		ns.db.soundVolume = math.min(100, (tonumber(ns.db.soundVolume) or 60) + 10)
		ns.RefreshOptions()
	end)
	frame.soundLess = soundLess
	frame.soundMore = soundMore

	local soundHint = extra:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	soundHint:SetPoint("TOPLEFT", 16, -210)
	soundHint:SetWidth(450)
	soundHint:SetJustifyH("LEFT")
	soundHint:SetText(ns.T("OPT_SOUND_HINT"))

	local shareHint = extra:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	shareHint:SetPoint("TOPLEFT", 16, -238)
	shareHint:SetWidth(450)
	shareHint:SetJustifyH("LEFT")
	shareHint:SetText(ns.T("OPT_EXPORT_HINT"))

	local box = CreateFrame("ScrollFrame", "WoWForeverRotShareScroll", extra, "UIPanelScrollFrameTemplate")
	box:SetPoint("TOPLEFT", 16, -268)
	box:SetPoint("BOTTOMRIGHT", -36, 48)
	local edit = CreateFrame("EditBox", "WoWForeverRotShareEdit", box)
	edit:SetMultiLine(true)
	edit:SetFontObject("ChatFontSmall")
	edit:SetWidth(420)
	edit:SetHeight(400)
	edit:SetAutoFocus(false)
	edit:EnableMouse(true)
	edit:SetMaxLetters(25000)
	edit:SetTextInsets(4, 4, 4, 4)
	edit:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	box:SetScrollChild(edit)
	frame.shareEdit = edit

	local exportBtn = CreateFrame("Button", nil, extra, "UIPanelButtonTemplate")
	exportBtn:SetSize(140, 22)
	exportBtn:SetPoint("BOTTOMLEFT", 16, 16)
	exportBtn:SetText(ns.T("OPT_EXPORT"))
	exportBtn:SetScript("OnClick", function()
		if ns.ExportProfile then
			edit:SetText(ns.ExportProfile())
			edit:HighlightText()
			edit:SetFocus()
		end
	end)

	local importBtn = CreateFrame("Button", nil, extra, "UIPanelButtonTemplate")
	importBtn:SetSize(140, 22)
	importBtn:SetPoint("LEFT", exportBtn, "RIGHT", 8, 0)
	importBtn:SetText(ns.T("OPT_IMPORT"))
	importBtn:SetScript("OnClick", function()
		if not ns.ImportProfile then
			return
		end
		local ok, msg, extraArg = ns.ImportProfile(edit:GetText() or "")
		if ok then
			print("|cff66ccffWoW Forever Rot|r: " .. ns.T(msg))
			ns.RefreshOptions()
			return
		end
		if msg == "OPT_IMPORT_CLASS" then
			print("|cff66ccffWoW Forever Rot|r: " .. ns.T("OPT_IMPORT_CLASS"):format(extraArg or "?"))
			return
		end
		print("|cff66ccffWoW Forever Rot|r: " .. ns.T(msg or "OPT_IMPORT_BAD"))
	end)

	local function showTab(which)
		listKind = which == "def" and "def" or "apl"
		general:SetShown(which == "general")
		rotation:SetShown(which == "rotation" or which == "def")
		extra:SetShown(which == "extra")
	end
	generalTab:SetScript("OnClick", function()
		showTab("general")
	end)
	rotTab:SetScript("OnClick", function()
		showTab("rotation")
		ns.RefreshOptions()
	end)
	defTab:SetScript("OnClick", function()
		showTab("def")
		ns.RefreshOptions()
	end)
	extraTab:SetScript("OnClick", function()
		showTab("extra")
		ns.RefreshOptions()
	end)

	ns.UI.options = frame
	return frame
end

local function aplRow(parent, index)
	local rows = ns.UI.options.aplRows
	if rows[index] then
		return rows[index]
	end
	local row = CreateFrame("Frame", nil, parent)
	row:SetSize(420, 28)
	row:EnableMouse(true)
	row:SetPoint("TOPLEFT", parent, "TOPLEFT", 2, -2 - (index - 1) * 30)
	row:SetScript("OnReceiveDrag", function(self)
		ns.DropSpellOnList(self.index, self.mode)
	end)
	row:SetScript("OnMouseUp", function(self)
		if ns.API.CursorSpell and ns.API.CursorSpell() then
			ns.DropSpellOnList(self.index, self.mode)
		end
	end)

	local num = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	num:SetPoint("LEFT", 2, 0)
	num:SetWidth(18)
	row.num = num

	local box = CreateFrame("CheckButton", "WoWForeverRotAPLCheck" .. index, row, "UICheckButtonTemplate")
	box:SetPoint("LEFT", 20, 0)
	box:SetSize(24, 24)
	row.box = box

	local icon = row:CreateTexture(nil, "ARTWORK")
	icon:SetSize(20, 20)
	icon:SetPoint("LEFT", 48, 0)
	row.icon = icon

	local name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	name:SetPoint("LEFT", 74, 0)
	name:SetWidth(136)
	name:SetJustifyH("LEFT")
	row.label = name

	local up = makeListBtn(row, 44, ns.T("OPT_MOVE_UP"))
	up:SetPoint("RIGHT", -96, 0)
	bindSimpleTip(up, ns.T("OPT_MOVE_UP"), ns.T("OPT_MOVE_UP_TIP"))
	row.up = up

	local down = makeListBtn(row, 44, ns.T("OPT_MOVE_DOWN"))
	down:SetPoint("RIGHT", -50, 0)
	bindSimpleTip(down, ns.T("OPT_MOVE_DOWN"), ns.T("OPT_MOVE_DOWN_TIP"))
	row.down = down

	local del = makeListBtn(row, 46, ns.T("OPT_REMOVE_SPELL"))
	del:SetPoint("RIGHT", 0, 0)
	bindSimpleTip(del, ns.T("OPT_REMOVE_SPELL"), ns.T("OPT_REMOVE_SPELL_TIP"))
	row.del = del

	box:SetScript("OnClick", function(self)
		if self.stepKey then
			local on = ns.CoerceChecked(self:GetChecked())
			if listKind == "def" then
				ns.SetDefEnabled(self.stepKey, on, nil, editSpec)
			else
				ns.SetAPLEnabled(self.stepKey, on, nil, editSpec, self.mode)
			end
			ns.RefreshOptions()
		end
	end)
	up:SetScript("OnClick", function(self)
		if self.index then
			if listKind == "def" then
				ns.MoveDef(self.index, -1, nil, editSpec)
			else
				ns.MoveAPL(self.index, -1, nil, editSpec, self.mode)
			end
			ns.RefreshOptions()
		end
	end)
	down:SetScript("OnClick", function(self)
		if self.index then
			if listKind == "def" then
				ns.MoveDef(self.index, 1, nil, editSpec)
			else
				ns.MoveAPL(self.index, 1, nil, editSpec, self.mode)
			end
			ns.RefreshOptions()
		end
	end)
	del:SetScript("OnClick", function(self)
		if not self.stepKey then
			return
		end
		if listKind == "def" then
			ns.RemoveDef(self.stepKey, nil, editSpec)
		else
			ns.RemoveAPL(self.stepKey, nil, editSpec, self.mode)
		end
		ns.RefreshOptions()
	end)

	rows[index] = row
	return row
end

function ns.DropSpellOnList(atIndex, mode)
	local spellID = ns.API.CursorSpell and ns.API.CursorSpell()
	if not spellID then
		return
	end
	local added
	if listKind == "def" or (ns.IsMaintenanceBuff and ns.IsMaintenanceBuff(spellID)) then
		added = ns.AddDef(spellID, nil, editSpec, atIndex)
	else
		added = ns.AddAPL(spellID, nil, editSpec, mode or editMode, atIndex)
	end
	if ClearCursor then
		pcall(ClearCursor)
	end
	ns.RefreshOptions()
	if not added then
		return
	end
end

function ns.RefreshOptions()
	local frame = ensureOptions()
	if frame.optLock then
		frame.optLock:SetChecked(ns.db.locked == true)
		frame.optGlow:SetChecked(ns.db.glow ~= false)
		if frame.optRotation then
			frame.optRotation:SetChecked(ns.db.showRotation ~= false)
		end
		if frame.optRange then
			frame.optRange:SetChecked(ns.db.showRange ~= false)
		end
		if frame.optModes then
			frame.optModes:SetChecked(ns.db.showModes ~= false)
		end
		frame.optDef:SetChecked(ns.db.showDefense ~= false)
		frame.optKick:SetChecked(ns.db.showInterrupt ~= false)
		frame.optPurge:SetChecked(ns.db.showPurge ~= false)
		if frame.optCleanse then
			frame.optCleanse:SetChecked(ns.db.showCleanse ~= false)
			frame.optWeapon:SetChecked(ns.db.showWeapon ~= false)
		end
		if frame.optHideIdle then
			frame.optHideIdle:SetChecked(ns.db.hideIdle ~= false)
		end
		if frame.optBarOnly then
			frame.optBarOnly:SetChecked(ns.db.barOnly ~= false)
		end
		if frame.optAutoProfile then
			frame.optAutoProfile:SetChecked(ns.db.autoProfile ~= false)
		end
		if frame.optCleanseGroup then
			frame.optCleanseGroup:SetChecked(ns.db.cleanseGroup ~= false)
		end
	end
	if frame.soundLabel then
		frame.soundLabel:SetText(ns.T("OPT_SOUND"):format(tonumber(ns.db.soundVolume) or 60))
	end
	if frame.colorButtons then
		for _, btn in ipairs(frame.colorButtons) do
			local r, g, b = ns.Color(btn.colorKey)
			btn:SetBackdropColor(r, g, b, 1)
			btn:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
		end
	end
	if frame.scaleLabel then
		local pct = math.floor((ns.UIScale and ns.UIScale() or 1) * 100 + 0.5)
		frame.scaleLabel:SetText(ns.T("OPT_SCALE"):format(pct))
	end
	local choices = ns.WeaponChoices and ns.WeaponChoices() or {}
	if frame.weaponLabel then
		frame.weaponLabel:SetShown(#choices > 0)
		for i, entry in ipairs(choices) do
			local box = frame.weaponBoxes[i]
			if not box then
				box = CreateFrame("CheckButton", "WoWForeverRotWep" .. i, frame.general, "UICheckButtonTemplate")
				box:SetPoint("TOPLEFT", 20, -200 - (i - 1) * 24)
				local text = box:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
				text:SetPoint("LEFT", box, "RIGHT", 4, 0)
				box.label = text
				box:SetScript("OnClick", function(self)
					if self.wepKey then
						ns.db.weaponBuff = self.wepKey
						if ns.FlushProfile then
							ns.FlushProfile()
						end
						ns.RefreshOptions()
						if ns.Tick then
							ns.Tick()
						end
					end
				end)
				frame.weaponBoxes[i] = box
			end
			box.wepKey = entry.key
			box.label:SetText(API.SpellName(entry.id) or entry.key)
			box:SetChecked(ns.db.weaponBuff == entry.key or (not ns.db.weaponBuff and i == 1))
			box:Show()
		end
		for i = #choices + 1, #frame.weaponBoxes do
			frame.weaponBoxes[i]:Hide()
		end
	end
	editSpec = editSpec or ns.ActiveSpec()
	editMode = editMode or (ns.CombatMode and ns.CombatMode()) or "auto"
	if editMode ~= "auto" and editMode ~= "aoe" and editMode ~= "burst" then
		editMode = "single"
	end
	local specs = ns.SpecList()
	local valid = false
	for _, spec in ipairs(specs) do
		if spec == editSpec then
			valid = true
		end
	end
	if not valid then
		editSpec = specs[1]
	end
	local profileKey = ns.ProfileKey and ns.ProfileKey() or "pve"
	local profile = ns.T("PROFILE_" .. profileKey:upper())
	if listKind == "def" then
		frame.specText:SetText(ns.T("DEF_FOR"):format(specLabel(editSpec) .. " — " .. profile))
	else
		frame.specText:SetText(ns.T("ROT_FOR"):format(specLabel(editSpec) .. " — " .. profile))
	end
	if frame.profileButtons then
		for _, btn in ipairs(frame.profileButtons) do
			btn:SetText(ns.T("PROFILE_" .. btn.profile:upper()))
			if btn.profile == profileKey then
				btn:SetNormalFontObject("GameFontNormalSmall")
			else
				btn:SetNormalFontObject("GameFontHighlightSmall")
			end
		end
	end
	if frame.resetApl then
		frame.resetApl:SetShown(listKind == "def")
	end
	for i = 1, 5 do
		local btn = frame.specButtons[i]
		local spec = specs[i]
		if spec then
			btn.spec = spec
			btn:SetText(specLabel(spec))
			btn:Show()
		else
			btn:Hide()
		end
	end
	if frame.modeButtons then
		for _, btn in ipairs(frame.modeButtons) do
			btn:SetText(modeLabel(btn.mode))
			btn:SetShown(listKind ~= "def")
			if btn.mode == editMode then
				btn:SetNormalFontObject("GameFontNormalSmall")
			else
				btn:SetNormalFontObject("GameFontHighlightSmall")
			end
		end
	end
	local showAuto = listKind ~= "def" and editMode == "auto"
	if frame.autoHint then
		frame.autoHint:SetText(ns.T("OPT_AUTO_HINT"))
		frame.autoHint:SetShown(showAuto)
	end
	if frame.autoCount then
		local n = tonumber(ns.db.autoEnemies) or 3
		frame.autoCount:SetText(ns.T("OPT_AUTO_COUNT"):format(n))
		frame.autoCount:SetShown(showAuto)
	end
	if frame.autoLess then
		frame.autoLess:SetShown(showAuto)
		frame.autoMore:SetShown(showAuto)
	end
	local child = frame.aplChild
	local y = 2
	local rowIndex = 0

	local function bindRow(row, step, index, mode)
		row:Show()
		row.mode = mode
		row.index = index
		row.num:SetText(tostring(index))
		row.box.stepKey = step.key
		row.box.mode = mode
		row.box:SetChecked(ns.IsStepEnabled(step))
		row.up.index = index
		row.up.mode = mode
		row.down.index = index
		row.down.mode = mode
		if row.del then
			row.del.stepKey = step.key
			row.del.index = index
			row.del.mode = mode
		end
		row.icon:SetTexture(API.SpellIcon(step.id) or (IMG .. "skull"))
		local name = API.SpellName(step.id) or step.key
		if step.racial then
			name = ns.T("RACIAL_PREFIX"):format(name)
		end
		row.label:SetText(name)
		local known = API.Known(step.id)
		row.label:SetTextColor(known and 1 or 0.55, known and 1 or 0.55, known and 1 or 0.55)
	end

	local function renderSteps(steps, mode)
		for i, step in ipairs(steps) do
			rowIndex = rowIndex + 1
			local row = aplRow(child, rowIndex)
			row:ClearAllPoints()
			row:SetPoint("TOPLEFT", child, "TOPLEFT", 2, -y)
			bindRow(row, step, i, mode)
			y = y + 30
		end
	end

	if listKind == "def" then
		if frame.modeHeaders then
			for _, header in pairs(frame.modeHeaders) do
				header:Hide()
			end
		end
		if frame.modeDrops then
			for _, drop in pairs(frame.modeDrops) do
				drop:Hide()
			end
		end
		renderSteps(ns.GetDef(nil, editSpec), nil)
		if frame.addSpell then
			frame.addSpell:ClearAllPoints()
			frame.addSpell:SetPoint("TOPLEFT", child, "TOPLEFT", 2, -y)
			frame.addSpell.mode = nil
			if frame.addSpell.label then
				frame.addSpell.label:SetText(ns.T("OPT_ADD_SPELL"))
			end
			frame.addSpell:Show()
			y = y + 40
		end
	else
		if frame.addSpell then
			frame.addSpell:Hide()
		end
		for _, mode in ipairs({ "auto", "single", "aoe", "burst" }) do
			local header = frame.modeHeaders and frame.modeHeaders[mode]
			if header then
				header:Show()
				header:ClearAllPoints()
				header:SetPoint("TOPLEFT", child, "TOPLEFT", 2, -y)
				header._scrollY = y
				header.label:SetText(modeLabel(mode))
				header.reset.mode = mode
				y = y + 24
			end
			renderSteps(ns.GetAPL(nil, editSpec, mode), mode)
			local drop = frame.modeDrops and frame.modeDrops[mode]
			if drop then
				drop:Show()
				drop:ClearAllPoints()
				drop:SetPoint("TOPLEFT", child, "TOPLEFT", 2, -y)
				drop.mode = mode
				if drop.label then
					drop.label:SetText(ns.T("OPT_ADD_SPELL"))
				end
				y = y + 40
			end
			y = y + 8
		end
	end

	for i = rowIndex + 1, #frame.aplRows do
		frame.aplRows[i]:Hide()
		frame.aplRows[i].box.stepKey = nil
		frame.aplRows[i].index = nil
		frame.aplRows[i].mode = nil
		if frame.aplRows[i].del then
			frame.aplRows[i].del.stepKey = nil
			frame.aplRows[i].del.mode = nil
		end
	end
	child:SetHeight(math.max(40, y + 10))
end

function ns.ToggleOptions()
	local frame = ensureOptions()
	if frame:IsShown() then
		frame:Hide()
		return
	end
	editSpec = ns.ActiveSpec()
	ns.RefreshOptions()
	frame:Show()
end

ns.ToggleSpellMenu = ns.ToggleOptions

local function placeMinimap(btn)
	local angle = (ns.db.minimapAngle or 210) * math.pi / 180
	local radius = 80
	btn:ClearAllPoints()
	btn:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

function ns.CreateMinimap()
	if ns.UI.minimap then
		return
	end
	local btn = CreateFrame("Button", "WoWForeverRotMinimap", Minimap)
	btn:SetSize(32, 32)
	btn:SetFrameStrata("MEDIUM")
	btn:SetFrameLevel(8)
	btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	btn:RegisterForDrag("LeftButton")
	btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
	local icon = btn:CreateTexture(nil, "ARTWORK")
	icon:SetTexture(IMG .. "minimap")
	icon:SetPoint("TOPLEFT", 6, -6)
	icon:SetPoint("BOTTOMRIGHT", -6, 6)
	local border = btn:CreateTexture(nil, "OVERLAY")
	border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	border:SetSize(54, 54)
	border:SetPoint("TOPLEFT")
	btn:SetScript("OnClick", function(_, button)
		if button == "RightButton" then
			ns.UI.SetLocked(not ns.db.locked)
			return
		end
		ns.ToggleOptions()
	end)
	btn:SetScript("OnDragStart", function(self)
		self:SetScript("OnUpdate", function(me)
			local mx, my = Minimap:GetCenter()
			local cx, cy = GetCursorPosition()
			local scale = Minimap:GetEffectiveScale()
			cx, cy = cx / scale, cy / scale
			ns.db.minimapAngle = math.deg(math.atan2(cy - my, cx - mx))
			placeMinimap(me)
		end)
	end)
	btn:SetScript("OnDragStop", function(self)
		self:SetScript("OnUpdate", nil)
	end)
	btn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:AddLine(ns.T("TITLE"), 1, 0.82, 0)
		GameTooltip:AddLine(ns.T("MINIMAP_L"), 1, 1, 1)
		GameTooltip:AddLine(ns.T("MINIMAP_R"), 0.7, 0.7, 0.7)
		GameTooltip:Show()
	end)
	btn:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	placeMinimap(btn)
	ns.UI.minimap = btn
end
