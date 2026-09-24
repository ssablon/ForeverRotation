local addonName, ns = ...

ns.CLASSES = {
	WARRIOR = 1,
	PALADIN = 2,
	HUNTER = 3,
	ROGUE = 4,
	PRIEST = 5,
	SHAMAN = 7,
	MAGE = 8,
	WARLOCK = 9,
	DRUID = 11,
}

-- Styles de jeu par classe. Druide hybrid = switch automatique caster / chat / ours.
ns.CLASS_ROLES = {
	WARRIOR = { "damage", "tank" },
	PALADIN = { "damage", "tank", "heal" },
	HUNTER = { "range", "melee" },
	ROGUE = { "damage" },
	PRIEST = { "damage", "heal" },
	SHAMAN = { "caster", "melee", "heal" },
	MAGE = { "damage" },
	WARLOCK = { "damage" },
	DRUID = { "hybrid", "heal", "tank" },
}

ns.COMBAT_MODES = { "auto", "single", "aoe", "burst" }

-- Couleurs officielles WoW, lues en dur (Forever peut cacher RAID_CLASS_COLORS).
ns.CLASS_COLORS = {
	WARRIOR = { 0.78, 0.61, 0.43 },
	PALADIN = { 0.96, 0.55, 0.73 },
	HUNTER = { 0.67, 0.83, 0.45 },
	ROGUE = { 1.00, 0.96, 0.41 },
	PRIEST = { 1.00, 1.00, 1.00 },
	SHAMAN = { 0.00, 0.44, 0.87 },
	MAGE = { 0.25, 0.78, 0.92 },
	WARLOCK = { 0.58, 0.51, 0.79 },
	DRUID = { 1.00, 0.49, 0.04 },
}

ns.CLASS_BY_ID = {
	[1] = "WARRIOR",
	[2] = "PALADIN",
	[3] = "HUNTER",
	[4] = "ROGUE",
	[5] = "PRIEST",
	[7] = "SHAMAN",
	[8] = "MAGE",
	[9] = "WARLOCK",
	[11] = "DRUID",
}

ns.CLASS_DAMAGE_ICON = {
	WARRIOR = "melee",
	PALADIN = "melee",
	HUNTER = "range",
	ROGUE = "melee",
	PRIEST = "caster",
	SHAMAN = "caster",
	MAGE = "caster",
	WARLOCK = "caster",
	DRUID = "caster",
}

ns.CLASS_SPELL = {
	WARRIOR = "Warrior",
	PALADIN = "Paladin",
	HUNTER = "Hunter",
	ROGUE = "Rogue",
	PRIEST = "Priest",
	SHAMAN = "Shaman",
	MAGE = "Mage",
	WARLOCK = "Warlock",
	DRUID = "Druid",
}

-- Raciaux Classic + Éolides. Air Walk (1259416) et passifs (Béni par le vent, Perspicacité) absents.
-- 95 = Éolide de l'Ordre suprême (Alliance) — ligne tellurique
-- 96 = Éolide sculpte-vents (Horde) — vue céleste
ns.RACIALS = {
	{ key = "Perception", id = 20600, races = { 1 }, opt = { combat = true } },
	{ key = "BloodFury", id = 20572, races = { 2 }, opt = { hostile = true }, on = true },
	{ key = "Stoneform", id = 20594, races = { 3 }, opt = { combat = true, hp = 70 }, defensive = true },
	{ key = "Shadowmeld", id = 20580, races = { 4 }, opt = { nobuff = true }, defensive = true },
	{ key = "WilloftheForsaken", id = 7744, races = { 5 }, defensive = true },
	{ key = "WarStomp", id = 20549, races = { 6 }, opt = { hostile = true } },
	{ key = "EscapeArtist", id = 20589, races = { 7 }, defensive = true },
	{ key = "Berserking", id = 20554, races = { 8 }, opt = { hostile = true }, on = true },
	{ key = "LeyLine", id = 1259705, races = { 95 }, factions = { "Alliance" }, opt = { hostile = true }, defensive = true },
	{ key = "SkyView", id = 1259686, races = { 96 }, factions = { "Horde" } },
}

