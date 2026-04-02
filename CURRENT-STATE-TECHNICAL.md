# We Can't Ship It — Technical Solution State

## Architecture Overview
- **Godot 4.x, Typed GDScript**: Strict typing and class_name usage throughout.
- **Autoload Singletons**: AppState (state), GameEvents (signals), ReviewService, StageDirector, DecorationLayer. No new autoloads.
- **Data-Driven Content**: All cards, offers, endings, and config values are externalized in .tres or .json files.
- **UI/State Pipeline**: UI emits intent → AppState mutates state → AppState emits via GameEvents → UI reacts. No direct UI-to-state mutation.
- **Signals**: All signals use typed resource payloads, never untyped dictionaries.

---

## Core Systems — IMPLEMENTED AND STABLE

- **Feature Cards**: Resource schema matches design doc. All stat deltas, interactions, and `archetype_affinity` are present on all 16 base cards and the custom card template.
- **Interaction System**: Pre-placement heat level (0–3, rendered as ⚡/⚡⚡/⚡⚡⚡) and post-placement feed are separated. All rules are data-driven.
- **Endings**: Resolution order matches design doc. Stat-gated endings checked first, then bucket identity, then fallback.
- **Publisher Trust Mode**: Boolean flag in run state, modifies dilemma weighting.
- **Three-Run Cycle**: `CycleStateManager` replaces `MetaProgressManager`. Cycle state persisted to `user://cycle_state.json`. Pressure modifier scales offer intervals per run. Main menu shows "RUN X OF 3". Quit handler saves cycle state.
- **Archetype System**: Full 4-level implementation. See below.

---

## Archetype System — FULLY IMPLEMENTED

### Card Schema
`archetype_affinity: PackedStringArray` present on `FeatureCard`. All 16 base cards have affinity assigned. Empty = alien card.

### Affinity Tiers (4 levels)
| Coverage | Meaning | Stat delta |
|---|---|---|
| 3/3 archetypes | Universal tool | No penalty |
| 2/3 archetypes | Genre stretch | +`genre_stretch_instability_bonus` (2) Instability |
| 1/3 archetypes | Wild swing | +4 Instability, +2 Ambition, -1 Soul |
| 0/3 archetypes | Alien card | +8 Instability, +4 Ambition, -3 Soul; soul-gated |

All values from `GameConfig`. `chosen_archetype == ""` deactivates the system entirely — all existing behavior preserved.

### Mismatch Resolver (`_apply_archetype_mismatch`)
Runs after existing interaction resolution in `add_feature_card()`. Emits `threshold_event` for each mismatch tier (flavor text in the post-placement feed).

### Pre-Placement Legibility
- `get_archetype_mismatch_level(card) -> int` (0–3) on AppState — public, read-only.
- `FeatureCardWidget` drag preview shows: `~` genre stretch, `⚠` wild swing, `☠` alien card.
- Interaction heat and archetype mismatch glyphs are independent and can stack.

### Alien Card Soul Gate
`can_place_card()` checks `soul >= alien_card_soul_gate` (5) when archetype chosen and card affinity empty. Placement is blocked below this threshold.

### Archetype Selection UI
Shown at run start via `ArchetypeSelectDialog` (built in `dialog_setup_utils.gd`). Three choices: RPG / Shooter / Action-Adventure. Skippable — `chosen_archetype` stays `""` if skipped, system inactive that run.

### Card Affinity Distribution (base set)
- Universal (3/3): Dynamic Music System, Mod Support SDK, Photomode+
- Genre stretch (2/3): 11 cards (most of the base set)
- Wild swing (1/3): Inventory Tetris (RPG only), Companion Romance (RPG only)
- Alien (0/3): None in base set — reserved for custom/rare cards

---

## GameConfig — ALL VALUES CURRENT

