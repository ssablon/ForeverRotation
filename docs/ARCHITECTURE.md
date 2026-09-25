# Architecture de WoW Forever Rot

Aide de rotation Classic Era pour le client **camelot** de WoW Forever (interface `16001`, dossier `_classic_beta_`). Le joueur appuie toujours sur les touches. L'addon propose jusqu'à 3 sorts, un rappel de défense, d'interruption, de purge, de dissipation et d'enchantement d'arme, puis pose une tête de mort sur le bouton de barre correspondant.

Lire aussi [AGENTS.md](../AGENTS.md) pour le dépôt, le chemin AddOns et la règle de push.

## Contraintes du client

Forever réutilise l'API Midnight / camelot, pas l'API Classic 1.14 seule.

- Les IDs de sorts peuvent différer du Classic public (exemple : aura de dévotion). Le code stocke des IDs de labo `1.60.1` dans `ns.Spell`, puis `ns.API.Resolve` retrouve le sort **connu du joueur** via `C_Spell.GetOverrideSpell`, `IsPlayerSpell` / `C_SpellBook`, puis le nom dans le grimoire.
- Certaines valeurs sont des *secret values*. `API.lua` et `APL.lua` passent par `issecretvalue` / `canaccessvalue` avant de lire un nombre ou une chaîne. Une valeur illisible est traitée comme absente.
- Chaque appel Blizzard est dans un `pcall`. Ne jamais remplacer `C_Spell`, `C_SpellBook`, `GetSpellInfo` ou les fonctions d'unité.
- Deux TOC obligatoires, même liste de fichiers : `WoWForeverRot.toc` et `WoWForeverRot_Camelot.toc`. Les deux portent `## Interface: 16001` et `## AllowLoadGameType: camelot`.
- SavedVariables globaux : `WoWForeverRotDB` et `WoWForeverSharedDB`.

## Cycle de vie

`Core.lua` crée une frame invisible.

Au `PLAYER_LOGIN` et `PLAYER_ENTERING_WORLD` :

1. `defaults()` complète `WoWForeverRotDB` et appelle `ns.BindProfile()`.
2. `ns.API.InvalidateSpells()` vide le cache de résolution.
3. `ns.UI.Create()` construit le HUD une seule fois (`ns.UI.root`).
4. `ns.CreateMinimap()` et `ns.GlowFetch()`.
5. `ns.Tick()`.

`ns.Tick` (timer `C_Timer` toutes les 0,2 s comme ConROC, plus cible) :

```
BuildQueue → BuildDefense → BuildInterrupt → BuildPurge → BuildCleanse → BuildWeapon
→ ns.UI.Update + glows seulement si la file a changé
→ RangeUpdate (toutes les 0,25 s) ou RangeClear
```

Chaque builder respecte son interrupteur `ns.db.show*`. `show*` absent vaut affiché (`~= false`).

`ns.API.castTarget` passe à vrai quand la cible commence un cast ou un canal, et à faux à l'arrêt, l'échec, l'interruption ou le changement de cible. `TargetCasting` s'en sert si `UnitCastingInfo` ne renvoie rien.

## Fichiers

| Fichier | Rôle |
| --- | --- |
| `Credits.lua` | Message de login partagé. Slash `/wftoc` et `/wfmsg`. N'utilise pas `ns`. |
| `Locale.lua` | Packs `enUS`, `frFR`, `deDE`, `esES`, `esMX`, `ruRU`, `zhCN`, `zhTW`, `ptBR`, `itIT`, `koKR`. `ns.T(key)` retombe sur `enUS` puis sur la clé brute. |
| `API.lua` | `ns.API` : résolution, grimoire, prêt, auras, soins, ennemis, arme. |
| `Data.lua` | IDs, rôles, couleurs, raciaux, interrupts, purges, cleanses, enchants, buffs longs, soins. |
| `Physics.lua` | Swing, clip de tir auto, tick d'énergie. Option `ns.db.showPhysics`. Pas de journal de combat. |
| `Lists.lua` | `ns.APLDefaults`, `ns.APLModes`, `ns.DefDefaults`. |
| `APL.lua` | Lecture / écriture des listes sauvegardées, fusion avec les défauts. |
| `Share.lua` | Export / import du profil actif (texte `WFR1`). |
| `UI.lua` | HUD, toolbar, positions, échelle. |
| `Options.lua` | Fenêtre d'options, éditeurs, minimap. `ns.ToggleSpellMenu = ns.ToggleOptions`. |
| `Glow.lua` | Overlays de barres et filtre de portée. |
| `Rotations.lua` | Builders de files. |
| `Core.lua` | Profils, rôles, modes, événements, slash `/wfr` et `/foreverrot`. |

