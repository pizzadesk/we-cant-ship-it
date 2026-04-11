# We Can't Ship It

A Godot 4 card-based roguelite about shipping an over-ambitious indie RPG. Players balance Ambition, Instability, and Soul to chase the Defining Game ending—a high-ambition, meaningfully janky, sincerely crafted project.

## Project Overview
- **Engine:** Godot 4.6.1
- **Language:** Typed GDScript
- **Content:** Data-driven via JSON, HJSON, and `.tres` resources
- **Core Fantasy:** Make risky feature decisions, turn bugs into memorable jank, and discover the broken combinations worth carrying into the next run.

## Gameplay Features
- **Feature Card System:** Place feature cards with unique tags and archetype affinities. All cards are data-driven resources.
- **Stat Management:** Balance Ambition, Instability, and Soul. Each action and card affects your stats and the final outcome.
- **Defining Game Status:** Achieve the Defining Game ending by meeting all stat thresholds—ambitious, janky, and sincere.
- **Dynamic Events:** Navigate dilemmas and draft offers. All events and offers are data-driven.
- **Run Arc:** One 5-day voice-finding run followed by three full attempts to ship the Defining Game.
- **Jank Discovery Loop:** Shipping reveals the run's signature jank and can unlock new cards for future runs.

## Technical Highlights
- **Strict Typing & Architecture:** All scripts use static typing and class_name. No direct UI-to-state mutation—state changes flow through AppState and GameEvents.
- **Fully Data-Driven:** All content and tuning values are externalized in data files. No hardcoded thresholds or content.
- **Extensible:** Add new cards, events, and endings via data files without code changes.

## Documentation
- [we_cant_ship_it_gdd.md](we_cant_ship_it_gdd.md): Current game design document.
- [data/game_config.tres](data/game_config.tres): All tuning values and thresholds.
- [data/cards/](data/cards/): All feature cards as `.tres` resources.
- [data/interaction_rules.json](data/interaction_rules.json): Flavor rules for shipped tag pairings.

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