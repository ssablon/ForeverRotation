local addonName, ns = ...
ns.UI = ns.UI or {}
local API = ns.API

local SIZE = 50
local GAP = 8
local IMG = "Interface\\AddOns\\WoWForeverRot\\images\\"
local CHROME = {
	bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 8,
	edgeSize = 16,
	insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

local function classColor()
	local token, classId = ns.ClassToken and ns.ClassToken()
	if (not token or not ns.CLASS_COLORS[token]) and classId and ns.CLASS_BY_ID then
		token = ns.CLASS_BY_ID[classId]
	end
	local pack = token and ns.CLASS_COLORS and ns.CLASS_COLORS[token]
	if pack then
		return pack[1], pack[2], pack[3]
	end
	return 0.83, 0.63, 0.09
end

local function applyChrome(frame, locked)
	if not frame or not frame.SetBackdrop then
		return
	end
	if not frame._wfrChrome then
		frame:SetBackdrop(CHROME)
		frame._wfrChrome = true
	end
	local dim = locked or (ns.db and ns.db.locked)
	frame:SetBackdropColor(0, 0, 0, dim and 0.22 or 0.75)
	local r, g, b = classColor()
	frame:SetBackdropBorderColor(r, g, b, 0.75)
end

local function savePoint(frame, key)
	local point, _, rel, x, y = frame:GetPoint()
	ns.db.pos = ns.db.pos or {}
	ns.db.pos[key] = { point, rel, x, y }
end

local function loadPoint(frame, key, default)
	local pos = ns.db.pos and ns.db.pos[key]
	if pos then
		frame:ClearAllPoints()
		frame:SetPoint(pos[1], UIParent, pos[2] or pos[1], pos[3], pos[4])
		return
	end
	if default then
		frame:ClearAllPoints()
		frame:SetPoint(unpack(default))
	end
end

local function showTip(frame)
	GameTooltip:SetOwner(frame, "ANCHOR_TOP")
	GameTooltip:ClearLines()
	if frame.tipTitle then
		GameTooltip:AddLine(frame.tipTitle, 1, 0.82, 0)
	end
	if frame.tipDesc then
		GameTooltip:AddLine(frame.tipDesc, 1, 1, 1, true)
	end
	if frame.spellID then
		local name = API.SpellName(frame.spellID)
		if name then
			GameTooltip:AddLine(name, 0.45, 0.82, 1)
		end
	end
	if frame.tipHint then
		GameTooltip:AddLine(frame.tipHint, 0.6, 0.6, 0.6, true)
	end
	GameTooltip:Show()
end

local function hideTip()
	GameTooltip:Hide()
end

local function bindTip(frame, titleKey, descKey)
	frame.tipTitleKey = titleKey
	frame.tipDescKey = descKey
	frame.tipTitle = ns.T(titleKey)
	frame.tipDesc = ns.T(descKey)
	frame:SetScript("OnEnter", showTip)
	frame:SetScript("OnLeave", hideTip)
end

local function makeMovable(frame, key, dragFrame)
	dragFrame = dragFrame or frame
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function(self)
		if ns.db.locked then
			return
		end
		self._wfrDragged = true
		dragFrame:StartMoving()
	end)
	frame:SetScript("OnDragStop", function()
		dragFrame:StopMovingOrSizing()
		savePoint(dragFrame, key)
	end)
end

local function makeIcon(name, parent, size)
	local frame = CreateFrame("Frame", name, parent or UIParent, "BackdropTemplate")
	frame:SetSize(size or SIZE, size or SIZE)
	frame:SetFrameStrata("MEDIUM")
	applyChrome(frame)
	local tex = frame:CreateTexture(nil, "ARTWORK")
	tex:SetPoint("TOPLEFT", 3, -3)
	tex:SetPoint("BOTTOMRIGHT", -3, 3)
	tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	frame.texture = tex
	local filter = frame:CreateTexture(nil, "OVERLAY")
	filter:SetPoint("TOPLEFT", 3, -3)
	filter:SetPoint("BOTTOMRIGHT", -3, 3)
	filter:SetTexture("Interface\\Buttons\\WHITE8x8")
	filter:SetBlendMode("BLEND")
	filter:SetVertexColor(0.9, 0.08, 0.08, 0.5)
	filter:Hide()
	frame.filter = filter
	local shine = frame:CreateTexture(nil, "OVERLAY")
	shine:SetPoint("TOPLEFT", 3, -3)
	shine:SetPoint("BOTTOMRIGHT", -3, 3)
	shine:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
	shine:SetBlendMode("ADD")
	shine:SetVertexColor(1, 0.95, 0.55, 0.55)
	shine:Hide()
	frame.shine = shine
	local cd = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
	cd:SetAllPoints(tex)
	cd:SetDrawEdge(false)
	frame.cooldown = cd
	local bind = frame:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
	bind:SetPoint("BOTTOMRIGHT", -3, 3)
	bind:SetWidth((size or SIZE) - 8)
	bind:SetJustifyH("RIGHT")
	bind:SetWordWrap(false)
	if bind.SetMaxLines then
		bind:SetMaxLines(1)
	end
	bind:SetTextColor(1, 0.92, 0.45)
	frame.bind = bind
	return frame
end

local function makeIconButton(name, parent, size)
	local btn = CreateFrame("Button", name, parent)
	btn:SetSize(size, size)
	local tex = btn:CreateTexture(nil, "ARTWORK")
	tex:SetAllPoints()
	btn.texture = tex
	btn:SetScript("OnEnter", function(self)
		self:SetAlpha(1)
		showTip(self)
	end)
	btn:SetScript("OnLeave", function(self)
		self:SetAlpha(self.idleAlpha or 0.85)
		hideTip()
	end)
	return btn
