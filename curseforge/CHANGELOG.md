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
