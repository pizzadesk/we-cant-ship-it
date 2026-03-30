# We Can't Ship It — Game Design Document (Revised)

## Game Premise
You run a small indie studio in a 21-day sprint trying to ship an over-ambitious RPG. The game rewards balancing chaos with heart: instability is not automatically bad, but it becomes dangerous when soul is low. The ultimate aspiration is the **Defining Game** — a title like STALKER, Gothic, or The Witcher 1: janky, ambitious, unmistakably crafted with love.

---

## Core Player Fantasy
- Make risky feature decisions under runway pressure.
- Turn accidental bugs into memorable "jank with soul."
- Chase the Goldilocks gate: ambitious enough, unstable enough, sincere enough.
- Build a recognizable studio identity across runs.

---

## Primary Run Structure

Each run starts with:
- Ambition: 0
- Instability: 0
- Soul: 10
- Runway Days: 21

Run flow:
1. Build a board of feature cards from the daily offer.
2. Spend days on explicit actions (place card, fix bugs, dev log, ship it).
3. Navigate event popups (dilemmas, drafts, publisher meetings).
4. Ship when ready or when runway forces it.
5. Review, highlights, jank assessment, ending resolution.
6. Carry forward meta progress, studio reputation, and legacy state.

---

## Core Stats and Their Roles

- **Ambition**: Project scope and creative reach. Drives score and ending eligibility.
- **Instability**: Technical chaos and emergent weirdness. Not inherently bad — the Goldilocks gate requires a meaningful range of it.
- **Soul**: Sincerity and creative conviction. The primary qualifier for the Defining Game ending. Depleted by bug fixing; recovered slowly through dev logs.
- **Runway Days**: Hard budget of decisions. Decreases only from player-facing actions and selected event effects.

---

## The Goldilocks Gate — Defining Game

The Defining Game ending is the apex outcome. It cannot be reached through identity bucket pressure alone — it requires all three stat thresholds to be met simultaneously at ship:

| Condition | Threshold |
|-----------|-----------|
| Ambition | ≥ 25 |
| Instability | 15 – 40 (inclusive) |
| Soul | ≥ 8 |

**Design intent:** A polished, soulless game doesn't qualify. An unambitious game doesn't qualify. A catastrophically unstable game doesn't qualify. Only a high-ambition, meaningfully janky, sincerely crafted project reaches this ending — reflecting the European jank classics that inspired it.

---

## Main Player Actions

### Place Feature Card
- Adds the card's Ambition and Instability values to run totals.
- Can trigger tag interactions with existing board cards (see Card Interaction System).
- Costs 1 Runway Day.
- **Reason not to place:** Tag pollution may trigger harmful interactions. The day cost competes with Dev Log (soul recovery). Excess Instability can overshoot the Goldilocks range. Too much Ambition without Soul drifts toward Prestige Collapse.

### Fix Bugs
- Reduces Instability.
- Costs **3 Soul** and 1 Runway Day.
- **Design intent:** Debugging near ship is demoralizing. Polish can drain creative conviction. This cost should be surfaced clearly in the UI — the player should feel what they're trading away.

### Dev Log
- Increases Soul by **1**.
- Costs 1 Runway Day.
- **Design intent:** Community reflection reinvigorates slowly. Recovering from one Fix Bugs action requires three Dev Log days — a brutal, realistic ratio that creates genuine late-run tension.

### Ship It
- Triggers post-ship dialog chain and run resolution.
- No Runway Day cost.

---

## Feature Card System

Cards are `.tres` resources with the following schema:

| Field | Type | Description |
|-------|------|-------------|
| `feature_name` | String | Display name |
| `ambition_value` | int | Scope contribution (range by tier) |
| `instability_value` | int | Chaos contribution (range by tier) |
| `tier` | String | `"common"` / `"uncommon"` / `"rare"` |
| `unlock_weight` | float | Post-run unlock quality weighting. Higher = unlocked by better runs. |
| `tags` | PackedStringArray | Keywords for interaction matching |
| `interactions` | Dictionary | Per-tag stat deltas: `{"tag": {"instability": N, "soul": N}}` |
| `interaction_flavor` | Dictionary | Per-tag flavor text for post-placement feed: `{"tag": "flavor string"}` |

### Card Tiers and Value Ranges

| Tier | Ambition range | Instability range | Unlock condition |
|------|---------------|-------------------|-----------------|
| Common | 1 – 4 | 1 – 4 | Available from run 1 |
| Uncommon | 1 – 6 | 1 – 6 | Unlocked by moderate endings |
| Rare | 1 – 10 | 1 – 10 | Unlocked by strong endings only |

Rare cards enable the Goldilocks gate more easily but push Instability dangerously high — meaningful risk/reward.

### Daily Offer
- Presents a rotating subset of unlocked cards filtered by tier availability.
- Players may skip today's offer, betting on a better card appearing tomorrow (opportunity cost design).

---

## Card Interaction System

Interactions are resolved when a card is placed onto the board. If any of the placed card's tags match tags present on existing board cards, the interaction dictionary is evaluated and stat deltas are applied.

### Pre-Placement Legibility
- Card tags are always visible before placement.
- If a placed card's tags overlap with any existing board card, a subtle **⚡ indicator** appears — signaling that an interaction exists without revealing its outcome.
- This preserves discovery while preventing blind placement.