end

function ns.UI.Create()
	if ns.UI.root then
		return
	end

	local root = CreateFrame("Frame", "WoWForeverRotFrame", UIParent, "BackdropTemplate")
	root:SetSize(SIZE * 3 + GAP * 2 + 16, 8 + SIZE + 8)
	root:SetFrameStrata("MEDIUM")
	applyChrome(root)
	makeMovable(root, "queue")
	bindTip(root, "TIP_NEXT", "TIP_NEXT_DESC")

	ns.UI.slots = {}
	local tipKeys = {
		{ "TIP_NEXT", "TIP_NEXT_DESC" },
		{ "TIP_QUEUE2", "TIP_QUEUE2_DESC" },
		{ "TIP_QUEUE3", "TIP_QUEUE3_DESC" },
	}
	for i = 1, 3 do
		local slot = makeIcon("WoWForeverRotSlot" .. i, root, i == 1 and SIZE or 40)
		if i == 1 then
			slot:SetPoint("TOPLEFT", root, "TOPLEFT", 8, -8)
		else
			slot:SetPoint("LEFT", ns.UI.slots[i - 1], "RIGHT", GAP, i == 2 and -4 or 0)
		end
		makeMovable(slot, "queue", root)
		bindTip(slot, tipKeys[i][1], tipKeys[i][2])
		ns.UI.slots[i] = slot
		local font = slot.bind:GetFont()
		if font then
			slot.bind:SetFont(font, i == 1 and 18 or 16, "OUTLINE")
		end
	end

	local gauge = CreateFrame("Frame", "WoWForeverRotGauge", root)
	gauge:SetFrameLevel(root:GetFrameLevel() + 5)
	gauge:SetPoint("TOPLEFT", ns.UI.slots[1], "BOTTOMLEFT", 0, -8)
	gauge:SetPoint("RIGHT", root, "RIGHT", -8, 0)
	gauge:SetHeight(12)
	gauge.rows = {}
	local function gaugeRow(parent, index)
		local row = parent.rows[index]
		if row then
			return row
		end
		row = CreateFrame("Frame", nil, parent)
		row:SetHeight(5)
		local bg = row:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetTexture("Interface\\Buttons\\WHITE8x8")
		bg:SetVertexColor(0.45, 0.18, 0.02, 0.95)
		local fill = row:CreateTexture(nil, "ARTWORK")
		fill:SetPoint("TOPLEFT", 1, -1)
		fill:SetPoint("BOTTOMLEFT", 1, 1)
		fill:SetWidth(1)
		fill:SetTexture("Interface\\Buttons\\WHITE8x8")
		row.fill = fill
		local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		label:SetPoint("LEFT", 4, 0)
		label:SetJustifyH("LEFT")
		row.label = label
		local time = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		time:SetPoint("RIGHT", -4, 0)
		time:SetJustifyH("RIGHT")
		row.time = time
		local mark = row:CreateTexture(nil, "OVERLAY")
		mark:SetWidth(2)
		mark:SetTexture("Interface\\Buttons\\WHITE8x8")
		mark:SetVertexColor(1, 1, 1, 0.95)
		mark:SetPoint("TOP", row, "TOPLEFT", 0, 0)
		mark:SetPoint("BOTTOM", row, "BOTTOMLEFT", 0, 0)
		row.mark = mark
		parent.rows[index] = row
		return row
	end
	local function physicsOn()
		return ns.Physics and ns.Physics.Enabled and ns.Physics.Enabled()
	end

	local function physicsBars()
		if not physicsOn() then
			return nil
		end
		if ns.Physics and ns.Physics.Status then
			local ok, st = pcall(ns.Physics.Status)
			local bars = ok and st and (st.bars or { st })
			if bars and #bars > 0 then
				return bars
			end
		end
		return {
			{ kind = "swing", progress = 0, hot = false, mark = 0.8, label = ns.T("PHYS_SWING") },
		}
	end

	local function paintGauge(self)
		if not physicsOn() or not ns.UI.root or not ns.UI.root:IsShown() then
			self:Hide()
			return
		end
		local bars = physicsBars()
		self:Show()
		local n = #bars
		local rowH, gap = 12, 3
		self:SetHeight(n * rowH + (n - 1) * gap)
		local inner = math.max(8, self:GetWidth() - 2)
		local cr, cg, cb = classColor()
		for i = 1, n do
			local row = gaugeRow(self, i)
			row:ClearAllPoints()
			row:SetPoint("LEFT")
			row:SetPoint("RIGHT")
			row:SetHeight(rowH)
			if i == 1 then
				row:SetPoint("TOP", self, "TOP", 0, 0)
			else
				row:SetPoint("TOP", self.rows[i - 1], "BOTTOM", 0, -gap)
			end
			row:Show()
			local bar = bars[i]
			if row.label then
				row.label:SetText(bar.label or "")
				if bar.hot then
					row.label:SetTextColor(1, 1, 1)
				else
					row.label:SetTextColor(1, 0.9, 0.7)
				end
			end
			if row.time then
				if bar.kind == "energy" and type(bar.left) == "number" then
					row.time:SetText(string.format("%.1f", bar.left))
					row.time:Show()
				else
					row.time:SetText("")
					row.time:Hide()
				end
			end
			if row.mark then
				local markAt = tonumber(bar.mark) or 0.8
				if markAt < 0.05 then
					markAt = 0.05
				end
				if markAt > 0.95 then
					markAt = 0.95
				end
				row.mark:ClearAllPoints()
				row.mark:SetPoint("TOP", row, "TOPLEFT", inner * markAt, 0)
				row.mark:SetPoint("BOTTOM", row, "BOTTOMLEFT", inner * markAt, 0)
			end
			row.fill:SetWidth(math.max(1, inner * (bar.progress or 0)))
			if bar.kind == "offhand" then
				if bar.hot then
					row.fill:SetVertexColor(0.45, 0.78, 1, 1)
				else
					row.fill:SetVertexColor(0.15, 0.48, 0.95, 0.9)
				end
			elseif bar.kind == "swing" then
				if bar.hot then
					row.fill:SetVertexColor(1, 0.72, 0.18, 1)
				else
					row.fill:SetVertexColor(0.92, 0.48, 0.08, 0.9)
				end
			elseif bar.kind == "energy" then
				row.fill:SetVertexColor(0.35, 0.85, 0.4, bar.hot and 1 or 0.9)
			elseif bar.hot then
				row.fill:SetVertexColor(1, 0.82, 0.2, 0.95)
			else
				row.fill:SetVertexColor(cr, cg, cb, 0.85)
			end
		end
		for i = n + 1, #self.rows do
			self.rows[i]:Hide()
		end
		if ns.UI.RefreshCue then
			ns.UI.RefreshCue()
		end
		if self._barCount ~= n then
			self._barCount = n
			if not self._fitting and ns.UI.FitFrame then
				self._fitting = true
				ns.UI.FitFrame()
				self._fitting = nil
			end
		end
	end

	gauge:SetScript("OnUpdate", function(self, elapsed)
		self._acc = (self._acc or 0) + elapsed
		if self._acc < 0.05 then
			return
		end
		self._acc = 0
		paintGauge(self)
	end)
	ns.UI.gauge = gauge
	ns.UI.PaintGauge = paintGauge

	function ns.UI.FitFrame()
		if not ns.UI.root then
			return
		end
		local on = physicsOn()
		local extra = 0
		if on then
			local bars = physicsBars()
			local n = bars and #bars or 1
			extra = 8 + n * 12 + math.max(0, n - 1) * 3
		end
		if ns.UI.gauge then
			if on then
				ns.UI.gauge:Show()
			else
				ns.UI.gauge._barCount = nil
				ns.UI.gauge:Hide()
			end
		end
		local height = 8 + SIZE + 8 + extra
		local rootFrame = ns.UI.root
		local current = tonumber(rootFrame:GetHeight())
		if current and math.abs(current - height) < 0.5 then
			return
		end
		local top, left = rootFrame:GetTop(), rootFrame:GetLeft()
		rootFrame:SetHeight(height)
		if type(top) == "number" and type(left) == "number" then
			rootFrame:ClearAllPoints()
			rootFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
		end
	end

	local function makeDefense()
		local frame = CreateFrame("Frame", "WoWForeverRotDefense", UIParent, "BackdropTemplate")
		frame:SetSize(42, 42)
		frame:SetFrameStrata("MEDIUM")
		applyChrome(frame)
		local inner = frame:CreateTexture(nil, "ARTWORK")
		inner:SetPoint("TOPLEFT", 4, -4)
		inner:SetPoint("BOTTOMRIGHT", -4, 4)
		inner:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		frame.texture = inner
		local cd = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
		cd:SetAllPoints(inner)
		cd:SetDrawEdge(false)
		frame.cooldown = cd
		local bind = frame:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
		bind:SetPoint("BOTTOMRIGHT", -2, 2)
		bind:SetWidth(34)
		bind:SetJustifyH("RIGHT")
		bind:SetWordWrap(false)
		if bind.SetMaxLines then
			bind:SetMaxLines(1)
		end
		bind:SetTextColor(1, 0.92, 0.45)
		frame.bind = bind
		return frame
	end

	local def = makeDefense()
	makeMovable(def, "defense")
	bindTip(def, "TIP_DEFENSE", "TIP_DEFENSE_DESC")
	ns.UI.defense = def

	local function paintIdle(slot, r, g, b)
		slot.texture:SetColorTexture(r, g, b, 0.35)
	end

	local kick = makeIcon("WoWForeverRotInterrupt", UIParent, 26)
	kick:ClearAllPoints()
	kick:SetPoint("RIGHT", ns.UI.slots[1], "LEFT", -8, 10)
	kick.texture:SetTexture(IMG .. "lightning-interrupt")
	kick.texture:SetVertexColor(0.2, 0.2, 0.2)
	makeMovable(kick, "interrupt")
	bindTip(kick, "TIP_INTERRUPT", "TIP_INTERRUPT_DESC")
	local cast = CreateFrame("StatusBar", nil, kick)
	cast:SetSize(26, 4)
	cast:SetPoint("TOP", kick, "BOTTOM", 0, -2)
	cast:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
	cast:SetStatusBarColor(1, 0.82, 0.2, 1)
	cast:SetMinMaxValues(0, 1)
	cast:SetValue(0)
	local castBg = cast:CreateTexture(nil, "BACKGROUND")
	castBg:SetAllPoints()
	castBg:SetTexture("Interface\\Buttons\\WHITE8x8")
	castBg:SetVertexColor(0, 0, 0, 0.65)
	cast:Hide()
	kick.cast = cast
	kick:SetScript("OnUpdate", function(self, elapsed)
		self._castAcc = (self._castAcc or 0) + elapsed
		if self._castAcc < 0.05 then
			return
		end
		self._castAcc = 0
		if not self.cast or not self:IsShown() or not ns.API.TargetCastProgress then
			if self.cast then
				self.cast:Hide()
			end
			return
		end
		local ok, progress = pcall(ns.API.TargetCastProgress)
		if not ok or type(progress) ~= "number" then
			self.cast:Hide()
			return
		end
		self.cast:Show()
		self.cast:SetValue(progress)
	end)
	ns.UI.interrupt = kick

	local purge = makeIcon("WoWForeverRotPurge", UIParent, 26)
	purge:ClearAllPoints()
	purge:SetPoint("RIGHT", ns.UI.slots[1], "LEFT", -8, -14)
	purge.texture:SetTexture(IMG .. "magiccircle-purge")
	purge.texture:SetVertexColor(0.2, 0.2, 0.2)
	makeMovable(purge, "purge")
	bindTip(purge, "TIP_PURGE", "TIP_PURGE_DESC")
	ns.UI.purge = purge

	local cleanse = makeIcon("WoWForeverRotCleanse", UIParent, 26)
	cleanse:ClearAllPoints()
	cleanse:SetPoint("LEFT", ns.UI.slots[3], "RIGHT", 8, 6)
	paintIdle(cleanse, 0.2, 0.85, 0.35)
	makeMovable(cleanse, "cleanse")
	bindTip(cleanse, "TIP_CLEANSE", "TIP_CLEANSE_DESC")
	ns.UI.cleanse = cleanse

	local weapon = makeIcon("WoWForeverRotWeapon", UIParent, 26)
	weapon:ClearAllPoints()
	weapon:SetPoint("LEFT", ns.UI.slots[3], "RIGHT", 8, -16)
	weapon.texture:SetTexture("Interface\\Icons\\INV_Axe_02")
	weapon.texture:SetVertexColor(1, 1, 1, 0.45)
	makeMovable(weapon, "weapon")
	bindTip(weapon, "TIP_WEAPON", "TIP_WEAPON_DESC")
	weapon.pulseTick = function(self, elapsed)
		if not self.needRefresh then
			self:SetAlpha(1)
			self:SetScript("OnUpdate", nil)
			return
		end
		self.pulse = (self.pulse or 0) + elapsed
		self:SetAlpha(0.4 + 0.6 * math.abs(math.sin(GetTime() * 5)))
	end
	ns.UI.weapon = weapon

	local lockWrap = CreateFrame("Frame", "WoWForeverRotLock", UIParent, "BackdropTemplate")
	lockWrap:SetSize(28, 28)
	lockWrap:SetFrameStrata("HIGH")
	applyChrome(lockWrap)
	local lock = makeIconButton("WoWForeverRotLockBtn", lockWrap, 18)
	lock:SetPoint("CENTER")
	lock:RegisterForClicks("LeftButtonUp")
	lock:SetScript("OnClick", function(self)
		if self._wfrDragged then
			self._wfrDragged = nil
			return
		end
		ns.UI.SetLocked(not ns.db.locked)
	end)
	makeMovable(lockWrap, "lock")
	makeMovable(lock, "lock", lockWrap)
	ns.UI.lock = lock
	ns.UI.lockWrap = lockWrap

	local TOOLBAR_W_FULL = 332
	local TOOLBAR_W_COMPACT = 188
	local bar = CreateFrame("Frame", "WoWForeverRotToolbar", UIParent, "BackdropTemplate")
	bar:SetSize(TOOLBAR_W_FULL, 32)
	bar:SetFrameStrata("MEDIUM")
	bar:SetHitRectInsets(-10, -10, -8, -8)
	bar:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 8,
		edgeSize = 16,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	local cr, cg, cb = classColor()
	bar:SetBackdropColor(0, 0, 0, 0.75)
	bar:SetBackdropBorderColor(cr, cg, cb, 0.75)
	makeMovable(bar, "toolbar")
	ns.UI.toolbar = bar
	ns.UI.ClassColor = classColor
	ns.UI.toolbarWidthFull = TOOLBAR_W_FULL
	ns.UI.toolbarWidthCompact = TOOLBAR_W_COMPACT

	local grip = CreateFrame("Frame", "WoWForeverRotToolbarGrip", bar)
	grip:SetSize(14, 22)
	grip:SetPoint("LEFT", bar, "LEFT", 4, 0)
	for i = 1, 6 do
		local dot = grip:CreateTexture(nil, "ARTWORK")
		dot:SetSize(3, 3)
		dot:SetTexture("Interface\\Buttons\\WHITE8x8")
		dot:SetVertexColor(1, 1, 1, 0.5)
		local col = (i - 1) % 2
		local row = math.floor((i - 1) / 2)
		dot:SetPoint("TOPLEFT", grip, "TOPLEFT", 3 + col * 5, -4 - row * 5)
	end
	makeMovable(grip, "toolbar", bar)
	bindTip(grip, "TIP_MOVE_BAR", "TIP_MOVE_BAR_DESC")
	ns.UI.toolbarGrip = grip

	local function makeCycleBtn(name, width, onClick)
		local btn = CreateFrame("Button", name, bar)
		btn:SetSize(width, 16)
		btn:SetNormalFontObject("GameFontHighlightSmall")
		btn:RegisterForClicks("LeftButtonUp")
		local ntex = btn:CreateTexture(nil, "BACKGROUND")
		ntex:SetTexture(IMG .. "buttonUp")
		ntex:SetTexCoord(0, 0.625, 0, 0.6875)
		ntex:SetAllPoints()
		btn:SetNormalTexture(ntex)
		btn.ntex = ntex
		local htex = btn:CreateTexture(nil, "HIGHLIGHT")
		htex:SetTexture(IMG .. "buttonHighlight")
		htex:SetTexCoord(0, 0.625, 0, 0.6875)
		htex:SetAllPoints()
		btn:SetHighlightTexture(htex)
		local ptex = btn:CreateTexture(nil, "BACKGROUND")
		ptex:SetTexture(IMG .. "buttonDown")
		ptex:SetTexCoord(0, 0.625, 0, 0.6875)
		ptex:SetAllPoints()
		btn:SetPushedTexture(ptex)
		btn.ptex = ptex
		function btn:SetActive(on)
			local r, g, b = classColor()
			local a = on and 1 or 0.6
			if on then
				self.ntex:SetTexture(IMG .. "buttonDown")
			else
				self.ntex:SetTexture(IMG .. "buttonUp")
			end
			self.ntex:SetVertexColor(r, g, b, a)
			self.ptex:SetVertexColor(r, g, b, 1)
			local normal = self:GetNormalTexture()
			if normal then
				normal:SetVertexColor(r, g, b, a)
			end
			local pushed = self:GetPushedTexture()
			if pushed then
				pushed:SetVertexColor(r, g, b, 1)
			end
			local fs = self:GetFontString()
			if fs then
				fs:SetTextColor(1, 1, 1, on and 1 or 0.85)
			end
		end
		btn:SetActive(false)
		btn:SetScript("OnClick", function(self)
			if self._wfrDragged then
				self._wfrDragged = nil
				return
			end
			onClick(self)
		end)
		btn:SetScript("OnEnter", showTip)
		btn:SetScript("OnLeave", hideTip)
		return btn
	end

	local roleBtn = makeCycleBtn("WoWForeverRotRoleBtn", 90, function()
		if ns.CycleRole then
			ns.CycleRole()
		end
	end)
	roleBtn:SetPoint("LEFT", grip, "RIGHT", 4, 0)
	roleBtn:SetActive(true)
	makeMovable(roleBtn, "toolbar", bar)
	ns.UI.roleBtn = roleBtn

	local autoBtn = makeCycleBtn("WoWForeverRotAutoBtn", 56, function()
		if ns.ToggleAuto then
			ns.ToggleAuto()
		end
	end)
	autoBtn:SetPoint("LEFT", roleBtn, "RIGHT", 4, 0)
	autoBtn:SetText(ns.T("MODE_AUTO"))
	makeMovable(autoBtn, "toolbar", bar)
	ns.UI.autoBtn = autoBtn

	local modeBtn = makeCycleBtn("WoWForeverRotModeBtn", 80, function()
		if ns.CycleCombatMode then
			ns.CycleCombatMode()
		end
	end)
	modeBtn:SetPoint("LEFT", autoBtn, "RIGHT", 4, 0)
	makeMovable(modeBtn, "toolbar", bar)
	ns.UI.modeBtn = modeBtn

	local profileBtn = makeCycleBtn("WoWForeverRotProfileBtn", 64, function()
		if ns.CycleProfile then
			ns.CycleProfile()
		end
	end)
	profileBtn:SetPoint("LEFT", modeBtn, "RIGHT", 4, 0)
	profileBtn:SetActive(true)
	makeMovable(profileBtn, "toolbar", bar)
	ns.UI.profileBtn = profileBtn

	ns.UI.roles = {}
	ns.UI.modes = {}

	local combo = CreateFrame("Frame", "WoWForeverRotCombo", UIParent, "BackdropTemplate")
	combo:SetSize(36, 36)
	combo:SetFrameStrata("MEDIUM")
	applyChrome(combo)
	local comboText = combo:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	comboText:SetPoint("CENTER", 0, 1)
	local comboFont = comboText:GetFont()
	if comboFont then
		comboText:SetFont(comboFont, 22, "OUTLINE")
	end
	comboText:SetText("0")
	combo.text = comboText
	makeMovable(combo, "combo")
	bindTip(combo, "TIP_COMBO", "TIP_COMBO_DESC")
	combo:SetScript("OnUpdate", function(self, elapsed)
		self._acc = (self._acc or 0) + elapsed
		if self._acc < 0.1 then
			return
		end
		self._acc = 0
		local idle = ns.API.ShouldHideIdle and ns.API.ShouldHideIdle()
		local token = ns.ClassToken and ns.ClassToken()
		local cat = token == "DRUID" and ns.db and ns.db.role == "cat"
		local show = not idle and ns.db and ns.db.showRotation ~= false and (token == "ROGUE" or cat)
		self:SetShown(show)
		if not show then
			return
		end
		local points = ns.API.Combo and ns.API.Combo() or 0
		if type(points) ~= "number" then
			points = 0
		end
		self.text:SetText(tostring(points))
		if points >= 5 then
			self.text:SetTextColor(1, 0.82, 0.2)
		else
			local r, g, b = classColor()
			self.text:SetTextColor(r, g, b)
		end
	end)
	ns.UI.combo = combo

	local notice = root:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	notice:SetPoint("TOP", root, "BOTTOM", 0, -4)
	notice:SetTextColor(1, 0.82, 0.2)
	notice:SetJustifyH("CENTER")
	notice:Hide()
	ns.UI.notice = notice

	ns.UI.root = root
	ns.UI.ApplyPosition()
	ns.UI.ApplyScale()
	ns.UI.RefreshRoles()
	ns.UI.SetLocked(ns.db.locked == true)
	if ns.UI.FitFrame then
		ns.UI.FitFrame()
	end
