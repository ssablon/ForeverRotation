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
