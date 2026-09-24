local addonName, ns = ...

local function esc(value)
	return tostring(value or ""):gsub("[,:=|\r\n]", "_")
end

local function packSteps(rows)
	local parts = {}
	if type(rows) ~= "table" then
		return ""
	end
	for _, row in ipairs(rows) do
		if type(row) == "table" and row.key then
			local chunk = esc(row.key) .. ":" .. (row.on == 0 and "0" or "1")
			if row.custom and row.id then
				chunk = chunk .. ":" .. tostring(row.id)
			end
			parts[#parts + 1] = chunk
		end
	end
	return table.concat(parts, ",")
end

local function packDrops(map)
	local parts = {}
	if type(map) ~= "table" then
		return ""
	end
	for key, yes in pairs(map) do
		if yes and type(key) == "string" then
			parts[#parts + 1] = esc(key)
		end
	end
	table.sort(parts)
	return table.concat(parts, ",")
end

local function writeApl(lines, prefix, root)
	if type(root) ~= "table" then
		return
	end
	for class, specs in pairs(root) do
		if type(class) == "string" and type(specs) == "table" then
			for spec, bucket in pairs(specs) do
				if type(spec) == "string" and type(bucket) == "table" then
					if bucket[1] and type(bucket[1]) == "table" and bucket[1].key then
						lines[#lines + 1] = prefix .. class .. "." .. spec .. ".single=" .. packSteps(bucket)
					else
						for mode, rows in pairs(bucket) do
							if type(mode) == "string" and type(rows) == "table" then
								if mode == "auto" or mode == "single" or mode == "aoe" or mode == "burst" then
									lines[#lines + 1] = prefix .. class .. "." .. spec .. "." .. mode .. "=" .. packSteps(rows)
								end
							end
						end
					end
				end
			end
		end
	end
end

local function writeDrops(lines, prefix, root, isDef)
	if type(root) ~= "table" then
		return
	end
	for class, specs in pairs(root) do
		if type(class) == "string" and type(specs) == "table" then
			for spec, bucket in pairs(specs) do
				if type(spec) == "string" and type(bucket) == "table" then
					if isDef then
						local packed = packDrops(bucket)
						if packed ~= "" then
							lines[#lines + 1] = prefix .. class .. "." .. spec .. "=" .. packed
						end
					else
						for mode, map in pairs(bucket) do
							if type(mode) == "string" and type(map) == "table" then
								local packed = packDrops(map)
								if packed ~= "" then
									lines[#lines + 1] = prefix .. class .. "." .. spec .. "." .. mode .. "=" .. packed
								end
							end
						end
					end
				end
			end
		end
	end
end

function ns.ExportProfile()
	if ns.FlushProfile then
		ns.FlushProfile()
	end
	local lines = {
		"WFR1",
		"C=" .. esc((ns.ClassToken and ns.ClassToken()) or ""),
		"P=" .. esc(ns.ProfileKey and ns.ProfileKey() or "pve"),
		"R=" .. esc(ns.db.role or "damage"),
		"M=" .. esc(ns.db.combatMode or "auto"),
		"L=" .. esc(ns.db.lastManualMode or "single"),
		"A=" .. tostring(tonumber(ns.db.autoEnemies) or 3),
		"W=" .. esc(ns.db.weaponBuff or ""),
	}
	writeApl(lines, "APL:", ns.db.apl)
	if type(ns.db.def) == "table" then
		for class, specs in pairs(ns.db.def) do
			if type(class) == "string" and type(specs) == "table" then
				for spec, rows in pairs(specs) do
					if type(spec) == "string" and type(rows) == "table" and rows[1] and rows[1].key then
						lines[#lines + 1] = "DEF:" .. class .. "." .. spec .. "=" .. packSteps(rows)
					end
				end
			end
		end
	end
	writeDrops(lines, "DRP:", ns.db.aplDrop, false)
	writeDrops(lines, "DDR:", ns.db.defDrop, true)
	return table.concat(lines, "\n")
end

local function parseSteps(text)
	local rows = {}
	if type(text) ~= "string" or text == "" then
		return rows
	end
	for chunk in string.gmatch(text, "[^,]+") do
		local key, on, id = string.match(chunk, "^([%w_]+):([01]):?(%d*)$")
		if key then
			local row = { key = key, on = on == "1" and 1 or 0 }
			if id and id ~= "" then
				row.id = tonumber(id)
				row.custom = true
			end
			rows[#rows + 1] = row
		end
	end
	return rows
end

local function parseDrops(text)
	local map = {}
	if type(text) ~= "string" or text == "" then
		return map
	end
	for key in string.gmatch(text, "[^,]+") do
		if key:match("^[%w_]+$") then
			map[key] = true
		end
	end
	return map
end

local function putNested(root, class, spec, mode, value)
	root[class] = root[class] or {}
	root[class][spec] = root[class][spec] or {}
	if mode then
		root[class][spec][mode] = value
	else
		root[class][spec] = value
	end
end

function ns.ImportProfile(text)
	if type(text) ~= "string" then
		return false, "OPT_IMPORT_BAD"
	end
	text = text:gsub("\r\n", "\n"):gsub("\r", "\n")
	local first = text:match("^%s*([^\n]+)")
	if first ~= "WFR1" then
		return false, "OPT_IMPORT_BAD"
	end
	local meta = { C = "", P = "", R = "damage", M = "auto", L = "single", A = "3", W = "" }
	local apl, def, drop, defDrop = {}, {}, {}, {}
	for line in string.gmatch(text, "[^\n]+") do
		local key, value = string.match(line, "^([CPRMLAW])=(.*)$")
		if key then
			meta[key] = value or ""
		else
			local kind, path, payload = string.match(line, "^(APL|DEF|DRP|DDR):([%w_%.]+)=(.*)$")
			if kind then
				local class, spec, mode = string.match(path, "^([%w_]+)%.([%w_]+)%.([%w_]+)$")
				if not class then
					class, spec = string.match(path, "^([%w_]+)%.([%w_]+)$")
				end
				if class and spec then
					if kind == "APL" and (mode == "auto" or mode == "single" or mode == "aoe" or mode == "burst") then
						putNested(apl, class, spec, mode, parseSteps(payload))
					elseif kind == "DEF" then
						if mode and (mode == "auto" or mode == "single" or mode == "aoe" or mode == "burst") then
							putNested(def, class, spec, mode, parseSteps(payload))
						else
							putNested(def, class, spec, nil, parseSteps(payload))
						end
					elseif kind == "DRP" and mode then
						putNested(drop, class, spec, mode, parseDrops(payload))
					elseif kind == "DDR" then
						putNested(defDrop, class, spec, nil, parseDrops(payload))
					end
				end
			end
		end
	end
	local mine = ns.ClassToken and ns.ClassToken() or ""
	if meta.C ~= "" and mine ~= "" and meta.C ~= mine then
		return false, "OPT_IMPORT_CLASS", meta.C
	end
	ns.db.apl = apl
	ns.db.def = def
	ns.db.aplDrop = drop
	ns.db.defDrop = defDrop
	if meta.R ~= "" then
		ns.db.role = ns.NormalizeRole and ns.NormalizeRole(meta.R) or meta.R
	end
	if meta.M == "auto" or meta.M == "single" or meta.M == "aoe" or meta.M == "burst" then
		ns.db.combatMode = meta.M
	end
	if meta.L == "single" or meta.L == "aoe" or meta.L == "burst" then
		ns.db.lastManualMode = meta.L
	end
	ns.db.autoEnemies = tonumber(meta.A) or 3
	if ns.db.autoEnemies < 2 then
		ns.db.autoEnemies = 2
	end
	if ns.db.autoEnemies > 8 then
		ns.db.autoEnemies = 8
	end
	ns.db.weaponBuff = meta.W ~= "" and meta.W or nil
	if ns.FlushProfile then
		ns.FlushProfile()
	end
	if ns.InvalidateAPLCache then
		ns.InvalidateAPLCache()
	end
	if ns.UI and ns.UI.RefreshRoles then
		ns.UI.RefreshRoles()
	end
	if ns.UI and ns.UI.RefreshModes then
		ns.UI.RefreshModes()
	end
	if ns.Tick then
		ns.Tick()
	end
	return true, "OPT_IMPORT_OK"
end
