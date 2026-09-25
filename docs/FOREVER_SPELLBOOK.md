# Catalogue Forever — sorts 1–60 et talents

Snapshot des grimoires et arbres **WoW Forever** (beta). Sert à aligner `Data.lua` / `Lists.lua` sans inventer d’IDs.

- Client : **1.60.1.69876** (grimoire 20 sept. 2026)
- Talents : calculateurs [wowforevertalent.com](https://wowforevertalent.com/) (maj 24 sept. 2026)
- IDs paladin neufs : [wowforeverbuilds.com/abilities/paladin](https://wowforeverbuilds.com/abilities/paladin) (build 1.60.1.69876)
- Diff Era : [foreverdiff.com](https://foreverdiff.com/) · [foreverchanges.pro/changes](https://foreverchanges.pro/changes)
- Wowhead Forever : [wowhead.com/forever](https://www.wowhead.com/forever) (pages JS, moins exploitables que le grimoire ci-dessus)

Les rangs peuvent encore bouger avant le lancement. Un sort **déjà dans `ns.Spell`** se résout par **nom + grimoire** : un ID Classic suffit souvent. Un sort **nouveau** exige un ID Forever réel (lab) plus un `step` dans les listes.

Légende addon : **IN** = clé dans `ns.Spell` · **GAP** = absent, à ajouter si combat · **UTIL** = hors file (portails, pistage, passifs) · **TAL** = talent / sort de talent

Passifs d’armes, langues, *Attack*, *Throw*, *Shoot* : omis partout (inutiles au HUD).

---

## Couverture actuelle de l’addon

`ns.Spell` est un noyau **ConROC Classic Era**, pas le grimoire Forever. Les sorts Era connus restent en général **IN**. Les **nouveaux sorts de rotation** sont le trou.

À ajouter en priorité (combat / soin / défense / proc) :

| Classe | Sorts absents de `Data.lua` (combat) |
| --- | --- |
| Guerrier | Victory Rush, Spearing Strike |
| Paladin | Holy Strike, Light's Vigil, Voice of Truth, Swift Judgement, Templar's Bulwark |
| Chasseur | Sniper Shot, Enchanted Flare, Strider Kick, Lacerate (chasseur), Scatter Shot |
| Voleur | Mutilate, Venom |
| Prêtre | Shadow Word: Death, Penance, Binding Heal, Prayer of Mending, Chastise, Confounding Flash, Contingency Plan, Divine Grace |
| Chaman | Lava Burst, Riptide, Water Shield, Fire Nova (sort, plus un totem), Totemic Projection, Call of the Elements / Ancestors / Spirits |
| Mage | Frostfire Bolt, Ice Lance, Arcane Blast |
| Démoniste | Incinerate, Wrack, Bane of Havoc, Summon Incubus ; *Bane of Agony* = ancien Curse of Agony (renommé) |
| Druide | Lacerate (ours), Mangle / Primal Bite, Berserk, Wild Growth, Revive |
| Raciaux (actifs) | Will to Survive, Elune's Light, Eureka!, Shatter Curse, Rapid Regeneration, Cannibalize ; Walk on Air volontairement exclu |

`Seal of Fury` et `Crusader Strike` sont déjà dans `ns.Spell.Paladin`.

---

## Guerrier

ForeverDiff : 44 sorts · 54 talents. Grimoire : 42 sorts + généraux.

### Arms

| Sort | Rangs / niv. | Addon |
| --- | --- | --- |
| Battle Stance | 1 | UTIL |
| Charge | 3 rangs | IN |
| Hamstring | 3 | IN |
| Heroic Strike | 9 | IN |
| Mocking Blow | 5 | IN |
| Mortal Strike | 4 | IN TAL |
| Overpower | 4 | IN |
| Rend | 7 | IN |
| Retaliation | 20 (changé) | IN |
| Spearing Strike | **New** · 1 | **GAP** |
| Sweeping Strikes | 30 | IN TAL |
| Tactical Mastery | 14 · maintenant entraînable | UTIL |
| Thunder Clap | 6 (changé, Battle+Def) | IN |
| Victory Rush | **New** · 20 · 30 s · heal 10 % | **GAP** |

### Fury

Battle Shout, Berserker Rage, Berserker Stance, Bloodthirst, Challenging Shout, Cleave, Death Wish, Demoralizing Shout, Execute, Intercept (30/42/52), Intimidating Shout, Piercing Howl, Pummel, Recklessness, Slam (**CD 15 s**, rangs 20–54), Whirlwind.

Tous **IN** sauf Challenging Shout / Intimidating Shout (**UTIL** / rare).

### Protection

Bloodrage, Concussion Blow, Defensive Stance, Disarm, Last Stand, Revenge, Shield Bash, Shield Block (2 charges / 7 s), Shield Slam, Shield Wall (15 min, 60 %), Sunder Armor, Taunt.

Tous **IN**.

### Talents (51 pts, 3 arbres)

**Arms** (max) : Improved Heroic Strike 3, Deflection 5, Improved Rend 3, Improved Charge 2, Improved Tactical Mastery 5, Improved Overpower 2, Anger Management 1, Deep Wounds 3, **Spearing Strike 1 (new)**, Two-Handed Weapon Specialization 3, Impale 2, **Bloodthrill 5 (new)**, Sweeping Strikes 1, **Weaponmaster 5 (new)**, Improved Slam 2, Improved Hamstring 3, Mortal Strike 1.

**Fury** : Booming Voice 5, Cruelty 5, Iron Will 5, Unbridled Wrath 5, Improved Cleave 3, Piercing Howl 1, Blood Craze 3, **Boundless Rage 3 (new)**, Dual Wield Specialization 5, **Raging Blows 1 (new)**, Enrage 5, Improved Execute 2, **Precision 3 (new)**, Death Wish 1, Improved Intercept 2, Improved Berserker Rage 2, Flurry 5, Bloodthirst 1.

**Protection** : Shield Specialization 5, Anticipation 5, Improved Bloodrage 2, Toughness 5, Improved Thunder Clap 3, Last Stand 1, **Master of Defense 2 (new)**, Improved Revenge 3, Defiance 3, Improved Sunder Armor 3, Improved Disarm 3, **Vanguard 1 (new)** (Charge en Defensive), Improved Shield Wall 2, Concussion Blow 1, Improved Shield Bash 2, **Bastion 5**, **Focused Rage 3 (new)**, Shield Slam 1.

---

## Paladin

ForeverDiff : 81 sorts · 60 talents. Grimoire : 53 sorts.

### Holy

Blessing of Light, Blessing of Wisdom, Cleanse, Consecration (entraînable 20), Divine Favor, Exorcism, Flash of Light, Greater Blessing of Light / Wisdom, Hammer of Wrath, Holy Light, Holy Shock, Holy Wrath, Lay on Hands, **Light's Vigil New** (ID **1310911**), Purify, Redemption, Seal of Light / Righteousness / Wisdom, Sense Undead, Turn Undead, **Voice of Truth New** (ID **1310897**).

IN : soins, sceaux, jugements, Cleanse, Consecration, Exorcism, Hammer of Wrath, Holy Shock/Wrath, Lay on Hands. **GAP** : Light's Vigil, Voice of Truth. UTIL : Redemption, Sense Undead, Turn Undead, Greater Blessings (groupe).

### Protection

Blessing of Freedom / Kings / Protection / Sacrifice / Salvation, Concentration Aura, Devotion Aura, Divine Intervention / Protection / Shield, auras de résistance, Greater Blessing of Kings / Salvation, Hammer of Justice, Holy Shield, Righteous Fury, **Seal of Fury New** (IN `SealFury`), Seal of Justice, **Swift Judgement New**, **Templar's Bulwark New** (ID **1311015**).

**GAP** : Swift Judgement, Templar's Bulwark.

### Retribution

Blessing of Might, Greater Blessing of Might, **Holy Strike New** (8 rangs dès 6), Judgement (ne consomme plus le sceau, 10 s), Repentance, Retribution Aura, Seal of Command, Seal of the Crusader.

**GAP** : Holy Strike. Crusader Strike déjà **IN**.

### Talents (52 · 20 new · 25 changed)

**Holy** : Improved Holy Strike 2, Divine Strength 5, Divine Intellect 5, Healing Light 3, Spiritual Focus 2, Improved Seals 3, Unyielding Faith 2, Voice of Truth 1, Reverence 3, Purifying Power 2, Infusion of Light 2, Illumination 5, Divine Favor 1, Divine Precision 3, Holy Shock 1, Consecrated Ground 2, Holy Power 5, Light's Vigil 1.

**Protection** : Toughness 5, Redoubt 5, Precision 3, Guardian's Favor 2, Anticipation 5, Improved Seal of Fury 1, Improved Righteous Fury 3, Shield Specialization 3, Sacred Duty 2, Swift Judgement 1, One-Handed Weapon Specialization 3, Improved Hammer of Justice 3, Templar's Bulwark 1, Reckoning 5, Iron Creed 5, Holy Shield 1.

**Retribution** : Deflection 5, Benediction 5, Improved Judgement 2, Holy Conduit 2, Conviction 5, Vindication 3, Sanctified Judgement 3, Seal of Command 1, Pursuit of Justice 2, Eye for an Eye 2, Sacred Arbiter 1, Crusade 2, Two-Handed Weapon Specialization 3, Vengeance 3, Repentance 1, Champion of the Light 3, Instrument of Law 2, Twist of Light 1.

---

## Chasseur

ForeverDiff : 94 sorts · 54 talents. Grimoire : 88 (dont 30 familiers).

### Beast Mastery

Aspects Beast / Cheetah / Hawk / Monkey / Pack / Wild, Beast Lore, Bestial Wrath, Call Pet, Dismiss Pet, Eagle Eye, Eyes of the Beast, Feed Pet, Intimidation, Mend Pet, Revive Pet, Scare Beast, **Summon Hawk New**, Tame Beast, Tranquilizing Shot.

IN : aspects (sauf Beast partiel), Bestial Wrath, Call Pet, Intimidation, Mend Pet. **GAP** : Summon Hawk, Tranquilizing Shot. UTIL : lore / feed / tame / eagle / dismiss.

### Marksmanship

Aimed Shot (entraînable, 2 s, CD partagé Multi-Shot), Arcane Shot, Auto Shot, Concussive Shot, Distracting Shot, **Enchanted Flare New**, Flare, Hunter's Mark, Multi-Shot, Rapid Fire, Scatter Shot, Scorpid / Serpent / Viper Sting, **Sniper Shot New**, Trueshot Aura, Volley.

IN : Aimed, Arcane, Auto, Concussive, Mark, Multi, Rapid, stings, Trueshot, Volley. **GAP** : Sniper Shot, Enchanted Flare, Scatter Shot, Distracting Shot, Flare.

### Survival

Counterattack, Deterrence, Disengage, Explosive / Freezing / Frost / Immolation Trap, Feign Death, **Lacerate New**, Mongoose Bite, Raptor Strike, **Strider Kick New**, Track *, Wing Clip.

IN : Counterattack, Deterrence, Disengage, Feign, Mongoose, Raptor, Wing Clip. **GAP** : Lacerate (chasseur), Strider Kick, traps (optionnel). UTIL : Track *.

### Familiers (30)

Bite, Claw, Charge, Cower, Dash, Dive, Growl, etc. + **New** : Dismember, Dust Cloud, Mine!, Pinch, Savage Rend, Swipe, Tendon Rip, Trickster's Dance, Web. Thunderstomp rang 4 new. Hors file joueur.

### Talents (50 · 14 new · 24 changed)

**Beast Mastery** : Deadly Aspects 5, Endurance Training 5, Focused Fire 2, Improved Aspect of the Monkey 3, Pathfinding 2, Improved Revive Pet 2, Bestial Swiftness 1, Unleashed Fury 5, Improved Mend Pet 2, Ferocity 5, Summon Hawk 1, Spirit Bond 2, Intimidation 1, Bestial Discipline 2, Frenzy 5, Bestial Wrath 1.

**Marksmanship** : Hawk Eye 3, Improved Concussive Shot 5, Lethal Attacks 5, Improved Stings 3, Efficiency 5, Careful Aim 5, Rapid Killing 2, Improved Arcane Shot 5, Lone Wolf 1, Trueshot Aura 1, Mortal Shots 5, Rapid Recuperation 2, Barrage 3, Scatter Shot 1, Ranged Weapon Specialization 5, Sniper Shot 1.

**Survival** : Improved Tracking 5, Deflection 5, Entrapment 5, Savage Strikes 2, Survivalist 5, Improved Wing Clip 3, Clever Traps 2, Surefooted 3, Deterrence 1, Survival Tactics 2, Predator's Edge 5, Counterattack 1, Resourcefulness 2, Expose Prey 2, Survivalist's Discipline 2, Strider Kick 1, Lightning Reflexes 5, Lacerating Strikes 1.

---

## Voleur

ForeverDiff : 58 sorts · 50 talents. Grimoire : 40 + poisons.

### Assassination

Ambush, Cheap Shot, Cold Blood, Eviscerate, Expose Armor, Garrote, Kidney Shot, **Mutilate New**, Rupture, Slice and Dice, **Venom New** (40).

IN : tous sauf **GAP Mutilate, Venom**.

### Combat

Adrenaline Rush, Backstab, Blade Flurry, Evasion, Feint, Gouge, Kick, Riposte, Sinister Strike, Sprint. Tous **IN**.

### Subtlety

Blind, Detect/Disarm Traps, Distract, Ghostly Strike, Hemorrhage, Pick Pocket, Premeditation, Preparation, Safe Fall, Sap, Stealth, Vanish.

IN : Ghostly, Hemorrhage, Premeditation, Stealth, Vanish. UTIL : Blind, traps, Pick Pocket, Sap, Safe Fall. **GAP** : Preparation (burst).

### Poisons

Crippling, Instant, Mind-numbing, Deadly, Wound, Blinding Powder. IN via `WEAPON_BUFFS` (sauf poudre).

Axes 1M : plus un sort, une compétence d’arme.

### Talents (53 · 9 new · 30 changed)

**Assassination** : Improved Gouge 3, Remorseless Attacks 2, Malice 5, Ruthlessness 3, Murder 2, Improved Slice and Dice 3, Relentless Strikes 1, Improved Expose Armor 2, Lethality 5, Vile Poisons 5, Cold Blood 1, Improved Poisons 5, Vigor 2, **Mutilate 1**, Improved Kidney Shot 2, Seal Fate 5, **Venom 1**.

**Combat** : Improved Eviscerate 3, Improved Sinister Strike 2, Lightning Reflexes 5, Puncturing Wounds 3, Deflection 3, Precision 3, Endurance 2, Riposte 1, Improved Sprint 2, Improved Kick 2, **Flawless Execution 1**, Dual Wield Specialization 5, Blade Flurry 1, **Hack and Slash 5**, Weapon Expertise 2, Aggression 3, Adrenaline Rush 1.

**Subtlety** : Camouflage 5, Master of Deception 3, Opportunity 2, Setup 3, Elusiveness 2, Dirty Tricks 2, Improved Ambush 3, Initiative 3, Ghostly Strike 1, Improved Distract 2, Heightened Senses 2, Premeditation 1, Serrated Blades 3, Dirty Deeds 2, Preparation 1, Hemorrhage 1, Quietus 5, Cutthroat 5, Thousand Cuts 1.

---

## Prêtre

ForeverDiff : 82 sorts · 54 talents. Grimoire : 56.

### Discipline

**Confounding Flash New**, **Contingency Plan New**, Dispel Magic, Divine Spirit, Elune's Grace, Feedback, Inner Fire, Inner Focus, Levitate, Mana Burn, **Penance New**, Power Infusion, PW: Fortitude / Shield, Prayer of Fortitude / Spirit, Shackle Undead, Starshards.

IN : Dispel (purge), Divine Spirit, Inner Fire/Focus, Mana Burn, PI, Fortitude, Shield. **GAP** : Penance, Confounding Flash, Contingency Plan. UTIL : Levitate, Shackle, Starshards (racial/book), Elune's Grace, Feedback.

### Holy

Abolish/Cure Disease, **Binding Heal New**, **Chastise New**, Desperate Prayer, **Divine Grace New**, Fear Ward (baseline tous), Flash / Greater / Heal / Lesser Heal, Holy Fire, Holy Nova, Lightwell, Prayer of Healing, **Prayer of Mending New**, Renew, Resurrection, Smite.

IN : heals, Holy Fire, Holy Nova, PoH, Renew, Smite. **GAP** : Binding Heal, Prayer of Mending, Chastise, Divine Grace. UTIL : Resurrection, Lightwell, Desperate Prayer.

### Shadow

**Dark Sacrifice New**, Devouring Plague (tous), Fade, Hex of Weakness, Mind Blast / Control / Flay / Soothe / Vision, Prayer of Shadow Protection, Psychic Scream, Shadow Protection, **Shadow Word: Death New** (32, 15 s), SW: Pain, Shadowform, Shadowguard, Silence, Touch of Weakness, Vampiric Embrace.

IN : Fade, Mind Blast/Flay, Psychic Scream, SW: Pain, Shadowform, VE, Silence, Devouring Plague. **GAP** : SW: Death, Dark Sacrifice. UTIL : Mind Control/Vision/Soothe, Hex, Shadowguard, Touch of Weakness.

### Talents (53 · 13 new · 29 changed)

**Discipline** : Power in Light 5, Wand Specialization 2, Twin Disciplines 5, Silent Resolve 3, Holy Precision 3, Improved PW: Shield 3, Martyrdom 2, Mental Agility 3, Inner Focus 1, Meditation 3, Improved Inner Fire 3, Mental Strength 5, Soul Warding 1, Improved Mana Burn 2, Penance 1, Renewed Hope 5, Divine Aegis 3, Power Infusion 1.

**Holy** : Twilight Focus 3, Improved Renew 3, Holy Specialization 5, Spell Warding 5, Divine Fury 5, Holy Nova 1, Blessed Recovery 3, Inspiration 3, Holy Reach 2, Improved Healing 3, Searing Light 2, Binding Heal 1, Litany of Light 2, Spirit of Redemption 1, Spiritual Guidance 5, Spiritual Healing 3, Prayer of Mending 1.

**Shadow** : Shadow Focus 5, Blackout 5, Spirit Tap 5, Shadow Affinity 3, Improved SW: Pain 2, Shadow Reach 2, Improved Mind Blast 5, Improved Psychic Scream 2, Mind Flay 1, Improved Mind Flay 2, Improved Fade 2, Vampiric Embrace 1, Shadow Weaving 3, Silence 1, Devouring Contagion 2, Early Demise 2, Darkness 5, Shadowform 1.

---

## Chaman

ForeverDiff : 69 sorts · 53 talents. Grimoire : 56.

### Elemental

Call of the Ancestors (30), Call of the Elements (20), **Call of the Spirits New** (40), Chain Lightning, Earth Shock, Earthbind Totem, **Fire Nova** (sort 30 yd, plus un totem), Flame / Frost Shock, **Lava Burst New**, Lightning Bolt, Magma / Searing / Stoneclaw Totem, Purge, Totemic Recall.

IN : CL, shocks, LB, Magma, Searing, Stoneclaw, Purge, Fire Nova (ID totem 1535 — **à revérifier** : Forever en a fait un sort). **GAP** : Lava Burst, Calls, Totemic Recall.

### Enhancement

Astral Recall, Far Sight, totems résistance / Flametongue / Frost / Grace / Grounding / Nature / Sentry / Stoneskin / Strength / Windfury / Windwall, armes Flametongue / Frostbrand / Rockbiter / Windfury, Ghost Wolf, Lightning Shield, **Rage of the Farseer New**, Stormstrike, **Totemic Projection New**, Water Breathing / Walking.

IN : armes, Lightning Shield, Stormstrike, Grounding, Grace, Strength, Stoneskin, Windfury Totem. **GAP** : Totemic Projection, Rage of the Farseer (TAL + book). UTIL : Far Sight, Water *, Astral Recall.

### Restoration

Ancestral Spirit, Chain Heal, Cure Disease/Poison, Disease/Poison Cleansing Totem, Healing Stream, Healing Wave, LHW, Mana Spring / Tide, Nature's Swiftness, Reincarnation, **Riptide New**, Tremor, **Water Shield New** (20).

IN : heals, HS, Mana Spring, NS, Tremor. **GAP** : Riptide, Water Shield. UTIL : Ancestral Spirit, Reincarnation.

### Talents (50 · 12 new · 29 changed)

**Elemental** : Convection 5, Concussion 5, Elemental Warding 3, Reverberation 5, Call of Flame 3, Elemental Devastation 3, Elemental Focus 1, Elemental Fury 5, Improved Fire Nova 2, Eye of the Storm 3, Call of Thunder 1, Elemental Reach 2, Lightning Overload 3, Earthbound 1, Elemental Alacrity 3, Lava Burst 1.

**Enhancement** : Earth's Grasp 2, Thundering Strikes 5, Ancestral Knowledge 5, Guardian Totems 2, Mental Dexterity 3, Improved Ghost Wolf 2, Improved Lightning Shield 3, Elemental Weapons 3, Shamanistic Focus 1, Anticipation 3, Toughness 5, Flurry 5, Stormstrike 1, Spirit Weapons 1, Mental Quickness 2, Improved Stormstrike 2, Maelstrom Weapon 5, Rage of the Farseer 1.

**Restoration** : Improved Healing Wave 5, Totemic Focus 5, Mindfulness 3, Natural Grace 3, Tidal Focus 5, Improved Reincarnation 2, Ancestral Healing 3, Healing Focus 3, Water Shield 1, Tidal Mastery 5, Restorative Totems 5, Mana Tide Totem 1, Healing Way 3, Nature's Swiftness 1, Purification 5, Riptide 1.

---

## Mage

ForeverDiff : 73 sorts · 41 talents. Grimoire : 58.

### Arcane

Amplify/Dampen Magic, **Arcane Blast** (rangs new), Arcane Brilliance / Explosion / Intellect / Missiles / Power, Blink, Conjure Food/Water/gemmes, Counterspell, Evocation, Mage Armor, Mana Shield, Polymorph (+ Turtle / Pig), Portails et Téléports (dont **Teleport: Dalaran New**), Presence of Mind, Remove Lesser Curse, Slow Fall.

IN : intellect, missiles, explosion, counterspell, blink, evocation, armors, PoM, AP, cleanse curse, wards partiels. **GAP** : Arcane Blast. UTIL : conjure, portals, polymorph, Slow Fall.

### Fire

Blast Wave, Combustion, Fire Blast, Fire Ward, Fireball, Flamestrike, **Frostfire Bolt New** (40, 3 s), Pyroblast, Scorch. Tous IN sauf **GAP Frostfire Bolt**.

### Frost

Blizzard, Cold Snap, Cone of Cold, Frost Armor / Nova / Ward / bolt, Ice Armor / Barrier / Block, **Ice Lance New**. **GAP** : Ice Lance. Cold Snap **TAL**.

### Talents (54 · 6 new · 31 changed)

**Arcane** : Wand Specialization 2, Arcane Focus 5, Improved Channeling 5, Arcane Subtlety 2, Magic Absorption 2, Arcane Concentration 5, Arcane Resilience 2, Arcane Geometry 2, Arcane Impact 3, Arcane Blast 1, Arcane Shielding 2, Improved Counterspell 2, Arcane Meditation 3, Missile Barrage 1, Presence of Mind 1, Arcane Mind 5, Arcane Instability 3, Arcane Power 1.

**Fire** : Wake of Fire 2, Incineration 3, Improved Fireball 5, Ignite 5, Flame Throwing 2, Impact 3, Burning Soul 3, Improved Flamestrike 3, Pyroblast 1, Improved Scorch 3, Improved Fire Ward 2, Hot Streak 1, Master of Elements 3, Critical Mass 3, Blast Wave 1, Fire Power 5, Combustion 1.

**Frost** : Frost Warding 2, Improved Frostbolt 5, Elemental Precision 5, Ice Shards 5, Permafrost 3, Improved Frost Nova 2, Frostbite 3, Piercing Ice 3, Frost Channeling 3, Ice Lance 1, Improved Blizzard 3, Arctic Reach 2, Ice Block 1, Shatter 3, Improved Cone of Cold 3, Cold Snap 1, Fingers of Frost 2, Winter's Chill 5, Ice Barrier 1.

---

## Démoniste

ForeverDiff : 64 sorts · 67 talents. Grimoire : 69 (dont démons).

### Affliction

Amplify Curse, **Bane of Agony** (ex Curse of Agony — IN sous `CurseofAgony`, **renommer / alias**), Bane of Doom, Corruption, Curse of Exhaustion / Recklessness / Elements / Tongues / Weakness, Death Coil, Drain Life / Mana / Soul, Fear, Howl of Terror, Life Tap, Siphon Life, **Wrack New**.

**GAP** : Wrack. Curse of Shadow encore dans `ns.Spell` — vérifier s’il existe encore à côté des Banes.

### Demonology

Banish, Create Fire/Health/Soul/Spellstone, Demon Armor/Skin, Demonic Sacrifice, Detect Invisibility, Eye of Kilrogg, Fel Domination, Health Funnel, Inferno, Ritual of Doom / Summoning, Sense Demons, Shadow Ward, Soul Link, **Subjugate Demon** (ex Enslave), Summon Felhunter / Imp / **Incubus New** / Succubus / Voidwalker, Unending Breath.

IN : armors, summons classiques, stones, Fear tools partiels. **GAP** : Incubus. UTIL : rituals, Eye, Sense, Inferno, Subjugate.

### Destruction

**Bane of Havoc New**, Conflagrate, Hellfire, Immolate, **Incinerate New**, Rain of Fire, Searing Pain, Shadow Bolt, Shadowburn, Soul Fire.

**GAP** : Incinerate, Bane of Havoc.

### Démons (16)

Blood Pact, Consume Shadows, Devour Magic, Fire Shield/bolt, Lash of Pain, etc., Spell Lock. Hors file joueur (sauf logique pet plus tard).

### Talents (52 · 19 new · 28 changed)

**Affliction** : Improved Life Tap 2, Suppression 5, Improved Corruption 5, Malediction 5, Soul Harvesting 2, Improved Drains 3, Improved Bane of Agony 2, Fel Concentration 3, Amplify Curse 1, Pandemic 3, Malevolence 5, Nightfall 2, Curse of Exhaustion 1, Siphon Life 1, Soul Siphon 3, Shadow Mastery 5, Wrack 1.

**Demonology** : Improved Health Funnel 2, Improved Imp 3, Demonic Embrace 5, Unholy Power 5, Demonic Aegis 2, Improved Voidwalker 3, Fel Vitality 3, Demonic Energies 2, Improved Sayaad 3, Demonic Sacrifice 1, Master Summoner 2, Decimation 2, Fel Domination 1, Demonic Brand 3, Improved Felhunter 3, Soul Link 1, Demonic Knowledge 3, Master Demonologist 5, Demonic Pact 1.

**Destruction** : Destructive Reach 2, Improved Shadow Bolt 5, Bane 5, Molten Skin 5, Cataclysm 3, Aftermath 5, Ruin 5, Shadowburn 1, Intensity 3, Agonizing Flames 3, Conflagrate 1, Pyroclasm 2, Bane of Havoc 1, Fire and Brimstone 3, Shadow and Flame 5, Incinerate 1.

---

## Druide

ForeverDiff : 72 sorts · 59 talents. Grimoire : 60.

### Balance

Barkskin, Entangling Roots, Faerie Fire, Hibernate, Hurricane, Insect Swarm, Moonfire, Moonkin, Nature's Grasp (entraînable), Omen of Clarity (entraînable), Soothe Animal, Starfire, Teleport: Moonglade, Thorns, Wrath.

IN : Barkskin, FF, Hurricane, IS, Moonfire, Moonkin, Starfire, Thorns, Wrath. UTIL : Roots, Hibernate, Soothe, Moonglade. Omen / Grasp : **IN Grasp**, Omen **GAP** (proc, pas un bouton de file).

### Feral

Aquatic / Bear / Cat / Dire Bear / Travel, Bash, **Berserk New** (40), Challenging Roar, Claw, Cower, Dash, Demo Roar, Enrage, Feline Grace, Feral Charge, Ferocious Bite, Frenzied Regen, Growl, **Lacerate New** (42/50/58), **Mangle New** (Forever a aussi renommé un talent *Primal Bite* selon les notes de build), Maul, Pounce, Prowl, Rake, Ravage, Rip, Shred, Swipe, Tiger's Fury, Track Humanoids.

IN : formes, Bash, Claw, Demo, Enrage, Charge, Bite, Frenzied, Growl, Maul, Prowl, Rake, Ravage, Rip, Shred, Swipe, Tiger. **GAP** : Lacerate, Mangle/Primal Bite, Berserk. UTIL : Aquatic, Travel, Dash, Cower, Pounce, Track.

### Restoration

Abolish/Cure Poison, Gift / Mark of the Wild, Healing Touch, Innervate, Nature's Swiftness, Rebirth, Regrowth, Rejuvenation, Remove Curse, **Revive New**, Swiftmend, Tranquility, **Wild Growth New**.

IN : heals, MotW, Innervate, NS, Swiftmend, Tranquility, Remove Curse. **GAP** : Wild Growth, Revive (hors combat). UTIL : Rebirth vs Revive.

### Talents (51 · 14 new · 32 changed)

**Balance** : Improved Wrath 5, Genesis 5, Moonglow 3, Improved Moonfire 2, Nature's Majesty 2, Nature's Reach 2, Improved Entangling Roots 3, Nature's Splendor 1, Insect Swarm 1, Vengeance 5, Improved Starfire 5, Overgrowth 2, Nature's Grace 1, Eclipse 3, Moonfury 5, Moonkin Form 1.

**Feral** : Ferocity 5, Heart of the Wild 5, Feral Swiftness 2, Feral Instinct 3, Brutal Impact 3, Thick Hide 3, Savage Fury 2, Feral Charge 1, Sharpened Claws 2, Shredding Attacks 3, Mangle 1, Predatory Strikes 3, Primal Fury 2, Predatory Instincts 2, Leader of the Pack 1, King of the Jungle 3, Natural Reaction 5, Rend and Tear 5, Berserk 1.

**Restoration** : Nature's Focus 5, Furor 5, Naturalist 5, Subtlety 3, Natural Shapeshifter 3, Reflection 3, Gift of Nature 5, Gift of the Earthmother 1, Tranquil Spirit 5, Improved Rejuvenation 3, Swiftmend 1, Nature's Swiftness 1, Living Spirit 3, Improved Tranquility 2, Improved Regrowth 5, Wild Growth 1.

---

## Raciaux (10 races × 4 = 40)

Source : [wowforevertalent.com/racials](https://wowforevertalent.com/racials/) (export 17 sept. 2026). 26/40 ont une ligne Classic. Ils **ne coûtent pas** de points de talent.

`ns.RACIALS` ne garde que les **actifs utiles** (ajoutés aux listes, `on = false` sauf Blood Fury / Berserking). Les passifs ne sont pas des boutons HUD.

IDs de race addon : Humain 1, Orc 2, Nain 3, Elfe de la nuit 4, Mort-vivant 5, Tauren 6, Gnome 7, Troll 8, Éolide Ordre (Alliance) 95, Éolide Sculpte-vents (Horde) 96.

### Alliance

| Race | Classes preview | Actif / passif | Forever | Addon |
| --- | --- | --- | --- | --- |
| Humain | War Hunt Mage Rog Pal Prie Lock | **Will to Survive** · instant · 3 min · casse les stuns | **New** | **GAP** |
| | | **Perception** · instant · 3 min · détection furtifs 20 s | Changé (toujours là) | **IN** `20600` |
| | | Sword Specialization · +2 % crit (épée) | Passif (Era = skill +5) | UTIL |
| | | The Human Spirit · +5 % Esprit | Passif | UTIL |
| Nain | War Hunt Rog Pal Prie **Shaman** | **Stoneform** · 3 min · bleed/poison/disease + −10 % phys 8 s | Changé (plus +armure) | **IN** `20594` |
| | | Find Treasure · minimap | | UTIL |
| | | Mace Specialization · +1 % crit (masse) | Passif | UTIL |
| | | Big Game Hunter · +5 % vs Bêtes | Passif (Era = crit fusil) | UTIL |
| Elfe de la nuit | War Hunt Rog Prie Dru | **Elune's Light** · 3 min · +10 % crit 15 s | **New** | **GAP** |
| | | **Shadowmeld** · 10 s ; en combat CD 2 min | Changé (Era hors combat) | **IN** `20580` |
| | | Quickness · +1 % esquive, +2 % vitesse, stealth +1 | Passif | UTIL |
| | | Wisp Spirit · +75 % vitesse mort | Passif (Era 50 %) | UTIL |
| Gnome | War Mage Rog Prie Lock | **Escape Artist** · 2 min · + immunité 3 s | Changé | **IN** `20589` |
| | | **Eureka!** · 2 min · 3 sorts : −coût / +10 % dmg (heal −15 % mana +10 %) | **New** | **GAP** |
| | | Expansive Mind · +5 % mana/rage/énergie | Passif (Era +5 % intel) | UTIL |
| | | Engineering Specialization · −20 % fail engi | Passif | UTIL |
| Éolide Ordre (95) | War Hunt Mage Rog Dru | **Walk on Air** · 2 min · glide 10 s | New | **exclu** (`1259416`) |
| | | **Read Ley Line** · 2 s / 2 min · regen vie+mana | | **IN** `LeyLine` `1259705` |
| | | Elemental Insight · +5 % vs élémentaires | Passif | UTIL |
| | | Wind Blessed · +1 % hâte | Passif | UTIL |

### Horde

| Race | Classes preview | Actif / passif | Forever | Addon |
| --- | --- | --- | --- | --- |
| Orc | War Hunt Mage Rog Lock Sham | **Blood Fury** · 2 min · +10 % AP et SP 15 s | Changé (Era +25 % AP, −heal) | **IN** `20572` `on=true` |
| | | **Shatter Curse** · 3 min · curse+bane + −15 % magie 8 s | **New** | **GAP** |
| | | Axe Specialization · +1 % crit (hache) | Passif | UTIL |
| | | Hardiness · −20 % durée stun | Passif | UTIL |
| Mort-vivant | War Mage Rog Prie Lock **Pal** | **Will of the Forsaken** · 2 min · charm/fear/sleep | Changé (plus d’immunité) | **IN** `7744` |
| | | **Cannibalize** · 2 min · 7 % vie **et mana** / 2 s × 10 s | Changé (Era vie seule) | **GAP** |
| | | Underwater Breathing | Passif | UTIL |
| | | Touch of the Grave · drain vie proc | **New** passif | UTIL |
| Tauren | War Hunt Dru Sham | **War Stomp** · 0,5 s / 2 min · stun 8 yd | | **IN** `20549` |
| | | Cultivation · 1 h · herbe doublée | Changé (Era +15 herbo) | UTIL |
| | | Plainsrunning · vitesse jusqu’à +30 % | **New** passif | UTIL |
| | | Endurance · +5 % vie, +1 % hit | Passif | UTIL |
| Troll | War Hunt Mage Rog Prie Lock Sham | **Berserking** · 3 min · +10 % haste 10 s | Changé (Era 10–30 % selon vie) | **IN** `20554` `on=true` |
| | | **Rapid Regeneration** · 3 min · 50 % vie / 6 s (canal) | **New** | **GAP** |
| | | Beast Slaying · +5 % vs Bêtes | Passif | UTIL |
| | | Regeneration · +10 % regen, 10 % en combat | Passif | UTIL |
| Éolide Sculpte-vents (96) | War Hunt Rog Dru Sham | **Walk on Air** | New | **exclu** |
| | | **Skysight** · 0,5 s / 2 min · +10 % vitesse 30 s (15 min près d’une convergence) | | **IN** `SkyView` `1259686` |
| | | Elemental Insight / Wind Blessed | Passifs | UTIL |

### Raciaux de prêtre (en plus des 40)

Toujours **liés à la race**, pas au talent. Fear Ward et Devouring Plague sont **baseline tous prêtres** (plus des raciaux).

| Race | Sorts | Addon |
| --- | --- | --- |
| Humain | Divine Grace (new, soin <50 %, 10 min), Feedback | **GAP** / Feedback dans le grimoire prêtre |
| Nain | Chastise (new), Desperate Prayer | **GAP** / Desperate Prayer |
| Elfe de la nuit | Elune's Grace (changé), Starshards (CD 30 s) | **GAP** (listés comme sorts prêtre) |
| Gnome | Confounding Flash, Contingency Plan | **GAP** |
| Mort-vivant | Dark Sacrifice (new), Touch of Weakness | **GAP** |
| Troll | Hex of Weakness, Shadowguard | **GAP** |

Classes preview qui ont **changé** vs Era : nain shaman, mort-vivant paladin, éolides druide, orc mage, gnome prêtre.

### À mettre dans `ns.RACIALS` (combat / défense)

| Priorité | Sort | Race | Pourquoi |
| --- | --- | --- | --- |
| 1 | Will to Survive | Humain | Casse stun — défense |
| 1 | Elune's Light | Elfe de la nuit | Burst crit 15 s |
| 1 | Eureka! | Gnome | Burst dmg/heal |
| 1 | Shatter Curse | Orc | Cleanse curse/bane |
| 2 | Rapid Regeneration | Troll | Canal heal |
| 2 | Cannibalize | Mort-vivant | Regen hors melee |
| — | Walk on Air | Éolides | Rester exclu (pas de file combat) |
| — | Find Treasure, Cultivation | Nain / Tauren | Hors rotation |

---

## Ce qu’il ne faut pas mettre dans la file

- Portails, téléports, conjurations, resurrection hors combat, pistage, lore, feed pet, pick lock/pocket.
- Passifs d’arbre (Improved X) : ils changent `opt` / CD, pas un bouton.
- Sorts de set / reliques (IDs 13xxxxx paladin) : pas des pas APL.
- Journal de combat pour les procs : toujours interdit.

## Prochaine implémentation (quand on code)

1. IDs lab des **GAP** (Wowhead Forever spell, `/dump` en jeu, ou wowforeverbuilds).
2. `ns.Spell` + `HEAL_SPELL_IDS` / `MAINTENANCE_BUFF_IDS` / `COOLDOWNS` selon le cas.
3. `step` dans `Lists.lua` (mono / AoE / burst / def).
4. Bump `listVersion` seulement si les listes sauvées doivent être remplacées.
5. Tester `Resolve` par nom : Holy Strike, Victory Rush, Lava Burst, etc.

Sources à relire si le client passe **1.60.1.70009+** : Slam / Thunder Clap / Holy Strike ont déjà bougé entre snapshots.
