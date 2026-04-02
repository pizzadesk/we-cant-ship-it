# We Can't Ship It — Game Design Document (Revised)

## Game Premise
You run a small indie studio across a **three-run cycle**, each run a 21-day sprint trying to ship an over-ambitious RPG. The game rewards balancing chaos with heart: instability is not automatically bad, but it becomes dangerous when soul is low. The ultimate aspiration is the **Defining Game** — a title like STALKER, Gothic, or The Witcher 1: janky, ambitious, unmistakably crafted with love. You have three attempts. Deliver the right jank. Fail and the cycle resets.

---

## Core Player Fantasy
- Make risky feature decisions under runway pressure.
- Turn accidental bugs into memorable "jank with soul."
- Chase the Goldilocks gate: ambitious enough, unstable enough, sincere enough.
- Build a recognizable studio identity across a three-run arc.

---

## The Three-Run Arc

The game is exactly three runs. This is communicated upfront on the main menu:

> "Three sprints. Ship something ambitious, a little broken, made with love. That's the goal."

Each run is ~10 minutes. The arc is:

| Run | Tone | Player State | Pressure Start |
|-----|------|--------------|----------------|
| 1 | Exploratory | Learning the system, wrong ending expected | Day 14 |
| 2 | Pressure | Knows enough to make meaningful mistakes | Day 10 |
| 3 | Convergence | Racing a known target with better cards | Day 7 |

Pressure start shifts mechanically each run — event popups arrive earlier, publisher meetings are more aggressive, dilemmas harder. Same content, escalating pace.

### Cycle Persistence Rules
- Cycle state **persists after each completed run**. A player who ships run 1 and closes the game returns to run 2.
- Quitting **mid-run** resets that run to its beginning. Cards unlocked from prior completed runs are preserved.
- Quitting **before run 1 is shipped** resets the entire cycle.
- On cycle completion (run 3 shipped): all three endings are evaluated together, the studio's three-game legacy is shown, Goldilocks resolved or cycle resets.

---

## Primary Run Structure

Each run starts with:
- Ambition: 0
- Instability: 0
- Soul: 12 *(raised from 10 — one Fix Bugs survivable without immediate Goldilocks disqualification)*
- Runway Days: 21

Run flow:
1. Build a board of feature cards from the daily offer.
2. Spend days on explicit actions (place card, fix bugs, dev log, ship it).
3. Navigate event popups (dilemmas, drafts, publisher meetings).
4. Ship when ready or when runway forces it.
5. Review, highlights, jank assessment, ending resolution.
6. Carry forward cycle state and card unlocks to next run.

---

## Core Stats and Their Roles

- **Ambition**: Project scope and creative reach. Drives score and ending eligibility.
- **Instability**: Technical chaos and emergent weirdness. Not inherently bad — the Goldilocks gate requires a meaningful range of it.
- **Soul**: Sincerity and creative conviction. The primary qualifier for the Defining Game ending. Depleted by bug fixing; recovered slowly through dev logs. **Capped at 15** — early Dev Log investment is meaningful but cannot trivialize the soul economy.
- **Runway Days**: Hard budget of decisions. Decreases only from player-facing actions and selected event effects.

---

## The Goldilocks Gate — Defining Game

The Defining Game ending is the apex outcome. It cannot be reached through identity bucket pressure alone — it requires all three stat thresholds to be met simultaneously at ship:

| Condition | Threshold |
|-----------|-----------|
| Ambition | ≥ 25 |
| Instability | 18 – 42 (inclusive) |
| Soul | ≥ 7 |

**Design intent:** A polished, soulless game doesn't qualify. An unambitious game doesn't qualify. A catastrophically unstable game doesn't qualify. Only a high-ambition, meaningfully janky, sincerely crafted project reaches this ending. Soul minimum lowered to 7 — one Fix Bugs cycle is survivable with discipline. Instability floor raised to 18 — passive common-card play alone cannot accidentally qualify.

---

## Main Player Actions

### Place Feature Card
- Adds the card's Ambition and Instability values to run totals.
- Can trigger tag interactions with existing board cards (see Card Interaction System).
- Costs 1 Runway Day.
- **Reason not to place:** Tag pollution may trigger harmful interactions. The day cost competes with Dev Log (soul recovery). Excess Instability can overshoot the Goldilocks range. Too much Ambition without Soul drifts toward Prestige Collapse.

### Fix Bugs
- Reduces Instability by 12.
- Costs **3 Soul** and 1 Runway Day.
- **Design intent:** Debugging near ship is demoralizing. Polish can drain creative conviction. This cost must be surfaced clearly in the UI. There is no winning line that uses Fix Bugs — this is intentional. The player should discover this, not be told. Contextual tooltip language shifts at Soul ≤ 6 to signal exhaustion without explaining the trap.

