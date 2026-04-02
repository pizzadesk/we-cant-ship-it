# We Can't Ship It — Current State (Game Designer Overview)

## Project Vision Alignment
- The core fantasy (balancing ambition, instability, and soul) is fully implemented and matches the design intent.
- The Goldilocks gate is enforced with correct stat thresholds and cannot be reached by bucket pressure alone.
- Feature cards, board interactions, and stat deltas are all data-driven and match the schema in the design doc.
- The soul economy (fix bugs/dev log) is intentionally asymmetric and tunable via game_config.tres.
- The three-run cycle system is fully implemented, replacing infinite meta progression.
- The archetype system is fully implemented across all layers.

---

## Core Systems Status — WORKING

- **Feature Card System**: All cards are .tres resources, with correct fields and interaction dictionaries. Tag-based interactions, flavor text, and archetype affinity are all present.
- **Run Structure**: 21-day sprint with Ambition, Instability, Soul, and Runway Days tracked and surfaced to the player.
- **Player Actions**: Place card, fix bugs, dev log, and ship are all implemented with correct costs and stat effects.
- **Interaction System**: Pre-placement ⚡/⚡⚡/⚡⚡⚡ heat hint and post-placement feed are both present. All interaction rules are data-driven.
- **Endings**: Stat-gated and bucket-based endings are resolved in the correct order, with Goldilocks gate prioritized.
- **Publisher Trust Mode**: Optional, modifies dilemma offer weighting.
- **Three-Run Cycle**: Cycle state persists across completed runs, pressure escalates per run, main menu shows run position.
- **Archetype System**: Genre selection at run start, 4-level mismatch evaluation, pre-placement glyphs, post-placement feed events.

---

## UI/UX
- Visual palette and theming are resource-driven and consistent across UI.
- All stat changes, interactions, and archetype mismatches are surfaced to the player.
- No direct UI-to-state mutation; all state changes flow through AppState and GameEvents.
- Archetype select dialog shown at run start (before first card offer). Skippable.
- Drag preview shows ⚡/⚡⚡/⚡⚡⚡ for interaction heat and ~/⚠/☠ for archetype mismatch severity.

---

## Data & Tuning — UP TO DATE

All tuning values in game_config.tres match the revised design doc. Key values:

| Parameter | Current Value | Design Target |
|---|---|---|
| soul_start | 12 | 12 ✓ |
| soul_max | 15 | 15 ✓ |
| goldilocks_instability_min | 18 | 18 ✓ |
| goldilocks_instability_max | 42 | 42 ✓ |
| goldilocks_soul_min | 7 | 7 ✓ |
| cult_jank_legendary_instability_min | 52 | 52 ✓ |
| prestige_collapse_soul_max | 6 | 6 ✓ |
| genre_stretch_instability_bonus | 2 | 2 ✓ |
| archetype_mismatch_instability_bonus | 4 | 4 ✓ |
| archetype_mismatch_ambition_bonus | 2 | 2 ✓ |
| archetype_mismatch_soul_penalty | 1 | 1 ✓ |
| alien_card_instability_bonus | 8 | 8 ✓ |
| alien_card_ambition_bonus | 4 | 4 ✓ |
| alien_card_soul_penalty | 3 | 3 ✓ |
| alien_card_soul_gate | 5 | 5 ✓ |

---

## Known Gaps — REMAINING

### 1. Post-Ship Gap Visualizer
**Status: Not implemented.**
`PresentationTextUtils.build_jank_meter_text()` needs a proportional delta bar section showing where each stat landed relative to the Goldilocks gate. Bars show progress percentage, not absolute distance. No numbers, no explanation — player reads the gap.

### 2. Cycle Resolution / Legacy Screen
**Status: Not implemented.**
After run 3 ships: a legacy screen should show the studio's three-game arc (all three endings together). If Goldilocks was reached: cycle complete, legacy flavor shown. If not: cycle resets.

### 3. Archetype Selection UI Polish
**Status: Functional, minimal.**
The archetype select dialog is a plain ConfirmationDialog. It works but does not use the full VisualPalette theming. A dedicated scene (ArchetypeSelectScreen.tscn) with richer layout would be the next iteration.

---

## Playtesting Readiness

**Full game loop: Ready for playtesting.** All core systems (run structure, card interactions, endings, archetype, cycle) are implemented and functional.

**Recommended playtest focus:**
- Does the archetype picker feel meaningful at run start, or does it feel like overhead?
- Does mismatch friction (especially wild swing ⚠ and alien ☠ glyphs) signal risk correctly before placement?
- Is there a viable Goldilocks path? (Expected: yes — confirm soul economy is brutal but fair)
- Does Community Darling feel reachable after style points fix?
- Does the three-run arc feel like escalation, or just repetition?

---

## Core Systems Status — UNCHANGED AND WORKING

- **Feature Card System**: All cards are .tres resources, with correct fields and interaction dictionaries. Tag-based interactions and flavor text are surfaced in the UI.
- **Run Structure**: 21-day sprint, with Ambition, Instability, Soul, and Runway Days tracked and surfaced to the player.
- **Player Actions**: Place card, fix bugs, dev log, and ship are all implemented with correct costs and stat effects.
- **Interaction System**: Pre-placement ⚡ hint and post-placement feed are both present. All interaction rules are data-driven.
- **Endings**: Stat-gated and bucket-based endings are resolved in the correct order, with Goldilocks gate prioritized.
- **Publisher Trust Mode**: Optional, modifies dilemma offer weighting.

---

