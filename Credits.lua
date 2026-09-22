--[[
  Crédit commun Vohnka — wow-forever.fr
  /wftoc on|off
]]

WoWForeverSharedDB = WoWForeverSharedDB or {}

local CREDIT = {
	enUS = {
		LINE = "|cffd4a017%s|r — created by |cffffd100Vohnka|r | |cff66ccffhttps://wow-forever.fr|r",
		ON = "|cffd4a017WoW Forever|r — credit message: |cff66ff66ON|r",
		OFF = "|cffd4a017WoW Forever|r — credit message: |cffff6060OFF|r",
		STATE = "|cffd4a017WoW Forever|r — credit message: ",
		USAGE = "|cffaaaaaa/wftoc on|off|r",
	},
	frFR = {
		LINE = "|cffd4a017%s|r — créé par |cffffd100Vohnka|r | |cff66ccffhttps://wow-forever.fr|r",
		ON = "|cffd4a017WoW Forever|r — message de crédit : |cff66ff66ON|r",
		OFF = "|cffd4a017WoW Forever|r — message de crédit : |cffff6060OFF|r",
		STATE = "|cffd4a017WoW Forever|r — message de crédit : ",
		USAGE = "|cffaaaaaa/wftoc on|off|r",
	},
	deDE = {
		LINE = "|cffd4a017%s|r — erstellt von |cffffd100Vohnka|r | |cff66ccffhttps://wow-forever.fr|r",
		ON = "|cffd4a017WoW Forever|r — Credit-Nachricht: |cff66ff66AN|r",
		OFF = "|cffd4a017WoW Forever|r — Credit-Nachricht: |cffff6060AUS|r",
		STATE = "|cffd4a017WoW Forever|r — Credit-Nachricht: ",
		USAGE = "|cffaaaaaa/wftoc on|off|r",
	},
	esES = {
		LINE = "|cffd4a017%s|r — creado por |cffffd100Vohnka|r | |cff66ccffhttps://wow-forever.fr|r",
		ON = "|cffd4a017WoW Forever|r — mensaje de crédito: |cff66ff66ON|r",
		OFF = "|cffd4a017WoW Forever|r — mensaje de crédito: |cffff6060OFF|r",
		STATE = "|cffd4a017WoW Forever|r — mensaje de crédito: ",
		USAGE = "|cffaaaaaa/wftoc on|off|r",
	},
	ruRU = {
		LINE = "|cffd4a017%s|r — создано |cffffd100Vohnka|r | |cff66ccffhttps://wow-forever.fr|r",
		ON = "|cffd4a017WoW Forever|r — сообщение с кредитами: |cff66ff66ВКЛ|r",
		OFF = "|cffd4a017WoW Forever|r — сообщение с кредитами: |cffff6060ВЫКЛ|r",
		STATE = "|cffd4a017WoW Forever|r — сообщение с кредитами: ",
		USAGE = "|cffaaaaaa/wftoc on|off|r",
	},
	zhCN = {
		LINE = "|cffd4a017%s|r — 作者 |cffffd100Vohnka|r | |cff66ccffhttps://wow-forever.fr|r",
		ON = "|cffd4a017WoW Forever|r — 致谢信息：|cff66ff66开|r",
		OFF = "|cffd4a017WoW Forever|r — 致谢信息：|cffff6060关|r",
		STATE = "|cffd4a017WoW Forever|r — 致谢信息：",
		USAGE = "|cffaaaaaa/wftoc on|off|r",
	},
	zhTW = {
		LINE = "|cffd4a017%s|r — 作者 |cffffd100Vohnka|r | |cff66ccffhttps://wow-forever.fr|r",
		ON = "|cffd4a017WoW Forever|r — 致謝訊息：|cff66ff66開|r",
		OFF = "|cffd4a017WoW Forever|r — 致謝訊息：|cffff6060關|r",
		STATE = "|cffd4a017WoW Forever|r — 致謝訊息：",
		USAGE = "|cffaaaaaa/wftoc on|off|r",
	},
	ptBR = {
		LINE = "|cffd4a017%s|r — criado por |cffffd100Vohnka|r | |cff66ccffhttps://wow-forever.fr|r",
		ON = "|cffd4a017WoW Forever|r — mensagem de crédito: |cff66ff66ON|r",
		OFF = "|cffd4a017WoW Forever|r — mensagem de crédito: |cffff6060OFF|r",
		STATE = "|cffd4a017WoW Forever|r — mensagem de crédito: ",
		USAGE = "|cffaaaaaa/wftoc on|off|r",
	},
	itIT = {
		LINE = "|cffd4a017%s|r — creato da |cffffd100Vohnka|r | |cff66ccffhttps://wow-forever.fr|r",
		ON = "|cffd4a017WoW Forever|r — messaggio di credito: |cff66ff66ON|r",
		OFF = "|cffd4a017WoW Forever|r — messaggio di credito: |cffff6060OFF|r",
		STATE = "|cffd4a017WoW Forever|r — messaggio di credito: ",
		USAGE = "|cffaaaaaa/wftoc on|off|r",
	},
	koKR = {
		LINE = "|cffd4a017%s|r — 제작 |cffffd100Vohnka|r | |cff66ccffhttps://wow-forever.fr|r",
		ON = "|cffd4a017WoW Forever|r — 크레딧 메시지: |cff66ff66켜짐|r",
		OFF = "|cffd4a017WoW Forever|r — 크레딧 메시지: |cffff6060꺼짐|r",
		STATE = "|cffd4a017WoW Forever|r — 크레딧 메시지: ",
		USAGE = "|cffaaaaaa/wftoc on|off|r",
	},
}
CREDIT.esMX = CREDIT.esES

local function creditL()
	return CREDIT[GetLocale()] or CREDIT.enUS
end

local function db()
	WoWForeverSharedDB = WoWForeverSharedDB or {}
	if WoWForeverSharedDB.loginMessage == nil then
		WoWForeverSharedDB.loginMessage = true
	end
	return WoWForeverSharedDB
end

function WoWForever_ShouldPrintCredit()
	return db().loginMessage ~= false
end

function WoWForever_PrintCredit(title)
	if not WoWForever_ShouldPrintCredit() then
		return
	end
	print(creditL().LINE:format(tostring(title or "WoW Forever")))
end

if not SlashCmdList.WFTOC then
	SLASH_WFTOC1 = "/wftoc"
	SLASH_WFTOC2 = "/wfmsg"
	SlashCmdList.WFTOC = function(msg)
		msg = strtrim(strlower(msg or ""))
		local store = db()
		local t = creditL()
		if msg == "off" or msg == "0" then
			store.loginMessage = false
			print(t.OFF)
		elseif msg == "on" or msg == "1" then
			store.loginMessage = true
			print(t.ON)
		else
			print(t.STATE .. (store.loginMessage and "|cff66ff66ON|r" or "|cffff6060OFF|r"))
			print(t.USAGE)
		end
	end
end