end

function ns.UI.RefreshTips()
	local frames = {
		ns.UI.root,
		ns.UI.defense,
		ns.UI.interrupt,
		ns.UI.purge,
		ns.UI.cleanse,
		ns.UI.weapon,
		ns.UI.combo,
		ns.UI.lock,
	}
	if ns.UI.slots then
		for _, slot in ipairs(ns.UI.slots) do
			frames[#frames + 1] = slot
		end
	end
	for _, frame in ipairs(frames) do
		if frame and frame.tipTitleKey then
			frame.tipTitle = ns.T(frame.tipTitleKey)
			frame.tipDesc = frame.tipDescKey and ns.T(frame.tipDescKey) or nil
		end
	end
end

function ns.UI.ApplyChrome()
	local locked = ns.db and ns.db.locked == true
	applyChrome(ns.UI.root, locked)
	applyChrome(ns.UI.defense, locked)
	applyChrome(ns.UI.interrupt, locked)
	applyChrome(ns.UI.purge, locked)
	applyChrome(ns.UI.cleanse, locked)
	applyChrome(ns.UI.weapon, locked)
	applyChrome(ns.UI.combo, locked)
	applyChrome(ns.UI.lockWrap, locked)
	if ns.UI.slots then
		for _, slot in ipairs(ns.UI.slots) do
			applyChrome(slot, locked)
		end
	end
	if ns.UI.toolbar then
		local r, g, b = classColor()
		ns.UI.toolbar:SetBackdropBorderColor(r, g, b, 0.75)
		ns.UI.toolbar:SetBackdropColor(0, 0, 0, locked and 0.2 or 0.75)
	end
end

function ns.UI.ApplyPosition()
	loadPoint(ns.UI.root, "queue", { "CENTER", UIParent, "CENTER", 0, -80 })
	loadPoint(ns.UI.lockWrap, "lock", { "TOP", ns.UI.root, "BOTTOM", 0, -4 })
	loadPoint(ns.UI.toolbar, "toolbar", { "TOP", ns.UI.root, "BOTTOM", 0, -40 })
	loadPoint(ns.UI.defense, "defense", { "TOP", ns.UI.root, "BOTTOM", 0, -80 })
	loadPoint(ns.UI.interrupt, "interrupt", { "RIGHT", ns.UI.root, "LEFT", -8, 12 })
	loadPoint(ns.UI.purge, "purge", { "RIGHT", ns.UI.root, "LEFT", -8, -12 })
	loadPoint(ns.UI.cleanse, "cleanse", { "LEFT", ns.UI.root, "RIGHT", 8, 12 })
	loadPoint(ns.UI.weapon, "weapon", { "LEFT", ns.UI.root, "RIGHT", 8, -12 })
	loadPoint(ns.UI.combo, "combo", { "BOTTOM", ns.UI.root, "TOP", 0, 8 })
	ns.UI.ApplyScale()
end

function ns.UIScale()
	local n = tonumber(ns.db and ns.db.uiScale) or 1
	if n < 0.6 then
		n = 0.6
	end
	if n > 2 then
		n = 2
	end
	return math.floor(n * 10 + 0.5) / 10
end

function ns.UI.ApplyScale()
	local s = ns.UIScale()
	for _, key in ipairs({ "root", "toolbar", "interrupt", "purge", "cleanse", "weapon", "defense", "lockWrap", "combo" }) do
		local frame = ns.UI[key]
		if frame then
			frame:SetScale(s)
		end
	end
end

function ns.SetUIScale(value)
	ns.db.uiScale = value
	ns.db.uiScale = ns.UIScale()
	ns.UI.ApplyScale()
	if ns.RefreshOptions then
		ns.RefreshOptions()
	end
end

function ns.UI.RefreshRoles()
	local classFile = ns.ClassToken and ns.ClassToken() or ""
	local roles = ns.CLASS_ROLES[classFile] or { "damage" }
	if not ns.RoleAllowed or not ns.RoleAllowed(ns.db.role) then
		ns.db.role = roles[1]
	end
	local role = ns.db.role or roles[1]
	local btn = ns.UI.roleBtn
	if btn then
		local name = ns.T("ROLE_" .. role:upper())
		btn:SetText(name)
		btn.tipTitle = ns.T("TIP_ROLE"):format(name)
		btn.tipDesc = role == "hybrid" and ns.T("TIP_HYBRID_DESC") or ns.T("TIP_ROLE_DESC")
		btn.tipHint = ns.T("TIP_ROLE_CYCLE")
		btn:Show()
	end
	if ns.UI.RefreshModes then
		ns.UI.RefreshModes()
	end
end

function ns.UI.RefreshModes()
	if not ns.UI.toolbar then
		return
	end
	local showMode = ns.db.showModes ~= false
	local selected = ns.CombatMode and ns.CombatMode() or "auto"
	local manual = ns.db.lastManualMode or "single"
	if manual ~= "single" and manual ~= "aoe" and manual ~= "burst" then
		manual = "single"
	end
	if selected ~= "auto" then
		manual = selected
	end
	if ns.UI.roleBtn then
		ns.UI.roleBtn:Show()
	end
	local autoBtn = ns.UI.autoBtn
	if autoBtn then
		autoBtn:SetText(ns.T("MODE_AUTO"))
		autoBtn.tipTitle = ns.T("MODE_AUTO")
		local need = tonumber(ns.db.autoEnemies) or 3
		local n = ns.API.EnemyCount and ns.API.EnemyCount() or 0
		autoBtn.tipDesc = ns.T("TIP_MODE_AUTO"):format(need)
		if selected == "auto" then
			local using = ns.ResolveCombatMode and ns.ResolveCombatMode() or "auto"
			if using == "aoe" then
				autoBtn.tipHint = ns.T("TIP_AUTO_NOW_AOE"):format(n)
			else
				autoBtn.tipHint = ns.T("TIP_AUTO_NOW_ST"):format(n)
			end
		else
			autoBtn.tipHint = ns.T("TIP_MODE_CYCLE")
		end
		if autoBtn.SetActive then
			autoBtn:SetActive(selected == "auto")
		end
		autoBtn:SetShown(showMode)
	end
	local modeBtn = ns.UI.modeBtn
	if modeBtn then
		modeBtn:SetText(ns.T("MODE_" .. manual:upper()))
		modeBtn.tipTitle = ns.T("MODE_" .. manual:upper())
		modeBtn.tipDesc = ns.T("TIP_MODE_" .. manual:upper())
		modeBtn.tipHint = ns.T("TIP_MODE_CYCLE")
		modeBtn:ClearAllPoints()
		if autoBtn and showMode then
			modeBtn:SetPoint("LEFT", autoBtn, "RIGHT", 4, 0)
		elseif ns.UI.roleBtn then
			modeBtn:SetPoint("LEFT", ns.UI.roleBtn, "RIGHT", 4, 0)
		else
			modeBtn:SetPoint("LEFT", ns.UI.toolbar, "LEFT", 6, 0)
		end
		if modeBtn.SetActive then
			modeBtn:SetActive(selected ~= "auto")
		end
		modeBtn:SetShown(showMode)
	end
	local profileBtn = ns.UI.profileBtn
	if profileBtn then
		local key = ns.ProfileKey and ns.ProfileKey() or "pve"
		local label = ns.T("PROFILE_" .. key:upper())
		profileBtn:SetText(label)
		profileBtn.tipTitle = ns.T("TIP_PROFILE"):format(label)
		profileBtn.tipDesc = ns.T("TIP_PROFILE_DESC")
		profileBtn.tipHint = ns.T("TIP_PROFILE_CYCLE")
		profileBtn:ClearAllPoints()
		if modeBtn and showMode then
			profileBtn:SetPoint("LEFT", modeBtn, "RIGHT", 4, 0)
		elseif autoBtn and showMode then
			profileBtn:SetPoint("LEFT", autoBtn, "RIGHT", 4, 0)
		elseif ns.UI.roleBtn then
			profileBtn:SetPoint("LEFT", ns.UI.roleBtn, "RIGHT", 4, 0)
		else
			profileBtn:SetPoint("LEFT", ns.UI.toolbar, "LEFT", 6, 0)
		end
		if profileBtn.SetActive then
			profileBtn:SetActive(true)
		end
		profileBtn:Show()
	end
	if ns.UI.roleBtn and ns.UI.roleBtn.SetActive then
		ns.UI.roleBtn:SetActive(true)
	end
	if ns.UI.ApplyChrome then
		ns.UI.ApplyChrome()
	end
	ns.UI.toolbar:SetWidth(showMode and (ns.UI.toolbarWidthFull or 332) or (ns.UI.toolbarWidthCompact or 188))
end

function ns.UI.ApplyMouse()
	local mouse = ns.db.locked ~= true
	local frames = {
		ns.UI.root,
		ns.UI.defense,
		ns.UI.interrupt,
		ns.UI.purge,
		ns.UI.cleanse,
		ns.UI.weapon,
		ns.UI.combo,
		ns.UI.toolbar,
		ns.UI.toolbarGrip,
		ns.UI.roleBtn,
		ns.UI.autoBtn,
		ns.UI.modeBtn,
		ns.UI.profileBtn,
		ns.UI.lockWrap,
	}
	for _, frame in ipairs(frames) do
		if frame then
			frame:EnableMouse(mouse)
		end
	end
	if ns.UI.slots then
		for _, slot in ipairs(ns.UI.slots) do
			slot:EnableMouse(mouse)
		end
	end
	if ns.UI.lockWrap then
		ns.UI.lockWrap:EnableMouse(true)
		ns.UI.lockWrap:SetFrameStrata("HIGH")
	end
	if ns.UI.lock then
		ns.UI.lock:EnableMouse(true)
		ns.UI.lock:SetFrameStrata("HIGH")
	end
end

function ns.UI.SetLocked(locked)
	ns.db.locked = locked and true or false
	if ns.UI.ApplyChrome then
		ns.UI.ApplyChrome()
	end
	if ns.UI.lock then
		ns.UI.lock.texture:SetTexture(IMG .. (locked and "padlock_closed" or "padlock_open"))
		ns.UI.lock.tipTitle = locked and ns.T("TIP_UNLOCK") or ns.T("TIP_LOCK")
		ns.UI.lock.tipDesc = ns.T("TIP_LOCK_HINT")
		ns.UI.lock.idleAlpha = 0.9
		ns.UI.lock:SetAlpha(0.9)
	end
	ns.UI.ApplyMouse()
end

function ns.UI.RefreshCue()
	if not ns.UI.slots then
		return
	end
	local cue = ns.Physics and ns.Physics.Enabled and ns.Physics.Enabled() and ns.Physics.Cue
	for _, slot in ipairs(ns.UI.slots) do
		if slot.shine then
			local hot = cue and slot.spellID and ns.Physics.Cue(slot.spellID)
			if hot then
				slot.shine:SetVertexColor(1, 1, 1, 0.9)
				slot.shine:Show()
				slot.tipHint = ns.T("TIP_CUE")
			else
				slot.shine:Hide()
				slot.tipHint = nil
			end
		end
	end
end

local function setBind(slot, spellID)
	if not slot or not slot.bind then
		return
	end
	if spellID and ns.SpellBinding then
		slot.bind:SetText(ns.SpellBinding(spellID) or "")
	else
		slot.bind:SetText("")
	end
end

local function paint(slot, spellID, dim)
	if not slot then
		return
	end
	slot.spellID = spellID
	slot.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	if not spellID then
		slot.texture:SetTexture(IMG .. "skull")
		slot.texture:SetVertexColor(1, 1, 1, 0.35)
		slot.cooldown:Hide()
		if slot.filter then
			slot.filter:Hide()
		end
		setBind(slot, nil)
		return
	end
	local icon = API.SpellIcon(spellID)
	if icon then
		slot.texture:SetTexture(icon)
	else
		slot.texture:SetTexture(IMG .. "skull")
	end
	slot.texture:SetVertexColor(1, 1, 1, dim and 0.55 or 1)
	if slot.filter then
		slot.filter:Hide()
	end
	local remain, duration = API.Cooldown(spellID)
	if duration and duration > 1.5 and remain > 0 then
		slot.cooldown:Show()
		slot.cooldown:SetCooldown(GetTime() - (duration - remain), duration)
	else
		slot.cooldown:Hide()
	end
	setBind(slot, spellID)
end

local function paintSide(slot, spellID, idleR, idleG, idleB)
	if not slot then
		return
	end
	slot.spellID = spellID
	if spellID then
		local icon = API.SpellIcon(spellID)
		if icon then
			slot.texture:SetTexture(icon)
		end
		slot.texture:SetVertexColor(1, 1, 1, 1)
	else
		slot.texture:SetColorTexture(idleR, idleG, idleB, 0.35)
		slot.texture:SetVertexColor(1, 1, 1, 1)
	end
end

function ns.UI.Update(queue, defenseID, interruptID, purgeID, cleanseID, weaponID, weaponNeed, notice)
	queue = queue or {}
	for i = 1, 3 do
		paint(ns.UI.slots[i], queue[i], i > 1)
	end
	if ns.UI.notice then
		if type(notice) == "string" and notice ~= "" then
			ns.UI.notice:SetText(notice)
			ns.UI.notice:Show()
		else
			ns.UI.notice:SetText("")
			ns.UI.notice:Hide()
		end
	end
	if defenseID then
		paint(ns.UI.defense, defenseID)
	else
		ns.UI.defense.spellID = nil
		ns.UI.defense.texture:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-ROLES")
		ns.UI.defense.texture:SetTexCoord(0, 0.26171875, 0.26171875, 0.5234375)
		ns.UI.defense.texture:SetVertexColor(0.25, 0.8, 1, 0.55)
		if ns.UI.defense.cooldown then
			ns.UI.defense.cooldown:Hide()
		end
		setBind(ns.UI.defense, nil)
	end
	if interruptID then
		ns.UI.interrupt.spellID = interruptID
		ns.UI.interrupt.texture:SetTexture(API.SpellIcon(interruptID) or (IMG .. "lightning-interrupt"))
		ns.UI.interrupt.texture:SetVertexColor(1, 1, 1, 1)
	else
		ns.UI.interrupt.spellID = nil
		ns.UI.interrupt.texture:SetTexture(IMG .. "lightning-interrupt")
		ns.UI.interrupt.texture:SetVertexColor(0.2, 0.2, 0.2, 0.8)
	end
	setBind(ns.UI.interrupt, interruptID)
	if purgeID then
		ns.UI.purge.spellID = purgeID
		ns.UI.purge.texture:SetTexture(API.SpellIcon(purgeID) or (IMG .. "magiccircle-purge"))
		ns.UI.purge.texture:SetVertexColor(1, 1, 1, 1)
	else
		ns.UI.purge.spellID = nil
		ns.UI.purge.texture:SetTexture(IMG .. "magiccircle-purge")
		ns.UI.purge.texture:SetVertexColor(0.2, 0.2, 0.2, 0.8)
	end
	setBind(ns.UI.purge, purgeID)
	paintSide(ns.UI.cleanse, cleanseID, 0.2, 0.85, 0.35)
	if not cleanseID then
		ns.UI.cleanse.texture:SetColorTexture(0.15, 0.45, 0.22, 0.55)
	end
	setBind(ns.UI.cleanse, cleanseID)
	if ns.UI.weapon then
		local hasWeapon = #(ns.WeaponChoices and ns.WeaponChoices() or {}) > 0
		local icon = (weaponID and API.SpellIcon(weaponID)) or "Interface\\Icons\\INV_Axe_02"
		ns.UI.weapon.spellID = weaponID
		ns.UI.weapon.texture:SetTexture(icon)
		ns.UI.weapon.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		ns.UI.weapon.needRefresh = hasWeapon and weaponNeed and true or false
		if ns.UI.weapon.needRefresh then
			ns.UI.weapon:SetScript("OnUpdate", ns.UI.weapon.pulseTick)
		else
			ns.UI.weapon:SetScript("OnUpdate", nil)
			ns.UI.weapon:SetAlpha(1)
		end
		if hasWeapon and weaponNeed then
			ns.UI.weapon.texture:SetVertexColor(1, 1, 1, 1)
			if ns.UI.weapon.filter then
				ns.UI.weapon.filter:Show()
			end
			if ns.UI.weapon.shine then
				ns.UI.weapon.shine:Hide()
			end
		elseif hasWeapon then
			ns.UI.weapon:SetAlpha(1)
			ns.UI.weapon.texture:SetVertexColor(1, 1, 1, 1)
			if ns.UI.weapon.filter then
				ns.UI.weapon.filter:Hide()
			end
			if ns.UI.weapon.shine then
				ns.UI.weapon.shine:Show()
			end
		else
			ns.UI.weapon:SetAlpha(1)
			ns.UI.weapon.texture:SetVertexColor(1, 1, 1, 0.45)
			if ns.UI.weapon.filter then
				ns.UI.weapon.filter:Hide()
			end
			if ns.UI.weapon.shine then
				ns.UI.weapon.shine:Hide()
			end
		end
	end
	local idle = ns.API.ShouldHideIdle and ns.API.ShouldHideIdle()
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
		setBind(ns.UI.weapon, weaponNeed and weaponID or nil)
	end
	ns.UI.RefreshRoles()
	ns.UI.RefreshCue()
end
