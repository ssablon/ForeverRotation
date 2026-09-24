local addonName, ns = ...
ns.UI = ns.UI or {}
local API = ns.API

local SIZE = 50
local GAP = 8
local IMG = "Interface\\AddOns\\WoWForeverRot\\images\\"

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
	frame:SetScript("OnDragStart", function()
		if ns.db.locked then
			return
		end
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
	frame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 8,
		edgeSize = 10,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	frame:SetBackdropColor(0, 0, 0, 0.35)
	frame:SetBackdropBorderColor(0.8, 0.65, 0.2, 0.4)
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
	root:SetSize(SIZE * 3 + GAP * 2 + 8, SIZE + 16)
	root:SetFrameStrata("MEDIUM")
	root:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 8,
		edgeSize = 12,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	root:SetBackdropColor(0, 0, 0, 0.45)
	root:SetBackdropBorderColor(0.83, 0.63, 0.09, 0.8)
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
			slot:SetPoint("LEFT", root, "LEFT", 8, 0)
		else
			slot:SetPoint("LEFT", ns.UI.slots[i - 1], "RIGHT", GAP, i == 2 and -5 or 0)
		end
		makeMovable(slot, "queue", root)
		bindTip(slot, tipKeys[i][1], tipKeys[i][2])
		ns.UI.slots[i] = slot
	end

	local function makeDefense()
		local frame = CreateFrame("Frame", "WoWForeverRotDefense", UIParent, "BackdropTemplate")
		frame:SetSize(42, 42)
		frame:SetFrameStrata("MEDIUM")
		frame:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8x8",
			edgeFile = "Interface\\Buttons\\WHITE8x8",
			tile = true,
			tileSize = 8,
			edgeSize = 2,
			insets = { left = 2, right = 2, top = 2, bottom = 2 },
		})
		frame:SetBackdropColor(0.04, 0.1, 0.14, 0.92)
		frame:SetBackdropBorderColor(0.2, 0.78, 0.95, 0.95)
		local inner = frame:CreateTexture(nil, "ARTWORK")
		inner:SetPoint("TOPLEFT", 4, -4)
		inner:SetPoint("BOTTOMRIGHT", -4, 4)
		inner:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		frame.texture = inner
		local cd = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
		cd:SetAllPoints(inner)
		cd:SetDrawEdge(false)
		frame.cooldown = cd
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
	kick:SetPoint("RIGHT", root, "LEFT", -8, 12)
	kick.texture:SetTexture(IMG .. "lightning-interrupt")
	kick.texture:SetVertexColor(0.2, 0.2, 0.2)
	makeMovable(kick, "queue", root)
	bindTip(kick, "TIP_INTERRUPT", "TIP_INTERRUPT_DESC")
	ns.UI.interrupt = kick

	local purge = makeIcon("WoWForeverRotPurge", UIParent, 26)
	purge:ClearAllPoints()
	purge:SetPoint("RIGHT", root, "LEFT", -8, -12)
	purge.texture:SetTexture(IMG .. "magiccircle-purge")
	purge.texture:SetVertexColor(0.2, 0.2, 0.2)
	makeMovable(purge, "queue", root)
	bindTip(purge, "TIP_PURGE", "TIP_PURGE_DESC")
	ns.UI.purge = purge

	local cleanse = makeIcon("WoWForeverRotCleanse", UIParent, 26)
	cleanse:ClearAllPoints()
	cleanse:SetPoint("LEFT", root, "RIGHT", 8, 12)
	paintIdle(cleanse, 0.2, 0.85, 0.35)
	makeMovable(cleanse, "queue", root)
	bindTip(cleanse, "TIP_CLEANSE", "TIP_CLEANSE_DESC")
	ns.UI.cleanse = cleanse

	local weapon = makeIcon("WoWForeverRotWeapon", UIParent, 26)
	weapon:ClearAllPoints()
	weapon:SetPoint("LEFT", root, "RIGHT", 8, -12)
	weapon.texture:SetTexture("Interface\\Icons\\INV_Axe_02")
	weapon.texture:SetVertexColor(1, 1, 1, 0.45)
	makeMovable(weapon, "queue", root)
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

	local lock = makeIconButton("WoWForeverRotLock", UIParent, 22)
	lock:SetPoint("TOP", root, "BOTTOM", 0, -4)
	lock:RegisterForClicks("LeftButtonUp")
	lock:SetScript("OnClick", function()
		ns.UI.SetLocked(not ns.db.locked)
	end)
	makeMovable(lock, "queue", root)
	ns.UI.lock = lock

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

	local bar = CreateFrame("Frame", "WoWForeverRotToolbar", UIParent, "BackdropTemplate")
	bar:SetSize(314, 26)
	bar:SetFrameStrata("MEDIUM")
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
	roleBtn:SetPoint("LEFT", bar, "LEFT", 6, 0)
	roleBtn:SetActive(true)
	ns.UI.roleBtn = roleBtn

	local autoBtn = makeCycleBtn("WoWForeverRotAutoBtn", 56, function()
		if ns.ToggleAuto then
			ns.ToggleAuto()
		end
	end)
	autoBtn:SetPoint("LEFT", roleBtn, "RIGHT", 4, 0)
	autoBtn:SetText(ns.T("MODE_AUTO"))
	ns.UI.autoBtn = autoBtn

	local modeBtn = makeCycleBtn("WoWForeverRotModeBtn", 80, function()
		if ns.CycleCombatMode then
			ns.CycleCombatMode()
		end
	end)
	modeBtn:SetPoint("LEFT", autoBtn, "RIGHT", 4, 0)
	ns.UI.modeBtn = modeBtn

	local profileBtn = makeCycleBtn("WoWForeverRotProfileBtn", 64, function()
		if ns.CycleProfile then
			ns.CycleProfile()
		end
	end)
	profileBtn:SetPoint("LEFT", modeBtn, "RIGHT", 4, 0)
	profileBtn:SetActive(true)
	ns.UI.profileBtn = profileBtn

	ns.UI.roles = {}
	ns.UI.modes = {}

	ns.UI.root = root
	ns.UI.ApplyPosition()
	ns.UI.ApplyScale()
	ns.UI.RefreshRoles()
	ns.UI.SetLocked(ns.db.locked == true)