### Post-Placement Feed
After placement, a feed entry summarizes what happened:
> *"PHYSICS + OPEN WORLD — something broke beautifully. +4 Instability, -1 Soul"*

This teaches the interaction system to players naturally across runs without front-loading information.

### Interaction Rules
- Fully data-driven from `interaction_rules.json`.
- Tag pairs can produce: Instability delta, Soul delta, flavor text.
- Some interactions are soul-gated — only triggering if Soul ≥ threshold, rewarding prior sincerity investment.

---

## Mid-Run Event Layer

Scheduled offer systems introduce high-impact choices at runway intervals:

- **Dilemmas**: Binary tradeoff events. Both choices have meaningful costs and benefits — no correct answer.
- **Drafts**: 3-option producer pitch picks affecting stats and runway.
- **Publisher Meetings** *(optional — see Publisher Trust Mode)*: 3-stance choices with trust implications.

Events can shift stats, runway days, and style pressure buckets.

---

## Publisher Trust Mode (Optional Toggle)

Enabled at run start. Off by default.

When enabled, Publisher Trust is a run modifier representing how much creative freedom you retain:
- **High trust**: Publisher leaves you alone. More creative latitude.
- **Low trust**: Publisher intrudes via dilemmas that pull toward safe, soulless choices — directly threatening the Goldilocks gate.

Trust is affected by publisher meeting stance choices during the run. This mode adds pressure for experienced players without complicating the base game.

---

## Identity and Style Pressure

The run tracks three pressure buckets accumulating from card tags, dilemma choices, and publisher stances:

| Bucket | Driven by |
|--------|-----------|
| Cult Jank | High instability cards, chaotic tag combos, "lean into it" dilemma choices |
| Prestige Collapse | High ambition + low soul patterns, publisher-pleasing choices |
| Community Darling | Moderate ambition, soul investment, accessible tag combos |

The **dominant bucket at ship** weights ending selection within its cluster. No bucket dominance triggers the Rough Diamond path.

---

## Ending Outcomes

| Ending | Trigger Condition |
|--------|------------------|
| **Defining Game** | Goldilocks gate: Amb ≥ 25, Inst 15–40, Soul ≥ 8 (stat-gated, bucket-independent) |
| **Legendary Jank** | Cult Jank dominant, high Instability |
| **Cult Classic** | Cult Jank dominant, moderate Instability |
| **Surprise Hit** | Community Darling dominant, decent Soul |
| **Rough Diamond** | Amb < 15, Inst < 15, Soul ≥ 8 — small, sincere, unremarkable but honest |
| **Cult Disaster** | Inst > 40, Soul < 5 — swung for jank glory with no heart to save it |
| **Prestige Collapse** | Prestige Collapse dominant, high Ambition, low Soul |
| **Financial Catastrophe** | Prestige Collapse dominant, critical stat failure |

**Defining Game, Rough Diamond, and Cult Disaster are stat-gated and bucket-independent.** All other endings are weighted by dominant identity bucket then resolved by stat thresholds within that cluster.

---

## Review and Scoring

On ship, the run produces:
- A **review score** derived from Ambition, Instability range, Soul contribution, and ship-window timing bonus/penalty.
- **Four reviewer outputs** with distinct voices and weighted text pools.
- **Mechanics highlights** derived from shipped card interactions.
- **Jank status assessment** based on ending resolution.

---

## Meta Progression — Studio Reputation

### Studio Tiers

| Tier | Name | Unlock Condition |
|------|------|-----------------|
| 1 | Shovelware Studio | Starting tier |
| 2 | Cult Outfit | Accumulated reputation |
| 3 | Beloved Auteur | Strong sustained reputation |
| 4 | Legendary Dev | Requires at least one Defining Game ending |

### Reputation Points Per Ending

| Ending | Rep |
|--------|-----|
| Defining Game | +4 |
| Legendary Jank / Surprise Hit | +3 |
| Cult Classic / Rough Diamond | +2 |
| Prestige Collapse | +1 |
| Cult Disaster / Financial Catastrophe | -1 |

Tier is assessed from cumulative rep and can downgrade if subsequent runs underperform.

### 3-Run Milestone Cycle
The game is infinite runs. Every 3 runs triggers a **studio retrospective**:
- Legacy marker recorded
- Narrative beat surfaced
- Tier formally assessed and updated

This creates authored arc moments without forcing resets.

### Card Unlocks
- Every run unlocks at least 1–2 common cards (the floor — struggling players always progress).
- Good endings unlock 1 high-ambition card.
- Defining Game endings unlock 1 legendary jank card + a permanent legacy marker.
- Unlock selection is quality-weighted by `unlock_weight` on each card resource.

### Persisted Meta State
- Runs played / best score
- Studio tier and reputation total
- Unlocked card IDs
- Publisher trust profile *(if Publisher Trust Mode enabled)*
- Legacy records (active/pending)
- Defining-game unlock flag
- `runs_since_milestone` counter
- `milestone_history` array

Serialized to `user://meta_progress.json`.

---

## Presentation and Tone

- UI intentionally degrades visually as Instability rises: wobble, tint, glitching, text corruption.
- The game voice is affectionate and sincere toward jank — never mocking.
- Choice prompts frame tradeoffs, not correct answers.
- The Fix Bugs soul cost must be communicated clearly in the UI — players should feel what polish takes from them.
- The ⚡ interaction hint should be subtle enough to preserve discovery while eliminating blind placement.
