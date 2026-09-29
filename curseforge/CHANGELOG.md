# 1.5.72

## Open source — development by Vohnka has stopped

Active development of Forever Rotation by the original author has ended. The GitHub repository is now **public** under the **MIT** license so anyone can fork it, fix bugs, and keep improving the addon for Forever.

### What changed for players
- Info → Links now includes **GitHub** next to Website, Discord, and CurseForge.
- About / support text states that maintenance by Vohnka has stopped and that forks are welcome.
- CurseForge description and project source point to https://github.com/ssablon/ForeverRotation.

### What did not change
- Rotation logic, holds, profiles, and HUD behaviour from **1.5.71** are unchanged in this build aside from the Info texts and links.
- The addon still never casts for you and still never reads the combat log.

---

# 1.5.71

## Range-aware suggestions + smoother feel (all classes)

Slot 1 prefers spells you can actually reach: melee abilities stay out of the press slot when the target is clearly far, and long-range shots can still win when Forever’s range flag is wrong or hidden. Hunter and Shaman auto melee/ranged role uses the same distance band first, so at range you get the ranged list (Aimed / Multi / Arcane…), not stuck melee. Clicking the HUD role button still turns auto off — chat tells you, and Extra turns it back on.

Aura storms no longer force a full rotation rebuild every tick (player/target/focus/mouseover wipe only; the 0.2 s ticker rebuilds). Auto role no longer writes SavedVariables mid-fight. Action-bar range tint and physics/cast gauges refresh a bit less often. Holds, profiles, and list order are unchanged. No combat log — Forever-safe.

---

# 1.5.70

## Forever Rotation 1.5.70 — release since 1.5.64

This CurseForge build includes every change from **1.5.65** through **1.5.70**. It is built for **WoW Forever** (Classic Era / camelot). The addon still never casts for you and still never reads the combat log.

### Stability (1.5.68 → 1.5.70)
- **Load fix (1.5.70):** a creature-type table used bare Unicode identifiers that WoW Lua rejects, so the addon failed to load, suggested nothing, and flooded Lua errors. Locale keys are quoted — reload and the HUD works again.
- **No freeze on level-up / quest turn-in / learning a spell (1.5.68–1.5.69):** Forever fires heavy spell/bar update storms on rewards. The addon no longer wipes known spell resolves or walks the whole spellbook/tooltips in one frame. Learn and level-up only soft-clear failed lookups and remap action bars after a short delay (about 0.5 s). **New ranks still appear without `/reload`.**

### Per-target DoTs and marks (1.5.65 → 1.5.66)
- Harmful re-suggest delays (**hold**) for DoTs, marks, and snares are tied to the **current enemy GUID** for every class and race. Tab to another mob (or leave a dead sticky target) and Hunter's Mark, Serpent Sting, Corruption, Rend, and similar spells can be suggested again.
- When target auras are **readable**, missing DoTs/marks are suggested even if a hold timer was still running; while the aura is up they stay hidden until about **6 seconds** remain (refresh), then can re-enter the queue.
- When Forever **hides** target auras, the per-mob hold fallback still applies.
- **Self holds** (Renew, Slice and Dice, …) stay global and unchanged.

### Smarter Classic helper logic without combat log (1.5.66 → 1.5.67)
- **Auto melee / ranged role** for Hunter and Shaman from target distance (Extra option, on by default). Clicking the HUD role button turns auto off until you re-enable it. Shaman heal role is never overwritten.
- **Pet notices** under the HUD for Hunter and Warlock in combat: call your pet, or that the pet is not attacking.
- Hunter **stings** are not suggested on Mechanical / Elemental. **Viper Sting** only when the target has mana (still off by default).
- **Sunder Armor** and **Lacerate** keep applying until **5 stacks**, then refresh. **Scorch** tracks Fire Vulnerability to 5 stacks. **Slice and Dice** / **Renew** can refresh when about 4 s remain.
- **Paladin:** Seal of the Crusader first when Judgement of the Crusader is missing, then Judgement (requires a seal), then DPS seals. Heal seals pair with Judgement of Light / Wisdom. **Exorcism** only on Undead / Demon. **Consecration** when enough enemies are nearby.
- **Shaman totems** (Strength of Earth, Mana Spring, Searing, optional Grace of Air / Windfury / Healing Stream) re-suggest when down or about to expire.
- **Bleeds** (Rend, Rip, Rake, Rupture) skip Mechanical / Elemental / Undead. Many DoTs/marks skip dying trash (< 20% HP) or elites (< 5% HP). Sunder skips if Expose Armor is up. Whirlwind / Swipe respect nearby enemies.
- **Drain Soul** execute window (< 20% HP), off by default so existing lists are not forced. Execute / Hammer of Wrath / Shadow Word: Death / Shadowburn were already gated.

