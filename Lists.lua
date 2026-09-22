local addonName, ns = ...
local S = ns.Spell
local D, P, W, H, R, Pr, Sh, M, L = S.Druid, S.Paladin, S.Warrior, S.Hunter, S.Rogue, S.Priest, S.Shaman, S.Mage, S.Warlock

local function step(key, id, opt)
	return { key = key, id = id, opt = opt or {}, on = true }
end

local mageArmors = { M.MageArmor, M.IceArmor, M.FrostArmor }
local lockSkins = { L.DemonArmor, L.DemonSkin }
local palaSeals = { P.SealCommand, P.SealFury, P.SealRighteousness, P.SealCrusader, P.SealLight, P.SealWisdom, P.SealJustice }
local palaAuras = {
	P.DevotionAura,
	P.RetributionAura,
	P.ConcentrationAura,
	P.SanctityAura,
	P.FireResistAura,
	P.FrostResistAura,
	P.ShadowResistAura,
}
local palaBlessings = {
	P.BlessingMight,
	P.BlessingKings,
	P.BlessingWisdom,
	P.BlessingSalvation,
	P.BlessingLight,
	P.BlessingSanctuary,
}
local hunterAspects = { H.AspectHawk, H.AspectMonkey, H.AspectWild, H.AspectCheetah, H.AspectPack, H.AspectBeast }