### Dev Log
- Increases Soul by 1. Soul cannot exceed 15.
- Costs 1 Runway Day.
- **Design intent:** Community reflection reinvigorates slowly. Recovering from one Fix Bugs action requires three Dev Log days — a brutal, realistic ratio. The Soul cap prevents early Dev Log spam from trivializing this tension.

### Ship It
- Triggers post-ship dialog chain and run resolution.
- No Runway Day cost.

---

## Feature Card System

Cards are `.tres` resources with the following schema:

| Field | Type | Description |
|-------|------|-------------|
| `feature_name` | String | Display name — intentionally imprecise. The archetype context produces the surprise. |
| `ambition_value` | int | Scope contribution (range by tier) |
| `instability_value` | int | Chaos contribution (range by tier) |
| `tier` | String | `"common"` / `"uncommon"` / `"rare"` |
| `unlock_weight` | float | Post-run unlock quality weighting. Higher = unlocked by better runs. |
| `tags` | PackedStringArray | Keywords for interaction matching |
| `archetype_affinity` | PackedStringArray | Which archetypes this card naturally belongs to. Empty = alien card. |
| `interactions` | Dictionary | Per-tag stat deltas: `{"tag": {"instability": N, "soul": N}}` |
| `interaction_flavor` | Dictionary | Per-tag flavor text for post-placement feed |

### Card Tiers and Value Ranges

| Tier | Ambition range | Instability range | Availability |
|------|---------------|-------------------|--------------|
| Common | 1 – 4 | 1 – 4 | All runs (available from run 1, remains in pool) |
| Uncommon | 1 – 6 | 1 – 6 | Run 2+ added to pool (cycle unlocks) |
| Rare | 1 – 10 | 1 – 10 | Run 3 added to pool (strong cycle performance) |

**Design intent:** The card pool available per run is the primary pacing mechanism. Run 1 common cards cannot reach Goldilocks thresholds reliably — this is by design. Pressure at midpoint happens naturally in runs 2–3 because the cards hit harder.

### Daily Offer
- Presents a rotating subset of unlocked cards filtered by tier availability.
- Players may skip today's offer, betting on a better card appearing tomorrow (opportunity cost design).

### Card Name Design
Card names are intentionally imprecise — they hint at a feeling, not a mechanic. The archetype seed chosen at run start interprets the card; the post-placement feed reveals what the team actually built.

---

## Archetype System

At run start, the player selects a target archetype: **RPG**, **Shooter**, or **Action-Adventure**. This seeds the run and is stored as `chosen_archetype` in cycle state.

Every card placement is evaluated against the chosen archetype via its `archetype_affinity` field:

| Affinity coverage | Meaning | Stat delta |
|---|---|---|
| 3/3 archetypes | Universal tool | Normal card values |
| 2/3 archetypes | Genre stretch | +2 Instability, flavor teases weirdness |
| 1/3 archetypes | Wild swing | +4 Instability, +2 Ambition, -1 Soul |
| 0/3 archetypes | Alien card | +8 Instability, +4 Ambition, -3 Soul |

**Alien cards** are the blackjack double-down. The player sees the risk before placing. Alien cards are **soul-gated** — placing one requires Soul ≥ 5. Below this threshold the card is visible but unplaceable, which creates late-run tension when Soul has been depleted.

**Archetype drift:** As alien and partial-affinity cards accumulate, the run's *actual* archetype diverges from the *chosen* archetype. This feeds the Cult Jank bucket and is the intended path to Legendary Jank — not a mistake, but a high-risk line.

### Pre-Placement Legibility
- Card tags always visible before placement.
- ⚡ interaction hint signals existence of an interaction. Magnitude is communicated via heat level: ⚡ (delta 1–4), ⚡⚡ (5–9), ⚡⚡⚡ (10+).
- Hint system is toggleable — can be disabled entirely if playtesting indicates it removes too much surprise.
- Archetype mismatch is signaled separately from tag interaction.

### Post-Placement Feed
```
"UNCONVENTIONAL INPUT in an RPG — the team is confused but intrigued.
 +4 Instability, +2 Ambition, -1 Soul"
```

---

## Card Interaction System

*(Unchanged from previous version — tag-based interactions, soul-gated rules, data-driven from interaction_rules.json)*

---

## Style Points Accumulation

| Action | Bucket | Delta |
|---|---|---|
| Place card where ambition_value > current Soul | Prestige Collapse | +ambition_value |
| Place card where ambition_value ≤ current Soul | Community Darling | +1 |
| Place card (always) | Cult Jank | +instability_value |
| Card has lore/quest/narrative/character/world tag | Community Darling | +3 |
| Dev Log | Community Darling | +4 |
| Fix Bugs | Prestige Collapse | +2 |
| Alien/mismatch card placement | Cult Jank | additional +instability delta |