ns.INTERRUPTS = {
	WARRIOR = 6552, -- Pummel
	ROGUE = 1766, -- Kick
	SHAMAN = 8042, -- Earth Shock (Era interrupt)
	MAGE = 2139, -- Counterspell
	PRIEST = 15487, -- Silence (talent)
}

ns.PURGES = {
	SHAMAN = 370, -- Purge
	PRIEST = 527, -- Dispel Magic
	MAGE = 30449, -- Spellsteal (may be absent)
}

-- Dispel perso : maladie / poison / malédiction / magie sur le joueur.
ns.CLEANSE = {
	PALADIN = {
		{ id = 4987, types = { "Magic", "Disease", "Poison" } }, -- Cleanse
		{ id = 1152, types = { "Disease", "Poison" } }, -- Purify
	},
	PRIEST = {
		{ id = 552, types = { "Disease" } }, -- Abolish Disease
		{ id = 528, types = { "Disease" } }, -- Cure Disease
		{ id = 527, types = { "Magic" } }, -- Dispel Magic (self)
	},
	SHAMAN = {
		{ id = 2870, types = { "Disease" } }, -- Cure Disease
		{ id = 526, types = { "Poison" } }, -- Cure Poison
	},
	DRUID = {
		{ id = 2893, types = { "Poison" } }, -- Abolish Poison
		{ id = 8946, types = { "Poison" } }, -- Cure Poison
		{ id = 2782, types = { "Curse" } }, -- Remove Curse
	},
	MAGE = {
		{ id = 475, types = { "Curse" } }, -- Remove Lesser Curse
	},
}

-- Enchantements d'arme Forever (lab 1.60.1) — durée 60 min, IDs = GetWeaponEnchantInfo 4e valeur.
ns.WEAPON_BUFFS = {
	SHAMAN = {
		{
			key = "Windfury",
			id = 8232,
			duration = 3600,
			ranks = { 8232, 8235, 10486, 16362, 439431, 461636 },
			enchants = { 283, 284, 525, 1669, 7569 },
			match = { "furie-des-vents", "windfury", "croc-croc", "croc croc" },
		},
		{
			key = "Flametongue",
			id = 8024,
			duration = 3600,
			ranks = { 8024, 8027, 8030, 16339, 16341, 16342, 461634 },
			enchants = { 3, 4, 5, 523, 1665, 1666, 7567 },
			match = { "langue de feu", "flametongue" },
		},
		{
			key = "Rockbiter",
			id = 8017,
			duration = 3600,
			ranks = { 8017, 8018, 8019, 10399, 16314, 16315, 16316, 461635 },
			enchants = { 1, 6, 29, 503, 504, 683, 1663, 1664, 7568 },
			match = { "croque-roc", "croque roc", "rockbiter" },
		},
		{
			key = "Frostbrand",
			id = 8033,
			duration = 3600,
			ranks = { 8033, 8038, 10456, 16355, 16356, 461633 },
			enchants = { 2, 12, 524, 1667, 1668, 7566 },
			match = { "arme de givre", "frostbrand" },
		},
	},
	ROGUE = {
		{ key = "InstantPoison", id = 8679, duration = 1800, enchants = { 323, 324, 325, 623, 624, 625 }, match = { "poison instantané", "instant poison" } },
		{ key = "DeadlyPoison", id = 2823, duration = 1800, enchants = { 7, 8, 626, 627, 2630 }, match = { "poison mortel", "deadly poison" } },
		{ key = "CripplingPoison", id = 3408, duration = 1800, enchants = { 22, 603 }, match = { "poison affaiblissant", "crippling" } },
		{ key = "WoundPoison", id = 13219, duration = 1800, enchants = { 703, 704, 705, 706 }, match = { "poison douloureux", "wound poison" } },
		{ key = "MindNumbingPoison", id = 5761, duration = 1800, enchants = { 23, 35, 643 }, match = { "distraction mentale", "mind-numbing", "mind numbing" } },
	},
	WARLOCK = {
		{ key = "Firestone", id = 6366, duration = 7200, enchants = { 1803, 1823, 1824, 1825 }, match = { "pierre de feu", "firestone" } },
		{ key = "Spellstone", id = 2362, duration = 7200, enchants = { 8059, 8060, 8061 }, match = { "pierre de sort", "spellstone" } },
	},
}