-- Noyau combat Era (ConROC Classic), 1–60. Auto = liste mono. Pas de SoD / Midnight.
ns.APLDefaults = {
	DRUID = {
		damage = {
			step("FaerieFire", D.FaerieFire, { nodebuff = true, hostile = true }),
			step("Moonfire", D.Moonfire, { nodebuff = true, hostile = true }),
			step("InsectSwarm", D.InsectSwarm, { nodebuff = true, hostile = true }),
			step("Starfire", D.Starfire, { hostile = true }),
			step("Wrath", D.Wrath, { filler = true }),
			step("Rejuvenation", D.Rejuvenation, { hp = 90,  nobuff = true, heal = true }),
			step("HealingTouch", D.HealingTouch, { hp = 80,  heal = true }),
		},
		heal = {
			step("Swiftmend", D.Swiftmend, { hp = 60,  heal = true }),
			step("Regrowth", D.Regrowth, { hp = 70,  heal = true }),
			step("Rejuvenation", D.Rejuvenation, { hp = 90,  nobuff = true, heal = true }),
			step("HealingTouch", D.HealingTouch, { hp = 80,  heal = true }),
			step("Innervate", D.Innervate, { combat = true }),
			step("Moonfire", D.Moonfire, { nodebuff = true, hostile = true }),
			step("Wrath", D.Wrath, { filler = true }),
		},
		tank = {
			step("DemoralizingRoar", D.DemoralizingRoar, { nodebuff = true, hostile = true }),
			step("FaerieFireFeral", D.FaerieFireFeral, { nodebuff = true, hostile = true }),
			step("Swipe", D.Swipe, { hostile = true }),
			step("Maul", D.Maul, { filler = true }),
		},
		cat = {
			step("Prowl", D.Prowl, { nobuff = true }),
			step("TigersFury", D.TigersFury, { nobuff = true }),
			step("FaerieFireFeral", D.FaerieFireFeral, { nodebuff = true, hostile = true }),
			step("Rip", D.Rip, { comboMin = 5, nodebuff = true, hostile = true }),
			step("FerociousBite", D.FerociousBite, { comboMin = 5, hostile = true }),
			step("Rake", D.Rake, { nodebuff = true, hostile = true }),
			step("Ravage", D.Ravage, { hostile = true }),
			step("Shred", D.Shred, { hostile = true }),
			step("Claw", D.Claw, { filler = true }),
		},
		bear = {
			step("DemoralizingRoar", D.DemoralizingRoar, { nodebuff = true, hostile = true }),
			step("FaerieFireFeral", D.FaerieFireFeral, { nodebuff = true, hostile = true }),
			step("Swipe", D.Swipe, { hostile = true }),
			step("Maul", D.Maul, { filler = true }),
		},
	},
	PALADIN = {
		damage = {
			step("SealCommand", P.SealCommand, { nobuff = true, anybuff = palaSeals }),
			step("SealFury", P.SealFury, { nobuff = true, anybuff = palaSeals }),
			step("SealRighteousness", P.SealRighteousness, { nobuff = true, anybuff = palaSeals }),
			step("SealCrusader", P.SealCrusader, { nobuff = true, anybuff = palaSeals }),
			step("HammerofWrath", P.HammerofWrath, { hp = 20, unit = "target", hostile = true }),
			step("Judgement", P.Judgement, { hostile = true }),
			step("CrusaderStrike", P.CrusaderStrike, { hostile = true }),
			step("HolyShock", P.HolyShock, { hostile = true }),
			step("Consecration", P.Consecration, { hostile = true }),
			step("Exorcism", P.Exorcism, { hostile = true }),
			step("FlashofLight", P.FlashofLight, { hp = 70,  heal = true }),
			step("HolyLight", P.HolyLight, { hp = 80,  heal = true }),
		},
		tank = {
			step("SealFury", P.SealFury, { nobuff = true, anybuff = palaSeals }),
			step("SealRighteousness", P.SealRighteousness, { nobuff = true, anybuff = palaSeals }),
			step("HolyShield", P.HolyShield, { combat = true, hostile = true }),
			step("CrusaderStrike", P.CrusaderStrike, { hostile = true }),
			step("Judgement", P.Judgement, { hostile = true }),
			step("Consecration", P.Consecration, { hostile = true }),
			step("HammerofJustice", P.HammerofJustice, { hostile = true }),
			step("HolyShock", P.HolyShock, { hostile = true }),
			step("FlashofLight", P.FlashofLight, { hp = 70,  heal = true }),
			step("HolyLight", P.HolyLight, { hp = 80,  heal = true }),
		},
		heal = {
			step("SealLight", P.SealLight, { nobuff = true, anybuff = palaSeals }),
			step("SealWisdom", P.SealWisdom, { nobuff = true, anybuff = palaSeals }),
			step("HolyShock", P.HolyShock, { hp = 80,  heal = true }),
			step("FlashofLight", P.FlashofLight, { hp = 70,  heal = true }),
			step("HolyLight", P.HolyLight, { hp = 80,  heal = true }),
			step("Judgement", P.Judgement, { hostile = true }),
		},
	},
	WARRIOR = {
		damage = {
			step("Charge", W.Charge, { hostile = true }),
			step("Bloodrage", W.Bloodrage, { hostile = true }),
			step("BerserkerRage", W.BerserkerRage, { combat = true }),
			step("Execute", W.Execute, { hp = 20, unit = "target", hostile = true }),
			step("Overpower", W.Overpower, { hostile = true }),
			step("MortalStrike", W.MortalStrike, { hostile = true }),
			step("Bloodthirst", W.Bloodthirst, { hostile = true }),
			step("Whirlwind", W.Whirlwind, { hostile = true }),
			step("Slam", W.Slam, { hostile = true }),
			step("Rend", W.Rend, { nodebuff = true, hostile = true }),
			step("Hamstring", W.Hamstring, { nodebuff = true, hostile = true }),
			step("HeroicStrike", W.HeroicStrike, { filler = true }),
		},
		tank = {
			step("DemoralizingShout", W.DemoralizingShout, { nodebuff = true, hostile = true }),
			step("Revenge", W.Revenge, { hostile = true }),
			step("ShieldSlam", W.ShieldSlam, { hostile = true }),
			step("SunderArmor", W.SunderArmor, { hostile = true }),
			step("ThunderClap", W.ThunderClap, { nodebuff = true, hostile = true }),
			step("ShieldBlock", W.ShieldBlock, { combat = true, hp = 80 }),
			step("HeroicStrike", W.HeroicStrike, { filler = true }),
		},
	},
	HUNTER = {
		range = {
			step("CallPet", H.CallPet, { nopet = true }),
			step("MendPet", H.MendPet, { pet = true, hp = 40, unit = "pet" }),
			step("HuntersMark", H.HuntersMark, { nodebuff = true, hostile = true }),
			step("SerpentSting", H.SerpentSting, { nodebuff = true, hostile = true }),
			step("Intimidation", H.Intimidation, { hostile = true }),
			step("AimedShot", H.AimedShot, { hostile = true }),
			step("MultiShot", H.MultiShot, { hostile = true }),
			step("ArcaneShot", H.ArcaneShot, { hostile = true }),
			step("ConcussiveShot", H.ConcussiveShot, { hostile = true }),
			step("ViperSting", H.ViperSting, { hostile = true }),
			step("ScorpidSting", H.ScorpidSting, { nodebuff = true, hostile = true }),
		},
		melee = {
			step("CallPet", H.CallPet, { nopet = true }),
			step("HuntersMark", H.HuntersMark, { nodebuff = true, hostile = true }),
			step("Counterattack", H.Counterattack, { hostile = true }),
			step("MongooseBite", H.MongooseBite, { hostile = true }),
			step("WingClip", H.WingClip, { nodebuff = true, hostile = true }),
			step("RaptorStrike", H.RaptorStrike, { filler = true }),
		},
	},
	ROGUE = {
		damage = {
			step("Stealth", R.Stealth, { nobuff = true }),
			step("SliceandDice", R.SliceandDice, { comboMin = 5, nobuff = true, hostile = true }),
			step("Rupture", R.Rupture, { comboMin = 5, nodebuff = true, hostile = true }),
			step("Eviscerate", R.Eviscerate, { comboMin = 5, hostile = true }),
			step("ExposeArmor", R.ExposeArmor, { comboMin = 5, hostile = true }),
			step("Hemorrhage", R.Hemorrhage, { hostile = true }),
			step("GhostlyStrike", R.GhostlyStrike, { hostile = true }),
			step("Riposte", R.Riposte, { hostile = true }),
			step("Garrote", R.Garrote, { hostile = true }),
			step("Ambush", R.Ambush, { hostile = true }),
			step("Backstab", R.Backstab, { hostile = true }),
			step("SinisterStrike", R.SinisterStrike, { filler = true }),
		},
	},
	PRIEST = {
		damage = {
			step("ShadowWordPain", Pr.ShadowWordPain, { nodebuff = true, hostile = true }),
			step("DevouringPlague", Pr.DevouringPlague, { nodebuff = true, hostile = true }),
			step("MindFlay", Pr.MindFlay, { hostile = true }),
			step("MindBlast", Pr.MindBlast, { hostile = true }),
			step("HolyFire", Pr.HolyFire, { nodebuff = true, hostile = true }),
			step("Smite", Pr.Smite, { filler = true }),
			step("FlashHeal", Pr.FlashHeal, { hp = 70,  heal = true }),
			step("Heal", Pr.Heal, { hp = 80,  heal = true }),
		},
		heal = {
			step("PowerWordShield", Pr.PowerWordShield, { hp = 90,  nobuff = true, heal = true }),
			step("FlashHeal", Pr.FlashHeal, { hp = 70,  heal = true }),
			step("GreaterHeal", Pr.GreaterHeal, { hp = 55,  heal = true }),
			step("Heal", Pr.Heal, { hp = 80,  heal = true }),
			step("Renew", Pr.Renew, { hp = 90,  nobuff = true, heal = true }),
			step("PrayerofHealing", Pr.PrayerofHealing, { hp = 75,  heal = true }),
			step("LesserHeal", Pr.LesserHeal, { hp = 85,  heal = true }),
			step("Smite", Pr.Smite, { filler = true }),
		},
	},
	SHAMAN = {
		caster = {
			step("SearingTotem", Sh.SearingTotem, { hostile = true }),
			step("FlameShock", Sh.FlameShock, { nodebuff = true, hostile = true }),
			step("FrostShock", Sh.FrostShock, { hostile = true }),
			step("EarthShock", Sh.EarthShock, { hostile = true }),
			step("ChainLightning", Sh.ChainLightning, { hostile = true }),
			step("LightningBolt", Sh.LightningBolt, { filler = true }),
			step("LesserHealingWave", Sh.LesserHealingWave, { hp = 70,  heal = true }),
			step("HealingWave", Sh.HealingWave, { hp = 80,  heal = true }),
		},
		melee = {
			step("StrengthofEarth", Sh.StrengthofEarth, { hostile = true }),
			step("Stormstrike", Sh.Stormstrike, { hostile = true }),
			step("FlameShock", Sh.FlameShock, { nodebuff = true, hostile = true }),
			step("FrostShock", Sh.FrostShock, { hostile = true }),
			step("EarthShock", Sh.EarthShock, { hostile = true }),
			step("LightningBolt", Sh.LightningBolt, { filler = true }),
			step("LesserHealingWave", Sh.LesserHealingWave, { hp = 70,  heal = true }),
			step("HealingWave", Sh.HealingWave, { hp = 80,  heal = true }),
		},
		heal = {
			step("HealingStream", Sh.HealingStream),
			step("ManaSpring", Sh.ManaSpring),
			step("LesserHealingWave", Sh.LesserHealingWave, { hp = 70,  heal = true }),
			step("ChainHeal", Sh.ChainHeal, { hp = 75,  heal = true }),
			step("HealingWave", Sh.HealingWave, { hp = 80,  heal = true }),
			step("FlameShock", Sh.FlameShock, { nodebuff = true, hostile = true }),
			step("LightningBolt", Sh.LightningBolt, { filler = true }),
		},
	},
	MAGE = {
		damage = {
			step("Pyroblast", M.Pyroblast, { hostile = true }),
			step("FireBlast", M.FireBlast, { hostile = true }),
			step("Scorch", M.Scorch, { hostile = true }),
			step("Frostbolt", M.Frostbolt, { hostile = true }),
			step("Fireball", M.Fireball, { filler = true }),
			step("ArcaneMissiles", M.ArcaneMissiles, { hostile = true }),
		},
	},
	WARLOCK = {
		damage = {
			step("SummonFelhunter", L.SummonFelhunter, { nopet = true }),
			step("SummonVoidwalker", L.SummonVoidwalker, { nopet = true }),
			step("SummonSuccubus", L.SummonSuccubus, { nopet = true }),
			step("SummonImp", L.SummonImp, { nopet = true }),
			step("LifeTap", L.LifeTap, { hp = 80 }),
			step("CurseofElements", L.CurseofElements, { nodebuff = true, hostile = true }),
			step("CurseofAgony", L.CurseofAgony, { nodebuff = true, hostile = true }),
			step("Corruption", L.Corruption, { nodebuff = true, hostile = true }),
			step("SiphonLife", L.SiphonLife, { nodebuff = true, hostile = true }),
			step("Immolate", L.Immolate, { nodebuff = true, hostile = true }),
			step("Conflagrate", L.Conflagrate, { hostile = true }),
			step("Shadowburn", L.Shadowburn, { hostile = true }),
			step("SoulFire", L.SoulFire, { hostile = true }),
			step("SearingPain", L.SearingPain, { hostile = true }),
			step("DrainLife", L.DrainLife, { hostile = true, hp = 40 }),
			step("ShadowBolt", L.ShadowBolt, { filler = true }),
		},
	},
}