### What did not change
- Your editable list order, profiles (Base / PvE / PvP / Custom), and Extra toggles.
- Physics swing / auto-shot helpers, interrupt / purge / cleanse / weapon windows.
- No combat log on Forever. Custom list version is unchanged.

---

# 1.5.69

## Zero freeze on level-up / quest (Forever)

Quest turn-in and level-up no longer hitch the client. Forever was firing large spell and action-bar update storms; the addon now soft-clears failed spell lookups only, debounces bar remapping (~0.5 s), and never rebuilds the full spellbook on those events.

### Details
- Stopped reacting to the noisy spell-change storm that Forever fires on rewards.
- Learn / level-up / talent: soft-clear failed resolves + short bar refresh.
- Action bar pushed: bars only.
- Glow mapping uses action info only (no action tooltips), chunked across frames.
- Spellbook name index warms at login or lazily for Forever remaps — throttled, not on quest storms.

New ranks still appear without `/reload`.

# 1.5.68

## Deferred spellbook and bar scans (Forever)

Learning a spell or turning in a quest could hitch the whole client for about a second with the addon enabled (out of combat). The addon was rescanning the spellbook and action-bar tooltips in one frame.

### What changed
- Spell learn / level-up no longer wipe known spell resolves.
- Spellbook name lookup is rebuilt across frames when needed.
- Action-bar glow refresh is chunked and skips expensive tooltip reads when the action already has a spell id.
- Reward-window events are coalesced so one storm does not re-scan repeatedly.

New ranks still appear without `/reload`.

# 1.5.67

## Deeper Classic helper logic without combat log

Forever cannot read the combat log. This build adds the remaining high-value Classic helper behaviour that unit auras, totems, creature type, and range can support.

### Stacks and refresh
- **Sunder Armor** and **Lacerate** keep applying until **5 stacks**, then refresh in the usual ~6 s window.
- **Scorch** tracks **Fire Vulnerability** to 5 stacks (Improved Scorch), then refreshes near expiry.
- **Slice and Dice** / **Renew** can refresh when about **4 s** remain (not only when missing).

### Paladin Seal to Judgement
- Damage: Seal of the Crusader first when Judgement of the Crusader is missing, then Judgement (requires any seal), then DPS seals.
- Heal: Seal of Light / Wisdom tied to their judgement debuffs.
- **Exorcism** only on Undead / Demon. **Consecration** when enough nearby enemies.

### Totems (Shaman)
- Strength of Earth, Mana Spring, Searing Totem (and optional Grace of Air / Windfury / Healing Stream) re-suggest when the totem is down or about to expire.

### Creature filters and low-HP skips
- Rend, Rip, Rake, Rupture skip Mechanical / Elemental / Undead.
- DoTs and marks skip dying trash (< 20% HP) or elites (< 5% HP).
- Sunder skips if Expose Armor is already up. Whirlwind / Swipe need nearby enemies.

### Hunter / other
- Viper Sting only when the target has mana (still off by default).
- Aspect of the Monkey available when the mob is targeting you (off by default).

No combat log — Forever-safe. Custom list order kept.

# 1.5.66

## Aura-first DoTs, auto role, and pet notices

Forever still cannot read the combat log. This build closes the main rotation gaps using unit auras, range, and creature type only.

### Aura-first DoTs and marks
- When the target aura API is **readable**, missing Hunter's Mark, Serpent Sting, Corruption, Rend, and other DoT/mark spells are suggested again even if a hold timer was still running.
- While the aura is up, the spell stays hidden until about **6 seconds** remain, then it can re-enter the queue (refresh).
- When Forever **hides** target auras, the previous per-mob hold (GUID) still applies as a fallback.
- Self holds (Renew, Slice and Dice, …) stay global and unchanged.

### Auto melee / ranged role
- Hunter and Shaman can auto-switch melee vs ranged/caster from target distance (Raptor Strike / Stormstrike range when known).
- Extra option: **Auto melee / ranged role** (on by default). Clicking the HUD role button turns auto off until you enable it again.
- Shaman heal role is never overwritten by auto.