**Design intent:** Prestige Collapse no longer accumulates unconditionally on every card. Ambition backed by soul feeds Community Darling instead. This makes Community Darling reachable without requiring lore-specific card draws.

---

## Mid-Run Event Layer

*(Unchanged structure — dilemmas, drafts, publisher meetings)*

Event offer intervals scale by current run number via a pressure factor:
```
pressure_factor = 1.0 + (0.3 × (current_run - 1))
effective_interval = base_interval / pressure_factor
```

Run 1 intervals unchanged. Run 2 ~30% faster. Run 3 ~60% faster.

---

## Publisher Trust Mode

*(Unchanged — optional toggle, off by default)*

---

## Identity and Style Pressure

*(Unchanged — Cult Jank, Prestige Collapse, Community Darling buckets)*

---

## Ending Outcomes

| Ending | Trigger Condition |
|--------|------------------|
| **Defining Game** | Goldilocks gate: Amb ≥ 25, Inst 18–42, Soul ≥ 7 |
| **Legendary Jank** | Cult Jank dominant, Instability ≥ 52 |
| **Cult Classic** | Cult Jank dominant, moderate Instability |
| **Surprise Hit** | Community Darling dominant, Soul ≥ 8, Score ≥ 6.5 |
| **Rough Diamond** | Amb < 15, Inst < 15, Soul ≥ 8 |
| **Cult Disaster** | Inst > 40, Soul < 5 |
| **Prestige Collapse** | Prestige Collapse dominant, Amb ≥ 25, Soul ≤ 6 |
| **Financial Catastrophe** | Prestige Collapse dominant, Soul ≤ 3 |

---

## Review and Scoring

*(Unchanged structure)*

Scoring coefficients adjusted for meaningful output range:
- `ambition_coefficient`: 0.14
- `instability_coefficient`: 0.05
- `soul_coefficient`: 0.15
- `soul_mitigation_factor`: 40.0

**Post-ship gap visualizer** (new): shown after every run, displays where each stat landed relative to the Goldilocks gate as a proportional bar — no numbers, no explanation. Player reads the gap and brings that knowledge into the next run.

```
AMBITION    ████████████░░  close
INSTABILITY ████░░░░░░░░░░  too low
SOUL        ██████████████  ✓
```

Bars show delta from a proportional baseline ("60% of the way there"), not distance from the ceiling.

---

## Cycle State — Replaces Meta Progression

The infinite meta progression system is replaced by a **cycle state** scoped to the three-run arc.

### Cycle State Schema
```
cycle_state:
  current_run: int           # 1, 2, or 3
  run_1_ending: String       # "" if not yet completed
  run_2_ending: String       # "" if not yet completed
  pressure_modifier: float   # derived from current_run
  unlocked_card_ids: []      # carries forward within cycle only
  cycle_complete: bool
```

Serialized to `user://cycle_state.json`.

### Card Unlocks Within Cycle
- Run 1 completion: unlocks 1–2 uncommon cards based on ending quality and near-miss gap
- Run 2 completion: unlocks 1–2 rare cards; near-Goldilocks run unlocks weirder, jankier cards
- Defining Game ending: unlocks 1 legendary jank card visible in cycle legacy screen

**Near-miss unlock logic:** The gap visualizer delta is used to weight which cards unlock. A player who nearly hit Goldilocks on instability receives cards that push instability higher. The unlock communicates direction without explanation.

### Cycle Resolution
On run 3 ship: all three endings evaluated together. A legacy screen shows the studio's three-game arc. If Goldilocks reached: cycle complete, legacy recorded. If not: cycle resets fully, new cycle begins from run 1 with base common card pool.

### Studio Tier and Reputation
Removed from active gameplay. Retained only as legacy flavor text shown on cycle completion screen — a record of what the studio built across attempts, not a mechanical modifier.

---

## Presentation and Tone

- UI intentionally degrades visually as Instability rises: wobble, tint, glitching, text corruption.
- The game voice is affectionate and sincere toward jank — never mocking.
- Choice prompts frame tradeoffs, not correct answers.
- The Fix Bugs soul cost must be communicated clearly in the UI.
- Main menu always shows current cycle position: "RUN 1 OF 3", "RUN 2 OF 3", "RUN 3 OF 3" with brief tone-appropriate copy.
- Upfront communication on first launch: *"Three sprints. Ship something ambitious, a little broken, made with love."* — no thresholds revealed, no mechanics explained.
- Post-ship gap visualizer uses proportional delta bars, not absolute numbers.
- Wrong ending on run 1 is framed as expected, not as failure. Tone: "The studio is finding its voice."
