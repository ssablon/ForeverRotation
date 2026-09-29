local addonName, ns = ...
local API = ns.API
local IMG = "Interface\\AddOns\\WoWForeverRot\\images\\"
local SITE_URL = "https://wow-forever.fr"
local DISCORD_URL = "https://discord.gg/qmb2uDu8Z3"
local CURSE_URL = "https://www.curseforge.com/wow/addons/forever-rot"
local GITHUB_URL = "https://github.com/ssablon/ForeverRotation"

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

local PANEL = {
	bgFile = "Interface\\Buttons\\WHITE8x8",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 16,
	edgeSize = 12,
	insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

local function addonVersion()
	local ver
	if C_AddOns and C_AddOns.GetAddOnMetadata then
		local ok, value = pcall(C_AddOns.GetAddOnMetadata, addonName, "Version")
		if ok then
			ver = value
		end
	end
	if (not ver or ver == "") and GetAddOnMetadata then
		local ok, value = pcall(GetAddOnMetadata, addonName, "Version")
		if ok then
			ver = value
		end
	end
	return ver or ""
end

local function makeListBtn(parent, width, label)
	local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
	btn:SetSize(width, 18)
	btn:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 8,
		edgeSize = 8,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	btn:SetBackdropColor(0.06, 0.06, 0.06, 0.95)
	btn:SetBackdropBorderColor(0.55, 0.45, 0.18, 0.85)
	local text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	text:SetPoint("CENTER", 0, 0)
	text:SetText(label)
	text:SetTextColor(0.92, 0.92, 0.92)
	btn.label = text
	function btn:SetText(value)
		self.label:SetText(value)
	end
	btn:SetScript("OnEnter", function(self)
		self:SetBackdropBorderColor(1, 0.82, 0.2, 1)
		self.label:SetTextColor(1, 0.82, 0.2)
	end)
	btn:SetScript("OnLeave", function(self)
		self:SetBackdropBorderColor(0.55, 0.45, 0.18, 0.85)
		self.label:SetTextColor(0.92, 0.92, 0.92)
	end)
	return btn
end

local function makeGoldBtn(parent, width, height, label)
	local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
	btn:SetSize(width, height)
	btn:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 8,
		edgeSize = 10,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	local text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	text:SetPoint("CENTER", 0, 0)
	text:SetText(label or "")
	btn.label = text
	function btn:SetText(value)
		self.label:SetText(value)
	end
	function btn:SetSelected(on)
		self._selected = on and true or false
		if self._selected then
			self:SetBackdropColor(0.28, 0.20, 0.04, 0.95)
			self:SetBackdropBorderColor(1, 0.82, 0.2, 1)
			self.label:SetTextColor(1, 0.82, 0.2)
		else
			self:SetBackdropColor(0.06, 0.06, 0.06, 0.95)
			self:SetBackdropBorderColor(0.55, 0.45, 0.18, 1)
			self.label:SetTextColor(0.92, 0.92, 0.92)
		end
	end
	function btn:SetNormalFontObject(font)
		self:SetSelected(font == "GameFontNormalSmall" or font == GameFontNormalSmall)
	end
	btn:SetSelected(false)
	btn:SetScript("OnEnter", function(self)
		self:SetBackdropBorderColor(1, 0.82, 0.2, 1)
		self.label:SetTextColor(1, 0.82, 0.2)
	end)
	btn:SetScript("OnLeave", function(self)
		self:SetSelected(self._selected)
	end)
	return btn
end

local function makeCard(parent, titleKey, x, y, width, height)
	local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	card:SetSize(width, height)
	card:SetPoint("TOPLEFT", x, y)
	card:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 8,
		edgeSize = 8,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	card:SetBackdropColor(0, 0, 0, 0.55)
	card:SetBackdropBorderColor(0.5, 0.42, 0.28, 0.9)
	local title = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOP", 0, -8)
	title:SetText(ns.T(titleKey))
	title:SetTextColor(1, 0.82, 0.2)
	card.title = title
	card.titleKey = titleKey
	card._y = -30
	card:SetScript("OnEnter", function(self)
		self:SetBackdropColor(0.35, 0.30, 0.09, 0.55)
		self:SetBackdropBorderColor(1, 0.94, 0.23, 0.95)
	end)
	card:SetScript("OnLeave", function(self)
		self:SetBackdropColor(0, 0, 0, 0.55)
		self:SetBackdropBorderColor(0.5, 0.42, 0.28, 0.9)
	end)
	return card
end

local function featureOn(key)
	if key == "locked" then
		return ns.db.locked == true
	end
	return ns.db[key] ~= false
end

local function paintSwitch(sw, on)
	if on then
		sw:SetBackdropColor(0.38, 0.25, 0.02, 0.95)
		sw:SetBackdropBorderColor(1, 0.82, 0.2, 1)
		sw.knob:ClearAllPoints()
		sw.knob:SetPoint("RIGHT", sw, "RIGHT", -3, 0)
		sw.knob:SetVertexColor(1, 0.82, 0.2, 1)
		sw.state:SetText(ns.T("SWITCH_ON"))
		sw.state:SetTextColor(1, 0.92, 0.45)
		sw.state:ClearAllPoints()
		sw.state:SetPoint("CENTER", sw, "CENTER", -10, 0)
	else
		sw:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
		sw:SetBackdropBorderColor(0.42, 0.42, 0.42, 1)
		sw.knob:ClearAllPoints()
		sw.knob:SetPoint("LEFT", sw, "LEFT", 3, 0)
		sw.knob:SetVertexColor(0.48, 0.48, 0.48, 1)
		sw.state:SetText(ns.T("SWITCH_OFF"))
		sw.state:SetTextColor(0.65, 0.65, 0.65)
		sw.state:ClearAllPoints()
		sw.state:SetPoint("CENTER", sw, "CENTER", 10, 0)
	end
end

local function makeSwitch(parent, key, label)
	local row = CreateFrame("Frame", nil, parent)
	row:SetHeight(24)
	local txt = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	txt:SetPoint("LEFT", 0, 0)
	txt:SetPoint("RIGHT", -66, 0)
	txt:SetJustifyH("LEFT")
	txt:SetText(label)
	txt:SetTextColor(0.92, 0.92, 0.92)
	local sw = CreateFrame("Button", nil, row, "BackdropTemplate")
	sw:SetSize(58, 22)
	sw:SetPoint("RIGHT", 0, 0)
	sw:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 8,
		edgeSize = 8,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	local knob = sw:CreateTexture(nil, "ARTWORK")
	knob:SetTexture("Interface\\Buttons\\WHITE8x8")
	knob:SetSize(16, 16)
	sw.knob = knob
	local state = sw:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	sw.state = state
	local function current()
		return featureOn(key)
	end
	sw:SetScript("OnClick", function()
		local on = not current()
		ns.db[key] = on
		paintSwitch(sw, on)
		if ns.ApplyFeatureFlags then
			ns.ApplyFeatureFlags()
		elseif ns.Tick then
			ns.Tick()
		end
	end)
	row:SetScript("OnEnter", function()
		txt:SetTextColor(1, 0.82, 0.2)
	end)
	row:SetScript("OnLeave", function()
		txt:SetTextColor(0.92, 0.92, 0.92)
	end)
	function row:SetChecked(on)
		paintSwitch(sw, on and true or false)
	end
	function row:GetChecked()
		return current()
	end
	row.Text = txt
	row.dbKey = key
	row.switch = sw
	paintSwitch(sw, current())
	return row
end

local function copyText(text)
	if type(text) ~= "string" or text == "" then
		return false
	end
	if CopyToClipboard then
		pcall(CopyToClipboard, text)
	end
	if ChatFrame_OpenChat then
		local ok = pcall(ChatFrame_OpenChat, text, DEFAULT_CHAT_FRAME)
		if ok then
			local box = DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.editBox
			if box and box.HighlightText then
				pcall(box.HighlightText, box)
			end
			ns.Print(ns.T("INFO_COPIED"))
			return true
		end
	end
	local box
	if ChatEdit_ChooseBoxForSend then
		local ok, chosen = pcall(ChatEdit_ChooseBoxForSend)
		if ok then
			box = chosen
		end
	end
	box = box or (DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.editBox)
	if not box then
		return false
	end
	if ChatEdit_ActivateChat then
		pcall(ChatEdit_ActivateChat, box)
	end
	if box.SetText then
		pcall(box.SetText, box, text)
	end
	if box.HighlightText then
		pcall(box.HighlightText, box)
	end
	if box.SetFocus then
		pcall(box.SetFocus, box)
	end
	ns.Print(ns.T("INFO_COPIED"))
	return true
end

local function makeLinkRow(parent, labelKey, url)
	local row = CreateFrame("Frame", nil, parent)
	row:SetHeight(26)
	local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	label:SetPoint("LEFT", 0, 0)
	label:SetWidth(90)
	label:SetJustifyH("LEFT")
	label:SetTextColor(0.92, 0.92, 0.92)
	label:SetText(ns.T(labelKey))
	row.label = label
	row.labelKey = labelKey
	local box = CreateFrame("EditBox", nil, row, "BackdropTemplate")
	box:SetPoint("LEFT", label, "RIGHT", 8, 0)
	box:SetPoint("RIGHT", -72, 0)
	box:SetHeight(22)
	box:SetAutoFocus(false)
	box:SetFontObject("ChatFontSmall")
	box:SetTextInsets(6, 6, 2, 2)
	box:SetText(url)
	box:SetCursorPosition(0)
	if box.SetBackdrop then
		box:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8x8",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true,
			tileSize = 8,
			edgeSize = 8,
			insets = { left = 2, right = 2, top = 2, bottom = 2 },
		})
		box:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
		box:SetBackdropBorderColor(0.42, 0.42, 0.42, 1)
	end
	box:SetScript("OnEditFocusGained", function(self)
		self:HighlightText()
	end)
	box:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	box:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
	end)
	row.box = box
	local copy = makeGoldBtn(row, 64, 22, ns.T("INFO_COPY"))
	copy:SetPoint("RIGHT", 0, 0)
	copy:SetScript("OnClick", function()
		if not copyText(url) then
			box:SetFocus()
			box:HighlightText()
		end
	end)
	row.copy = copy
	return row