end

function ns.UI.ApplyPosition()
	loadPoint(ns.UI.root, "queue", { "CENTER", UIParent, "CENTER", 0, -80 })
	if ns.UI.lock then
		ns.UI.lock:ClearAllPoints()
		ns.UI.lock:SetPoint("TOP", ns.UI.root, "BOTTOM", 0, -4)
	end
	loadPoint(ns.UI.toolbar, "toolbar", { "TOP", ns.UI.root, "BOTTOM", 0, -36 })
	loadPoint(ns.UI.defense, "defense", { "TOP", ns.UI.root, "BOTTOM", 0, -76 })
	if ns.UI.interrupt then
		ns.UI.interrupt:ClearAllPoints()
		ns.UI.interrupt:SetPoint("RIGHT", ns.UI.root, "LEFT", -8, 12)
	end
	if ns.UI.purge then
		ns.UI.purge:ClearAllPoints()
		ns.UI.purge:SetPoint("RIGHT", ns.UI.root, "LEFT", -8, -12)
	end
	if ns.UI.cleanse then
		ns.UI.cleanse:ClearAllPoints()
		ns.UI.cleanse:SetPoint("LEFT", ns.UI.root, "RIGHT", 8, 12)
	end
	if ns.UI.weapon then
		ns.UI.weapon:ClearAllPoints()
		ns.UI.weapon:SetPoint("LEFT", ns.UI.root, "RIGHT", 8, -12)
	end
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
	for _, key in ipairs({ "root", "toolbar", "interrupt", "purge", "cleanse", "weapon", "defense", "lock" }) do
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
	if ns.UI.ClassColor then
		local r, g, b = ns.UI.ClassColor()
		ns.UI.toolbar:SetBackdropBorderColor(r, g, b, 0.75)
	end
	ns.UI.toolbar:SetWidth(showMode and 314 or 170)
end

