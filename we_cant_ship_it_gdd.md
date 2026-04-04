**WE CAN\'T SHIP IT**

Game Design Document

*Revised Edition*

*Three sprints. Ship something ambitious, a little broken, made with
love.*

**1. Game Premise**

You run a small indie studio across a three-run cycle, each run a 21-day
sprint trying to ship an over-ambitious game. The game rewards balancing
chaos with heart. Instability is not automatically bad --- it becomes
dangerous only at extremes. The ultimate aspiration is the Defining
Game: a title like STALKER, Gothic, or The Witcher 1 --- janky,
ambitious, unmistakably crafted with love.

**You have three attempts. Deliver the right jank. Fail and the cycle
resets.**

**Core Player Fantasy**

-   Make risky feature decisions under runway pressure.

-   Turn accidental bugs into memorable jank with soul.

-   Chase the Defining Game: ambitious enough, unstable enough,
    sincere enough.

-   Discover what your specific broken game accidentally created --- and
    weaponize it next run.

-   Build a recognizable studio identity across a three-run arc.

**2. The Three-Run Arc**

The game is exactly three runs, communicated upfront on the main menu:

> *\"Three sprints. Ship something ambitious, a little broken, made with
> love. That\'s the goal.\"*

Each run is approximately 10 minutes. The arc escalates in pressure and
available card power:

  -----------------------------------------------------------------------------
  **Run**   **Tone**         **Player State**      **Pressure    **Card Pool**
                                                   Start**       
  --------- ---------------- --------------------- ------------- --------------
  1         Exploratory      Learning --- wrong    Day 14        Common only
                             ending expected,                    
                             Defining Game 
                             unattainable                   

  2         Pressure         Knows enough to make  Day 10        Common +
                             meaningful mistakes                 Uncommon

  3         Convergence      Racing a known target Day 7         Common +
                             with better cards                   Uncommon +
                                                                 Rare
  -----------------------------------------------------------------------------

Pressure start shifts mechanically each run --- event popups arrive
earlier, dilemmas are harder. Same content structure, escalating pace.

**Run 1: Pedagogical Contract**

Run 1 is explicitly a jank prospecting run. The Defining Game is shown
as locked on the post-ship gap visualizer --- players learn the rhythm
without chasing an unreachable target. The wrong ending is framed as
expected, not as failure:

> *\"The studio is finding its voice.\"*

This reframes Run 1 as discovery rather than punishment. Players leave
Run 1 knowing what jank their specific board produced. That knowledge
--- not a score --- is the reward.

**Cycle Persistence Rules**

-   Cycle state persists after each completed run. A player who ships
    Run 1 and closes the game returns to Run 2.

-   Quitting mid-run resets that run to its beginning. Jank cards and
    unlocks from prior completed runs are preserved.

-   Quitting before Run 1 is shipped resets the entire cycle.

-   On cycle completion (Run 3 shipped): all three endings are evaluated
    together, the studio\'s three-game legacy is shown, Defining Game
    reached or cycle resets.

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

Runway Days: 21. Decreases only from player-facing actions and selected
event effects. This is the dealer\'s upcard --- it forces your hand.

**4. The Defining Game**

The Defining Game ending is the apex outcome. It requires all three stat
thresholds simultaneously at ship:

  -------------------------------------------------------------------------
  **Stat**      **Threshold**      **Design Intent**
  ------------- ------------------ ----------------------------------------
  Ambition      ≥ 25               An unambitious game doesn\'t qualify.

  Instability   15 -- 50           A polished or catastrophically broken
                (inclusive)        game doesn\'t qualify. Widened window
                                   gives late-run agency.

  Soul          ≥ 7                A soulless game doesn\'t qualify. One
                                   Fix Bugs cycle is survivable with
                                   discipline.
  -------------------------------------------------------------------------

The Defining Game is locked in Run 1. It is unlocked in Run 2 and
shown on the gap visualizer. Players discover the thresholds by reading
the gap --- no numbers, no explanation.

