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
| `popups.json` | Dialog titles, ship summary headers, jank meter labels/flavours, review roulette intros per ending, ending epilogues, choice effect text, stat names |
| `publisher.json` | All publisher dialog text — English bureaucratic absurdist voice. Edit tone here, not in code. Keys: `memorandum_header`, `grades`, `summaries`, `labels`, `effect_names`. |
| `help.json` | Help dialog body — stored as an array of lines for easy editing. One array entry = one paragraph or blank line. |
| `card_ui.json` | Card widget display strings (stat format, progress label, "Feature Unknown", variant note, etc.) |

**Voice guide:**
- General UI: broken but sincere English — chaotic, affectionate, eurojank energy
- Publisher dialogs: cold, formal, procedurally absurd — "Case Reference:", "Tentatively Viable", "Operationally Unacceptable"
- Players are never told there is a correct choice

---

## cards/

Feature card definitions. Each `.tres` is a `FeatureCard` resource with:
- `feature_name` — display name shown in UI
- `ambition_value` — ambition added when dropped onto the board
- `instability_value` — instability added per drop
- `tags` — array of strings; overlapping tags between cards trigger interactions (see `interaction_rules.json`)
- `interactions` — optional per-card override dictionary

These are plain text files. You can open them in VS Code and edit values directly. Available tags: `physics`, `horses`, `combat`, `inventory`, `ui`, `multiplayer`, `quest`, `lore`, `weather`, `animation`.

---

## custom_cards/

Add your own cards here. Copy `card_template.tres`, rename it, and edit the fields. See `TUTORIAL.txt` for full instructions. Custom cards are automatically picked up by the game's daily offer system.

---

## interaction_rules.json

Defines what happens when two cards with overlapping tags are both on the board. Structure:
```json
{
  "rules": [
    {
      "tags": ["tag_a", "tag_b"],
      "instability_delta": 3,
      "soul_delta": 2,
      "flavors": ["Flavor text shown in the event feed. Tokens: {tag_a} {tag_b} {new_feature} {existing_feature}"],
      "soul_required": 20
    }
  ]
}
```
`soul_required` is optional — omit it and the interaction fires regardless of current soul.

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

---

## offers.json

Defines all dilemma, draft, and publisher meeting events that fire during a run. Add new events here; the offer scheduling system in AppState picks them up automatically.