function ns.UI.SetLocked(locked)
	ns.db.locked = locked and true or false
	local alpha = locked and 0.15 or 0.45
	if ns.UI.root then
		ns.UI.root:SetBackdropColor(0, 0, 0, alpha)
	end
	if ns.UI.toolbar then
		ns.UI.toolbar:SetBackdropColor(0, 0, 0, locked and 0.2 or 0.4)
	end
	if ns.UI.lock then
		ns.UI.lock.texture:SetTexture(IMG .. (locked and "padlock_closed" or "padlock_open"))
		ns.UI.lock.tipTitle = locked and ns.T("TIP_UNLOCK") or ns.T("TIP_LOCK")
		ns.UI.lock.tipDesc = ns.T("TIP_LOCK_HINT")
		ns.UI.lock.idleAlpha = 0.9
		ns.UI.lock:SetAlpha(0.9)
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

function ns.UI.Update(queue, defenseID, interruptID, purgeID, cleanseID, weaponID, weaponNeed)
	queue = queue or {}
	for i = 1, 3 do
		paint(ns.UI.slots[i], queue[i], i > 1)
	end
	if defenseID then
		paint(ns.UI.defense, defenseID)
		ns.UI.defense:SetBackdropBorderColor(0.35, 0.95, 1, 1)
	else
		ns.UI.defense.spellID = nil
		ns.UI.defense.texture:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-ROLES")
		ns.UI.defense.texture:SetTexCoord(0, 0.26171875, 0.26171875, 0.5234375)
		ns.UI.defense.texture:SetVertexColor(0.25, 0.8, 1, 0.55)
		ns.UI.defense:SetBackdropBorderColor(0.2, 0.78, 0.95, 0.7)
		if ns.UI.defense.cooldown then
			ns.UI.defense.cooldown:Hide()
		end
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
	if purgeID then
		ns.UI.purge.spellID = purgeID
		ns.UI.purge.texture:SetTexture(API.SpellIcon(purgeID) or (IMG .. "magiccircle-purge"))
		ns.UI.purge.texture:SetVertexColor(1, 1, 1, 1)
	else
		ns.UI.purge.spellID = nil
		ns.UI.purge.texture:SetTexture(IMG .. "magiccircle-purge")
		ns.UI.purge.texture:SetVertexColor(0.2, 0.2, 0.2, 0.8)
	end
	paintSide(ns.UI.cleanse, cleanseID, 0.2, 0.85, 0.35)
	if not cleanseID then
		ns.UI.cleanse.texture:SetColorTexture(0.15, 0.45, 0.22, 0.55)
	end
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
			ns.UI.weapon:SetBackdropBorderColor(0.9, 0.15, 0.1, 1)
		elseif hasWeapon then
			ns.UI.weapon:SetAlpha(1)
			ns.UI.weapon.texture:SetVertexColor(1, 1, 1, 1)
			if ns.UI.weapon.filter then
				ns.UI.weapon.filter:Hide()
			end
			if ns.UI.weapon.shine then
				ns.UI.weapon.shine:Show()
			end
			ns.UI.weapon:SetBackdropBorderColor(0.95, 0.82, 0.25, 1)
		else
			ns.UI.weapon:SetAlpha(1)
			ns.UI.weapon.texture:SetVertexColor(1, 1, 1, 0.45)
			if ns.UI.weapon.filter then
				ns.UI.weapon.filter:Hide()
			end
			if ns.UI.weapon.shine then
				ns.UI.weapon.shine:Hide()
			end
			ns.UI.weapon:SetBackdropBorderColor(0.8, 0.65, 0.2, 0.4)
		end
	end
	if ns.UI.root then
		ns.UI.root:SetShown(ns.db.showRotation ~= false)
	end
	if ns.UI.defense then
		ns.UI.defense:SetShown(ns.db.showDefense ~= false)
	end
	if ns.UI.interrupt then
		ns.UI.interrupt:SetShown(ns.db.showInterrupt ~= false)
	end
	if ns.UI.purge then
		ns.UI.purge:SetShown(ns.db.showPurge ~= false)
	end
	if ns.UI.cleanse then
		ns.UI.cleanse:SetShown(ns.db.showCleanse ~= false)
	end
	if ns.UI.weapon then
		ns.UI.weapon:SetShown(ns.db.showWeapon ~= false)
	end
	ns.UI.RefreshRoles()
end
