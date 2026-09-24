# WoW Forever Rot

Rotation helper for **WoW Forever** (Classic Era combat on the camelot / Midnight-family client, interface `16001`).

It shows the next abilities on a small HUD and flashes the matching action-bar buttons. It does **not** cast spells for you.

Author: [Vohnka](https://wow-forever.fr) · Current version: **1.5.19**

Player-facing text is translated for `enUS`, `frFR`, `deDE`, `esES`, `esMX`, `ruRU`, `zhCN`, `zhTW`, `ptBR`, `itIT`, and `koKR`. Missing strings fall back to English.

## Requirements

- WoW Forever Classic client (`_classic_beta_`, camelot)
- Interface version `16001`
- All nine Classic classes: Warrior, Paladin, Hunter, Rogue, Priest, Shaman, Mage, Warlock, Druid

Forever uses its own spell IDs for some abilities (for example Devotion Aura). The addon resolves spells by **name + spellbook**, so ranks and remapped IDs still match.

## Install

1. Copy the `WoWForeverRot` folder into:

   `World of Warcraft\_classic_beta_\Interface\AddOns\WoWForeverRot`

2. Restart the client or type `/reload`.
3. Enable **WoW Forever Rot** in the add-on list.

The folder must contain both `.toc` files, the `.lua` files, and the `images/` directory.

The CurseForge app often installs into official Classic. On Forever, unzip by hand into `_classic_beta_`.

## What it does

| Surface | Role |
| --- | --- |
| **Rotation HUD** | Next 3 combat abilities from your checked list |
| **Defense** | Missing long buffs / auras, plus emergency buttons when health is low |
| **Weapon** | Missing weapon imbue (shaman / rogue poisons, etc.) |
| **Interrupt / Purge / Cleanse** | Target interrupt, enemy magic purge, dispellable debuffs |
| **Spellflash** | Skull overlay on the action-bar button |
| **Classic timing** | White-hit swing (main + off-hand), hunter auto-shot clip, energy tick |

### Spellflash colors

| Color | Meaning |
| --- | --- |
| White skull | Next damage / utility spell |
| Green skull | Heal (only when someone actually needs healing) |
| Blue skull | Defense buff |
| Red skull | Weapon imbue |
| Red bar tint | Out of range (action bars only, not the HUD) |

### Combat list vs defense

- **Rotation** = short combat spells (strikes, shocks, heals, judgements…).
- **Defense** = buffs that last more than one minute, auras, and long self-buffs (Blessing of Might, Devotion Aura, Mark of the Wild, Inner Fire, aspects, Battle Shout, armors…). Those never enter the combat queue.
- Unchecked spells stay in the editor but are ignored in combat.
- Custom spells are added from the cursor (spellbook drag). Test / OLD spells are rejected.

### Heals

Heals are suggested from the **friendly unit that needs them** (mouseover, friendly target, then you / party if you are attacking a mob).

Examples (paladin):

- Holy Shock / Holy Light around **80%**
- Flash of Light around **70%**
- Lay on Hands around **20%**

Full health → no heal suggestion, damage rotation stays visible. Same idea for Priest, Shaman, and Druid (fast heal vs big heal vs HoT).

### Profiles

Four profiles, all saved independently:

| Profile | Slash | Typical use |
| --- | --- | --- |
| Base | `/wfr base` | Default / shared |
| PvE | `/wfr jce` or `/wfr pve` | PvE |
| PvP | `/wfr jcj` or `/wfr pvp` | PvP |
| Customs | `/wfr custom` | Experiments |

Switch from the options window or the class-colored HUD button. **Reset** only wipes the **selected** profile. You can export / import a profile as text. Optional auto-switch uses PvE or PvP from the instance type.

### Combat modes

`Auto` / `Single` / `AoE` / `Burst`. Add, remove, and reorder are **per mode**. Auto uses the single-target list until enough enemies are nearby (default: 3).

### Roles

Per class: damage, tank, heal, and the extra Classic styles (hunter range/melee, shaman caster/melee, druid hybrid / cat / bear). The HUD role button cycles the styles that exist for your class.

### Extra options

- Hide the HUD when dead, mounted, eating, or in town
- Only suggest spells that are on your action bars
- Auto PvE / PvP profile
- Group dispel limited to types your class can remove
- Classic combat timing (white hits, dual wield, auto-shot, energy)
- Overlay colors and alert volume

## Slash commands

`/wfr` or `/foreverrot`

| Command | Action |
| --- | --- |
| *(no argument)* | Print help |
| `lock` / `unlock` | Lock or move the HUD |
| `reset` | Reset HUD positions |
| `resetall` | Reset the **current** profile lists |
| `role` | Cycle playstyle |
| `mode` | Cycle combat mode |
| `profile` | Cycle profile |
| `base` / `jce` / `jcj` / `custom` | Jump to that profile |
| `menu` / `options` | Open the configuration window |

Open options with `/wfr options` or a left-click on the minimap button. Right-click the minimap button to lock or unlock the windows.

When locked, the mouse clicks through the HUD. The padlock stays clickable.

## Files

```
WoWForeverRot.toc              # standard load
WoWForeverRot_Camelot.toc      # camelot / Forever load
Credits.lua
Locale.lua                     # enUS + 10 locales
API.lua                        # spell resolve, auras, ready, heals
Data.lua                       # IDs, racials, interrupts, cleanse
Physics.lua                    # swing / auto-shot / energy timing
Lists.lua                      # default APLs and defense lists
APL.lua                        # saved lists, merge, add/remove
Share.lua                      # profile import / export
UI.lua                         # HUD
Options.lua                    # configuration
Glow.lua                       # action-bar skull flash
Rotations.lua                  # queue builders
Core.lua                       # profiles, events, slash
images/                        # skull, roles, lock, minimap
```

Saved variables: `WoWForeverRotDB`, `WoWForeverSharedDB` (credit line shared with other WoW Forever add-ons).

## Notes

- This is a **helper**, not a bot. You still press the keys.
- Racials appear in the editor (off by default). Air Walk is never put in the combat list.
- Do not overwrite Blizzard spell APIs from other add-ons; this one reads `C_Spell` / `C_SpellBook` and never patches them.

## For agents and contributors

The player guide above is not the implementation map. Before changing code, read [AGENTS.md](AGENTS.md) and [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

The git repository is the source of truth. The copy under `World of Warcraft\_classic_beta_\Interface\AddOns\WoWForeverRot` must be refreshed from this repo. Do not replace this repo with files taken from the game folder.

## License

Private repository. © Vohnka / [wow-forever.fr](https://wow-forever.fr). All rights reserved.