ns.WEAPON_BUFF_IDS = {}
ns.WEAPON_ENCHANT_IDS = {}
for _, list in pairs(ns.WEAPON_BUFFS) do
	for _, entry in ipairs(list) do
		ns.WEAPON_BUFF_IDS[entry.id] = entry
		if entry.ranks then
			for _, rankID in ipairs(entry.ranks) do
				ns.WEAPON_BUFF_IDS[rankID] = entry
			end
		end
		if entry.enchants then
			for _, enchID in ipairs(entry.enchants) do
				ns.WEAPON_ENCHANT_IDS[enchID] = entry
			end
		end
	end
end

-- IDs Forever / Classic Era (lab 1.60.1)
ns.Spell = {
	Druid = {
		Wrath = 5176,
		Moonfire = 8921,
		Starfire = 2912,
		FaerieFire = 770,
		InsectSwarm = 5570,
		Hurricane = 16914,
		MarkoftheWild = 1126,
		Thorns = 467,
		HealingTouch = 5185,
		Regrowth = 8936,
		Rejuvenation = 774,
		Barkskin = 22812,
		NaturesGrasp = 16689,
		BearForm = 5487,
		CatForm = 768,
		Maul = 6807,
		Swipe = 779,
		Claw = 1082,
		Rake = 1822,
		Rip = 1079,
		Shred = 5221,
		FerociousBite = 22568,
		Moonkin = 24858,
		TigersFury = 5217,
		NaturesSwiftness = 17116,
		Tranquility = 740,
		FaerieFireFeral = 16857,
		DemoralizingRoar = 99,
		Growl = 6795,
		Bash = 5211,
		Ravage = 6785,
		Prowl = 5215,
		Swiftmend = 18562,
		DireBear = 9634,
		Enrage = 5229,
		Innervate = 29166,
		FrenziedRegen = 22842,
		FeralCharge = 16979,
	},
	Paladin = {
		HolyLight = 635,
		FlashofLight = 19750,
		SealRighteousness = 20154,
		SealFury = 20163,
		SealCommand = 20375,
		SealCrusader = 21082,
		Judgement = 20271,
		BlessingMight = 19740,
		BlessingWisdom = 19742,
		BlessingKings = 20217,
		Consecration = 26573,
		HammerofJustice = 853,
		HammerofWrath = 24275,
		Exorcism = 879,
		DevotionAura = 465,
		RetributionAura = 7294,
		DivineProtection = 498,
		DivineShield = 642,
		LayonHands = 633,
		RighteousFury = 25780,
		HolyWrath = 2812,
		HolyShock = 20473,
		HolyShield = 20925,
		SealLight = 20165,
		SealWisdom = 20166,
		SealJustice = 20164,
		ConcentrationAura = 19746,
		SanctityAura = 20218,
		CrusaderStrike = 678,
		BlessingSalvation = 1038,
		BlessingLight = 19977,
		BlessingSanctuary = 20911,
		FireResistAura = 19891,
		FrostResistAura = 19888,
		ShadowResistAura = 19876,
	},
	Warrior = {
		HeroicStrike = 78,
		BattleShout = 6673,
		Charge = 100,
		Rend = 772,
		ThunderClap = 6343,
		Overpower = 7384,
		Execute = 5308,
		MortalStrike = 12294,
		Bloodthirst = 23881,
		Whirlwind = 1680,
		Hamstring = 1715,
		SunderArmor = 7386,
		Revenge = 6572,
		ShieldSlam = 23922,
		ShieldBlock = 2565,
		Taunt = 355,
		LastStand = 12975,
		ShieldWall = 871,
		Bloodrage = 2687,
		Pummel = 6552,
		Cleave = 845,
		Recklessness = 1719,
		SweepingStrikes = 12292,
		DeathWish = 12328,
		BerserkerRage = 18499,
		Intercept = 20252,
		Slam = 1464,
		DemoralizingShout = 1160,
		Retaliation = 20230,
		Disarm = 676,
		ShieldBash = 72,
		MockingBlow = 694,
		PiercingHowl = 12323,
	},
	Hunter = {
		RaptorStrike = 2973,
		SerpentSting = 1978,
		ArcaneShot = 3044,
		AimedShot = 19434,
		MultiShot = 2643,
		HuntersMark = 1130,
		AspectHawk = 13165,
		ConcussiveShot = 5116,
		MendPet = 136,
		CallPet = 883,
		WingClip = 2974,
		FeignDeath = 5384,
		Deterrence = 19263,
		AspectMonkey = 13163,
		RapidFire = 3045,
		Volley = 1510,
		BestialWrath = 19574,
		MongooseBite = 1495,
		Counterattack = 19306,
		Intimidation = 19577,
		ViperSting = 3034,
		ScorpidSting = 3043,
		AspectWild = 20043,
		AspectCheetah = 5118,
		AspectPack = 13159,
		AspectBeast = 13161,
		TrueshotAura = 19506,
		WyvernSting = 19386,
		Disengage = 781,
	},
	Rogue = {
		SinisterStrike = 1752,
		Eviscerate = 2098,
		Stealth = 1784,
		Backstab = 53,
		Gouge = 1776,
		Kick = 1766,
		SliceandDice = 5171,
		Garrote = 703,
		Ambush = 8676,
		Rupture = 1943,
		Evasion = 5277,
		Sprint = 2983,
		BladeFlurry = 13877,
		AdrenalineRush = 13750,
		ColdBlood = 14177,
		Hemorrhage = 16511,
		ExposeArmor = 8647,
		GhostlyStrike = 14278,
		Riposte = 14251,
		CheapShot = 1833,
		KidneyShot = 408,
		Vanish = 1856,
		Feint = 1966,
		Premeditation = 14183,
	},
	Priest = {
		Smite = 585,
		LesserHeal = 2050,
		ShadowWordPain = 589,
		PowerWordShield = 17,
		Renew = 139,
		MindBlast = 8092,
		InnerFire = 588,
		Heal = 2054,
		FlashHeal = 2061,
		HolyFire = 14914,
		PsychicScream = 8122,
		Fade = 586,
		WeakenedSoul = 6788,
		HolyNova = 15237,
		InnerFocus = 14751,
		PrayerofHealing = 596,
		MindFlay = 15407,
		GreaterHeal = 2060,
		Shadowform = 15473,
		VampiricEmbrace = 15286,
		DivineSpirit = 14752,
		PowerWordFortitude = 1243,
		PowerInfusion = 10060,
		DevouringPlague = 2944,
		ManaBurn = 8129,
		ShadowProtection = 976,
		Silence = 15487,
	},
	Shaman = {
		LightningBolt = 403,
		HealingWave = 331,
		Rockbiter = 8017,
		EarthShock = 8042,
		LightningShield = 324,
		FlameShock = 8050,
		SearingTotem = 3599,
		LesserHealingWave = 8004,
		FrostShock = 8056,
		ChainLightning = 421,
		Stormstrike = 17364,
		Purge = 370,
		Windfury = 8232,
		Flametongue = 8024,
		Frostbrand = 8033,
		Stoneclaw = 5730,
		GroundingTotem = 8177,
		FireNova = 1535,
		MagmaTotem = 8190,
		ElementalMastery = 16166,
		NaturesSwiftness = 16188,
		ChainHeal = 1064,
		StrengthofEarth = 8075,
		Stoneskin = 8071,
		HealingStream = 5394,
		ManaSpring = 5675,
		WindfuryTotem = 8512,
		GraceofAir = 8835,
		TremorTotem = 8143,
	},
	Mage = {
		Fireball = 133,
		FrostArmor = 168,
		ArcaneIntellect = 1459,
		Frostbolt = 116,
		FireBlast = 2136,
		ArcaneMissiles = 5143,
		FrostNova = 122,
		ArcaneExplosion = 1449,
		Counterspell = 2139,
		Blink = 1953,
		ConeofCold = 120,
		Pyroblast = 11366,
		Flamestrike = 2120,
		Scorch = 2948,
		IceArmor = 7302,
		MageArmor = 6117,
		Evocation = 12051,
		IceBlock = 11958,
		IceBarrier = 11426,
		Blizzard = 10,
		Combustion = 11129,
		PresenceofMind = 12043,
		ArcanePower = 12042,
		BlastWave = 11113,
		ManaShield = 1463,
		FireWard = 543,
		FrostWard = 6143,
		AmplifyMagic = 1008,
		DampenMagic = 604,
	},
	Warlock = {
		ShadowBolt = 686,
		Immolate = 348,
		DemonSkin = 687,
		SummonImp = 688,
		Corruption = 172,
		LifeTap = 1454,
		CurseofAgony = 980,
		SummonVoidwalker = 697,
		DrainLife = 689,
		Fear = 5782,
		SearingPain = 5676,
		RainofFire = 5740,
		Shadowburn = 17877,
		Conflagrate = 17962,
		DeathCoil = 6789,
		Hellfire = 1949,
		DemonArmor = 706,
		SoulFire = 6353,
		SiphonLife = 18265,
		DrainSoul = 1120,
		CurseofElements = 1490,
		CurseofShadow = 17862,
		HowlofTerror = 5484,
		SummonSuccubus = 712,
		SummonFelhunter = 691,
		ShadowWard = 6229,
		UnendingBreath = 5697,
		DetectInvisibility = 132,
	},
}