**5. Main Player Actions**

Four actions. Hit or stand --- every choice costs a day except shipping.

**Place Feature Card**

-   Adds the card\'s Ambition and Instability values to run totals.

-   Triggers archetype interpretation and any board combination jank
    checks.

-   Costs 1 Runway Day.

*Reasons not to place: Instability may overshoot the Defining Game ceiling.
The day competes with Dev Log for soul recovery. The combination on your
board may produce unwanted jank --- or exactly the jank you\'re
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
  Too Early           Ship with ≥ 13 Runway Days     −0.5 score. "You
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
the board and commit before runway forces their hand. Defining Game
endings are exempt from timing penalties --- reaching the apex outcome
should not be penalised by the moment you chose to ship.*

**6. Archetype System**

At run start, the player selects a target archetype: RPG, Shooter, or
Action-Adventure. This is a real strategic commitment --- not a genre
skin. Archetype does three things:

-   Sets the Defining Game Instability window for this run.

-   Determines which archetype-exclusive cards appear in the daily
    offer.

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

**Archetype-Exclusive Cards**

Each archetype has 4--6 exclusive cards that only appear in that
archetype\'s daily offer pool. These cards are genre-flavored in name
and feel, not just in stats:

-   RPG exclusives: Dialogue System, Faction Reputation, World Map,
    Branching Questline, Lore Codex.

-   Shooter exclusives: Gunfeel Tuning, Enemy AI Aggression, Arena
    Layout, Reload Animation, Damage Numbers.

-   Action-Adventure exclusives: Traversal System, Open World Density,
    Side Quest Generator, Physics Playground, Day-Night Cycle.

*These cards have normal Ambition/Instability values but are stamped
with their archetype. When placed in a different archetype\'s run (via
jank card inheritance across runs), they carry higher instability
modifiers --- a shooter card in an RPG run produces friction.*
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
other two are discarded --- they will not reappear in future offers this
run. No skipping, no reroll.

*Design intent: Blackjack doesn't offer a reroll. The tension is in the
choice between three known options today. Passive waiting is not
available: every card you pass on is gone. The constraint is scarcity
of decisions, not scarcity of time.*

**8. Emergent Jank System**

This is the game\'s core differentiator. After shipping, the board you
built is evaluated for jank-generating card combinations. Specific
pairings or clusters --- interpreted through the run\'s archetype ---
produce specific jank outcomes. The jank card unlocked is a postcard
from the wreckage of your specific decisions.

**The Combinatorial Matrix: Principle**

Jank is not derived from stats. It is derived from what cards were on
your board and which archetype gave them meaning. The formula is:

**Card A + Card B + Archetype = Jank Card**

The matrix does not need to be exhaustive. An uncovered combination
ships without notable jank --- not every broken game becomes legendary.

**Illustrative Combination Examples**

  ------------------------------------------------------------------------------
  **Card A**   **Card B**   **Archetype**      **Jank Card    **Flavor**
                                               Unlocked**     
  ------------ ------------ ------------------ -------------- ------------------
  Physics      Dialogue     RPG                The Yeetable   Quest NPCs can be
  Playground   System                          NPC            launched off
                                                              geometry.
                                                              Speedrunners found
                                                              a clip through the
                                                              final boss.
                                                              Beloved.

  Physics      Dialogue     Shooter            Ragdoll        Enemies deliver
  Playground   System                          Monologue      scripted death
                                                              speeches
                                                              mid-ragdoll.
                                                              Somehow emotional.

  Procedural   Faction      RPG                The Infinite   Faction logic
  Generation   Reputation                      Betrayal       fires on proc-gen
                                                              entities. Every
                                                              merchant is
                                                              secretly hostile.
                                                              Players wrote lore
                                                              about it.

  Gunfeel      Day-Night    Shooter            Midnight       Recoil multipliers
  Tuning       Cycle                           Recoil         read the wrong
                                                              time variable.
                                                              Guns are perfect
                                                              at 3am game-time.
                                                              Tournaments
                                                              adjusted.

  Open World   Branching    Action-Adventure   The Haunted    Quest markers
  Density      Questline                       Waypoint       persist after
                                                              completion in
                                                              dense areas.
                                                              Players report
                                                              \'following a
                                                              ghost.\'

  Arena Layout Enemy AI     Shooter            The Honourable AI pathfinds to
               Aggression                      Duel           center of arena
                                                              before engaging.
                                                              Players started
                                                              treating it as a
                                                              ritual.
  ------------------------------------------------------------------------------

