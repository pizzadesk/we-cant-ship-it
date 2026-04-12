# data/ — Content Layer

All game content lives here. **No GDScript knowledge required to edit these files** — they are plain text (JSON, `.tres`).

**For collaborators and playtesters:** start with [`COLLABORATOR-GUIDE.txt`](COLLABORATOR-GUIDE.txt). It covers all three things you can change (game rules, cards, text) without touching any code.

| File | Purpose |
|---|---|
| `COLLABORATOR-GUIDE.txt` | Entry point — read this first |
| `TUTORIAL-game-config.txt` | Full parameter reference for `game_config_override.json` |
| `game_config_override.json` | Drop-in numeric override for all game balance values |
| `custom_cards/TUTORIAL.txt` | Step-by-step guide for making a custom feature card |

---

## strings/

UI text, organised by concern. Edit in any text editor. Changes take effect on next game run.

| File | Contents |
|---|---|
| `buttons.json` | Button labels (Ship It!, Keep Current Legacy, Pick C, etc.) |
| `tooltips.json` | Action button tooltips (Fix Bugs, Dev Log, Ship It with context-sensitive variants) |
| `log_messages.json` | Studio event feed messages (feature added, interactions, day spent, onboarding, etc.) |
| `popups.json` | Dialog titles, ship summary headers, jank meter labels/flavours, review intros per ending, ending epilogues, choice effect text, stat names |
| `card_ui.json` | Card widget display strings (stat format, progress label, "Feature Unknown", variant note, etc.) |

**Voice guide:**
- Read `VOICE-GUIDE.txt` before editing any narrative copy.
- The feature card descriptions are the gold standard for all other text surfaces.
- Players are never told there is a correct choice.

---

## cards/

Feature card definitions. Each `.tres` is a `FeatureCard` resource with:
- `feature_name` — display name shown in UI
- `ambition_value` — ambition added when dropped onto the board
- `instability_value` — instability added per drop
- `tags` — array of strings; used for review flavor and post-ship interpretation (see `interaction_rules.json`)
- `interactions` — optional per-card override dictionary

These are plain text files. You can open them in VS Code and edit values directly. Available tags: `physics`, `horses`, `combat`, `inventory`, `ui`, `multiplayer`, `quest`, `lore`, `weather`, `animation`.

---

## custom_cards/

Add your own cards here. Copy `card_template.tres`, rename it, and edit the fields. See `TUTORIAL.txt` for full instructions. Custom cards are automatically picked up by the game's daily offer system.

---

## interaction_rules.json

Defines flavor text for noteworthy tag pairings inside shipped builds. These rules do not change live gameplay stats. They exist to help reviews describe what kind of mess the studio actually shipped. Structure:
```json
{
  "rules": [
    {
      "tags": ["tag_a", "tag_b"],
      "instability_delta": 3,
      "soul_delta": 2,
      "flavors": ["Flavor text for reviews. Tokens: {tag_a} {tag_b} {new_feature} {existing_feature}"],
      "soul_required": 20
    }
  ]
}
```
`soul_required` is optional — omit it and the flavor line can always appear.

---

## stage_themes/

Four `.tres` resources defining the visual identity at each stage of a run (tied to runway days remaining). Placeholder values only — real assets blocked by photography session.

| File | Stage | Runway Remaining |
|---|---|---|
| `stage_1_vscode.tres` | VSCode — confident, monospace | ≥ 15 days |
| `stage_2_agile.tres` | Agile/Notion — warming, drifting | ≥ 10 days |
| `stage_3_desk.tres` | Physical desk — corkboard, masking tape | ≥ 5 days |
| `stage_4_fridge.tres` | Fridge — post-its, magnets, marker font | ≥ 0 days |

---

## game_config.tres

All numeric thresholds for the run: score formula coefficients, ending conditions, action economy (fix bugs cost, dev log gain), jank status zone boundaries, offer scheduling intervals. Edit here to tune balance — **do not hardcode numbers in GDScript**.

---

## review_pools.json

Weighted review text pools used by ReviewService for the four reviewer archetypes (MegaScore Weekly, HorseQuestFanForum, steam_user_2000h, Indie Orbit). Do not add new archetypes without instruction — the structure is tightly coupled to ReviewService.

Reviewers must stay outlet-specific while still reacting to the shipped game that actually exists. Signature jank and meme-family language should be preferred over generic genre chatter.

If you add a new `meme_families` value in `jank_combinations.json`, update the reviewer pools in the same pass or the new folklore category will have no outlet-specific reaction lines.

---

## jank_combinations.json

Authored mid-run prospect and signature-jank recipe list. Each entry can define the card pair, archetype, name, description, prospect title, prospect hint, lock-in line, and optional `meme_families` metadata.

Important runtime behavior:
- The first exact lock in a run becomes the canonical signature jank for that run.
- While a prospect is active, the backlog softly boosts the exact missing partner card so the pursuit is chaseable but not guaranteed.
- Signature jank discovered at lock or ship time is what reviewers and post-ship recap screens talk about.

---

## offers.json

Defines all dilemma and draft events that fire during a run. Add new events here; the offer scheduling system in AppState picks them up automatically.