### Pet notices
- In combat, Hunter and Warlock see a short gold notice under the HUD: call your pet, or that the pet is not attacking.

### Creature type and execute
- Hunter stings are not suggested on Mechanical / Elemental targets.
- Drain Soul is available in the warlock list as an execute (< 20% HP), off by default so existing lists are not forced.
- Execute / Hammer of Wrath / Shadow Word: Death / Shadowburn were already gated by target HP.

### Enemy range bands
- Enemy counting can filter nameplates by yard bands (about 10 / 28) for tighter AoE checks. Auto AoE still uses the full hostile nameplate count.

No combat log — Forever-safe. Custom list order is kept.

# 1.5.65

## Per-target re-suggest delay for DoTs and marks

After you applied Hunter's Mark or Serpent Sting, the addon kept hiding those spells for the full hold duration even on a **new** mob. Harmful aura holds (DoTs, marks, snares, …) are now tied to the current enemy GUID for **every** class and race. Tab to another target or leave a dead sticky target and the spell can be suggested again. Self holds (Renew, Slice and Dice, …) stay global. No combat log — Forever-safe.


# 1.5.64

## Rotation reliability (summary of 1.5.58 → 1.5.63)

### List order is respected
- Your list order is authoritative for every class, race, mode (Auto / Single / AoE / Burst) and for both default and manually edited lists.
- Talent-school gates (`require` / `requireAny`) no longer hide a filler. Example: if Frostbolt is above Fireball and ready, Frostbolt is suggested — not Fireball.
- Forever FR name matching folds accents (Éclair ↔ Eclair) so class spells and racials resolve correctly in the spellbook.
- Class rotations stay class-only; racials stay race-only (Human ≠ Orc ≠ Aeolid). Mage burst includes Frostbolt above Fireball like single-target.

### Re-suggest delay (hold)
- After you cast a spell, it can stay off the queue for N seconds (DoT, HoT, snare). Defaults come from Forever/Classic aura durations (e.g. Frostbolt chill = 5s, Corruption = 12s, Shadow Word: Pain = 18s, Serpent Sting = 15s, Flame Shock = 12s, …).
- Every spell row in Rotation and Defense has an editable delay box — including spells with no known aura (default **0**).
- **0** means no aura re-cast delay only. It does **not** mean spam one spell in a loop. The queue still follows list order and conditions (spell 1 → 2 → 3); each spell appears at most once per queue (except next-swing fillers).
- Hold tip text is translated in all supported languages (enUS, frFR, deDE, esES/esMX, ruRU, zhCN, zhTW, ptBR, itIT, koKR).

### Rotation pass (advance & wrap)
- Casting any spell that is on your list marks it used for the current pass — even if you cast it before the HUD had shown it.
- The HUD then offers the **next** usable spell in the list.
- When nothing usable remains in that pass, the queue **restarts from the top**.
- The pass clears on target change and when leaving combat.
- Real cooldowns, `hold` delays, range, and other StepOk conditions still apply on top of this.

### Queue behaviour kept
- Up to three different next spells; fillers still yield to a ready shock / DoT / cooldown lower in the list when that is correct.
- Slot 1 prefers confirmed in-range; out-of-range stays in slots 2–3.

# 1.5.63

- Rotation pass tracking: casting any list spell (even before it was shown) marks it used and advances to the next usable spell. When the pass is exhausted, the queue restarts from the top. Clears on target change and leaving combat.

# 1.5.62

- Clarify hold = 0: no aura re-cast delay only. Rotation still follows list order and conditions (1 → 2 → 3); it does not mean spam the same spell in a loop.

# 1.5.61

- Every spell row has an editable re-suggest delay (default 0 when no aura duration is known). Hold strings translated in all supported languages.

# 1.5.60

- Per-spell re-suggest delay (hold): after you cast, the spell stays off the queue for N seconds. Defaults from Forever/Classic DoT, HoT and snare durations (Frostbolt chill = 5). Editable next to each spell in options; 0 = no aura delay (rotation order still applies).

# 1.5.59

- Class lists stay class-only; racials stay race-only (no cross-race fallback).
- Spell name matching folds accents (Éclair ↔ Eclair) so Forever FR resolves every class filler and racial correctly.
- Mage burst includes Frostbolt above Fireball, same list-order rule as single target.

# 1.5.58