All tuning values match the revised design doc. New archetype fields:
- `genre_stretch_instability_bonus: int = 2`
- `archetype_mismatch_instability_bonus: int = 4`
- `archetype_mismatch_ambition_bonus: int = 2`
- `archetype_mismatch_soul_penalty: int = 1`
- `alien_card_instability_bonus: int = 8`
- `alien_card_ambition_bonus: int = 4`
- `alien_card_soul_penalty: int = 3`
- `alien_card_soul_gate: int = 5`

---

## Remaining Work

### 1. Post-Ship Gap Visualizer
Add proportional delta bars to `PresentationTextUtils.build_jank_meter_text()`. Three bars (Ambition, Instability, Soul) showing how far each stat landed from the Goldilocks gate as a percentage. No numbers, no explanation.

### 2. Cycle Resolution / Legacy Screen
After run 3: aggregate all three endings, show studio arc, evaluate Goldilocks across the cycle. If not achieved: `start_new_cycle()`. If achieved: show legacy flavor and reset.

### 3. Archetype Dialog Polish
Current implementation is a plain `ConfirmationDialog`. A dedicated `ArchetypeSelectScreen.tscn` with richer layout and VisualPalette-driven theming is the intended final form.

---

## Custom Card Contributor Onboarding

`data/custom_cards/` contains:
- `card_template.tres` — copy this to start a new card (includes `archetype_affinity`)
- `debug.tres` — working reference card with all fields filled
- `README.txt` — quick rules and field overview
- `TUTORIAL.txt` — step-by-step guide covering all fields including archetype_affinity

Contributors need only a plain text editor. No Godot installation required.

---

## Core Systems Implementation — UNCHANGED AND STABLE

- **Feature Cards**: Resource schema matches design doc. All stat deltas and interactions are dictionaries with explicit keys.
- **Interaction System**: Pre-placement (read-only, for hints) and post-placement (full resolution) logic is separated. All rules are data-driven.
- **Endings**: Resolution order matches design doc. Stat-gated endings checked first, then bucket identity, then fallback.
- **Publisher Trust Mode**: Boolean flag in run state, modifies dilemma weighting.

---

## Resource & Data Management — UNCHANGED
- **VisualPalette**: Only one script with class_name VisualPalette. All UI theming is resource-driven.
- **GameConfig**: All tuning values are exported in game_config.tres and referenced in code.
- **No Hardcoded Content**: All content and tuning is externalized.

---

## Code Quality & Conventions — UNCHANGED
- Strict typing, class_name for resources, no nested functions, no magic numbers, no untyped signals, no direct UI mutation.

---

## Error State & Regression — UNCHANGED
- All parse and runtime errors resolved. VisualPalette resource loads cleanly.

---

## Systems Requiring Changes

### 1. Meta Progression → Cycle State (Breaking Change)

**Current:** `MetaProgressManager` persists studio reputation, tiers, milestones, and unlocked cards across infinite runs to `user://meta_progress.json`.

**Required:** Replace with `CycleState` scoped to three-run arc, persisted to `user://cycle_state.json`.

New cycle state schema:
```gdscript
# user://cycle_state.json
{
  "current_run": 1,           # int: 1, 2, or 3
  "run_1_ending": "",         # String: "" until completed
  "run_2_ending": "",
  "pressure_modifier": 1.0,   # float: derived from current_run
  "unlocked_card_ids": [],    # Array[String]: carries forward within cycle
  "cycle_complete": false
}
```

**Persistence rules (critical):**
- Save cycle state after each **completed run ship** only — never mid-run
- On `NOTIFICATION_WM_CLOSE_REQUEST` mid-run: preserve cycle state as-is (current run will restart)
- On pre-run-1-ship quit: wipe cycle_state.json entirely on next launch
- On crash (not catchable): same as mid-run quit — current run restarts, prior completed runs preserved

**What to remove:** `MetaProgressManager`, studio tier logic, milestone cycle, reputation accumulation, `user://meta_progress.json`. Legacy record system can be retained as cycle completion flavor only.

