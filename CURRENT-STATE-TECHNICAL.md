# We Can't Ship It — Technical Solution State

## Architecture Overview
- **Godot 4.6.1, Typed GDScript**: Strict typing and class_name usage throughout.
- **Autoload Singletons**: AppState (state), GameEvents (signals), ReviewService, StageDirector, DecorationLayer. No new autoloads added.
- **Data-Driven Content**: All cards, offers, endings, and config values are externalized in .tres, .json, or .hjson files.
- **UI/State Pipeline**: UI emits intent → AppState mutates state → AppState emits via GameEvents → UI reacts. No direct UI-to-state mutation.
- **Signals**: All signals use typed resource payloads, never untyped dictionaries.

## Core Systems Implementation
- **Feature Cards**: Resource schema matches design doc. All stat deltas and interactions are dictionaries with explicit keys.
- **Interaction System**: Pre-placement (read-only, for hints) and post-placement (full resolution) logic is separated. All rules are data-driven.
- **Endings**: Resolution order matches design doc. Stat-gated endings checked first, then bucket identity, then fallback.
- **Meta Progression**: Studio reputation, milestones, and unlocks are tracked in AppState and meta state.
- **Publisher Trust Mode**: Boolean flag in run state, modifies dilemma weighting, persists only when enabled.

## Resource & Data Management
- **VisualPalette**: Only one script with class_name VisualPalette. All UI theming is resource-driven.
- **GameConfig**: All tuning values (thresholds, costs) are exported in game_config.tres and referenced in code.
- **No Hardcoded Content**: All content and tuning is externalized; code only references data.

## Code Quality & Conventions
- **Strict Typing**: All scripts use static typing and class_name for resources.
- **No Nested Functions**: All functions are top-level; static context is used where appropriate.
- **No Magic Numbers**: All thresholds and costs reference GameConfig.
- **No Untyped Signals**: All signals use typed resource payloads.
- **No Direct UI Mutation**: All state changes flow through AppState.

## Error State & Regression
- All parse and runtime errors (class_name conflicts, resource loading) have been resolved.
- VisualPalette resource loads cleanly; no duplicate class_name remains.
- All UI palette scripts parse and load without error.

## Extensibility & Maintenance
- New cards, events, and endings can be added via data files.
- Tuning is centralized in game_config.tres.
- Codebase is modular, with clear separation of data, logic, and UI.

---

# Summary
The technical implementation is robust, modular, and fully data-driven. All architecture and code conventions from the design doc are enforced. The project is ready for further tuning, polish, and content expansion with minimal risk of regression.