- List order is authoritative for fillers: Frostbolt / Arcane / Fireball are no longer hidden by talent-school gates (requireAny). If Frostbolt is above Fireball and ready, Frostbolt is suggested.

# 1.5.57

- Fillers yield again to a ready shock, DoT, or cooldown lower in the list, so that spell becomes slot 1 (e.g. Earth Shock over Lightning Bolt). Unknown range still counts. The HUD still shows each spell only once per queue.

# 1.5.56

- Rotation follows list order strictly: the first ready in-range spell is suggested, then the next different ones for slots 2–3. Cast fillers no longer yield to later cooldowns, and the HUD no longer stacks the same spell three times. Mage Pyroblast is usable in combat when listed.

# 1.5.55

- Slot 1 is only a spell confirmed in range. Out-of-range shocks, DoTs, and melee stay in slots 2–3 until you can reach the target. Same distance rule for every class and race.

# 1.5.54

- Same press rule for every class and race: a filler yields only to a later cooldown, DoT, or proc that is ready and in range. Ice Lance, Starfire, Swipe, and auto racials no longer steal the queue.

# 1.5.53

- A ready in-range shock, DoT, or cooldown becomes the spell to press even if a filler is listed first. Rotation edits apply at once (Apply button); no /reload.

# 1.5.52

- Queue lookahead works for every class: combo, stealth finishers, current cast pinned, positional spells during the GCD, and a filler after shocks so the HUD never sticks on one icon.

# 1.5.51

- HUD queue lookahead: after the first spell, the next two assume it was pressed (DoT up, shock on cooldown). Learned shocks and DoTs show again instead of only the filler.
- New trainer spells are picked up without /reload. Target DoTs stay known when the client hides auras.

# 1.5.50

- Missing Forever 1-60 combat spells from the lab: Swift Judgement, Enchanted Flare, Tranquilizing Shot, Preparation, and the rest of the editor list. Classic IDs that do not exist on this client now use the Forever ones.

# 1.5.49

- Options no longer measure text height. That call froze the camelot client after the Multi language title change.

# 1.5.48

- Title now shows (Multi language). The About card, CurseForge page, and website describe the addon more clearly.

# 1.5.47

- Copy on the Info page puts the link in the chat box, selected, so Ctrl+C works. This client has no system clipboard API.

# 1.5.46

- Mouse-button keybinds stay inside the HUD icons (Mouse Button 4 shows as M4).

# 1.5.45

- Options Info page lists slash commands, credits, website, Discord, and CurseForge. The new option labels are translated in every language pack.

# 1.5.44

- Options use a sidebar and cards, with ON/OFF switches, like a modern config window. Same settings, clearer layout.

# 1.5.43

- The HUD shrinks when you turn off the swing bars and grows again when you turn them back on.

# 1.5.42

- Leveling no longer hitches the client. Spell learn and bar scans wait and reuse known spells.
- Weapon imbues, poisons, stones, and other HUD buffs update as soon as you apply them. No /reload.

# 1.5.41

- The addon is now named Forever Rotation. Same helper, clearer name. /wfr and /foreverrot still work; /foreverrotation is added.

# 1.5.40

- Weapon buffs, heals, defense, interrupts, racials, and the rest of the HUD refresh as soon as the game reports a change. You no longer need /reload after an imbue, poison, or stone. This is for every class and race.

# 1.5.39

- Forever 1-60 combat spells and racials are added on top of Classic Era lists. Unknown spells stay hidden until you learn them.
- Spell match uses all 11 client languages when a lab id is remapped.

# 1.5.38

- The action bar scan no longer clears the rotation. A button that can be read one moment and not the next was emptying the queue, then filling it again, with no cast and no target.

# 1.5.37

- The suggested spell no longer vanishes while you are casting it or while it is still traveling to the target.
- A shared cast lock no longer clears the queue. The next spell can show before the projectile lands.
- Heroic Strike, Maul, and Raptor Strike stay suggested between swings. Only a shot that would clip the auto shot is held back.

# 1.5.36

- The skull overlay finds the action button again for attacks, heals, and defense. A hidden spell id no longer drops the button name, and the spell icon is used when the name is hidden.
- The match stays on the buttons that carry that spell. It does not light every occupied slot.

# 1.5.35

- A partial action-bar scan no longer hides the rotation. If a button cannot be read, its spells stay suggested for every class and race.
- Macro buttons are matched from the macro text, and several ranks of the same spell stay on the same button.
- Hunters always have Auto Shot between Aimed Shot, Multi-Shot, and Arcane Shot. Warrior AoE and burst keep Heroic Strike.