**What AppState needs:**
```gdscript
# New fields in AppState
var _cycle_state: Dictionary = {}
var current_run: int = 1

# New method
func load_cycle_state() -> void
func save_cycle_state() -> void
func reset_cycle() -> void
func advance_run() -> void
```

**`reset_run()` change:** Must read `current_run` from cycle state and set `soul = 12` (not 10).

---

### 2. OfferScheduler — Pressure Escalation

**Current:** Offer intervals are fixed values from GameConfig.

**Required:** Intervals scale by `current_run` via pressure factor.

```gdscript
# In OfferScheduler, add parameter to offer methods:
func maybe_offer_dilemma(..., current_run: int) -> Dictionary:
    var pressure_factor: float = 1.0 + (0.3 * float(current_run - 1))
    var effective_interval: int = int(float(_game_config.dilemma_offer_interval) / pressure_factor)
    # use effective_interval instead of _game_config.dilemma_offer_interval
```

AppState must pass `current_run` to all `_maybe_offer_*` calls in `spend_day()`.

---

### 3. AppState — Soul Cap

**Current:** Soul has no upper bound.

**Required:** One line change in `do_dev_log()`:
```gdscript
func do_dev_log() -> void:
    if runway_days <= 0:
        return
    soul = min(soul + _game_config.dev_log_soul_gain, _game_config.soul_max)  # was: soul += dev_log_soul_gain
    _style_points["community_darling"] += 4  # was: 6
    spend_day("dev_log")
```

---

### 4. AppState — Style Points Accumulation Fix

**Current:** `prestige_collapse += ambition_value` on every card unconditionally.

**Required:** Conditional accumulation in `add_feature_card()`:
```gdscript
# Replace:
_style_points["prestige_collapse"] += max(placed_card.ambition_value, 0)

# With:
if placed_card.ambition_value > soul:
    _style_points["prestige_collapse"] += placed_card.ambition_value
else:
    _style_points["community_darling"] += 1
```

Community Darling tag check widened:
```gdscript
# Replace:
if placed_card.tags.has("lore") or placed_card.tags.has("quest"):
    _style_points["community_darling"] += 2

# With:
var darling_tags: PackedStringArray = ["lore", "quest", "narrative", "character", "world"]
for tag in darling_tags:
    if placed_card.tags.has(tag):
        _style_points["community_darling"] += 3
        break
```

---

### 5. FeatureCard Schema — Archetype Affinity

**New field** (non-breaking — defaults to empty, existing cards unaffected):
```gdscript
# In feature_card.gd
@export var archetype_affinity: PackedStringArray = []
```

Empty affinity = alien card behavior when archetype is chosen.

---

### 6. AppState — Archetype Mismatch Resolver

New field in run state:
```gdscript
var chosen_archetype: String = ""  # "" = feature inactive
```

Set once in `reset_run()` from cycle state or archetype selection screen. Never mutated mid-run.

Mismatch check runs **after** existing interaction resolution in `add_feature_card()`:
```gdscript
func _apply_archetype_mismatch(card: FeatureCard) -> void:
    if chosen_archetype.is_empty():
        return
    if card.archetype_affinity.is_empty():
        # Alien card
        if soul < _game_config.alien_card_soul_gate:
            return  # blocked — UI should prevent placement reaching here
        instability += _game_config.alien_card_instability_bonus
        ambition += _game_config.alien_card_ambition_bonus
        soul = max(soul - _game_config.alien_card_soul_penalty, 0)
        _style_points["cult_jank"] += _game_config.alien_card_instability_bonus
        return
    if card.archetype_affinity.has(chosen_archetype):
        return  # on-archetype, no penalty
    # Mismatch
    instability += _game_config.archetype_mismatch_instability_bonus
    ambition += _game_config.archetype_mismatch_ambition_bonus
    soul = max(soul - _game_config.archetype_mismatch_soul_penalty, 0)
    _style_points["cult_jank"] += _game_config.archetype_mismatch_instability_bonus
```

---

### 7. has_potential_interaction() — Magnitude Heat Level

**Current:** Returns `bool`.