ns.APLModes = {
	DRUID = {
		damage = {
			aoe = {
				step("Hurricane", D.Hurricane, { hostile = true }),
				step("Moonfire", D.Moonfire, { nodebuff = true, hostile = true }),
				step("FaerieFire", D.FaerieFire, { nodebuff = true, hostile = true }),
				step("Starfire", D.Starfire, { hostile = true }),
				step("Wrath", D.Wrath, { filler = true }),
				step("HealingTouch", D.HealingTouch, { hp = 80,  heal = true }),
			},
			burst = {
				step("NaturesSwiftness", D.NaturesSwiftness, { hostile = true }),
				step("Starfire", D.Starfire, { hostile = true }),
				step("Moonfire", D.Moonfire, { nodebuff = true, hostile = true }),
				step("InsectSwarm", D.InsectSwarm, { nodebuff = true, hostile = true }),
				step("Wrath", D.Wrath, { filler = true }),
				step("HealingTouch", D.HealingTouch, { hp = 80,  heal = true }),
			},
		},
		heal = {
			aoe = {
				step("Tranquility", D.Tranquility, { hp = 70,  heal = true }),
				step("Hurricane", D.Hurricane, { hostile = true }),
				step("Rejuvenation", D.Rejuvenation, { hp = 90,  nobuff = true, heal = true }),
				step("Regrowth", D.Regrowth, { hp = 70,  heal = true }),
				step("HealingTouch", D.HealingTouch, { hp = 80,  heal = true }),
			},
			burst = {
				step("NaturesSwiftness", D.NaturesSwiftness),
				step("Swiftmend", D.Swiftmend, { hp = 60,  heal = true }),
				step("HealingTouch", D.HealingTouch, { hp = 80,  heal = true }),
				step("Regrowth", D.Regrowth, { hp = 70,  heal = true }),
				step("Innervate", D.Innervate, { combat = true }),
			},
		},
		tank = {
			aoe = {
				step("DemoralizingRoar", D.DemoralizingRoar, { nodebuff = true, hostile = true }),
				step("Swipe", D.Swipe, { hostile = true }),
				step("Maul", D.Maul, { filler = true }),
			},
			burst = {
				step("Enrage", D.Enrage, { combat = true }),
				step("Swipe", D.Swipe, { hostile = true }),
				step("Maul", D.Maul, { hostile = true }),
				step("Bash", D.Bash, { hostile = true }),
			},
		},
		cat = {
			aoe = {
				step("TigersFury", D.TigersFury, { nobuff = true }),
				step("Rip", D.Rip, { comboMin = 5, nodebuff = true, hostile = true }),
				step("Rake", D.Rake, { nodebuff = true, hostile = true }),
				step("Claw", D.Claw, { filler = true }),
			},
			burst = {
				step("TigersFury", D.TigersFury, { nobuff = true }),
				step("FerociousBite", D.FerociousBite, { comboMin = 5, hostile = true }),
				step("Shred", D.Shred, { hostile = true }),
				step("Ravage", D.Ravage, { hostile = true }),
				step("Claw", D.Claw, { filler = true }),
			},
		},
		bear = {
			aoe = {
				step("DemoralizingRoar", D.DemoralizingRoar, { nodebuff = true, hostile = true }),
				step("Swipe", D.Swipe, { hostile = true }),
				step("Maul", D.Maul, { filler = true }),
			},
			burst = {
				step("Enrage", D.Enrage, { combat = true }),
				step("Maul", D.Maul, { hostile = true }),
				step("Swipe", D.Swipe, { hostile = true }),
				step("Bash", D.Bash, { hostile = true }),
			},
		},
	},
	PALADIN = {
		damage = {
			aoe = {
				step("Consecration", P.Consecration, { hostile = true }),
				step("HolyWrath", P.HolyWrath, { hostile = true }),
				step("CrusaderStrike", P.CrusaderStrike, { hostile = true }),
				step("Judgement", P.Judgement, { hostile = true }),
				step("SealCommand", P.SealCommand, { nobuff = true, anybuff = palaSeals }),
				step("Exorcism", P.Exorcism, { hostile = true }),
				step("FlashofLight", P.FlashofLight, { hp = 70,  heal = true }),
				step("HolyLight", P.HolyLight, { hp = 80,  heal = true }),
			},
			burst = {
				step("SealCommand", P.SealCommand, { nobuff = true, anybuff = palaSeals }),
				step("Judgement", P.Judgement, { hostile = true }),
				step("CrusaderStrike", P.CrusaderStrike, { hostile = true }),
				step("HammerofWrath", P.HammerofWrath, { hostile = true }),
				step("HolyShock", P.HolyShock, { hostile = true }),
				step("Consecration", P.Consecration, { hostile = true }),
				step("FlashofLight", P.FlashofLight, { hp = 70,  heal = true }),
				step("HolyLight", P.HolyLight, { hp = 80,  heal = true }),
			},
		},
		tank = {
			aoe = {
				step("Consecration", P.Consecration, { hostile = true }),
				step("HolyWrath", P.HolyWrath, { hostile = true }),
				step("HolyShield", P.HolyShield, { combat = true }),
				step("Judgement", P.Judgement, { hostile = true }),
				step("FlashofLight", P.FlashofLight, { hp = 70,  heal = true }),
				step("HolyLight", P.HolyLight, { hp = 80,  heal = true }),
			},
			burst = {
				step("HolyShield", P.HolyShield, { combat = true }),
				step("Consecration", P.Consecration, { hostile = true }),
				step("Judgement", P.Judgement, { hostile = true }),
				step("HammerofJustice", P.HammerofJustice, { hostile = true }),
				step("FlashofLight", P.FlashofLight, { hp = 70,  heal = true }),
				step("HolyLight", P.HolyLight, { hp = 80,  heal = true }),
			},
		},
		heal = {
			aoe = {
				step("HolyWrath", P.HolyWrath, { hostile = true }),
				step("Consecration", P.Consecration, { hostile = true }),
				step("HolyShock", P.HolyShock, { hp = 80,  heal = true }),
				step("FlashofLight", P.FlashofLight, { hp = 70,  heal = true }),
				step("HolyLight", P.HolyLight, { hp = 80,  heal = true }),
			},
			burst = {
				step("HolyShock", P.HolyShock, { hp = 80,  heal = true }),
				step("HolyLight", P.HolyLight, { hp = 80,  heal = true }),
				step("FlashofLight", P.FlashofLight, { hp = 70,  heal = true }),
				step("LayonHands", P.LayonHands, { combat = true, hp = 20, heal = true }),
			},
		},
	},
	WARRIOR = {
		damage = {
			aoe = {
				step("SweepingStrikes", W.SweepingStrikes, { hostile = true }),
				step("Whirlwind", W.Whirlwind, { hostile = true }),
				step("Cleave", W.Cleave, { hostile = true }),
				step("ThunderClap", W.ThunderClap, { nodebuff = true, hostile = true }),
				step("DemoralizingShout", W.DemoralizingShout, { nodebuff = true, hostile = true }),
				step("PiercingHowl", W.PiercingHowl, { hostile = true }),
				step("HeroicStrike", W.HeroicStrike, { filler = true }),
			},
			burst = {
				step("Recklessness", W.Recklessness, { hostile = true }),
				step("DeathWish", W.DeathWish, { hostile = true }),
				step("Bloodrage", W.Bloodrage, { hostile = true }),
				step("Execute", W.Execute, { hp = 20, unit = "target", hostile = true }),
				step("MortalStrike", W.MortalStrike, { hostile = true }),
				step("Bloodthirst", W.Bloodthirst, { hostile = true }),
				step("Whirlwind", W.Whirlwind, { hostile = true }),
				step("Slam", W.Slam, { hostile = true }),
			},
		},
		tank = {
			aoe = {
				step("ThunderClap", W.ThunderClap, { nodebuff = true, hostile = true }),
				step("DemoralizingShout", W.DemoralizingShout, { nodebuff = true, hostile = true }),
				step("Cleave", W.Cleave, { hostile = true }),
				step("Revenge", W.Revenge, { hostile = true }),
				step("SunderArmor", W.SunderArmor, { hostile = true }),
			},
			burst = {
				step("ShieldSlam", W.ShieldSlam, { hostile = true }),
				step("Revenge", W.Revenge, { hostile = true }),
				step("SunderArmor", W.SunderArmor, { hostile = true }),
				step("ThunderClap", W.ThunderClap, { hostile = true }),
				step("ShieldBlock", W.ShieldBlock, { combat = true }),
			},
		},
	},
	HUNTER = {
		range = {
			aoe = {
				step("HuntersMark", H.HuntersMark, { nodebuff = true, hostile = true }),
				step("MultiShot", H.MultiShot, { hostile = true }),
				step("Volley", H.Volley, { hostile = true }),
				step("ArcaneShot", H.ArcaneShot, { hostile = true }),
				step("SerpentSting", H.SerpentSting, { nodebuff = true, hostile = true }),
			},
			burst = {
				step("RapidFire", H.RapidFire, { hostile = true }),
				step("BestialWrath", H.BestialWrath, { hostile = true }),
				step("Intimidation", H.Intimidation, { hostile = true }),
				step("AimedShot", H.AimedShot, { hostile = true }),
				step("MultiShot", H.MultiShot, { hostile = true }),
				step("ArcaneShot", H.ArcaneShot, { hostile = true }),
			},
		},
		melee = {
			aoe = {
				step("MultiShot", H.MultiShot, { hostile = true }),
				step("Volley", H.Volley, { hostile = true }),
				step("Counterattack", H.Counterattack, { hostile = true }),
				step("MongooseBite", H.MongooseBite, { hostile = true }),
				step("RaptorStrike", H.RaptorStrike, { filler = true }),
			},
			burst = {
				step("RapidFire", H.RapidFire, { hostile = true }),
				step("BestialWrath", H.BestialWrath, { hostile = true }),
				step("Intimidation", H.Intimidation, { hostile = true }),
				step("MongooseBite", H.MongooseBite, { hostile = true }),
				step("RaptorStrike", H.RaptorStrike, { filler = true }),
			},
		},
	},
	ROGUE = {
		damage = {
			aoe = {
				step("BladeFlurry", R.BladeFlurry, { hostile = true }),
				step("SliceandDice", R.SliceandDice, { comboMin = 5, nobuff = true, hostile = true }),
				step("Eviscerate", R.Eviscerate, { comboMin = 5, hostile = true }),
				step("Hemorrhage", R.Hemorrhage, { hostile = true }),
				step("SinisterStrike", R.SinisterStrike, { filler = true }),
			},
			burst = {
				step("AdrenalineRush", R.AdrenalineRush, { hostile = true }),
				step("ColdBlood", R.ColdBlood, { hostile = true }),
				step("Premeditation", R.Premeditation, { hostile = true }),
				step("BladeFlurry", R.BladeFlurry, { hostile = true }),
				step("Eviscerate", R.Eviscerate, { comboMin = 5, hostile = true }),
				step("Hemorrhage", R.Hemorrhage, { hostile = true }),
				step("SinisterStrike", R.SinisterStrike, { filler = true }),
			},
		},
	},
	PRIEST = {
		damage = {
			aoe = {
				step("HolyNova", Pr.HolyNova, { hostile = true }),
				step("ShadowWordPain", Pr.ShadowWordPain, { nodebuff = true, hostile = true }),
				step("MindFlay", Pr.MindFlay, { hostile = true }),
				step("MindBlast", Pr.MindBlast, { hostile = true }),
				step("Smite", Pr.Smite, { filler = true }),
				step("FlashHeal", Pr.FlashHeal, { hp = 70,  heal = true }),
			},
			burst = {
				step("InnerFocus", Pr.InnerFocus, { hostile = true }),
				step("PowerInfusion", Pr.PowerInfusion, { hostile = true }),
				step("MindBlast", Pr.MindBlast, { hostile = true }),
				step("MindFlay", Pr.MindFlay, { hostile = true }),
				step("HolyFire", Pr.HolyFire, { nodebuff = true, hostile = true }),
				step("Smite", Pr.Smite, { filler = true }),
				step("FlashHeal", Pr.FlashHeal, { hp = 70,  heal = true }),
			},
		},
		heal = {
			aoe = {
				step("PrayerofHealing", Pr.PrayerofHealing, { hp = 75,  heal = true }),
				step("HolyNova", Pr.HolyNova),
				step("Renew", Pr.Renew, { hp = 90,  nobuff = true, heal = true }),
				step("FlashHeal", Pr.FlashHeal, { hp = 70,  heal = true }),
				step("GreaterHeal", Pr.GreaterHeal, { hp = 55,  heal = true }),
			},
			burst = {
				step("InnerFocus", Pr.InnerFocus),
				step("PowerInfusion", Pr.PowerInfusion),
				step("FlashHeal", Pr.FlashHeal, { hp = 70,  heal = true }),
				step("GreaterHeal", Pr.GreaterHeal, { hp = 55,  heal = true }),
				step("Heal", Pr.Heal, { hp = 80,  heal = true }),
			},
		},
	},
	SHAMAN = {
		caster = {
			aoe = {
				step("ChainLightning", Sh.ChainLightning, { hostile = true }),
				step("FireNova", Sh.FireNova, { hostile = true }),
				step("MagmaTotem", Sh.MagmaTotem, { hostile = true }),
				step("SearingTotem", Sh.SearingTotem, { hostile = true }),
				step("FlameShock", Sh.FlameShock, { nodebuff = true, hostile = true }),
				step("FrostShock", Sh.FrostShock, { hostile = true }),
				step("LesserHealingWave", Sh.LesserHealingWave, { hp = 70,  heal = true }),
			},
			burst = {
				step("ElementalMastery", Sh.ElementalMastery, { hostile = true }),
				step("ChainLightning", Sh.ChainLightning, { hostile = true }),
				step("FlameShock", Sh.FlameShock, { nodebuff = true, hostile = true }),
				step("LightningBolt", Sh.LightningBolt, { filler = true }),
				step("LesserHealingWave", Sh.LesserHealingWave, { hp = 70,  heal = true }),
			},
		},
		melee = {
			aoe = {
				step("FireNova", Sh.FireNova, { hostile = true }),
				step("MagmaTotem", Sh.MagmaTotem, { hostile = true }),
				step("ChainLightning", Sh.ChainLightning, { hostile = true }),
				step("Stormstrike", Sh.Stormstrike, { hostile = true }),
				step("FlameShock", Sh.FlameShock, { nodebuff = true, hostile = true }),
				step("LesserHealingWave", Sh.LesserHealingWave, { hp = 70,  heal = true }),
			},
			burst = {
				step("ElementalMastery", Sh.ElementalMastery, { hostile = true }),
				step("Stormstrike", Sh.Stormstrike, { hostile = true }),
				step("EarthShock", Sh.EarthShock, { hostile = true }),
				step("FlameShock", Sh.FlameShock, { nodebuff = true, hostile = true }),
				step("LightningBolt", Sh.LightningBolt, { filler = true }),
				step("LesserHealingWave", Sh.LesserHealingWave, { hp = 70,  heal = true }),
			},
		},
		heal = {
			aoe = {
				step("ChainHeal", Sh.ChainHeal, { hp = 75,  heal = true }),
				step("HealingStream", Sh.HealingStream),
				step("LesserHealingWave", Sh.LesserHealingWave, { hp = 70,  heal = true }),
				step("HealingWave", Sh.HealingWave, { hp = 80,  heal = true }),
			},
			burst = {
				step("NaturesSwiftness", Sh.NaturesSwiftness),
				step("HealingWave", Sh.HealingWave, { hp = 80,  heal = true }),
				step("ChainHeal", Sh.ChainHeal, { hp = 75,  heal = true }),
				step("LesserHealingWave", Sh.LesserHealingWave, { hp = 70,  heal = true }),
			},
		},
	},
	MAGE = {
		damage = {
			aoe = {
				step("ArcaneExplosion", M.ArcaneExplosion, { hostile = true }),
				step("BlastWave", M.BlastWave, { hostile = true }),
				step("Flamestrike", M.Flamestrike, { hostile = true }),
				step("Blizzard", M.Blizzard, { hostile = true }),
				step("ConeofCold", M.ConeofCold, { hostile = true }),
				step("FrostNova", M.FrostNova, { hostile = true }),
			},
			burst = {
				step("Combustion", M.Combustion, { hostile = true }),
				step("PresenceofMind", M.PresenceofMind, { hostile = true }),
				step("ArcanePower", M.ArcanePower, { hostile = true }),
				step("Pyroblast", M.Pyroblast, { hostile = true }),
				step("FireBlast", M.FireBlast, { hostile = true }),
				step("Fireball", M.Fireball, { filler = true }),
			},
		},
	},
	WARLOCK = {
		damage = {
			aoe = {
				step("RainofFire", L.RainofFire, { hostile = true }),
				step("Hellfire", L.Hellfire, { hostile = true, hp = 40 }),
				step("Corruption", L.Corruption, { nodebuff = true, hostile = true }),
				step("CurseofAgony", L.CurseofAgony, { nodebuff = true, hostile = true }),
				step("HowlofTerror", L.HowlofTerror, { combat = true }),
				step("ShadowBolt", L.ShadowBolt, { filler = true }),
			},
			burst = {
				step("Shadowburn", L.Shadowburn, { hostile = true }),
				step("SoulFire", L.SoulFire, { hostile = true }),
				step("DeathCoil", L.DeathCoil, { hostile = true }),
				step("Conflagrate", L.Conflagrate, { hostile = true }),
				step("ShadowBolt", L.ShadowBolt, { filler = true }),
			},
		},
	},
}