Namespace : `local addonName, ns = ...`. Ne pas créer un second état global hors des SavedVariables déjà déclarés.

## Données de classe (`Data.lua`)

`ns.CLASSES` et `ns.CLASS_BY_ID` : les 9 classes Classic. Pas de DK.

`ns.CLASS_ROLES` — boutons de style du HUD :

| Classe | Rôles |
| --- | --- |
| Guerrier | `damage`, `tank` |
| Paladin | `damage`, `tank`, `heal` |
| Chasseur | `range`, `melee` |
| Voleur, mage, démoniste | `damage` |
| Prêtre | `damage`, `heal` |
| Chaman | `caster`, `melee`, `heal` |
| Druide | `hybrid`, `heal`, `tank` |

`ns.NormalizeRole` convertit un vieux `damage` chaman en `caster`, chasseur en `range`, druide en `hybrid`, sinon le premier rôle autorisé.

`ns.ActiveSpec` (dans `APL.lua`) choisit la **clé de liste**, qui n'est pas toujours le rôle HUD :

- Druide `heal` → `heal`. Druide `tank` → `bear` si forme d'ours, sinon `tank`.
- Sinon forme de félin → `cat`, forme d'ours → `bear`, sinon `damage`.
- Les autres classes : le rôle HUD tel quel.

`ns.APLDefaults.DRUID.hybrid` alias `damage`. Les défenses chasseur `range`/`melee` et chaman `caster`/`melee` alias `damage`. L'éditeur utilise `ns.SpecList` (pour le druide : `damage`, `cat`, `bear`, `heal`, `tank`).

`ns.CLASS_COLORS` est en dur. Ne pas dépendre de `RAID_CLASS_COLORS`.

`ns.RACIALS` : Perception, Furie sanguinaire, Forme de pierre, Camouflage, Volonté des Réprouvés, Choc martial, Maître de l'évasion, Berserker, Ligne tellurique (race 95, Alliance, aussi défensif), Vue céleste (race 96, Horde). Air Walk `1259416` et les passifs Éolides ne sont pas listés. Les raciaux sont ajoutés aux listes avec `on = false`.

`ns.INTERRUPTS` : guerrier 6552, voleur 1766, chaman 8042 (Horion de terre), mage 2139, prêtre 15487.

`ns.PURGES` : chaman 370, prêtre 527, mage 30449 (vol de sort, peut être absent).

`ns.CLEANSE` : dissipation **sur le joueur** seulement, par types `Magic`, `Disease`, `Poison`, `Curse`. Le mage en purge ne voit que `isStealable`. Les autres acceptent aussi `dispelName == "Magic"`.

`ns.WEAPON_BUFFS` : chaman (Furie des vents, Langue de feu, Croque-roc, Arme de givre), voleur (poisons), démoniste (pierre de feu / de sort). Chaque entrée a `key`, `id`, `duration`, parfois `ranks`, `enchants` (4e valeur de `GetWeaponEnchantInfo`) et `match` (texte de tooltip, minuscules). Les index `ns.WEAPON_BUFF_IDS` et `ns.WEAPON_ENCHANT_IDS` sont construits au chargement.

`ns.MAINTENANCE_BUFF_IDS` : buffs > 1 min, auras, aspects, bénédictions, armures, cri de guerre, etc. Défense uniquement.

`ns.HEAL_SPELL_IDS` : soins et HoT, y compris des IDs de rangs. Un soin n'est pas bloqué par une cible hostile.