-- Buffs > 1 min, 60 min, permanents / auras : Défense uniquement, jamais la file de combat.
ns.MAINTENANCE_BUFF_IDS = {}
do
	local P, D, Pr, M, L, Sh, H, W = ns.Spell.Paladin, ns.Spell.Druid, ns.Spell.Priest, ns.Spell.Mage, ns.Spell.Warlock, ns.Spell.Shaman, ns.Spell.Hunter, ns.Spell.Warrior
	local ids = {
		P.BlessingMight, P.BlessingWisdom, P.BlessingKings, P.BlessingSalvation, P.BlessingLight, P.BlessingSanctuary,
		P.DevotionAura, P.RetributionAura, P.ConcentrationAura, P.SanctityAura,
		P.FireResistAura, P.FrostResistAura, P.ShadowResistAura,
		P.RighteousFury,
		D.MarkoftheWild, D.Thorns, D.Moonkin,
		Pr.InnerFire, Pr.PowerWordFortitude, Pr.DivineSpirit, Pr.ShadowProtection, Pr.Shadowform, Pr.VampiricEmbrace,
		M.ArcaneIntellect, M.FrostArmor, M.IceArmor, M.MageArmor, M.AmplifyMagic, M.DampenMagic,
		L.DemonArmor, L.DemonSkin, L.UnendingBreath, L.DetectInvisibility,
		Sh.LightningShield,
		H.AspectHawk, H.AspectMonkey, H.AspectWild, H.AspectCheetah, H.AspectPack, H.AspectBeast, H.TrueshotAura,
		W.BattleShout,
		25782, 25894, 25898, 25899, 25890, 21562, 21849, 23028, 27681, 27683,
	}
	for _, id in ipairs(ids) do
		if id then
			ns.MAINTENANCE_BUFF_IDS[id] = true
		end
	end