# 1.5.34

- Rotation suggestions, the red out-of-range tint, and the skull overlay work again when the client hides action-bar spell ids.
- Spells are matched from the button tooltip. Range uses the action slot itself.

# 1.5.33

- Language follows the WoW client (English, French, German, Spanish, Russian, Simplified Chinese, Traditional Chinese, Portuguese, Italian, Korean). Mexican Spanish uses Spanish, and British English uses English.
- Options can force a language. Auto keeps the client language. The choice is saved.
- Every setting is stored per character: position, scale, options, lists, profile, language, and lock. They stay after a reload or a restart.

# 1.5.32

- The energy bar shows the seconds left until the next tick and keeps moving at full energy.
- It resyncs only on a real regen tick of about 20, not on Thistle Tea or Relentless Strikes.
- A movable combo-point window uses the same frame style as the HUD, for rogues and cat druids. The number turns gold at 5.
- When the client reports a parry, the main-hand swing shortens by 40 percent, and never below 20 percent of weapon speed.

# 1.5.31

- The energy bar advances on its own and resyncs when a tick lands.

# 1.5.30

- The skull overlay stays on the one action button for the spell to press.

# 1.5.29

- Rotation icons stay in color at long range, so a melee still sees the spell to engage.
- The key to press on those icons is larger. Red range tint stays on the action bar only.

# 1.5.28

- Main hand, off hand and energy can show together, under the spell icons.
- Turning off classic combat timing hides those bars again.

# 1.5.27

- Energy stays on the swing gauge when both weapons are shown.
- A white outline marks when to press. Out-of-range tints the HUD, and a yellow bar tracks the enemy cast.

# 1.5.26

- Swing bars sit under the spell icons, with a white mark for the cast window.
- The HUD loads again on the Forever beta when attack speed is hidden by the client.

# 1.5.25

- Swing bars sit below the spell icons instead of covering them.

# 1.5.24

- The swing gauge is drawn inside the rotation frame.

# 1.5.23

- Swing bars show under the rotation frame.

# 1.5.22

- Swing speed is read from the weapon tooltip when the client hides attack speed.

# 1.5.21

- The addon loads again after a broken French translation line.

# 1.5.20

- The HUD shows on login instead of staying hidden while idle.

# 1.5.19

- English-only player README. UI strings complete in all 11 locales.
- Classic white-hit timing for every class, dual-wield bars, HUD chrome.

# 1.5.18

- Main-hand and off-hand swing bars use different colors (orange / blue).

# 1.5.17

- White-hit swing timing for every class, with a second bar when dual wielding.

# 1.5.16

- Optional Classic combat timing: heroic strike / cleave / raptor / maul in the next-swing window, hunter aimed / multi / volley held off the auto-shot clip, energy spells offered just before the next tick.
- HUD windows use the same class-colored chrome as the mode toolbar. Queue, defense, interrupt, purge, cleanse, weapon and lock still move independently.

# 1.5.15

- Translate the new Extra options into all supported locales (not only French).

# 1.5.14

- Hide the HUD when dead, mounted, eating, or in town.
- Locked windows are click-through; the padlock stays clickable.
- Action-bar keybinds on HUD icons.
- Group dispel only for types the current class can remove.
- Profile import/export, auto PvE/PvP profile, bar-only suggestions, overlay colors, alert volume.

# 1.5.13

- Toolbar moves from the left grip or by dragging any button (clicks still change mode).

# 1.5.12

- Red out-of-range overlay is back on action-bar buttons (heals included), not on the rotation HUD.

# 1.5.11

- Every recommended spell (heal, defense, interrupt, purge, cleanse) uses the same red out-of-range tint as attacks.

# 1.5.10

- Fix load error: priest Silence cooldown used a missing spell id.

# 1.5.9

- Heal spells use the same red out-of-range tint as attacks (checked on the heal target, not the enemy).
- General options apply instantly. No /reload.

# 1.5.8

- Feature checkboxes now toggle and apply at once (windows, skull glow, range tint, mode selector).
- Clicking the option label works, not only the small box.
- HUD refresh no longer waits for a spell change.

# 1.5.7

- 0.2s ticker (no per-frame OnUpdate).
- Range check only on already glowing buttons.
- No tick on every spellcast event.
- Addon-list logo.