## UI/UX — UNCHANGED
- Visual palette and theming are resource-driven and consistent across UI.
- All stat changes and interactions are surfaced clearly to the player.
- No direct UI-to-state mutation; all state changes flow through AppState and GameEvents.

---

## Data & Tuning — PARTIALLY CHANGED

All tuning values are in game_config.tres. The following values require updating to match the revised design doc:

| Parameter | Old Value | New Value | Reason |
|---|---|---|---|
| soul_start (run reset) | 10 | 12 | One Fix Bugs survivable |
| soul_max | none | 15 | Prevent Dev Log spam exploit |
| goldilocks_instability_min | 15 | 18 | Passive play cannot accidentally qualify |
| goldilocks_instability_max | 40 | 42 | 2pt buffer for late interactions |
| goldilocks_soul_min | 8 | 7 | One Fix Bugs cycle survivable |
| cult_jank_legendary_instability_min | 58 | 52 | Legendary Jank reachable intentionally |
| community_darling_surprise_hit_soul_min | 10 | 8 | Align with revised soul economy |
| community_darling_surprise_hit_score_min | 7.0 | 6.5 | Community Darling already hard to reach |
| prestige_collapse_soul_max | 7 | 6 | One more point of grace |
| ambition_coefficient | 0.12 | 0.14 | Rewards scope more |
| instability_coefficient | 0.04 | 0.05 | Rewards chaos more |
| soul_coefficient | 0.12 | 0.15 | Soul feels more impactful |
| soul_mitigation_factor | 50.0 | 40.0 | Less aggressive score suppression |
| sweet_spot_instability_min | 35 | 18 | Align with new Goldilocks floor |
| sweet_spot_instability_max | 60 | 45 | Align with Goldilocks range |
| too_early_runway_threshold | 14 | 13 | Fix day 12-14 overlap with sweet spot |
| sweet_spot_score_bonus | 1.0 | 1.2 | Reward correct read more |
| too_early_score_penalty | -0.4 | -0.5 | Punish impatience more |
| panic_ship_score_penalty | -0.6 | -0.4 | Panic ship shouldn't always doom run |

New fields to add to game_config.tres:
- `soul_max: int = 15`
- `archetype_mismatch_instability_bonus: int = 4`
- `archetype_mismatch_ambition_bonus: int = 2`
- `archetype_mismatch_soul_penalty: int = 1`
- `alien_card_instability_bonus: int = 8`
- `alien_card_ambition_bonus: int = 4`
- `alien_card_soul_penalty: int = 3`
- `alien_card_soul_gate: int = 5`

---

## Known Gaps — NEW FEATURES NOT YET IMPLEMENTED

### 1. Three-Run Cycle System
**Status: Not implemented.**
The game currently operates as infinite runs with persistent meta progression. The entire meta progression system (studio reputation, tiers, milestone cycle) needs to be replaced with a cycle state scoped to three runs.

What's needed:
- `CycleState` resource or dictionary tracking current_run, run endings, unlocked cards, cycle_complete
- Cycle state persists after completed runs; mid-run quits reset current run only; pre-run-1-ship quits reset cycle
- `NOTIFICATION_WM_CLOSE_REQUEST` handler to distinguish intentional quit from crash
- Cycle state display on main menu ("RUN X OF 3" + tone copy)
- Cycle resolution screen after run 3 showing three-game legacy

### 2. Pressure Escalation Across Runs
**Status: Not implemented.**
Event offer intervals are fixed. They need to scale by `current_run` via pressure factor:
```
pressure_factor = 1.0 + (0.3 × (current_run - 1))
effective_interval = base_interval / pressure_factor
```
OfferScheduler needs to read `current_run` from cycle state.

### 3. Archetype System
**Status: Not implemented.**
Cards lack `archetype_affinity` field. No archetype selection screen exists. No mismatch resolver in interaction pipeline.

What's needed:
- `archetype_affinity: PackedStringArray` on FeatureCard schema
- Archetype selection screen at run start (before first daily offer)
- Mismatch resolver running after existing interaction logic in AppState
- Alien card soul gate check before placement
- Interaction magnitude heat level (⚡/⚡⚡/⚡⚡⚡) extending existing hint system

### 4. Style Points Accumulation Fix
**Status: Needs code change.**
Prestige Collapse currently accumulates unconditionally on every card's ambition value. This must be conditioned on `ambition_value > soul` to prevent passive Prestige drift.

Community Darling tag set needs widening beyond lore/quest to include narrative, character, world tags.

### 5. Post-Ship Gap Visualizer
**Status: Not implemented.**
`PresentationTextUtils.build_jank_meter_text()` needs a proportional delta bar section showing where each stat landed relative to Goldilocks gate. Bars show progress percentage, not absolute distance.

### 6. Upfront Communication
**Status: Not implemented.**
First-launch screen or main menu needs: *"Three sprints. Ship something ambitious, a little broken, made with love."* No mechanics explained. No thresholds revealed.

---

## Playtesting Readiness

**Base game: Ready for playtesting now.** All core systems are implemented and functional.

**Archetype and cycle features: Not ready.** Implement base game playtest first to validate soul economy, stat ranges, and Goldilocks accessibility before layering new systems.

**Recommended playtest focus:**
- Is there a viable Goldilocks path that uses Fix Bugs at all? (Expected: no — confirm this is felt as discovery, not frustration)
- Does Community Darling feel reachable after style points fix?
- Does late-board interaction spike feel like revelation or ambush?
- Is the soul economy brutal in a fun way or a punishing way at the revised starting values?