end

-- Soins / HoT : jamais bloqués par une cible hostile (self-cast / retarget).
ns.HEAL_SPELL_IDS = {}
do
	local P, D, Pr, Sh, H = ns.Spell.Paladin, ns.Spell.Druid, ns.Spell.Priest, ns.Spell.Shaman, ns.Spell.Hunter
	local ids = {
		P.HolyLight, P.FlashofLight, P.LayonHands,
		D.HealingTouch, D.Regrowth, D.Rejuvenation, D.Swiftmend, D.Tranquility,
		Pr.FlashHeal, Pr.GreaterHeal, Pr.Heal, Pr.LesserHeal, Pr.Renew, Pr.PrayerofHealing, Pr.PowerWordShield,
		Sh.HealingWave, Sh.LesserHealingWave, Sh.ChainHeal, Sh.HealingStream,
		H.MendPet,
		639, 647, 1026, 1042, 3472, 10328, 10329,
		19939, 19940, 19941, 19942, 19943,
		19968, 19980, 19981, 2800, 10310,
		9472, 9473, 9474, 10915, 10916, 10917,
		10963, 10964, 10965, 2052, 2053, 2055, 6063, 6064,
		332, 547, 913, 939, 959, 8005, 10395, 10396,
		8008, 8010, 10466, 10467, 10468,
		5186, 5187, 5188, 5189, 6778, 8903, 9758, 9888, 9889,
	}
	for _, id in ipairs(ids) do
		if id then
			ns.HEAL_SPELL_IDS[id] = true
		end
	end
end

