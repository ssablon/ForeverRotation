# 1.5.66

## ConROC-parity helpers without combat log

Forever still cannot read the combat log. This build closes the main rotation gaps using unit auras, range, and creature type only — so DoTs, marks, melee/ranged switching, pet reminders, stings, and execute windows behave closer to a Classic helper without secret CLEU APIs.

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
- Drain Soul is available in the warlock list as an execute (&lt; 20% HP), off by default so existing lists are not forced.
- Execute / Hammer of Wrath / Shadow Word: Death / Shadowburn were already gated by target HP.

### Enemy range bands
- Enemy counting can filter nameplates by yard bands (about 10 / 28) for tighter AoE checks. Auto AoE still uses the full hostile nameplate count.

No combat log — Forever-safe. Custom list order is kept.

# 1.5.65

- Target DoT / mark / snare re-suggest delay (`hold`) is per-mob: switching target or a dead sticky target clears it so Hunter's Mark, Serpent Sting, Corruption, Rend, and other harmful aura spells can be suggested again on the next enemy. Self holds (Renew, Slice and Dice, …) stay global. No combat log (Forever-safe).

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

- HUD queue now works like ConROC: after the first spell, the next two assume it was pressed (DoT up, shock on cooldown). Learned shocks and DoTs show again instead of only the filler.
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

- 0.2s ticker like ConROC (no per-frame OnUpdate).
- Range check only on already glowing buttons.
- No tick on every spellcast event.
- Addon-list logo.