end

local function addSwitch(card, key, label)
	local row = makeSwitch(card, key, label)
	row:SetPoint("TOPLEFT", card, "TOPLEFT", 12, card._y)
	row:SetPoint("TOPRIGHT", card, "TOPRIGHT", -12, card._y)
	card._y = card._y - 26
	return row
end

local function makeBarSlider(parent, width, minV, maxV, step)
	local bar = CreateFrame("Button", nil, parent, "BackdropTemplate")
	bar:SetSize(width, 16)
	bar:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 8,
		edgeSize = 8,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	bar:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
	bar:SetBackdropBorderColor(0.42, 0.42, 0.42, 1)
	local fill = bar:CreateTexture(nil, "ARTWORK")
	fill:SetTexture("Interface\\Buttons\\WHITE8x8")
	fill:SetVertexColor(1, 0.82, 0.2, 0.85)
	fill:SetPoint("TOPLEFT", 3, -3)
	fill:SetPoint("BOTTOMLEFT", 3, 3)
	bar.fill = fill
	bar._min, bar._max, bar._step, bar._value = minV, maxV, step, minV
	function bar:Render()
		local span = self._max - self._min
		local p = span > 0 and (self._value - self._min) / span or 0
		self.fill:SetWidth(math.max(2, (self:GetWidth() - 6) * p))
	end
	function bar:SetValue(value)
		self._value = tonumber(value) or self._min
		self:Render()
	end
	function bar:GetValue()
		return self._value
	end
	local function applyFromCursor(self)
		local okLeft, left = pcall(self.GetLeft, self)
		local okScale, scale = pcall(self.GetEffectiveScale, self)
		local okCur, cx = pcall(GetCursorPosition)
		left, scale, cx = tonumber(okLeft and left), tonumber(okScale and scale) or 1, tonumber(okCur and cx)
		if not left or not cx then
			return
		end
		local p = (cx / scale - left) / math.max(1, self:GetWidth())
		p = math.min(1, math.max(0, p))
		local raw = self._min + p * (self._max - self._min)
		local snapped = math.floor(raw / self._step + 0.5) * self._step
		snapped = math.min(self._max, math.max(self._min, snapped))
		self._value = snapped
		self:Render()
		if self.OnValueChanged then
			self:OnValueChanged(snapped)
		end
	end
	bar:SetScript("OnMouseDown", function(self)
		self._drag = true
		applyFromCursor(self)
	end)
	bar:SetScript("OnMouseUp", function(self)
		self._drag = nil
	end)
	bar:SetScript("OnLeave", function(self)
		if not self._drag then
			return
		end
	end)
	bar:SetScript("OnUpdate", function(self)
		if self._drag and not IsMouseButtonDown("LeftButton") then
			self._drag = nil
		end
		if self._drag then
			applyFromCursor(self)
		end
	end)
	bar:Render()
	return bar
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
	ns.optSerial = (ns.optSerial or 0) + 1
	local frame = CreateFrame("Frame", "WoWForeverRotOptions" .. ns.optSerial, UIParent, "BackdropTemplate")
	frame:SetSize(900, 680)
	frame:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
	frame:SetFrameStrata("DIALOG")
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 24,
		insets = { left = 8, right = 8, top = 8, bottom = 8 },
	})
	frame:Hide()
	tinsert(UISpecialFrames, frame:GetName())

	local titleBar = CreateFrame("Frame", nil, frame)
	titleBar:SetPoint("TOPLEFT", 12, -10)
	titleBar:SetPoint("TOPRIGHT", -42, -10)
	titleBar:SetHeight(36)
	titleBar:EnableMouse(true)
	titleBar:RegisterForDrag("LeftButton")
	titleBar:SetScript("OnDragStart", function()
		frame:StartMoving()
	end)
	titleBar:SetScript("OnDragStop", function()
		frame:StopMovingOrSizing()
	end)

	local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("LEFT", 8, 0)
	title:SetPoint("RIGHT", titleBar, "RIGHT", -8, 0)
	title:SetJustifyH("LEFT")
	frame.windowTitle = title

	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -6, -6)

	local nav = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	nav:SetPoint("TOPLEFT", 16, -52)
	nav:SetPoint("BOTTOMLEFT", 16, 16)
	nav:SetWidth(200)
	nav:SetBackdrop(PANEL)
	nav:SetBackdropColor(0.02, 0.02, 0.02, 0.96)
	nav:SetBackdropBorderColor(0.55, 0.45, 0.18, 1)

	local navTitle = nav:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	navTitle:SetPoint("TOPLEFT", 14, -14)
	navTitle:SetTextColor(1, 0.82, 0.2)
	frame.navTitle = navTitle

	local navStatus = nav:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	navStatus:SetPoint("TOPLEFT", navTitle, "BOTTOMLEFT", 0, -6)
	navStatus:SetPoint("RIGHT", -12, 0)
	navStatus:SetJustifyH("LEFT")
	navStatus:SetTextColor(0.65, 0.65, 0.65)
	frame.navStatus = navStatus

	local content = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	content:SetPoint("TOPLEFT", nav, "TOPRIGHT", 12, 0)
	content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 16)
	content:SetBackdrop(PANEL)
	content:SetBackdropColor(0.015, 0.015, 0.015, 0.98)
	content:SetBackdropBorderColor(0.55, 0.45, 0.18, 1)

	local pageTitle = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	pageTitle:SetPoint("TOPLEFT", 16, -14)
	pageTitle:SetTextColor(1, 0.82, 0.2)
	frame.pageTitle = pageTitle

	frame.profileButtons = {}
	for i, key in ipairs({ "base", "pve", "pvp", "custom" }) do
		local btn = makeGoldBtn(content, 88, 22, ns.T("PROFILE_" .. key:upper()))
		btn:SetPoint("TOPLEFT", 16 + (i - 1) * 94, -42)
		btn.profile = key
		btn:SetScript("OnClick", function(self)
			if ns.SetProfile then
				ns.SetProfile(self.profile)
			end
		end)
		frame.profileButtons[i] = btn
	end

	local general = CreateFrame("Frame", nil, content)
	general:SetPoint("TOPLEFT", 8, -72)
	general:SetPoint("BOTTOMRIGHT", -8, 8)

	local rotation = CreateFrame("Frame", nil, content)
	rotation:SetPoint("TOPLEFT", 8, -72)
	rotation:SetPoint("BOTTOMRIGHT", -8, 8)
	rotation:Hide()

	local extra = CreateFrame("Frame", nil, content)
	extra:SetPoint("TOPLEFT", 8, -72)
	extra:SetPoint("BOTTOMRIGHT", -8, 8)
	extra:Hide()

	local info = CreateFrame("Frame", nil, content)
	info:SetPoint("TOPLEFT", 8, -72)
	info:SetPoint("BOTTOMRIGHT", -8, 8)
	info:Hide()
	frame.general = general
	frame.rotation = rotation
	frame.extra = extra
	frame.info = info
	frame.content = content
	frame.nav = nav

	local hudCard = makeCard(general, "OPT_CARD_HUD", 8, -4, 318, 172)
	frame.optLock = addSwitch(hudCard, "locked", ns.T("OPT_LOCK"))
	frame.optRotation = addSwitch(hudCard, "showRotation", ns.T("OPT_ROTATION"))
	frame.optGlow = addSwitch(hudCard, "glow", ns.T("OPT_GLOW"))
	frame.optRange = addSwitch(hudCard, "showRange", ns.T("OPT_RANGE"))
	frame.optModes = addSwitch(hudCard, "showModes", ns.T("OPT_MODES"))

	local winCard = makeCard(general, "OPT_CARD_WINDOWS", 338, -4, 318, 172)
	frame.optDef = addSwitch(winCard, "showDefense", ns.T("OPT_DEFENSE"))
	frame.optKick = addSwitch(winCard, "showInterrupt", ns.T("OPT_INTERRUPT"))
	frame.optPurge = addSwitch(winCard, "showPurge", ns.T("OPT_PURGE"))
	frame.optCleanse = addSwitch(winCard, "showCleanse", ns.T("OPT_CLEANSE"))
	frame.optWeapon = addSwitch(winCard, "showWeapon", ns.T("OPT_WEAPON"))

	local displayCard = makeCard(general, "OPT_CARD_DISPLAY", 8, -188, 318, 196)
	local scaleLabel = displayCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	scaleLabel:SetPoint("TOPLEFT", 12, -32)
	scaleLabel:SetTextColor(0.92, 0.92, 0.92)
	frame.scaleLabel = scaleLabel
	local scaleBar = makeBarSlider(displayCard, 200, 60, 200, 10)
	scaleBar:SetPoint("TOPLEFT", 12, -52)
	scaleBar.OnValueChanged = function(_, value)
		ns.db.uiScale = value / 100
		if ns.UI and ns.UI.ApplyScale then
			ns.db.uiScale = ns.UIScale and ns.UIScale() or (value / 100)
			ns.UI.ApplyScale()
		end
		if frame.scaleLabel then
			frame.scaleLabel:SetText(ns.T("OPT_SCALE"):format(math.floor((ns.UIScale and ns.UIScale() or value / 100) * 100 + 0.5)))
		end
	end
	frame.scaleBar = scaleBar

	local langLabel = displayCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	langLabel:SetPoint("TOPLEFT", 12, -80)
	langLabel:SetTextColor(0.92, 0.92, 0.92)
	frame.langLabel = langLabel
	local langBtn = makeGoldBtn(displayCard, 170, 22, ns.LocaleLabel and ns.LocaleLabel() or "Auto")
	langBtn:SetPoint("TOPLEFT", 12, -100)
	langBtn:SetScript("OnClick", function()
		if ns.CycleLocale then
			ns.CycleLocale()
		end
	end)
	frame.langBtn = langBtn

	local resetPos = makeGoldBtn(displayCard, 140, 22, ns.T("OPT_RESET_POS"))
	resetPos:SetPoint("TOPLEFT", 12, -132)
	resetPos:SetScript("OnClick", function()
		ns.db.pos = nil
		ns.UI.ApplyPosition()
	end)
	frame.resetPos = resetPos

	local resetAll = makeGoldBtn(displayCard, 140, 22, ns.T("OPT_RESET_ALL"))
	resetAll:SetPoint("LEFT", resetPos, "RIGHT", 8, 0)
	resetAll:SetScript("OnClick", function()
		ns.ConfirmResetAll()
	end)
	frame.resetAll = resetAll

	local weaponCard = makeCard(general, "OPT_CARD_WEAPON", 338, -188, 318, 196)
	frame.weaponCard = weaponCard
	frame.weaponLabel = weaponCard.title
	frame.weaponBoxes = {}

	local hint = general:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	hint:SetPoint("BOTTOMLEFT", 12, 8)
	hint:SetPoint("BOTTOMRIGHT", -12, 8)
	hint:SetJustifyH("LEFT")
	hint:SetTextColor(0.65, 0.65, 0.65)
	frame.hint = hint

	local specText = rotation:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	specText:SetPoint("TOPLEFT", 8, -2)
	specText:SetTextColor(1, 0.82, 0.2)
	frame.specText = specText

	frame.specButtons = {}
	for i = 1, 5 do
		local btn = makeGoldBtn(rotation, 86, 22, "")
		btn:SetPoint("TOPLEFT", 8 + (i - 1) * 92, -22)
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
		local btn = makeGoldBtn(rotation, 80, 22, modeLabel(mode))
		btn:SetPoint("TOPLEFT", 8 + (i - 1) * 86, -48)
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
	autoHint:SetPoint("TOPLEFT", 8, -76)
	autoHint:SetWidth(420)
	autoHint:SetJustifyH("LEFT")
	autoHint:SetTextColor(0.72, 0.72, 0.72)
	frame.autoHint = autoHint

	local autoLess = makeGoldBtn(rotation, 24, 20, "-")
	autoLess:SetPoint("TOPRIGHT", rotation, "TOPRIGHT", -54, -74)
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

	local autoMore = makeGoldBtn(rotation, 24, 20, "+")
	autoMore:SetPoint("TOPRIGHT", rotation, "TOPRIGHT", -8, -74)
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
	autoCount:SetTextColor(1, 0.82, 0.2)
	frame.autoCount = autoCount

	local resetApl = makeGoldBtn(rotation, 120, 22, ns.T("OPT_RESET_APL"))
	resetApl:SetPoint("TOPRIGHT", rotation, "TOPRIGHT", -8, -22)
	frame.resetApl = resetApl
	local applyApl = makeGoldBtn(rotation, 100, 22, ns.T("OPT_APPLY"))
	applyApl:SetPoint("RIGHT", resetApl, "LEFT", -6, 0)
	frame.applyApl = applyApl
	applyApl:SetScript("OnClick", function()
		if ns.ApplyRotationEdit then
			ns.ApplyRotationEdit()
		end
		if ns.Print then
			ns.Print(ns.T("OPT_APPLY_DONE"))
		end
	end)
	resetApl:SetScript("OnClick", function()
		if listKind == "def" then
			ns.ResetDef(nil, editSpec)
		else
			ns.ResetAPL(nil, editSpec, editMode)
		end
		ns.RefreshOptions()
	end)

	local listCard = CreateFrame("Frame", nil, rotation, "BackdropTemplate")
	listCard:SetPoint("TOPLEFT", 4, -100)
	listCard:SetPoint("BOTTOMRIGHT", -4, 4)
	listCard:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 8,
		edgeSize = 8,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	listCard:SetBackdropColor(0, 0, 0, 0.45)
	listCard:SetBackdropBorderColor(0.5, 0.42, 0.28, 0.9)
	frame.listCard = listCard

	local scroll = CreateFrame("ScrollFrame", "WoWForeverRotAPLScroll", listCard, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", 6, -8)
	scroll:SetPoint("BOTTOMRIGHT", -28, 8)
	local child = CreateFrame("Frame", nil, scroll)
	child:SetSize(600, 10)
	scroll:SetScrollChild(child)
	frame.aplScroll = scroll
	frame.aplChild = child
	frame.aplRows = {}
	frame.modeHeaders = {}
	frame.modeDrops = {}

	local function makeDropZone(name)
		local addBtn = CreateFrame("Button", name, child, "BackdropTemplate")
		addBtn:SetSize(560, 32)
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
			self:SetBackdropBorderColor(1, 0.82, 0.2, 1)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:AddLine(ns.T("OPT_ADD_SPELL"), 1, 0.82, 0)
			GameTooltip:AddLine(ns.T("OPT_DROP_SPELL"), 1, 1, 1, true)
			GameTooltip:Show()
		end)
		addBtn:SetScript("OnLeave", function(self)
			self:SetBackdropBorderColor(0.83, 0.63, 0.09, 0.85)
			GameTooltip:Hide()
		end)
		addBtn:Hide()
		return addBtn
	end

	frame.addSpell = makeDropZone("WoWForeverRotAddSpell")
	for _, mode in ipairs({ "auto", "single", "aoe", "burst" }) do
		local header = CreateFrame("Frame", nil, child)
		header:SetSize(580, 22)
		local text = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		text:SetPoint("LEFT", 4, 0)
		text:SetTextColor(1, 0.82, 0.2)
		header.label = text
		local reset = makeGoldBtn(header, 90, 18, ns.T("OPT_RESET_APL"))
		reset:SetPoint("RIGHT", 0, 0)
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

	local combatCard = makeCard(extra, "OPT_CARD_COMBAT", 8, -4, 318, 148)
	frame.optHideIdle = addSwitch(combatCard, "hideIdle", ns.T("OPT_HIDE_IDLE"))
	frame.optPhysics = addSwitch(combatCard, "showPhysics", ns.T("OPT_PHYSICS"))
	frame.optRoleAuto = addSwitch(combatCard, "roleAuto", ns.T("OPT_ROLE_AUTO"))
	frame.optBarOnly = addSwitch(combatCard, "barOnly", ns.T("OPT_BAR_ONLY"))

	local autoCard = makeCard(extra, "OPT_CARD_AUTOMATION", 338, -4, 318, 96)
	frame.optAutoProfile = addSwitch(autoCard, "autoProfile", ns.T("OPT_AUTO_PROFILE"))
	frame.optCleanseGroup = addSwitch(autoCard, "cleanseGroup", ns.T("OPT_CLEANSE_GROUP"))

	local alertCard = makeCard(extra, "OPT_CARD_ALERTS", 8, -138, 318, 132)
	local soundLabel = alertCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	soundLabel:SetPoint("TOPLEFT", 12, -32)
	soundLabel:SetTextColor(0.92, 0.92, 0.92)
	frame.soundLabel = soundLabel
	local soundBar = makeBarSlider(alertCard, 200, 0, 100, 10)
	soundBar:SetPoint("TOPLEFT", 12, -52)
	soundBar.OnValueChanged = function(_, value)
		ns.db.soundVolume = value
		if frame.soundLabel then
			frame.soundLabel:SetText(ns.T("OPT_SOUND"):format(value))
		end
	end
	frame.soundBar = soundBar
	local soundHint = alertCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	soundHint:SetPoint("TOPLEFT", 12, -78)
	soundHint:SetPoint("RIGHT", -12, 0)
	soundHint:SetJustifyH("LEFT")
	soundHint:SetTextColor(0.65, 0.65, 0.65)
	frame.soundHint = soundHint

	local colorCard = makeCard(extra, "OPT_COLORS", 338, -112, 318, 184)
	frame.colorButtons = {}
	frame.colorLabels = {}
	local colorKeys = { "next", "heal", "def", "weapon", "range" }
	local colorLabels = { "OPT_COLOR_NEXT", "OPT_COLOR_HEAL", "OPT_COLOR_DEF", "OPT_COLOR_WEAPON", "OPT_COLOR_RANGE" }
	for i, key in ipairs(colorKeys) do
		local row = CreateFrame("Frame", nil, colorCard)
		row:SetHeight(24)
		row:SetPoint("TOPLEFT", 12, -28 - (i - 1) * 28)
		row:SetPoint("RIGHT", -12, 0)
		local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		label:SetPoint("LEFT", 0, 0)
		label:SetTextColor(0.92, 0.92, 0.92)
		label:SetText(ns.T(colorLabels[i]))
		label.key = colorLabels[i]
		local btn = CreateFrame("Button", nil, row, "BackdropTemplate")
		btn:SetSize(22, 22)
		btn:SetPoint("RIGHT", 0, 0)
		btn:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8x8",
			edgeFile = "Interface\\Buttons\\WHITE8x8",
			edgeSize = 1,
		})
		btn.colorKey = key
		btn:SetScript("OnClick", function()
			pickColor(key)
		end)
		frame.colorButtons[i] = btn
		frame.colorLabels[i] = label
	end

	local shareCard = makeCard(extra, "OPT_CARD_SHARE", 8, -282, 648, 248)
	local shareHint = shareCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	shareHint:SetPoint("TOPLEFT", 12, -28)
	shareHint:SetPoint("RIGHT", -12, 0)
	shareHint:SetJustifyH("LEFT")
	shareHint:SetTextColor(0.72, 0.72, 0.72)
	frame.shareHint = shareHint

	local box = CreateFrame("ScrollFrame", "WoWForeverRotShareScroll", shareCard, "UIPanelScrollFrameTemplate")
	box:SetPoint("TOPLEFT", 12, -50)
	box:SetPoint("BOTTOMRIGHT", -32, 40)
	local edit = CreateFrame("EditBox", "WoWForeverRotShareEdit", box)
	edit:SetMultiLine(true)
	edit:SetFontObject("ChatFontSmall")
	edit:SetWidth(580)
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

	local exportBtn = makeGoldBtn(shareCard, 140, 22, ns.T("OPT_EXPORT"))
	exportBtn:SetPoint("BOTTOMLEFT", 12, 10)
	exportBtn:SetScript("OnClick", function()
		if ns.ExportProfile then
			edit:SetText(ns.ExportProfile())
			edit:HighlightText()
			edit:SetFocus()
		end
	end)
	frame.exportBtn = exportBtn

	local importBtn = makeGoldBtn(shareCard, 140, 22, ns.T("OPT_IMPORT"))
	importBtn:SetPoint("LEFT", exportBtn, "RIGHT", 8, 0)
	importBtn:SetScript("OnClick", function()
		if not ns.ImportProfile then
			return
		end
		local ok, msg, extraArg = ns.ImportProfile(edit:GetText() or "")
		if ok then
			ns.Print(ns.T(msg))
			ns.RefreshOptions()
			return
		end
		if msg == "OPT_IMPORT_CLASS" then
			ns.Print(ns.T("OPT_IMPORT_CLASS"):format(extraArg or "?"))
			return
		end
		ns.Print(ns.T(msg or "OPT_IMPORT_BAD"))
	end)
	frame.importBtn = importBtn

	local aboutCard = makeCard(info, "OPT_CARD_ABOUT", 8, -4, 648, 196)
	local aboutBody = aboutCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	aboutBody:SetPoint("TOPLEFT", 12, -30)
	aboutBody:SetPoint("TOPRIGHT", -12, -30)
	aboutBody:SetHeight(48)
	aboutBody:SetJustifyH("LEFT")
	aboutBody:SetJustifyV("TOP")
	aboutBody:SetWordWrap(true)
	aboutBody:SetTextColor(0.92, 0.92, 0.92)
	frame.aboutBody = aboutBody
	local aboutPoints = aboutCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	aboutPoints:SetPoint("TOPLEFT", 12, -82)
	aboutPoints:SetPoint("TOPRIGHT", -12, -82)
	aboutPoints:SetHeight(56)
	aboutPoints:SetJustifyH("LEFT")
	aboutPoints:SetJustifyV("TOP")
	aboutPoints:SetWordWrap(true)
	aboutPoints:SetTextColor(0.78, 0.86, 0.96)
	frame.aboutPoints = aboutPoints
	local aboutCredit = aboutCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	aboutCredit:SetPoint("TOPLEFT", 12, -144)
	aboutCredit:SetTextColor(1, 0.82, 0.2)
	frame.aboutCredit = aboutCredit
	local aboutSupport = aboutCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	aboutSupport:SetPoint("TOPLEFT", 12, -162)
	aboutSupport:SetPoint("RIGHT", -12, 0)
	aboutSupport:SetJustifyH("LEFT")
	aboutSupport:SetTextColor(0.72, 0.72, 0.72)
	frame.aboutSupport = aboutSupport

	local cmdCard = makeCard(info, "OPT_CARD_COMMANDS", 8, -212, 648, 196)
	local cmdHint = cmdCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	cmdHint:SetPoint("TOPLEFT", 12, -28)
	cmdHint:SetPoint("RIGHT", -12, 0)
	cmdHint:SetJustifyH("LEFT")
	cmdHint:SetTextColor(0.72, 0.72, 0.72)
	frame.cmdHint = cmdHint
	local cmdList = cmdCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	cmdList:SetPoint("TOPLEFT", 12, -48)
	cmdList:SetPoint("RIGHT", -12, 0)
	cmdList:SetJustifyH("LEFT")
	cmdList:SetWordWrap(true)
	cmdList:SetTextColor(0.92, 0.92, 0.92)
	frame.cmdList = cmdList

	local linksCard = makeCard(info, "OPT_CARD_LINKS", 8, -420, 648, 150)
	frame.siteRow = makeLinkRow(linksCard, "INFO_SITE", SITE_URL)
	frame.siteRow:SetPoint("TOPLEFT", 12, -32)
	frame.siteRow:SetPoint("RIGHT", -12, 0)
	frame.discordRow = makeLinkRow(linksCard, "INFO_DISCORD", DISCORD_URL)
	frame.discordRow:SetPoint("TOPLEFT", 12, -60)
	frame.discordRow:SetPoint("RIGHT", -12, 0)
	frame.curseRow = makeLinkRow(linksCard, "INFO_CURSE", CURSE_URL)
	frame.curseRow:SetPoint("TOPLEFT", 12, -88)
	frame.curseRow:SetPoint("RIGHT", -12, 0)
	frame.githubRow = makeLinkRow(linksCard, "INFO_GITHUB", GITHUB_URL)
	frame.githubRow:SetPoint("TOPLEFT", 12, -116)
	frame.githubRow:SetPoint("RIGHT", -12, 0)

	frame.navButtons = {}
	local navDefs = {
		{ key = "general", label = "TAB_GENERAL" },
		{ key = "rotation", label = "TAB_ROTATION" },
		{ key = "def", label = "TAB_DEFENSE" },
		{ key = "extra", label = "TAB_EXTRA" },
		{ key = "info", label = "TAB_INFO" },
	}
	for i, def in ipairs(navDefs) do
		local btn = CreateFrame("Button", nil, nav)
		btn:SetHeight(28)
		btn:SetPoint("TOPLEFT", nav, "TOPLEFT", 10, -58 - ((i - 1) * 30))
		btn:SetPoint("RIGHT", nav, "RIGHT", -10, 0)
		btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
		local text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		text:SetPoint("LEFT", 8, 0)
		text:SetPoint("RIGHT", -6, 0)
		text:SetJustifyH("LEFT")
		btn.text = text
		btn.labelKey = def.label
		btn.tabKey = def.key
		btn:SetScript("OnClick", function(self)
			frame.ShowTab(self.tabKey)
			if self.tabKey ~= "general" then
				ns.RefreshOptions()
			end
		end)
		frame.navButtons[def.key] = btn
	end

	function frame.RelocalizeChrome()
		local ver = addonVersion()
		local title = tostring(ns.T("TITLE") or "Forever Rotation")
		local sub = tostring(ns.T("TITLE_SUB") or "(Multi language)")
		if ver ~= "" then
			frame.windowTitle:SetText(title .. "  |cffbbbbbb" .. sub .. "|r  |cff66ccffv" .. ver .. "|r")
		else
			frame.windowTitle:SetText(title .. "  |cffbbbbbb" .. sub .. "|r")
		end
		frame.navTitle:SetText(ns.T("OPT_NAV_TITLE"))
		if frame.hint then
			frame.hint:SetText(ns.T("OPT_HINT"))
		end
		if frame.soundHint then
			frame.soundHint:SetText(ns.T("OPT_SOUND_HINT"))
		end
		if frame.shareHint then
			frame.shareHint:SetText(ns.T("OPT_EXPORT_HINT"))
		end
		if frame.resetPos then
			frame.resetPos:SetText(ns.T("OPT_RESET_POS"))
		end
		if frame.resetAll then
			frame.resetAll:SetText(ns.T("OPT_RESET_ALL"))
		end
		if frame.resetApl then
			frame.resetApl:SetText(ns.T("OPT_RESET_APL"))
		end
		if frame.applyApl then
			frame.applyApl:SetText(ns.T("OPT_APPLY"))
		end
		if frame.exportBtn then
			frame.exportBtn:SetText(ns.T("OPT_EXPORT"))
		end
		if frame.importBtn then
			frame.importBtn:SetText(ns.T("OPT_IMPORT"))
		end
		if frame.aboutBody then
			frame.aboutBody:SetText(ns.T("INFO_ABOUT"))
		end
		if frame.aboutPoints then
			frame.aboutPoints:SetText(ns.T("INFO_ABOUT_POINTS"))
		end
		if frame.aboutCredit then
			frame.aboutCredit:SetText(ns.T("INFO_CREDIT"))
		end
		if frame.aboutSupport then
			frame.aboutSupport:SetText(ns.T("INFO_SUPPORT"))
		end
		if frame.cmdHint then
			frame.cmdHint:SetText(ns.T("INFO_CMD_HINT"))
		end
		if frame.cmdList then
			frame.cmdList:SetText(ns.T("INFO_CMD_LIST"))
		end
		for _, row in ipairs({ frame.siteRow, frame.discordRow, frame.curseRow, frame.githubRow }) do
			if row and row.label and row.labelKey then
				row.label:SetText(ns.T(row.labelKey))
			end
			if row and row.copy then
				row.copy:SetText(ns.T("INFO_COPY"))
			end
		end
		if frame.colorLabels then
			for _, label in ipairs(frame.colorLabels) do
				label:SetText(ns.T(label.key))
			end
		end
		for _, card in ipairs({ hudCard, winCard, displayCard, weaponCard, combatCard, autoCard, alertCard, colorCard, shareCard, aboutCard, cmdCard, linksCard }) do
			if card and card.title and card.titleKey then
				card.title:SetText(ns.T(card.titleKey))
			end
		end
		for _, btn in pairs(frame.navButtons) do
			btn.text:SetText(ns.T(btn.labelKey))
		end
	end

	function frame.ShowTab(which)
		frame.activeTab = which
		listKind = which == "def" and "def" or "apl"
		general:SetShown(which == "general")
		rotation:SetShown(which == "rotation" or which == "def")
		extra:SetShown(which == "extra")
		info:SetShown(which == "info")
		local titles = {
			general = "TAB_GENERAL",
			rotation = "TAB_ROTATION",
			def = "TAB_DEFENSE",
			extra = "TAB_EXTRA",
			info = "TAB_INFO",
		}
		frame.pageTitle:SetText(ns.T(titles[which] or "TAB_GENERAL"))
		frame.navStatus:SetText(ns.T(titles[which] or "TAB_GENERAL"))
		for key, btn in pairs(frame.navButtons) do
			local selected = key == which
			if selected then
				btn:LockHighlight()
				btn.text:SetTextColor(1, 0.82, 0.2)
			else
				btn:UnlockHighlight()
				btn.text:SetTextColor(0.9, 0.9, 0.9)
			end
		end
	end

	frame.RelocalizeChrome()
	frame.ShowTab("general")
	ns.UI.options = frame
	return frame