-- Secours si GetSpellBaseCooldown ne renvoie rien. Le client prime dès qu'il répond.
-- Valeurs Classic Era (secondes). Les horions partagent un seul temps de recharge.
do
	local P = ns.Spell.Paladin
	local W = ns.Spell.Warrior
	local H = ns.Spell.Hunter
	local R = ns.Spell.Rogue
	local Pr = ns.Spell.Priest
	local Sh = ns.Spell.Shaman
	local M = ns.Spell.Mage
	local L = ns.Spell.Warlock
	local D = ns.Spell.Druid
	ns.COOLDOWNS = {
		[P.Judgement] = 8,
		[P.HammerofJustice] = 60,
		[P.HammerofWrath] = 6,
		[P.Exorcism] = 15,
		[P.Consecration] = 8,
		[P.HolyShock] = 15,
		[P.HolyWrath] = 60,
		[P.CrusaderStrike] = 6,
		[P.LayonHands] = 3600,
		[P.DivineShield] = 300,
		[P.DivineProtection] = 300,
		[W.MortalStrike] = 6,
		[W.Bloodthirst] = 6,
		[W.Whirlwind] = 10,
		[W.Revenge] = 5,
		[W.ShieldSlam] = 6,
		[W.ThunderClap] = 4,
		[W.ShieldBlock] = 5,
		[W.Pummel] = 10,
		[W.ShieldBash] = 12,
		[W.Intercept] = 30,
		[W.Bloodrage] = 60,
		[W.BerserkerRage] = 30,
		[W.SweepingStrikes] = 30,
		[W.DeathWish] = 180,
		[W.Taunt] = 10,
		[W.MockingBlow] = 120,
		[W.Disarm] = 60,
		[W.Retaliation] = 1800,
		[W.Recklessness] = 1800,
		[W.ShieldWall] = 1800,
		[W.LastStand] = 480,
		[H.AimedShot] = 6,
		[H.MultiShot] = 10,
		[H.ArcaneShot] = 6,
		[H.ConcussiveShot] = 12,
		[H.Counterattack] = 5,
		[H.Intimidation] = 60,
		[H.FeignDeath] = 30,
		[H.RapidFire] = 300,
		[H.BestialWrath] = 120,
		[H.Deterrence] = 300,
		[H.WyvernSting] = 120,
		[R.Kick] = 10,
		[R.Gouge] = 10,
		[R.Riposte] = 6,
		[R.GhostlyStrike] = 20,
		[R.BladeFlurry] = 120,
		[R.AdrenalineRush] = 300,
		[R.Evasion] = 300,
		[R.Sprint] = 300,
		[R.Vanish] = 300,
		[Pr.MindBlast] = 8,
		[Pr.PsychicScream] = 30,
		[Pr.Fade] = 30,
		[Pr.Silence] = 45,
		[Pr.InnerFocus] = 180,
		[Pr.PowerInfusion] = 180,
		[Sh.EarthShock] = 6,
		[Sh.FlameShock] = 6,
		[Sh.FrostShock] = 6,
		[Sh.ChainLightning] = 6,
		[Sh.Stormstrike] = 20,
		[Sh.ElementalMastery] = 180,
		[Sh.NaturesSwiftness] = 180,
		[M.FireBlast] = 8,
		[M.ConeofCold] = 10,
		[M.BlastWave] = 30,
		[M.FrostNova] = 25,
		[M.Counterspell] = 30,
		[M.Blink] = 15,
		[M.Combustion] = 180,
		[M.PresenceofMind] = 180,
		[M.ArcanePower] = 180,
		[M.Evocation] = 480,
		[M.IceBlock] = 300,
		[L.Conflagrate] = 10,
		[L.Shadowburn] = 15,
		[L.DeathCoil] = 120,
		[L.HowlofTerror] = 40,
		[D.Swiftmend] = 15,
		[D.Bash] = 60,
		[D.Barkskin] = 60,
		[D.FeralCharge] = 15,
		[D.Enrage] = 60,
		[D.FrenziedRegen] = 180,
		[D.NaturesSwiftness] = 180,
		[D.Innervate] = 360,
		[D.Tranquility] = 300,
	}
	ns.COOLDOWN_GROUPS = {
		{ seconds = 6, ids = { Sh.EarthShock, Sh.FlameShock, Sh.FrostShock } },
	}
end
