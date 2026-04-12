**WE CAN\'T SHIP IT**

Game Design Document

*Revised Edition*

*Four runs. One to find the voice. Three to prove it.*

**1. Game Premise**

You run a small indie studio across a four-run cycle. Run 1 is a short
5-day voice-finding sprint. Runs 2-4 are 19-day attempts to ship
an over-ambitious game. The game rewards balancing chaos with heart.
Instability is not automatically bad --- it becomes dangerous only at
extremes. The ultimate aspiration is the Defining Game: a title like
STALKER, Gothic, or The Witcher 1 --- janky, ambitious, unmistakably
crafted with love.

**You get one short run to find the voice, then three real attempts.
Deliver the right jank. Fail and the cycle resets.**

**Core Player Fantasy**

-   Make risky feature decisions under runway pressure.

-   Turn accidental bugs into memorable jank with soul.

-   Chase the Defining Game: ambitious enough, unstable enough,
    sincere enough.

-   Notice a signature jank prospect forming mid-run, then decide
    whether to stabilize it or feed it until it locks.

-   Discover what your specific broken game accidentally created --- and
    carry that studio identity across the cycle.

-   Build a recognizable studio identity across a four-run arc.

**2. The Four-Run Arc**

The game is exactly four runs, communicated upfront on the main menu:

> *\"Four runs. One to find the voice. Three to prove it. That's the
> goal.\"*

Each run is approximately 10 minutes. The arc escalates in pressure and
available card power:

-   **Run 1 / Exploratory** --- 5-day voice-finding sprint. Common-only
    pool. Defining Game locked. Signature pursuit introduced as the
    reward structure.

-   **Run 2 / Pressure** --- first real attempt. 19-day runway. Common
    plus Uncommon cards. Earlier event pressure and more meaningful
    mistakes.

-   **Run 3 / Convergence** --- second real attempt. 19-day runway.
    Common, Uncommon, and Rare cards. Stronger swings and more decisive
    draft pressure.

-   **Run 4 / Final Shot** --- last attempt to ship the Defining Game.
    19-day runway. Full pressure, full pool, least room for hesitation.

Pressure scaling is communicated as pacing rather than exact day
promises. Event offers arrive earlier, draft cadence is more aggressive,
and collisions between draft and dilemma events are deferred rather than
suppressed so the player still sees the choice.

**Run 1: Pedagogical Contract**

Run 1 is explicitly a 5-day jank prospecting tutorial sprint. The
Defining Game is shown as locked on the post-ship gap visualizer ---
players learn the rhythm without chasing an unreachable target. The
wrong ending is framed as expected, not as failure:

> *\"The studio is finding its voice.\"*

This reframes Run 1 as discovery rather than punishment. Players leave
Run 1 knowing what jank their specific board produced. That knowledge
--- not a score --- is the reward.

**Cycle Persistence Rules**

-   Cycle state persists after each completed run. A player who ships
    Run 1 and closes the game returns to Run 2, the first real attempt.

-   Quitting mid-run resets that run to its beginning. Jank cards and
    unlocks from prior completed runs are preserved.

-   Quitting before Run 1 is shipped resets the entire cycle.

-   On cycle completion (Run 4 shipped): all four endings are evaluated
    together, the studio's studio arc is shown, Defining Game reached
    or cycle resets.

**Returning Player Recap**

On returning to a saved cycle, a \'Previously On\' screen is shown
before the run begins:

-   Gap visualizer delta from the last completed run.

