# We Can't Ship It

A Godot 4 card-based roguelite about shipping an over-ambitious indie RPG. Players balance Ambition, Instability, and Soul to chase the Defining Game ending—a high-ambition, meaningfully janky, sincerely crafted project.

## Project Overview
- **Engine:** Godot 4.6.1
- **Language:** Typed GDScript
- **Content:** Data-driven via JSON, HJSON, and `.tres` resources
- **Core Fantasy:** Make risky feature decisions, turn bugs into memorable jank, and build a legendary studio identity across runs.

## Gameplay Features
- **Feature Card System:** Place feature cards with unique tags and interactions. All cards are data-driven resources.
- **Stat Management:** Balance Ambition, Instability, and Soul. Each action and card affects your stats and the final outcome.
- **Defining Game Status:** Achieve the Defining Game ending by meeting all stat thresholds—ambitious, janky, and sincere.
- **Dynamic Events:** Navigate dilemmas, drafts, and publisher meetings. All events and offers are data-driven.
- **Meta Progression:** Studio reputation, milestones, and unlocks persist across runs.

## Technical Highlights
- **Strict Typing & Architecture:** All scripts use static typing and class_name. No direct UI-to-state mutation—state changes flow through AppState and GameEvents.
- **Fully Data-Driven:** All content and tuning values are externalized in data files. No hardcoded thresholds or content.
- **Extensible:** Add new cards, events, and endings via data files without code changes.

## Documentation
- [GAME-DESIGN.md](GAME-DESIGN.md): Vision of the game.
- [CURRENT-STATE-GAME-DESIGNER.md](CURRENT-STATE-GAME-DESIGNER.md): High-level, game-designer-style overview of the current implementation and its alignment with the design vision.
- [CURRENT-STATE-TECHNICAL.md](CURRENT-STATE-TECHNICAL.md): Technical solution summary, detailing architecture, conventions, and code/data alignment.
- [data/game_config.tres](data/game_config.tres): All tuning values and thresholds.
- [data/cards/](data/cards/): All feature cards as `.tres` resources.
- [data/interaction_rules.json](data/interaction_rules.json): Tag interaction rules.

## Getting Started
1. Open the project in Godot 4.6.1 or later.
2. Run the main scene (`scenes/main.tscn`).
3. All content and tuning can be modified via the `data/` folder.

## Contributing
- Please read the documentation files above before making changes.
- All new content should be added via data files, not hardcoded.
- Follow strict typing and architecture conventions as described in the technical summary.

---

© pizzadesk. See LICENSE for details.