**Required:** Returns `int` heat level (0 = none, 1 = low, 2 = medium, 3 = high).

```gdscript
func get_interaction_heat(card: FeatureCard, board: Array[FeatureCard]) -> int:
    var total_delta: int = 0
    for existing in board:
        for new_tag in card.tags:
            for existing_tag in existing.tags:
                var rule: Dictionary = _get_rule(String(new_tag), String(existing_tag))
                if _is_rule_blocked_by_soul(rule):
                    continue
                total_delta += abs(int(rule.get("instability_delta", 0)))
                total_delta += abs(int(rule.get("soul_delta", 0)))
    if total_delta == 0:
        return 0
    if total_delta < 5:
        return 1
    if total_delta < 10:
        return 2
    return 3
```

UI reads heat level and renders ⚡/⚡⚡/⚡⚡⚡ accordingly.

---

### 8. New UI Components

**ArchetypeSelectScreen.tscn** (new scene):
- Shown once at run start, before first daily offer
- Three choices: RPG / Shooter / Action-Adventure
- On selection: sets `AppState.chosen_archetype`, emits `archetype_chosen(archetype: String)` via GameEvents
- Skippable: chosen_archetype remains "" if skipped
- Uses existing VisualPalette — no hardcoded colors

**Gap Visualizer** (in PresentationTextUtils):
- Added to `build_jank_meter_text()`
- Three bars: Ambition, Instability, Soul vs Goldilocks gate
- Bars show proportional delta ("60% of the way") not absolute distance
- No numbers, no explanation — player reads the gap

**Main Menu Cycle Display** (in main.gd `_show_main_menu()`):
- Reads `current_run` from cycle state
- Displays: "RUN 1 OF 3 — The studio is young. Anything could happen."
- "RUN 2 OF 3 — The publisher is watching. Deliver something."
- "RUN 3 OF 3 — This is it. Ship the defining game or start over."

**Quit Handler** (in main.gd):
```gdscript
func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        _save_cycle_state_on_quit()
        get_tree().quit()

func _save_cycle_state_on_quit() -> void:
    # Save cycle state as-is — current run will restart on next launch
    # Cycle state from completed runs is preserved
    if _game_state != null:
        _game_state.save_cycle_state()
```

---

### 9. GameConfig — New Fields

Add to game_config.tres (no existing fields modified):
```gdscript
@export var soul_max: int = 15
@export var archetype_mismatch_instability_bonus: int = 4
@export var archetype_mismatch_ambition_bonus: int = 2
@export var archetype_mismatch_soul_penalty: int = 1
@export var alien_card_instability_bonus: int = 8
@export var alien_card_ambition_bonus: int = 4
@export var alien_card_soul_penalty: int = 3
@export var alien_card_soul_gate: int = 5
```

Existing fields with value changes (see CURRENT-STATE-GAME-DESIGNER.md for full table).

---

## Implementation Order

Non-destructive sequence — each step is independently deployable:

1. **GameConfig value updates** — no code changes, immediate effect
2. **Soul cap** — one line in `do_dev_log()`
3. **Style points fix** — two blocks in `add_feature_card()`
4. **Cycle state** — replace MetaProgressManager, add persistence, add quit handler
5. **Pressure escalation** — OfferScheduler reads current_run
6. **Main menu cycle display** — UI only, reads cycle state
7. **Upfront communication** — UI only, first-launch screen
8. **Gap visualizer** — PresentationTextUtils addition
9. **Interaction heat level** — extend has_potential_interaction()
10. **Archetype feature** — FeatureCard schema, AppState mismatch resolver, ArchetypeSelectScreen

Steps 1–3 are safe to ship before playtesting. Steps 4–8 constitute the three-run cycle feature. Steps 9–10 are the archetype feature and should follow cycle playtesting.

---

## Summary
The technical foundation is robust and does not require architectural changes. All new features extend existing systems non-destructively. The largest change is replacing MetaProgressManager with CycleState — everything else is additive or a single-method modification.
