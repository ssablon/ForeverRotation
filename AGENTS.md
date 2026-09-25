# WoW Forever Rot — guide agent

Addon d'aide à la rotation pour **WoW Forever** (combat Classic Era, client camelot, interface `16001`). Il affiche les prochains sorts et surligne les boutons. Il ne lance aucun sort.

Version actuelle : **1.5.32**. Auteur : Vohnka — https://wow-forever.fr  
Dépôt : https://github.com/ssablon/WoWForeverRot (privé, branche `main`).

La carte complète du code est dans [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md). Ce fichier dit seulement par où commencer.

## Source de vérité

Éditer **ce dépôt**. La copie jouée est :

`C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\WoWForeverRot`

Si les deux divergent, le dépôt gagne : recopier le dépôt vers AddOns. Ne pas écraser GitHub avec le dossier du jeu. Le guide joueur est `README.md` (anglais uniquement).

Après chaque changement demandé : bumper `VERSION.txt` + les deux TOC, recopier vers AddOns, commiter, `git push origin HEAD`, puis publier le zip sur CurseForge (projet `1708963`). Voir `.cursor/rules/publish-curseforge.mdc`.

## Ordre de chargement

Les deux TOC chargent les mêmes fichiers, dans cet ordre :

`Credits.lua` → `Locale.lua` → `API.lua` → `Data.lua` → `Physics.lua` → `Lists.lua` → `APL.lua` → `Share.lua` → `UI.lua` → `Options.lua` → `Glow.lua` → `Rotations.lua` → `Core.lua`

Tout l'état partagé vit dans la table `ns` (deuxième valeur de `...`). `Core.lua` démarre un `C_Timer.NewTicker(0.2)` comme ConROC (`interval = 0.20`). Pas d'`OnUpdate` sur tout le HUD : seulement la jauge physique (50 ms) si `showPhysics` est actif.

## Où modifier quoi

| Besoin | Fichier |
| --- | --- |
| Nouveau sort, racial, interrupt, purge, cleanse, enchant d'arme | `Data.lua` (`ns.Spell`, puis les tables dérivées) |
| Ordre par défaut mono / AoE / burst / défense | `Lists.lua` |
| Sauvegarde, fusion, ajout, retrait d'un sort | `APL.lua` |
| Import / export de profil | `Share.lua` |
| Conditions « le sort est proposé » | `API.lua` (`StepOk`, `Ready`, `Resolve`) |
| Timing Classic (swing, tir auto, énergie) | `Physics.lua` (`ns.db.showPhysics`) |
| File HUD, défense, interrupt, arme | `Rotations.lua` |
| Fenêtres, toolbar | `UI.lua` |
| Options, glisser un sort | `Options.lua` |
| Tête de mort sur les barres | `Glow.lua` |
| Profils, slash, migrations | `Core.lua` |
| Texte joueur | `Locale.lua` (`ns.T`) |

## Pièges qui cassent Forever

- Résoudre un sort par **nom + grimoire** (`ns.API.Resolve`). Un ID Classic peut être remappé.
- Rejeter les noms `TEST`, `(OLD)`, `(PT)` (`junkSpellName`).
- Les buffs de `ns.MAINTENANCE_BUFF_IDS` sont retirés des listes de combat au chargement (`stripMaintFromApl`) et refusés par `AddAPL`.
- Un sort avec un temps de recharge propre ne reste pas affiché : `NoteSpellCast` le retire jusqu'à la fin du CD, puis le pas suivant est testé. Le GCD ne compte pas. Ne pas court-circuiter `ns.API.Cooldown` avec `filler`. `filler` reste bloqué par `ns.Physics.Blocks` (Frappe héroïque hors fenêtre de swing, Aimed/Multi pendant le clip).
- Fulgurance, Revanche, Riposte, Contre-attaque et Morsure de la mangouste utilisent `opt.proc` (`IsSpellUsable` vrai). Ne pas appeler `CombatLogGetCurrentEventInfo` : le client bloque l'addon.
- `listVersion` est à 4 : au prochain login les listes sauvées sont remplacées par l'ordre ConROC Classic.
- Le mode `auto` utilise la liste mono (`APLDefaults`) tant que `ns.API.EnemyCount()` est sous `autoEnemies` (défaut 3, minimum 2). Au-dessus, il utilise la liste `aoe`.
- Le bouton HUD druide `hybrid` n'est pas une clé de liste. `ns.ActiveSpec()` choisit `cat`, `bear`, `heal`, `tank` ou `damage`.
- `ns.ResetCurrentProfile` n'efface que le profil actif (`base`, `pve`, `pvp`, `custom`).
- Incrémenter la version dans **les deux** TOC.