## Listes par défaut (`Lists.lua`)

Un pas est `{ key, id, opt, on = true }`, créé par `step(key, id, opt)`.

- `ns.APLDefaults[classe][spec]` : liste mono, aussi utilisée par le mode `auto`.
- `ns.APLModes[classe][spec].aoe` et `.burst` : variantes. S'il n'y a pas de variante, `defaultsFor` retombe sur `APLDefaults`.
- `ns.DefDefaults[classe][spec]` : buffs longs et boutons d'urgence (`hp` bas).

À la fin du fichier, `stripMaintFromApl` retire de `APLDefaults` et `APLModes` tout pas dont l'ID est dans `MAINTENANCE_BUFF_IDS`. Ajouter un buff long seulement dans `DefDefaults` et dans `MAINTENANCE_BUFF_IDS`.

Les listes viennent d'un noyau Era type ConROC Classic, niveaux 1–60. Pas de SoD ni de sorts Midnight.

## Options d'un pas (`opt`)

Évaluées par `ns.API.StepOk` dans l'ordre. Un champ absent est ignoré.

| Champ | Effet |
| --- | --- |
| `role` | Le pas est ignoré si `ns.db.role` diffère. Testé dans `Rotations.stepReady`, pas dans `StepOk`. |
| `hostile` | Exige `ns.API.Hostile()` (cible vivante, réaction ≤ 4). Réaction illisible = hostile. |
| `heal` | Force le traitement soin (`IsHelpful` / `IsHealSpell`). |
| `hp` | Vie en pourcentage, strictement `>` pour refuser. Cible : `opt.unit`, sinon l'allié à soigner si le sort est utile, sinon le joueur. |
| *(soin sans `hp`)* | Seuil implicite **99**. |
| `unit` | Unité forcée pour `hp` (`"target"`, `"pet"`, …). |
| `nobuff` | Refus si cette aura utile est déjà sur l'unité de soin, ou sur le joueur. L'aura est le sort lui-même. |
| `nodebuff` | `true` = le sort ne doit pas déjà être un débuff sur la cible. Un ID = cet autre débuff ne doit pas être présent (`WeakenedSoul` du mot de pouvoir : Bouclier). |
| `anybuff` | Liste d'IDs. Si le joueur a **l'un** d'eux, le pas est refusé. Sert aux sceaux, auras, aspects, armures exclusifs. |
| `form` | Exige l'aura de forme sur le joueur (`ns.API.Form`). |
| `noform` | Refus si cette forme est active. |
| `combat` | Exige le joueur en combat. |
| `comboMin` | Points de combo joueur/cible minimum. |
| `pet` / `nopet` | Familier présent ou absent. |
| `ready = false` | Accepte le pas sans tester le cooldown ni l'utilisabilité. |
| `filler` | Sort de spam sans temps de recharge propre (Colère, Frappe héroïque, Attaque pernicieuse…). Ignoré seulement par un vrai cooldown, pas par le GCD. `ns.Physics.Blocks` s'applique quand même. |
| `nocombat` | Refus si le joueur est en combat (Charge, Camouflage, Proie). |
| `needbuff` | ID d'aura utile exigée sur le joueur (Garrot et Embuscade exigent Camouflage). |
| `needdebuff` | ID de débuff exigé sur la cible (Conflagration exige Immolation). |
| `proc` | Le client doit répondre que le sort est utilisable. Sert à Fulgurance, Revanche, Riposte, Contre-attaque et Morsure de la mangouste. Si la réponse est masquée, le pas est sauté. Ne pas lire le journal de combat : cet appel est réservé à l'interface Blizzard et bloque l'addon. |
| `usable` | Le client doit répondre que le sort est utilisable (Exorcisme, Colère divine, Attaque sournoise dans le dos). Si la réponse est masquée, le pas est sauté. |
| `manaMax` | Refus si le pourcentage de mana du joueur est au-dessus de ce seuil (Connexion). |
| `hpMin` | Refus si la vie (joueur, ou `unit`) est sous ce pourcentage. |
| `require` / `requireAny` | Le sort (ou l'un des sorts) doit être connu. Sert à choisir Éclair de givre ou Projectiles des arcanes selon les talents. |
| `anydebuff` | Liste d'IDs. Si la cible a **l'un** d'eux, le pas est refusé. Une seule piqûre, une seule malédiction. |

`ns.API.Ready` : sort résolu, pas de cooldown propre en cours, pas de `noMana`. Le GCD (environ 1,5 s) ne retire pas le sort de la file : il reste le prochain bouton à presser. Un cooldown plus long (Jugement, Horion, Visée, Déflagration…) le retire jusqu'à la fin, et le pas suivant de la liste est testé. Ça vaut pour toutes les classes, les raciaux et la défense.

Le client camelot masque souvent `GetSpellCooldown` en combat. Au lancement réussi, `ns.API.NoteSpellCast` démarre le temps de recharge de base du sort (`GetSpellBaseCooldown`, sinon `ns.COOLDOWNS`). Les trois horions du chaman partagent ce temps (`ns.COOLDOWN_GROUPS`). Un proc qui rend le sort disponible plus tôt peut attendre la fin de ce délai, parce que le jeu ne laisse pas lire le temps restant.

Fulgurance, Revanche, Riposte, Contre-attaque et Morsure de la mangouste (`opt.proc`) ne sont proposés que si `IsSpellUsable` répond vrai. Une réponse masquée saute le pas. Le journal de combat n'est pas lu.

`Physics.lua` (option Extra `showPhysics`, défaut vrai) : coups blancs pour **toutes** les classes via `PLAYER_ENTER_COMBAT` / `UNIT_ATTACK` + `UnitAttackSpeed` (main + main gauche si dual wield). La fenêtre next-swing (Frappe héroïque, Enchaînement, Attaque du raptor, Mutiler) lit seulement la main droite. `UNIT_SPELLCAST_SUCCEEDED` + Auto Shot 75 pour le clip chasseur ; `UNIT_POWER_UPDATE` pour le tick d'énergie 2 s. Sans swing observé, le next-swing n'est pas caché. Pas de `CombatLogGetCurrentEventInfo`. `UNIT_ATTACK` ne relance que la main dont le timer est échu ; un changement de vitesse recale la progression. La jauge réserve la place de trois barres (main droite, main gauche, énergie ou tir) sous les icônes. `showPhysics` à faux masque la jauge et rend cette place.

Un sort seulement utile (`IsHelpful` et pas `IsHarmful`) peut passer via le coût de puissance si `IsSpellUsable` est faux ou absent. Un sort nuisible avec `usable == false` est refusé.

`ns.API.Add` empile au plus 3 IDs **déjà résolus**, sans doublon, et seulement si `StepOk`.

## Files (`Rotations.lua`)

`ns.BuildQueue` parcourt `ns.GetAPL()` :

- ignore un pas décoché, un enchant d'arme, un buff de maintenance, et (si `barOnly`) un sort absent des barres déjà indexées par GlowFetch ;
- sépare les soins ;
- `API.Add` pour chaque autre pas ;
- si aucun soin n'est entré dans les 3 cases, le premier soin `StepOk` est inséré en tête et la file est recoupée à 3.

`ns.queueHeal[id]` (ID de liste et ID résolu) sert au surlignage vert.

`ns.BuildDefense` : premier pas défense coché et `StepOk`.

`ns.BuildInterrupt` : ID de classe connu et prêt, cible hostile qui cast.

`ns.BuildPurge` : ID de classe prêt, cible hostile, aura purgeable.

`ns.BuildCleanse` : première entrée **connue et prête** dont `entry.types` matche un débuff sur le joueur, ou sur le groupe si `cleanseGroup ~= false`. Un guerrier / chasseur sans table `CLEANSE` n'affiche rien. Un mage ne voit que les malédictions, un prêtre maladie / magie seulement s'il a le sort, etc. Unité non alliée ignorée.

`ns.BuildWeapon` renvoie `spellID, remain, need`.

1. Enchant choisi : `ns.db.weaponBuff`, sinon le premier connu, sinon le premier de la liste.
2. Présent si l'aura du buff est sur le joueur, si une main a un enchant temporaire (même si l'ID Forever n'est pas dans la liste), ou si le tooltip de l'arme contient le nom. Un ID connu d'un autre buff ne compte pas.
3. Absent seulement si les deux mains répondent « pas d'enchant », sans aura et sans tooltip : rappel rouge tout de suite. `has == false` seul ne suffit pas, Forever expose souvent le buff par l'aura ou le tooltip.
4. Réponse illisible : 5 s de grâce après le lancement, sinon la dernière expiration vue, sinon rappel rouge. Changer d'arme efface la mémoire. Pas de mémorisation de 30 ou 60 minutes après le lancement.

## Fusion des listes (`APL.lua`)

Clés de sauvegarde : `ns.db.apl[CLASS][spec][mode]` et `ns.db.def[CLASS][spec]`.

Un seau de modes est une table avec `auto` / `single` / `aoe` / `burst` et **sans** index `[1]`. Une ancienne liste plate (index `[1]`) est migrée en `{ single = legacy }` à la première écriture (`ensureModeBucket`). En lecture, une liste plate ne compte que pour le mode `single`.

`ns.GetAPL(class, spec, mode)` :

- mode explicite, sinon `ns.ResolveCombatMode()` ;
- `auto` et `single` lisent `APLDefaults` ;
- `aoe` et `burst` lisent `APLModes`, sinon le défaut mono ;
- les raciaux sont ajoutés à la fin, décochés ;
- sans sauvegarde ni retrait, les défauts sont renvoyés tels quels ;
- sinon `mergeSteps(..., skipMaint = true)` : l'ordre sauvegardé gagne, les pas par défaut nouveaux sont ajoutés s'ils ne sont pas dans `aplDrop` et pas déjà présents (même ID ou même nom).

Retirer un pas non `custom_*` écrit sa clé dans `aplDrop` / `defDrop`, pour qu'un défaut ne revienne pas. `custom_` vient du nom du sort (`custom_` + nom sans espaces).

`packRows` ne sauve que `{ key, on = 1|0, id si custom, custom }`. Les `opt` des sorts par défaut restent dans `Lists.lua`. Un sort custom utile reçoit `opt.heal = true` à l'ajout et à la fusion. Un sort custom de défense reçoit `opt.combat = true`.

`ns.AddAPL` refuse un buff de maintenance. `ns.DropSpellOnList` envoie ces sorts vers `ns.AddDef`. Les noms `TEST`, `(OLD)`, `(PT)` ne sortent pas de `ns.API.CursorSpell`.

Modes de combat (`ns.COMBAT_MODES`) : `auto`, `single`, `aoe`, `burst`.

- `ns.CombatMode()` est le choix du joueur.
- `ns.ResolveCombatMode()` : si `auto` et `EnemyCount() >= autoEnemies` (plancher 2), renvoie `aoe`, sinon `auto`.
- `ns.SetCombatMode` mémorise le dernier mode manuel dans `lastManualMode` (jamais `auto`).
- `ns.ToggleAuto` bascule entre `auto` et `lastManualMode`.
- `EnemyCount` compte les nameplates hostiles. Hors combat joueur, tout nameplate hostile compte ; en combat, seulement ceux en combat. Sans nameplate, une cible hostile vaut 1. Les nameplates doivent être activés pour l'AoE auto.

`ns.CoerceChecked` n'accepte que `true`, `1`, `"1"`. `ns.IsStepEnabled` refuse `false`, `0`, `"0"`.

## Profils (`Core.lua`)

`ns.PROFILE_ORDER = { "base", "pve", "pvp", "custom" }`.

Le profil actif est recopié dans `ns.db.profiles[key]` par `FlushProfile` (changement de profil, options, logout) et rechargé par `BindProfile`. Champs de profil : `apl`, `aplDrop`, `def`, `defDrop`, `role`, `combatMode`, `lastManualMode`, `autoEnemies`, `weaponBuff`.

`ns.ResetCurrentProfile` vide ces listes pour le profil courant, remet `autoEnemies = 3`, `lastManualMode = single`, `combatMode = auto`, rôle normalisé. Les autres profils restent. `ns.ResetAll` appelle la même fonction.

Migrations dans `defaults()` :

- `uiVersion ~= 6` : oublie les positions `toolbar` et `defense`.
- `listVersion ~= 4` : efface `apl`, `aplDrop`, `def`, `defDrop` globaux **et** ceux de chaque profil.

Bumper `listVersion` seulement quand les anciennes sauvegardes doivent être jetées. Les joueurs perdent alors leurs réordonnancements.

Autres défauts : `glow`, `showRotation`, `showDefense`, `showInterrupt`, `showPurge`, `showCleanse`, `showWeapon`, `showRange`, `showModes` à vrai ; `uiScale` 1 (borné 0,6–2, pas de 0,1) ; `role` `damage` puis normalisé ; `autoEnemies` 3 ; `combatMode` `auto` ; profil initial `pve` si la table `profiles` n'existe pas.

## Interface

HUD (`UI.lua`), ancré sur `WoWForeverRotFrame` :

- 3 icônes de file (la première plus grande). Positions sauvées sous `ns.db.pos.queue`. Jauge physique sous la file si `showPhysics`.
- Interruption (`pos.interrupt`) et purge (`pos.purge`) à gauche, dissipation (`pos.cleanse`) et arme (`pos.weapon`) à droite. Chaque icône se déplace toute seule.
- Cadenas (`pos.lock`) sous la file. Clic gauche verrouille ou déverrouille. Les options s'ouvrent par `/wfr options` ou le clic gauche du bouton minimap.
- Toolbar (`pos.toolbar`) : poignée à gauche, rôle, Auto, mode manuel, profil. Glisser la poignée ou un bouton. Couleur de classe. Son chrome n'est pas modifié.
- Défense (`pos.defense`) sous la toolbar.
- File, défense, interrupt, purge, cleanse, arme et cadenas partagent le chrome de la toolbar (fond ChatFrame, bord tooltip, couleur de classe).
- Échelle appliquée à root, toolbar, interrupt, purge, cleanse, weapon, defense, lockWrap.

`/wfr reset` et le bouton d'options effacent `ns.db.pos`.

Verrouillé : le fond est plus transparent, le drag est ignoré, et la souris traverse les fenêtres. Le cadenas reste cliquable et a un tooltip (`ns.db.locked`).

`hideIdle` (défaut vrai) : masque file, défense, interrupt, purge, cleanse et arme si le joueur est mort, en taxi, monté, en train de manger / boire, ou au repos (ville / auberge) hors combat. Toolbar et cadenas restent.

Les icônes HUD affichent le binding de barre (`ns.SpellBinding`) déjà connu par GlowFetch.

Options (`WoWForeverRotOptions`, 500×560, dans `UISpecialFrames`) :

- onglets Général / Rotation / Défense / Extra ;
- boutons de profil Base, JCE (`pve`), JCJ (`pvp`), Customs ;
- cases des `show*` , glow, portée, sélecteur de modes ;
- choix d'enchant, échelle, seuil AoE (2–8), reset position, reset du profil ;
- éditeur : specs de `SpecList`, modes `auto/single/aoe/burst`, cases, monter, descendre, retirer, zone de drop.

Minimap : angle `ns.db.minimapAngle` (défaut 210). Clic gauche options, clic droit verrou, drag pour tourner autour de la minimap.

Textures dans `images/` : `skull`, éclairs, cercle de purge, cadenas, boutons, rôles, `minimap.tga`, `logo.tga` (icône du gestionnaire d'addons, logo officiel). Le bouton minimap est créé dans `Options.lua`.

## Surlignage (`Glow.lua`)

`ns.GlowFetch` (au plus toutes les 2 s, ou forcé) scanne :

- `ActionButton1-12`, `MultiBarBottomLeft/BottomRight/Right/Left`, `MultiBar5-7` ;
- `StanceButton` ;
- Dominos `DominosActionButton1-132` si chargé ;
- Bartender4 `BT4Button1-180` ;
- ElvUI `ElvUI_Bar1-10Button1-12`.

Association par ID, par nom, et par `C_ActionBar.FindSpellActionButtons` croisé avec le slot du bouton. Les macros passent par `GetMacroSpell`.

Overlays `button.WFROverlays`, blend `ADD`, tête de mort :

| Clé | Couleur | Déclencheur |
| --- | --- | --- |
| `next` | blanc | premier sort de la file, pas un soin |
| `heal` | vert | soin (`queueHeal` ou `IsHealSpell`) |
| `def` | bleu, ou vert si soin | défense |
| `kick` | icône éclair | interruption |
| `purge` | icône cercle | purge |
| `cleanse` | vert | dissipation |
| `weapon` | rouge | enchant à refaire |

`ns.db.glow == false` coupe les têtes de mort de rotation et de défense. Interrupt, purge, cleanse et arme ont leur propre `Glow*` appelé depuis `Tick` sans retester `glow` dans ces fonctions : ils suivent surtout `showInterrupt` / `showPurge` / `showCleanse` / `showWeapon`, qui court-circuitent le builder.

`ns.RangeUpdate` teinte en rouge les boutons **de la barre de sorts** déjà connus (`rangeButtons` rempli par GlowFetch, pas un second scan). Le HUD (file, défense, interrupt, purge) utilise le même `ns.SpellInRange`. Soins : `HealRangeUnit`. Coupé par `showRange == false`.

## Résolution d'un sort

`ns.API.Resolve(spellID)` cache dans `resolveCache` (vidé par `InvalidateSpells` au login, `LEARNED_SPELL_IN_TAB`, `PLAYER_TALENT_UPDATE`). `SPELLS_CHANGED` est ignoré : le client camelot le déclenche trop souvent.

1. Override `C_Spell.GetOverrideSpell` si c'est un nombre lisible.
2. Si le joueur connaît cet ID, le garder.
3. Sinon l'ID d'origine s'il est connu.
4. Sinon ID obtenu par le nom (`C_Spell.GetSpellInfo` ou `GetSpellInfo`), s'il est connu.
5. Sinon parcours du grimoire (`GetSpellBookSkillLineInfo`, puis index 1–400, banques player/pet/`spell`/`0`/`1`).
6. Cache `false` si rien. `Known` est « Resolve ≠ nil ».

`CursorSpell` lit `GetCursorInfo`. Il exige un type `spell` ou `spellid` lorsqu'un type est présent, puis retrouve le sort du grimoire par nom. Un ID curseur dont le joueur ne connaît pas le nom est rejeté.

Auras : `C_UnitAuras.GetPlayerAuraBySpellID` pour le joueur, puis `GetAuraDataBySpellName`, sinon `GetAuraDataByIndex` jusqu'à 40. Comparaison par ID résolu, nom normalisé (sans « Rang »), ou famille (`sceau` / `seal`, bénédiction, aura, aspect, armure).

Un buff perso (`nobuff` sans `heal`) est toujours lu sur le joueur. Le sceau est un buff utile : le chercher sur la cible hostile le fait réapparaître dans la file.

Sur le client camelot, choisir une cible peut rendre les auras illisibles (*secret values*). Une lecture qui échoue n'est pas une absence. Le sceau est retenu **30 secondes** après le lancement (durée Classic), puis il est à nouveau proposé même en combat. Les bénédictions durent 5 minutes dans cette mémoire, les auras et aspects 30 minutes, sauf si le jeu donne une durée réelle plus courte. Les soins (`opt.heal`) continuent de regarder l'allié à soigner.

La file imite ConROC : le 1er sort est celui qui est lançable maintenant, le 2e celui du prochain GCD, le 3e celui d'après. Un sort hors liste ne coupe pas la suggestion : au tick suivant, la priorité est recalculée. Le HUD se met à jour toutes les 0,05 s.

Soins — unité : `opt.unit` s'il existe, sinon `mouseover`, `target`, `focus`, `targettarget`, sinon `player`. `HealHealth` utilise `LowestFriendly` (joueur, mouseover, target, focus, targettarget, pet, party1–4) quand aucun de mouseover/target/focus n'est allié. Unité morte ou attaquable = pas alliée.

## Commandes

`/wfr` ou `/foreverrot` :

| Argument | Action |
| --- | --- |
| *(vide)* | aide (`ns.T("HELP")`) |
| `lock` / `unlock` | `ns.UI.SetLocked` |
| `reset` | oublie `pos` et `point` |
| `resetall` | popup puis reset du profil actif |
| `role` | cycle `CLASS_ROLES` |
| `mode` | cycle `single` → `aoe` → `burst` (sort de `auto`) |
| `profile` | cycle base → pve → pvp → custom |
| `base` | profil `base` |
| `jce` ou `pve` | profil `pve` |
| `jcj` ou `pvp` | profil `pvp` |
| `custom` ou `customs` | profil `custom` |
| `menu` / `options` / `opt` | `ns.ToggleOptions` |

`/wftoc on|off` (aussi `/wfmsg`) : `WoWForeverSharedDB.loginMessage`. C'est partagé avec les autres addons WoW Forever. Ne pas dupliquer ce bloc.

## Schéma `WoWForeverRotDB`

```
uiVersion            = 6
listVersion          = 4
profile              = "base" | "pve" | "pvp" | "custom"
locked               = bool
glow, showRotation, showDefense, showInterrupt, showPurge,
showCleanse, showWeapon, showRange, showModes
hideIdle, barOnly, autoProfile, cleanseGroup, showPhysics
soundVolume          = 0 .. 100
colors.next / heal / def / weapon / range
uiScale              = 0.6 .. 2
role, combatMode, lastManualMode, autoEnemies, weaponBuff
apl, aplDrop, def, defDrop     -- miroir du profil actif
profiles[key]        -- même champs de liste + role/mode/arme
pos.queue / pos.toolbar / pos.defense
pos.interrupt / pos.purge / pos.cleanse / pos.weapon / pos.lock
  = { point, relativePoint, x, y }  -- 2e valeur = nom de l'ancre, aujourd'hui UIParent via GetPoint
minimapAngle
```

`WoWForeverSharedDB` : `{ loginMessage = true|false }`.

## Ajouter un sort

1. ID dans `ns.Spell.<Classe>` (`Data.lua`).
2. Si soin ou HoT : `ns.HEAL_SPELL_IDS`, y compris les rangs utiles.
3. Si buff long ou aura : `ns.MAINTENANCE_BUFF_IDS` et un `step` dans `DefDefaults` seulement.
4. Sinon un `step` dans `APLDefaults`, et dans `APLModes` si l'AoE ou le burst diffère.
5. Enchant d'arme : entrée `WEAPON_BUFFS` (rangs, IDs d'enchant, tokens). Pas de pas de combat.
6. Interrupt / purge / cleanse : les tables dédiées, pas la file.
7. Texte nouveau : toutes les locales de `Locale.lua`, au minimum `enUS` (les autres héritent via le métatable).
8. Version dans les deux TOC.
9. Bumper `listVersion` seulement si les sauvegardes actuelles doivent être invalidées.

Vérifier en jeu : `/reload`, sort coché, sort décoché, sort retiré (il ne doit pas revenir), profil voisin intact, cible pleine vie (pas de soin), vie basse (soin en tête), nameplates pour l'auto AoE.

## Ce qu'il ne faut pas faire

- Recopier le dossier AddOns par-dessus le dépôt.
- Patcher une API Blizzard pour « aider » la détection.
- Comparer seulement des IDs bruts sans `Resolve` ou sans le nom.
- Mettre un buff de `MAINTENANCE_BUFF_IDS` dans la rotation.
- Changer `packRows` sans lire les anciennes sauvegardes (`on` numérique, liste plate d'avant les modes).
- Oublier le second TOC ou n'incrémenter qu'une version.
- Dissiper le raid : `BuildCleanse` ne regarde que `player`.
- Supposer que `hybrid`, `range` ou `caster` sont les clés stockées pour toutes les listes. Voir `ActiveSpec` et les alias en bas de `Lists.lua`.
