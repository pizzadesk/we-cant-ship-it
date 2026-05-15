# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Run

Use **Godot 4.6.1 or later**. Open the project root in Godot and run `scenes/main.tscn`. There is no automated test suite or CLI build pipeline — do not invent build or test commands.

## Architecture

**We Can't Ship It** is a card-based roguelite made in Godot 4 GDScript. Players balance Ambition, Instability, and Soul across a four-run cycle to reach the "Defining Game" ending. Run 1 is a locked tutorial (no Defining Game ending available); Runs 2–4 are the real shipping attempts.

### Autoload Singletons (declared in `project.godot`)

State flows through autoloads, not direct UI mutation:

- **AppState** — run state, card placement, offer scheduling, cycle persistence
- **GameEvents** — publish-subscribe event bus; UI reacts to signals rather than being told what to do
- **ReviewService** — generates post-ship reviews from shipped card tags and meme families
- **StageDirector** — manages visual theme transitions per runway stage
- **DecorationLayer** — runtime UI decoration effects

### Scene Wiring (`scripts/main.gd`)

`main.gd` is the composition layer. It instantiates and wires six scene-level views (`HeaderPanel`, `LeftColumn`, `FeatureBoard`, `RightColumn`, `DialogHost`, `MainMenuLayer`), creates controllers, routes drag-and-drop payloads (backlog → board → AppState), and owns dialog factories and jank visual effects. It should connect things, not absorb unrelated game logic.

### View / Controller / Presenter Split (`scripts/ui/`)

- **Views** (`scripts/ui/*.gd`): expose scene nodes and presentation helpers
- **Controllers** (`scripts/ui/controllers/*.gd`): coordinate run flow, listen to `GameEvents`, update views — key ones: `RunHudController`, `BacklogController`, `ChoiceFlowController`, `PostShipFlowController`
- **Presenters** (`scripts/ui/presenters/*.gd`): format and push specific data bundles to views — `CyclePresentation`, `PostShipPresentation`, `ReviewPresentation`

### Data Subsystem (`scripts/data/`)

Business logic that isn't UI lives here, not in controllers or autoloads:

- **Payloads** (`scripts/data/payloads/`): ~13 typed DTO classes (e.g. `ShipResult`, `CardPlacement`) used to pass structured data between layers without loose dictionaries
- **Services** (`scripts/data/services/`): `AppContentRepository` (loads and caches data files), `ArchetypeRules` (archetype mismatch scoring), `RunOfferFlow` (offer scheduling), `RunResolutionService` (end-of-run scoring and ending selection)

### Data Layer (`data/`)

All tuning, cards, offers, strings, review pools, threshold events, and signature jank live in `data/` — no hardcoded gameplay numbers or content strings in GDScript. Key files:

- `data/game_config_override.json` — live tuning (use this for routine balance changes, not `game_config.tres`)
- `data/cards/` and `data/custom_cards/` — `.tres` feature card definitions
- `data/jank_combinations.json` — card-pair recipes → jank names and meme families
- `data/review_pools.json` — reviewer voice and flavor (must stay in sync with `meme_families` values)
- `data/offers.json` — dilemma and draft events
- `data/strings/` — all UI text: `buttons.json`, `card_ui.json`, `log_messages.json`, `popups.json`, `tooltips.json`
- `data/archetypes.json` — card archetype definitions used for mismatch scoring
- `data/interaction_rules.json` — card interaction rule definitions
- `data/threshold_events.json` — stat-threshold-triggered narrative events
- `data/stage_themes/` — four `.tres` files driving visual progression per runway stage

## Key Conventions

**Prefer data edits over GDScript** when the change is about balance, cards, offers, text, reviews, or signature jank.

**Typed GDScript everywhere**: use `class_name`, explicit types, no loose patterns.

**`PackedStringArray` is a value type**: unlike `Array`, it is copied on assignment and when passed as a function argument. Appending to a `PackedStringArray` parameter inside a helper has no effect on the caller's copy. Pass the owning object (e.g. the result DTO) instead.

**Node name contracts**: `%NodeName` lookups in `main.gd` rely on `unique_name_in_owner`. Renaming or reparenting `RootMargin`, `HeaderPanel`, `LeftColumn`, `FeatureBoard`, `RightColumn`, `CrunchTimer`, `DialogHost`, `JankTint`, `ScanlineOverlay`, or `MainMenuLayer` requires matching script updates.

**Drag-and-drop ownership**: `FeatureBoard` receives full drag payload dictionaries. Scene-level code removes backlog entries and forwards placement to `AppState`. Do not duplicate card state across UI widgets.

**Jank FX are intentional**: instability text corruption, wobble, tint, and scanlines are deliberate presentation behavior — do not clean them up unless the task is explicitly about those effects.

**JSON safety**: quoted strings, unquoted numeric values, no trailing commas, strict formatting. `.tres` files must be plain-text UTF-8 without a BOM.

**Meme family sync**: if you add or rename `meme_families` in `data/jank_combinations.json`, update `data/review_pools.json` in the same change.

**Custom card filenames**: follow the naming rules in `data/custom_cards/` exactly — invalid filenames silently prevent cards from loading.

**Narrative voice**: deadpan, concrete, specific, and sincere about accidental beauty. `data/VOICE-GUIDE.txt` is the authority.

**Scene composition**: edit sub-scenes in `scenes/ui/` when changing a panel or view. Only change `scenes/main.tscn` when the cross-view wiring itself is changing.

## Key Docs

- Game design and four-run arc: [we_cant_ship_it_gdd.md](we_cant_ship_it_gdd.md)
- Content editing (non-programmer): [data/COLLABORATOR-GUIDE.txt](data/COLLABORATOR-GUIDE.txt)
- Content layer file reference: [data/README.md](data/README.md)
- Tuning parameter reference: [data/TUTORIAL-game-config.txt](data/TUTORIAL-game-config.txt)
- Narrative voice rules: [data/VOICE-GUIDE.txt](data/VOICE-GUIDE.txt)
- Scoped instructions (GDScript architecture, scene structure, data content): [.github/instructions/](.github/instructions/)
- Agent workflows (add/rebalance content, investigate-before-changing, refactor main scene): [.github/prompts/](.github/prompts/)