end

local function aplRow(parent, index)
	local rows = ns.UI.options.aplRows
	if rows[index] then
		return rows[index]
	end
	local row = CreateFrame("Frame", nil, parent)
	row:SetSize(580, 28)
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
	name:SetWidth(200)
	name:SetJustifyH("LEFT")
	row.label = name

	local hold = CreateFrame("EditBox", "WoWForeverRotAPLHold" .. index, row, "InputBoxTemplate")
	hold:SetSize(34, 18)
	hold:SetPoint("RIGHT", -152, 0)
	hold:SetAutoFocus(false)
	hold:SetNumeric(true)
	hold:SetMaxLetters(3)
	hold:SetJustifyH("CENTER")
	hold:SetTextInsets(2, 2, 0, 0)
	row.hold = hold

	local holdUnit = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	holdUnit:SetPoint("LEFT", hold, "RIGHT", 2, 0)
	holdUnit:SetText("s")
	row.holdUnit = holdUnit

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

	local function commitHold(self)
		if not self.stepKey then
			return
		end
		local sec = tonumber(self:GetText()) or 0
		if listKind == "def" then
			ns.SetDefHold(self.stepKey, sec, nil, editSpec)
		else
			ns.SetAPLHold(self.stepKey, sec, nil, editSpec, self.mode)
		end
		ns.RefreshOptions()
	end
	hold:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
		commitHold(self)
	end)
	hold:SetScript("OnEditFocusLost", commitHold)
	hold:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
		ns.RefreshOptions()
	end)
	bindSimpleTip(hold, ns.T("OPT_HOLD"), ns.T("OPT_HOLD_TIP"))

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
	if frame.RelocalizeChrome then
		pcall(frame.RelocalizeChrome)
	end
	if frame.ShowTab and frame.activeTab then
		frame.ShowTab(frame.activeTab)
	end
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
		if frame.optPhysics then
			frame.optPhysics:SetChecked(ns.db.showPhysics ~= false)
			if frame.optRoleAuto then
				frame.optRoleAuto:SetChecked(ns.db.roleAuto ~= false)
			end
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
		if frame.langLabel then
			frame.langLabel:SetText(ns.T("OPT_LANG"))
		end
		if frame.langBtn and ns.LocaleLabel then
			frame.langBtn:SetText(ns.LocaleLabel())
		end
		frame.soundLabel:SetText(ns.T("OPT_SOUND"):format(tonumber(ns.db.soundVolume) or 60))
		if frame.soundBar then
			frame.soundBar:SetValue(tonumber(ns.db.soundVolume) or 60)
		end
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
		if frame.scaleBar then
			frame.scaleBar:SetValue(pct)
		end
	end
	local choices = ns.WeaponChoices and ns.WeaponChoices() or {}
	if frame.weaponCard then
		frame.weaponCard:SetShown(#choices > 0)
		for i, entry in ipairs(choices) do
			local box = frame.weaponBoxes[i]
			if not box then
				box = CreateFrame("CheckButton", "WoWForeverRotWep" .. i, frame.weaponCard, "UICheckButtonTemplate")
				local text = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
				text:SetPoint("LEFT", box, "RIGHT", 4, 0)
				text:SetTextColor(0.92, 0.92, 0.92)
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
			box:ClearAllPoints()
			box:SetPoint("TOPLEFT", 12, -28 - (i - 1) * 24)
			box.wepKey = entry.key
			box.label:SetText(API.SpellLabel(entry.id) or entry.key)
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
		local name = API.SpellLabel(step.id) or step.key
		if step.racial then
			name = ns.T("RACIAL_PREFIX"):format(name)
		end
		row.label:SetText(name)
		local known = API.Known(step.id)
		row.label:SetTextColor(known and 1 or 0.55, known and 1 or 0.55, known and 1 or 0.55)
		if row.hold then
			row.hold.stepKey = step.key
			row.hold.mode = mode
			local hold = step.opt and tonumber(step.opt.hold)
			if hold == nil and ns.SPELL_HOLD and step.id then
				hold = ns.SPELL_HOLD[step.id]
			end
			if not row.hold:HasFocus() then
				row.hold:SetText(tostring(hold or 0))
			end
		end
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

function ns.RefreshLocale()
	if ns.UI and ns.UI.RefreshTips then
		ns.UI.RefreshTips()
	end
	if ns.UI and ns.UI.RefreshRoles then
		ns.UI.RefreshRoles()
	end
	local shown = ns.UI and ns.UI.options and ns.UI.options:IsShown()
	if ns.UI and ns.UI.options then
		ns.UI.options:Hide()
		ns.UI.options:SetParent(nil)
		ns.UI.options = nil
	end
	if shown and ns.ToggleOptions then
		ns.ToggleOptions()
	end
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
