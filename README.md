# We Can't Ship It

A Godot 4 card-based roguelite about shipping an over-ambitious indie RPG. Players balance Ambition, Instability, and Soul to chase the Defining Game ending—a high-ambition, meaningfully janky, sincerely crafted project.

## Project Overview
- **Engine:** Godot 4.6.1
- **Language:** Typed GDScript
- **Content:** Data-driven via JSON and `.tres` resources
- **Core Fantasy:** Make risky feature decisions, turn bugs into memorable jank, and discover the broken combinations worth carrying into the next run.

## Gameplay Features
- **Feature Card System:** Place feature cards with archetype affinities, visible risk states, and responsive board packing.
- **Stat Management:** Balance Ambition, Instability, and Soul while reading a live Defining Game target band and safety states.
- **Four-Run Arc:** One 5-day voice-finding run followed by three 19-day real attempts to ship the Defining Game.
- **Mid-Run Signature Jank:** Authored jank pairs surface prospect hints, can lock immediately during the run, and grant an instant Soul reward.
- **Prospect Chase Support:** The daily backlog remains archetype-weighted, but an active prospect softly boosts the exact missing partner card so locks feel chaseable rather than random.
- **Dynamic Events:** Navigate dilemmas and draft offers. Scheduling, thresholds, and choice fallout are data-driven.
- **Studio Console:** A live in-game log records actions, offers, threshold beats, prospects, and signature locks beneath the board.
- **Reviewer Roulette:** Post-ship reviews react to the build that actually shipped, with outlet-specific voices anchored to signature jank and its memeology.

## Technical Highlights
- **Strict Typing & Architecture:** All scripts use static typing and class_name. State changes flow through AppState and GameEvents rather than direct UI mutation.
- **View/Controller Split:** `main.gd` wires scene-level behavior while panel, board, sidebar, dialog, and post-ship presentation logic stay in focused view/controller scripts.
- **Fully Data-Driven:** Tuning, cards, offers, threshold events, and signature jank recipes are externalized in data files.
- **Extensible:** Add new cards, events, strings, and jank combinations largely through data rather than architecture changes.

## Documentation
- [we_cant_ship_it_gdd.md](we_cant_ship_it_gdd.md): Current game design document.
- [data/game_config.tres](data/game_config.tres): All tuning values and thresholds.
- [data/game_config_override.json](data/game_config_override.json): Live tuning overrides currently defining shipped balance.
- [data/cards/](data/cards/): All feature cards as `.tres` resources.
- [data/jank_combinations.json](data/jank_combinations.json): Authored prospect and signature jank recipes.
- [data/VOICE-GUIDE.txt](data/VOICE-GUIDE.txt): Source of truth for card, console, popup, and review voice.
- [data/COLLABORATOR-GUIDE.txt](data/COLLABORATOR-GUIDE.txt): Non-programmer editing guide for tuning, cards, strings, and jank combos.

## Getting Started
1. Open the project in Godot 4.6.1 or later.
2. Run the main scene (`scenes/main.tscn`).
3. All content and tuning can be modified via the `data/` folder.

## Contributing
- Please read the documentation files above before making changes.
- All new content should be added via data files, not hardcoded.
- Follow strict typing and architecture conventions as described in the technical summary.
- If gameplay or UI behavior changes materially, update the GDD and collaborator guide in the same pass.

---

© pizzadesk. See LICENSE for details.