ns.DefDefaults = {
	DRUID = {
		damage = {
			step("MarkoftheWild", D.MarkoftheWild, { nobuff = true }),
			step("Thorns", D.Thorns, { nobuff = true }),
			step("Moonkin", D.Moonkin, { nobuff = true }),
			step("Barkskin", D.Barkskin, { combat = true, hp = 50 }),
			step("NaturesGrasp", D.NaturesGrasp, { combat = true, hp = 40 }),
		},
		tank = {
			step("MarkoftheWild", D.MarkoftheWild, { nobuff = true }),
			step("Thorns", D.Thorns, { nobuff = true }),
			step("Barkskin", D.Barkskin, { combat = true, hp = 60 }),
			step("FrenziedRegen", D.FrenziedRegen, { combat = true, hp = 40 }),
			step("NaturesGrasp", D.NaturesGrasp, { combat = true, hp = 40 }),
		},
		heal = {
			step("MarkoftheWild", D.MarkoftheWild, { nobuff = true }),
			step("Thorns", D.Thorns, { nobuff = true }),
			step("Barkskin", D.Barkskin, { combat = true, hp = 50 }),
			step("Innervate", D.Innervate, { combat = true, hp = 35 }),
		},
		cat = {
			step("MarkoftheWild", D.MarkoftheWild, { nobuff = true }),
			step("Thorns", D.Thorns, { nobuff = true }),
			step("Barkskin", D.Barkskin, { combat = true, hp = 50 }),
		},
		bear = {
			step("MarkoftheWild", D.MarkoftheWild, { nobuff = true }),
			step("Thorns", D.Thorns, { nobuff = true }),
			step("Barkskin", D.Barkskin, { combat = true, hp = 60 }),
			step("FrenziedRegen", D.FrenziedRegen, { combat = true, hp = 40 }),
		},
	},
	PALADIN = {
		damage = {
			step("DevotionAura", P.DevotionAura, { nobuff = true, anybuff = palaAuras }),
			step("RetributionAura", P.RetributionAura, { nobuff = true, anybuff = palaAuras }),
			step("SanctityAura", P.SanctityAura, { nobuff = true, anybuff = palaAuras }),
			step("ConcentrationAura", P.ConcentrationAura, { nobuff = true, anybuff = palaAuras }),
			step("FireResistAura", P.FireResistAura, { nobuff = true, anybuff = palaAuras }),
			step("FrostResistAura", P.FrostResistAura, { nobuff = true, anybuff = palaAuras }),
			step("ShadowResistAura", P.ShadowResistAura, { nobuff = true, anybuff = palaAuras }),
			step("BlessingMight", P.BlessingMight, { nobuff = true, anybuff = palaBlessings }),
			step("BlessingKings", P.BlessingKings, { nobuff = true, anybuff = palaBlessings }),
			step("BlessingWisdom", P.BlessingWisdom, { nobuff = true, anybuff = palaBlessings }),
			step("DivineProtection", P.DivineProtection, { combat = true, hp = 40 }),
			step("DivineShield", P.DivineShield, { combat = true, hp = 25 }),
			step("LayonHands", P.LayonHands, { combat = true, hp = 15 }),
		},
		tank = {
			step("RighteousFury", P.RighteousFury, { nobuff = true }),
			step("DevotionAura", P.DevotionAura, { nobuff = true, anybuff = palaAuras }),
			step("RetributionAura", P.RetributionAura, { nobuff = true, anybuff = palaAuras }),
			step("SanctityAura", P.SanctityAura, { nobuff = true, anybuff = palaAuras }),
			step("ConcentrationAura", P.ConcentrationAura, { nobuff = true, anybuff = palaAuras }),
			step("BlessingKings", P.BlessingKings, { nobuff = true, anybuff = palaBlessings }),
			step("BlessingMight", P.BlessingMight, { nobuff = true, anybuff = palaBlessings }),
			step("HolyShield", P.HolyShield, { combat = true, hp = 80 }),
			step("DivineProtection", P.DivineProtection, { combat = true, hp = 40 }),
			step("DivineShield", P.DivineShield, { combat = true, hp = 25 }),
			step("LayonHands", P.LayonHands, { combat = true, hp = 15 }),
		},
		heal = {
			step("DevotionAura", P.DevotionAura, { nobuff = true, anybuff = palaAuras }),
			step("ConcentrationAura", P.ConcentrationAura, { nobuff = true, anybuff = palaAuras }),
			step("RetributionAura", P.RetributionAura, { nobuff = true, anybuff = palaAuras }),
			step("BlessingWisdom", P.BlessingWisdom, { nobuff = true, anybuff = palaBlessings }),
			step("BlessingKings", P.BlessingKings, { nobuff = true, anybuff = palaBlessings }),
			step("DivineProtection", P.DivineProtection, { combat = true, hp = 40 }),
			step("DivineShield", P.DivineShield, { combat = true, hp = 25 }),
			step("LayonHands", P.LayonHands, { combat = true, hp = 15 }),
		},
	},
	WARRIOR = {
		damage = {
			step("BattleShout", W.BattleShout, { nobuff = true }),
			step("BerserkerRage", W.BerserkerRage, { combat = true, hp = 60 }),
			step("LastStand", W.LastStand, { combat = true, hp = 35 }),
			step("ShieldWall", W.ShieldWall, { combat = true, hp = 25 }),
			step("Retaliation", W.Retaliation, { combat = true, hp = 40 }),
		},
		tank = {
			step("BattleShout", W.BattleShout, { nobuff = true }),
			step("ShieldBlock", W.ShieldBlock, { combat = true, hp = 70 }),
			step("LastStand", W.LastStand, { combat = true, hp = 35 }),
			step("ShieldWall", W.ShieldWall, { combat = true, hp = 25 }),
		},
	},
	HUNTER = {
		damage = {
			step("AspectHawk", H.AspectHawk, { nobuff = true, anybuff = hunterAspects }),
			step("AspectMonkey", H.AspectMonkey, { nobuff = true, anybuff = hunterAspects }),
			step("AspectWild", H.AspectWild, { nobuff = true, anybuff = hunterAspects }),
			step("TrueshotAura", H.TrueshotAura, { nobuff = true }),
			step("Deterrence", H.Deterrence, { combat = true, hp = 40 }),
			step("FeignDeath", H.FeignDeath, { combat = true, hp = 25 }),
			step("Disengage", H.Disengage, { combat = true, hp = 35 }),
		},
	},
	ROGUE = {
		damage = {
			step("Evasion", R.Evasion, { combat = true, hp = 40 }),
			step("Vanish", R.Vanish, { combat = true, hp = 20 }),
			step("Sprint", R.Sprint, { combat = true, hp = 25 }),
			step("Feint", R.Feint, { combat = true, hp = 50 }),
		},
	},
	PRIEST = {
		damage = {
			step("InnerFire", Pr.InnerFire, { nobuff = true }),
			step("PowerWordFortitude", Pr.PowerWordFortitude, { nobuff = true }),
			step("Shadowform", Pr.Shadowform, { nobuff = true }),
			step("VampiricEmbrace", Pr.VampiricEmbrace, { nobuff = true }),
			step("ShadowProtection", Pr.ShadowProtection, { nobuff = true }),
			step("PowerWordShield", Pr.PowerWordShield, { combat = true, hp = 70, nobuff = true, nodebuff = Pr.WeakenedSoul }),
			step("Fade", Pr.Fade, { combat = true, hp = 50 }),
		},
		heal = {
			step("InnerFire", Pr.InnerFire, { nobuff = true }),
			step("PowerWordFortitude", Pr.PowerWordFortitude, { nobuff = true }),
			step("DivineSpirit", Pr.DivineSpirit, { nobuff = true }),
			step("ShadowProtection", Pr.ShadowProtection, { nobuff = true }),
			step("PowerWordShield", Pr.PowerWordShield, { combat = true, hp = 70, nobuff = true, nodebuff = Pr.WeakenedSoul }),
			step("Fade", Pr.Fade, { combat = true, hp = 50 }),
		},
	},
	SHAMAN = {
		damage = {
			step("LightningShield", Sh.LightningShield, { nobuff = true }),
			step("Stoneclaw", Sh.Stoneclaw, { combat = true, hp = 50 }),
			step("GroundingTotem", Sh.GroundingTotem, { combat = true, hp = 60 }),
			step("TremorTotem", Sh.TremorTotem, { combat = true, hp = 70 }),
		},
		heal = {
			step("LightningShield", Sh.LightningShield, { nobuff = true }),
			step("GroundingTotem", Sh.GroundingTotem, { combat = true, hp = 60 }),
			step("Stoneclaw", Sh.Stoneclaw, { combat = true, hp = 40 }),
			step("HealingStream", Sh.HealingStream, { combat = true, hp = 80 }),
		},
	},
	MAGE = {
		damage = {
			step("ArcaneIntellect", M.ArcaneIntellect, { nobuff = true }),
			step("MageArmor", M.MageArmor, { nobuff = true, anybuff = mageArmors }),
			step("IceArmor", M.IceArmor, { nobuff = true, anybuff = mageArmors }),
			step("FrostArmor", M.FrostArmor, { nobuff = true, anybuff = mageArmors }),
			step("AmplifyMagic", M.AmplifyMagic, { nobuff = true }),
			step("ManaShield", M.ManaShield, { combat = true, hp = 55 }),
			step("IceBarrier", M.IceBarrier, { combat = true, hp = 80 }),
			step("FireWard", M.FireWard, { combat = true, hp = 70 }),
			step("FrostWard", M.FrostWard, { combat = true, hp = 70 }),
			step("IceBlock", M.IceBlock, { combat = true, hp = 30 }),
			step("Blink", M.Blink, { combat = true, hp = 25 }),
		},
	},
	WARLOCK = {
		damage = {
			step("DemonArmor", L.DemonArmor, { nobuff = true, anybuff = lockSkins }),
			step("DemonSkin", L.DemonSkin, { nobuff = true, anybuff = lockSkins }),
			step("UnendingBreath", L.UnendingBreath, { nobuff = true }),
			step("ShadowWard", L.ShadowWard, { combat = true, hp = 60 }),
			step("HowlofTerror", L.HowlofTerror, { combat = true, hp = 35 }),
		},
	},
}