-   Which jank cards were unlocked, named alongside the two source cards
    that produced them. (e.g. "Physics Playground + Dialogue System →
    The Yeetable NPC.")

-   Current run number with tone-appropriate studio voice copy.

This screen is the only onboarding. No mechanics are re-explained.

**3. Core Stats**

Three stats. Every card placement moves them. The Defining Game is
your 21.

  -------------------------------------------------------------------------
  **Stat**      **Role**                                   **Starting
                                                           Value**
  ------------- ------------------------------------------ ----------------
  Ambition      Project scope and creative reach. Drives   0
                ending eligibility.                        

  Instability   Technical chaos and emergent weirdness.    0
                Not inherently bad --- the Defining Game 
                requires a meaningful range of it.         
                Overshooting is your bust.                 

  Soul          Sincerity and creative conviction. The     12
                primary qualifier for the Defining Game.   
                Depleted by fixing bugs; recovered through 
                dev logs.                                  
  -------------------------------------------------------------------------

Runway Days: 5 in Run 1, 19 in Runs 2-4. Decreases only from
player-facing actions and selected event effects. This is the dealer\'s
upcard --- it forces your hand.

**4. The Defining Game**

The Defining Game ending is the apex outcome. It requires all three stat
thresholds simultaneously at ship:

  -------------------------------------------------------------------------
  **Stat**      **Threshold**      **Design Intent**
  ------------- ------------------ ----------------------------------------
  Ambition      ≥ 25               An unambitious game doesn\'t qualify.

    Instability   Within the chosen   A polished or catastrophically broken
                                archetype window    game doesn\'t qualify. The live HUD
                                                                     shows the current run\'s target band
                                                                     from Run 2 onward.

  Soul          ≥ 7                A soulless game doesn\'t qualify. One
                                   Fix Bugs cycle is survivable with
                                   discipline.
  -------------------------------------------------------------------------

The Defining Game is locked in Run 1. It is unlocked in Run 2, the
first real attempt, and shown in two places: the live Defining Game
readout during the run and the post-ship gap visualizer after release.
Run 1 remains discovery-first; Runs 2-4 are explicit enough to support
meaningful tactical play.

**5. Main Player Actions**

Four actions. Hit or stand --- every choice costs a day except shipping.

**Place Feature Card**

-   Adds the card\'s Ambition and Instability values to run totals.

-   Triggers archetype interpretation and mid-run jank prospecting.

-   If an exact authored jank pair completes, the run immediately locks
    a canonical signature jank, grants +1 Soul once, and preserves that
    result through ship.

-   Costs 1 Runway Day.

*Reasons not to place: Instability may overshoot the Defining Game ceiling.
The day competes with Dev Log for soul recovery. The combination on your
board may produce unwanted jank --- or exactly the signature prospect you\'re
hunting.*

**Fix Bugs**

-   Reduces Instability by 10.

-   Costs 2 Soul and 1 Runway Day.

-   Also applies a small Ambition penalty (-2) --- the team loses
    momentum.

*Design intent: Fix Bugs is a genuine dilemma, not a trap. It is
situationally correct when you are above the Defining Game instability
ceiling with enough Soul to absorb the cost. Players should discover
this through play. The UI surfaces the soul cost explicitly --- no
hidden mechanics.*

**Dev Log**

-   Increases Soul by 1.

-   Costs 1 Runway Day.

*Design intent: Recovering from one Fix Bugs action requires two Dev Log
days --- a realistic, painful ratio. Every Dev Log day is a card not
placed. The action should feel like a reluctant defensive move, not a
routine rotation.*

**Ship It**

-   Triggers post-ship dialog chain and run resolution.

-   No Runway Day cost.

-   Can be triggered voluntarily or forced when Runway reaches 0.

-   Shipping timing carries a review score consequence. The same stat
    profile shipped at different points in the runway reads differently
    to critics.

**Ship Window**

  -----------------------------------------------------------------------
  **Window**          **Trigger**                    **Review Impact**
  ------------------- ------------------------------ --------------------
    Too Early           Ship with ≥ 12 Runway Days     −0.5 score. "You
                      remaining.                     shipped before the
                                                     jank had time to
                                                     become culture."

  Standard Launch     Mid-runway window.             No modifier.

  Sweet Spot          Narrow window of remaining     Score bonus. "You
                      Runway and matching             shipped at peak
                      Instability range.             chaos without total
                                                     collapse."

  Last-Minute Panic   Ship with ≤ 2 Runway Days      −0.4 score. "You
                      remaining.                     shipped in full
                                                     panic mode."
  -----------------------------------------------------------------------

*Design intent: Ship It is not just a stat threshold check. Timing is a
second dimension. Shipping too early reads as undercooked; shipping in
blind panic reads as unfinished. The sweet spot rewards players who read
the board and commit before runway forces their hand. Timing still
matters even for otherwise strong builds, so the player is pushed to
read the board rather than rely on a single threshold crossing.*

**6. Archetype System**

At run start, the player selects a target archetype: RPG, Shooter, or
Action-Adventure. This is a real strategic commitment --- not a genre
skin. Archetype does three things:

-   Sets the Defining Game Instability window for this run.

-   Strongly weights the daily offer toward on-archetype cards while
    still allowing off-brief and alien cards to surface occasionally.

-   Acts as the interpretive lens for emergent jank --- the same card
    combination produces different jank outcomes depending on archetype.

**Defining Game Windows by Archetype**

  ---------------------------------------------------------------------------
  **Archetype**      **Instability    **Risk Profile**
                     Window**         
  ------------------ ---------------- ---------------------------------------
  RPG                12 -- 54         Widest window. Tolerates scope sprawl
                                      and system collision. Harder to bust,
                                      lower peak reward.

  Action-Adventure   15 -- 50         Balanced. Default difficulty. The
                                      reference line.

  Shooter            18 -- 42         Tightest window. High risk, highest
                                      reward for Defining Game. One alien
                                      card can bust you.
  ---------------------------------------------------------------------------

**Offer Weighting and Friction**

The daily backlog is weighted rather than hard-filtered. Cards that fit
the chosen archetype appear much more often, universal cards stay common,
and off-genre or alien cards still break through often enough to create
temptation and mismatch friction.

This keeps archetype selection feeling like a commitment without turning
the run into a sealed lane. The player is usually offered the kind of
game they said they were making, but the backlog can still tempt them
into a reach, a wild swing, or a studio identity crisis.

When a signature jank prospect is active, the exact missing partner card
gets a temporary offer-weight bonus and is allowed back into the backlog
rotation even if it was already shown earlier in the run. The intended
feel is "chaseable, not guaranteed."

**Archetype Mismatch Penalty**

Placing a card outside its native archetype applies a friction penalty
derived from how far the card is from the chosen genre. This is the
mechanical expression of the strategic commitment archetype selection
demands. Four levels:

  -------------------------------------------------------------------------------
  **Level**             **Condition**                        **Effect**
  --------------------- ------------------------------------ --------------------
  None                  Card is on-archetype, or universal   No modifier.
                        (covers all three archetypes).

  Genre Stretch (~)     Card covers 2 archetypes; the        +2 Instability.
                        chosen run is the third.

  Wild Swing (⚠)        Card covers 1 archetype; not the     +4 Instability,
                        chosen run.                          +2 Ambition, −1
                                                             Soul.

  Alien (☠)             Card has no archetype affinity.      +8 Instability,
                        Radically off-genre.                 +4 Ambition, −3
                                                             Soul. Placement
                                                             requires Soul ≥ 5.
  -------------------------------------------------------------------------------

*Design intent: Genre stretch is a considered reach into adjacent territory.
Wild swing is a team confused but intrigued. Alien cards are a studio identity
crisis --- high-variance, potentially legend-making, costly enough to demand
conviction. The Soul gate prevents desperation alien placements: the player
must have enough sincerity to survive the disruption.*
**7. Feature Card System**

Cards are the primary decision surface. Every card has a name, an
Ambition value, an Instability value, a tier, and an archetype affinity.
Card names are intentionally imprecise --- they hint at a feeling, not a
mechanic.

**Card Tiers**

  ------------------------------------------------------------------------
  **Tier**    **Ambition      **Instability    **Availability**
              Range**         Range**          
  ----------- --------------- ---------------- ---------------------------
  Common      1 -- 4          1 -- 4           All runs

  Uncommon    1 -- 6          1 -- 6           Run 2+ (cycle unlocks)

  Rare        1 -- 10         1 -- 10          Run 3 (strong cycle
                                               performance)

  Jank        Variable        Variable         Unlocked post-run via board
                                               combination discovery
  ------------------------------------------------------------------------

Run 1 common cards cannot reach Defining Game thresholds reliably. This is
by design. Pressure at midpoint happens naturally in Runs 2--3 because
the cards hit harder.

**Daily Offer --- Pick One of Three**

Each day, three cards are presented face-up. The player picks one. The
other two are usually discarded for the rest of the run. No skipping, no
reroll. The one explicit exception is a live signature-jank prospect:
the exact missing partner card can be reintroduced with a temporary
weight bonus so the pursuit stays legible.

*Design intent: Blackjack doesn't offer a reroll. The tension is in the
choice between three known options today. Passive waiting is not
available. The constraint is scarcity of decisions, not scarcity of
time, while prospect chase support prevents the most exciting hook from
depending entirely on blind churn.*

**8. Emergent Jank System**

This is the game\'s core differentiator. The board is evaluated on every
feature placement for authored jank combinations. Specific pairings ---
interpreted through the run\'s archetype --- first form a prospect, then
can lock into a canonical signature jank for the run. The post-ship
screen confirms and archives what the player already felt taking shape.

**The Combinatorial Matrix: Principle**

Jank is not derived from stats. It is derived from what cards were on
your board and which archetype gave them meaning. The formula is:

**Card A + Card B + Archetype = Jank Card**

The current implementation uses authored pairs rather than freeform
clusters. The matrix is intentionally not exhaustive. The hook is not
raw permutation volume; it is pursuit of legible, named signature jank.

**Prospecting Layer**

-   When one half of a valid authored pair appears on the board in the
    correct archetype context, the game surfaces a prospect title and
    hint mid-run.

-   The player sees this through a prominent banner and a persistent
    jank-state strip on the board.

-   Once a prospect is live, the daily backlog softly biases toward the
    exact missing partner card so the player can meaningfully chase the
    lock instead of waiting on ordinary offer churn.

-   The first exact lock in a run becomes the canonical signature jank
    for that run. Later matches do not replace it.

-   Locking a signature jank grants +1 Soul immediately. This makes the
    hook feel rewarding in the moment, not only in post-ship recap.

The matrix does not need to be exhaustive. An uncovered combination
ships without notable jank --- not every broken game becomes legendary.

**Illustrative Combination Examples**

-   **Ragdoll Physics + Deep Branching Dialogue + RPG -> The Yeetable
    NPC**
    Quest NPCs can be launched off geometry. Speedrunners found a clip
    through the final boss. Beloved.

-   **Ragdoll Physics + Deep Branching Dialogue + Shooter -> Ragdoll
    Monologue**
    Enemies deliver scripted death speeches mid-ragdoll. Somehow
    emotional.

-   **Faction Reputation + Dynamic Faction Wars + RPG -> The Infinite
    Betrayal**
    Faction loyalty re-evaluates every tick against war state. Every
    merchant is secretly hostile. Players wrote lore about it.

-   **Firearm Customization + Day Night Cycle + Shooter -> Midnight
    Recoil**
    Recoil multipliers read the wrong time variable. Guns are perfect at
    3am game-time. Tournaments adjusted.

-   **Side Quest Generator + Seamless Open World + Action-Adventure ->
    The Haunted Waypoint**
    Quest markers persist after completion in dense world spaces.
    Players report following a ghost.

-   **Ambush AI Encounters + Fortress Siege Mode + Shooter -> The
    Honourable Duel**
    AI pathfinds to the centre of siege arenas before engaging. Players
    started treating it as a ritual.

**Jank Cards in Subsequent Runs**

Jank cards unlocked from prior runs enter the card pool for the next
run. They carry their archetype stamp. Placing a jank card from an RPG
run into a Shooter run creates second-order instability --- jank
breeding jank. This is the intended mastery path, not an exploit.

Mastery feels like expertise when players think \'I\'m building a weird
RPG\' rather than \'I\'m farming the physics-dialogue interaction.\'
Card names, prospect titles, and flavor copy stay rooted in creative
intent.

**Discovery Protection**

Jank discovery only feels organic if players don\'t optimize for it. The
protection: Defining Game and jank discovery pull in different directions
often enough that you cannot chase both simultaneously. A board
optimized for jank farming will typically overshoot Instability or
neglect Soul --- missing Defining Game. A board chasing Defining Game will be
too controlled to produce the most interesting jank.

**This tension is the principle worth preserving above all else in this
system.**

**9. Post-Ship Resolution**

Post-ship screens resolve in a fixed sequence:

1.  **Review Roulette** --- critic reactions first. The emotional
    gut-punch.

2.  **Gap Visualizer** --- analytical debrief. Where each stat landed
    relative to the Defining Game.

3.  **Jank Discovery** --- confirmation and recap. What your specific
    board became, and what enters the cycle memory.

This order is intentional: gut-punch → debrief → confirmation. Critic
reactions carry the emotional weight; the gap visualizer makes the
analysis legible; jank discovery closes the loop on the signature the
player was already chasing mid-run.

**Review Roulette**

Shown immediately after shipping. Critic reviews resolve before the
player sees any stat analysis. The review score is derived from the
shipped stats and ship window, but the copy is anchored to the shipped
build itself: reviewers react to the run's locked signature jank when
one exists, then to its meme-family afterlife before falling back to broader genre or
ending language. Ship window timing is still noted in critical framing.
The first thing the player sees is how the world reacted --- before they
can see why.

**Gap Visualizer**

Shown after Review Roulette. Displays where each stat landed relative to
the Defining Game as a proportional delta bar. No numbers. No
explanation. The player reads the gap and brings that knowledge into the
next run.

> AMBITION ████████████░░ close INSTABILITY ████░░░░░░░░░░ too low SOUL
> ██████████████ ✓

Bars show delta from a proportional baseline, not distance from the
ceiling. Run 1 shows the Defining Game as locked. Runs 2--4 show it
open.

**Jank Discovery Screen**

After the gap visualizer, the jank discovery screen resolves. If a
signature jank was locked or discovered by ship-time evaluation:

-   A brief description of what broke and what players found is shown
    --- affectionate in tone, never mocking.

-   The jank card unlocked is named and added to the cycle card pool.

-   The archetype stamp is shown on the card.

If no combination is found: \'The studio shipped something solid.
Nothing legendary broke.\' This is not framed as failure.

**Card Unlocks Within Cycle**

-   Run 1 completion: 1--2 uncommon cards unlocked based on ending
    quality and gap delta direction.

-   Run 2 completion: 1--2 rare cards unlocked. Near-Defining Game run
    unlocks weirder, jankier cards.

-   Run 3 completion: 1--2 rare cards unlocked again, skewing toward
    riskier final-attempt fuel.

-   Defining Game ending: 1 legendary jank card unlocked, visible on the
    cycle legacy screen.

Near-miss unlock logic: the gap visualizer delta weights which cards
unlock. A player who nearly hit Defining Game on Instability receives cards
that push Instability higher. The unlock communicates direction without
explanation.

**10. Ending Outcomes**

Five endings. Each should feel meaningfully distinct in its post-ship
presentation.

  -----------------------------------------------------------------------
  **Ending**      **Trigger Condition**        **Tone**
  --------------- ---------------------------- --------------------------
  Defining Game   Defining Game: Amb ≥ 25,   The apex. Janky,
                  Inst within archetype        ambitious, unmistakably
                  window, Soul ≥ 7             made with love.

  Legendary Jank  Instability ≥ 55, jank card  Chaos achieved art. Not
                  combination found on board   what anyone planned.

  Surprise Hit    Soul ≥ 8, Ambition 15--24,   Smaller than dreamed. More
                  no Defining Game                beloved than expected.

  Prestige        Ambition ≥ 25, Soul ≤ 4      Technically impressive.
  Collapse                                     Nobody felt anything.

  Shipped         All other cases              Not legendary. Not a
  Something                                    disaster. The studio
                                               survives.
  -----------------------------------------------------------------------

**11. Cycle State**

**Schema**

> cycle_state: current_run: int \# 1, 2, 3, or 4 run_1_ending: String \#
> \"\" if not yet completed run_2_ending: String \# \"\" if not yet
> completed run_3_ending: String \# \"\" if not yet completed
> run_4_ending: String \# \"\" if not yet completed pressure_modifier:
> float \# derived from current_run
> unlocked_card_ids: \[\] \# carries forward within cycle only
> jank_card_ids: \[\] \# archetype-stamped jank cards from board
> combinations cycle_complete: bool

Serialized to user://cycle_state.json.

**Cycle Resolution**

On Run 4 ship: all four endings evaluated together. A legacy screen
shows the studio's four-run arc and the jank cards discovered across
all runs --- a record of what accidentally became iconic. If Defining
Game reached: cycle complete, legacy recorded. If not: cycle resets
fully, new cycle begins from Run 1 with base common card pool.

**Event Pressure Scaling**

Event offer intervals scale by current run number via a pressure factor:

> pressure_factor = 1.0 + (0.3 × (current_run - 1)) effective_interval =
> base_interval / pressure_factor

Run 1 is tutorial-tuned. Run 2 approximately 30% faster. Run 3
approximately 60% faster. Run 4 is the most compressed sprint.

**12. Tone and Presentation**

These are principles, not implementation specs. Visual and audio detail
is a subsequent design phase.

-   The game voice is affectionate and sincere toward jank --- never
    mocking.

-   UI degrades visually as Instability rises: wobble, tint, glitching,
    text corruption.

-   Wobble severity is archetype-aware, not purely linear. As Instability
    approaches the archetype\'s ceiling, wobble amplitude and glitch
    frequency amplify independently of the raw value. A Shooter run
    (ceiling 42) feels noticeably more chaotic at Instability 38 than an
    RPG run (ceiling 54) does at the same value. The window edges are
    meant to be felt, not just read.

-   The Soul stat surfaces a live Defining Game eligibility warning
    beneath its value label. \"Defining Game: at risk\" appears in amber
    when one Fix Bugs action would drop Soul below the qualifying floor
    (≥ 7). \"Defining Game: lost\" appears in red when Soul has already
    fallen below the floor. This makes the Soul-Defining Game link
    explicit mid-run rather than discovered at the gap visualizer.

-   Choice prompts frame tradeoffs, not correct answers.

-   The Fix Bugs soul cost is surfaced explicitly in the UI. No hidden
    mechanics.

-   The Soul gauge reflects actual Soul value with no visual cap. A
    gauge that reads "full" at 15 when Soul can exceed 15 silently
    contradicts the no-hidden-mechanics principle.

-   The archetype Instability window is not shown as live markers on the
    HUD during Run 1. Run 1 is explicitly exploratory --- discovery
    intent is preserved where it matters. From Run 2 onward, floor and
    ceiling markers are visible on the Instability gauge. By Run 2 the
    player has earned the information, and the shorter 19-day real runs
    make live markers a playability requirement, not a hand-hold.

-   The right-hand Defining Game readout is explicit from Run 2 onward.
    It shows the current ambition line, instability target band, soul
    safety state, and next-move guidance. The intended feel is "clear
    stakes, hard decisions," not "mystery spreadsheet."

-   Backlog cards separate identity from risk. "What this adds" and
    "how off-brief or dangerous it is" should scan independently.

-   Jank prospects and signature locks are not generic toasts. They are
    treated as named moments, with a prominent banner and a persistent
    board-state reminder.

-   The center column now contains both the current build and a Studio
    Console. The console records player actions, offered dilemmas,
    draft picks, threshold events, prospects, and signature locks in
    real time. It is vertically resizable against the board so the
    player can choose whether the run needs more space for cards or more
    space for memory.

-   Added feature cards on the board should fill left-to-right until the
    row reaches the container boundary, then wrap to the next row.
    Arbitrary fixed column counts are not the intended presentation.

-   Main menu always shows current cycle position: RUN 1 OF 4 through
    RUN 4 OF 4, with brief tone-appropriate copy.

-   Wrong ending on Run 1 is framed as expected, not as failure: \'The
    studio is finding its voice.\'

-   The gap visualizer uses proportional delta bars, not absolute
    numbers.

-   Jank discovery descriptions are written with love for the specific
    broken thing found.

**13. Current Implementation Architecture**

The current codebase intentionally separates game state, data loading,
resolution logic, and UI presentation.

-   **AppState** is the authoritative runtime state owner. It tracks
    ambition, instability, soul, runway, chosen archetype, the current
    board, and the live jank pursuit state.

-   **GameEvents** is the event bus. UI listens to emitted state
    changes, offers, threshold events, feature placements, prospect
    updates, and signature locks. Views do not mutate game state
    directly.

-   **AppContentRepository** loads all external content: game config,
    cards, offers, threshold events, and jank combinations. Live tuning
    comes from `data/game_config_override.json` layered over the base
    resource.

-   **RunResolutionService**, **RunOfferFlow**, **OfferScheduler**, and
    **JankResolver** own their specialized systems. Post-ship jank and
    mid-run prospecting use the same authored combination data.

-   The main scene uses a view/controller split. `main.gd` wires the
    scene together, while view scripts own references and presentation
    helpers for the backlog panel, feature board, sidebar, dialogs, and
    post-ship flow.

-   The center column is now the run narrative lane: current build,
    jank pursuit state, and studio console live together there. The
    board/log split is resizable vertically; the left and right columns
    remain fixed.

**Appendix: Removed Systems**

The following systems were present in prior GDD drafts and have been
deliberately cut. This appendix records the rationale to prevent
re-introduction without cause.

  -----------------------------------------------------------------------
  **System**               **Reason Removed**
  ------------------------ ----------------------------------------------
  Style Buckets (Cult Jank Redundant with stat thresholds. Endings now
  / Prestige Collapse /    derive directly from stats. Removed complexity
  Community Darling)       without removing meaning.

  Tag Interaction System   Stat effects removed. Archetype routing
                           replaces the interesting parts of tag
                           interaction in rapid-fire card decisions.
                           The tag field is retained as a flavor hint
                           for the critic review system only --- not a
                           live mechanic.

  Soul Cap (15)            The runway day cost already protects against
                           Dev Log spam. The cap added a rule players
                           must track for a problem already solved
                           mechanically. The Soul gauge has no visual
                           cap --- it reflects actual Soul value.
                           Showing "full" at 15 when Soul can exceed
                           15 silently contradicts the no-hidden-
                           mechanics principle.

  Publisher Trust Mode     Optional toggles are design debt. Publisher
                           pressure is handled through the event layer.

  Studio Tier and          Retained only as legacy flavor text ---
  Reputation               finished the cut. Legacy screen shows jank
                           cards discovered, not studio tier.

  Skip / Hold Mechanic on  Replaced by pick-one-of-three. Skipping
  Daily Offer              required explanation; selection pressure does
                           not.

  8-Ending Table           Reduced to 5 distinct endings. Near-duplicate
                           endings (Cult Classic vs Legendary Jank,
                           Financial Catastrophe vs Prestige Collapse)
                           diluted post-ship distinctiveness.
  -----------------------------------------------------------------------