**Jank Cards in Subsequent Runs**

Jank cards unlocked from prior runs enter the card pool for the next
run. They carry their archetype stamp. Placing a jank card from an RPG
run into a Shooter run creates second-order instability --- jank
breeding jank. This is the intended mastery path, not an exploit.

Mastery feels like expertise when players think \'I\'m building a weird
RPG\' rather than \'I\'m farming the physics-dialogue interaction.\'
Card names and flavor must stay rooted in creative intent.

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

3.  **Jank Discovery** --- combinatorial reveal. What your specific
    board accidentally created.

This order is intentional: gut-punch → debrief → discovery. Critic
reactions carry the emotional weight; the gap visualizer makes the
analysis legible; jank discovery closes the loop on individual
decisions.

**Review Roulette**

Shown immediately after shipping. Critic reviews resolve before the
player sees any stat analysis. The review score is derived from the
ending type, with ship window timing noted in the indie blog critic
copy. The first thing the player sees is how the world reacted ---
before they can see why.

**Gap Visualizer**

Shown after Review Roulette. Displays where each stat landed relative to
the Defining Game as a proportional delta bar. No numbers. No
explanation. The player reads the gap and brings that knowledge into the
next run.

> AMBITION ████████████░░ close INSTABILITY ████░░░░░░░░░░ too low SOUL
> ██████████████ ✓

Bars show delta from a proportional baseline, not distance from the
ceiling. Run 1 shows the Defining Game as locked. Runs 2--3 show it
open.

**Jank Discovery Screen**

After the gap visualizer, the jank discovery screen resolves. The board
is evaluated for combinations. If a combination is found:

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

> cycle_state: current_run: int \# 1, 2, or 3 run_1_ending: String \#
> \"\" if not yet completed run_2_ending: String \# \"\" if not yet
> completed pressure_modifier: float \# derived from current_run
> unlocked_card_ids: \[\] \# carries forward within cycle only
> jank_card_ids: \[\] \# archetype-stamped jank cards from board
> combinations cycle_complete: bool

Serialized to user://cycle_state.json.

**Cycle Resolution**

On Run 3 ship: all three endings evaluated together. A legacy screen
shows the studio\'s three-game arc and the jank cards discovered across
all runs --- a record of what accidentally became iconic. If Defining Game
reached: cycle complete, legacy recorded. If not: cycle resets fully,
new cycle begins from Run 1 with base common card pool.

**Event Pressure Scaling**

Event offer intervals scale by current run number via a pressure factor:

> pressure_factor = 1.0 + (0.3 × (current_run - 1)) effective_interval =
> base_interval / pressure_factor

Run 1 intervals unchanged. Run 2 approximately 30% faster. Run 3
approximately 60% faster.

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
    player has earned the information, and Run 3's tighter pressure
    (Rare cards swinging ±10 Instability, pressure starting Day 7)
    makes live markers a playability requirement, not a hand-hold.

-   Main menu always shows current cycle position: RUN 1 OF 3, RUN 2 OF
    3, RUN 3 OF 3, with brief tone-appropriate copy.

-   Wrong ending on Run 1 is framed as expected, not as failure: \'The
    studio is finding its voice.\'

-   The gap visualizer uses proportional delta bars, not absolute
    numbers.

-   Jank discovery descriptions are written with love for the specific
    broken thing found.

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