-- Alias de rôles pour le fallback éditeur / spec.
ns.APLDefaults.DRUID.hybrid = ns.APLDefaults.DRUID.damage
ns.APLModes.DRUID.hybrid = ns.APLModes.DRUID.damage
ns.DefDefaults.DRUID.hybrid = ns.DefDefaults.DRUID.damage
ns.DefDefaults.HUNTER.range = ns.DefDefaults.HUNTER.damage
ns.DefDefaults.HUNTER.melee = ns.DefDefaults.HUNTER.damage
ns.DefDefaults.SHAMAN.caster = ns.DefDefaults.SHAMAN.damage
ns.DefDefaults.SHAMAN.melee = ns.DefDefaults.SHAMAN.damage

local function stripMaintFromApl(node)
	if type(node) ~= "table" then
		return
	end
	if node[1] and type(node[1]) == "table" and node[1].key then
		for i = #node, 1, -1 do
			local id = node[i].id
			if id and ns.MAINTENANCE_BUFF_IDS and ns.MAINTENANCE_BUFF_IDS[id] then
				table.remove(node, i)
			end
		end
		return
	end
	for _, child in pairs(node) do
		if type(child) == "table" then
			stripMaintFromApl(child)
		end
	end
end
stripMaintFromApl(ns.APLDefaults)
stripMaintFromApl(ns.APLModes)
