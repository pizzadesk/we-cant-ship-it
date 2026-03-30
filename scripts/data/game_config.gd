extends Resource
class_name GameConfig

## Central game mechanics and balance configuration resource.
## This is the SINGLE ENTRY POINT for all tunable game parameters:
## - Scoring formulas and coefficients
## - Winning conditions (Goldilocks gate thresholds)
## - Reputation economy and studio tier progression
## - Ending resolution thresholds and conditions
## - Offer scheduling (dilemmas, drafts, publisher meetings)
## - Ship window timing penalties/bonuses
## - Jank status classification thresholds
## - Card unlock and progression tuning
##
## Access: var config: GameConfig = AppState.get_game_config()
## Edit: Open data/game_config.tres in Inspector and adjust parameters.
## Save: Changes take effect immediately in running game (no recompilation).
##
## Design: NO magic numbers in code; all thresholds/coefficients live here.
## Backward compatible: missing parameters default to safe values.
## Organized by game system (score, reputation, endings, etc.).

# --- SCORING FORMULA COEFFICIENTS ---
@export var score_base: float = 5.0
@export var ambition_coefficient: float = 0.12
@export var instability_coefficient: float = 0.04
@export var soul_coefficient: float = 0.12
@export var soul_mitigation_factor: float = 50.0

# --- ACTION ECONOMY ---
# Cost and benefit of player actions; intentionally asymmetric 3:1 soul ratio
@export var fix_bugs_instability_reduction: int = 12
@export var fix_bugs_soul_cost: int = 3
@export var dev_log_soul_gain: int = 1
@export var dev_log_instability_cost: int = 0

# --- GOLDILOCKS GATE (DEFINING GAME ENDING) ---
# Apex achievement; requires ALL thresholds simultaneously for meaningful jank with soul
@export var goldilocks_ambition_min: int = 25
@export var goldilocks_instability_min: int = 15
@export var goldilocks_instability_max: int = 40
@export var goldilocks_soul_min: int = 8

# --- STAT-GATED ENDINGS (BUCKET-INDEPENDENT) ---
# Gates prevent unintended high-quality outcomes from low-effort runs
@export var cult_disaster_instability_min: int = 41
@export var cult_disaster_soul_max: int = 4
@export var rough_diamond_ambition_max: int = 14
@export var rough_diamond_instability_max: int = 14
@export var rough_diamond_soul_min: int = 8

# --- BUCKET-WEIGHTED ENDING THRESHOLDS ---
# Used when dominant identity bucket is clear
@export var cult_jank_legendary_instability_min: int = 58
@export var community_darling_surprise_hit_soul_min: int = 10
@export var community_darling_surprise_hit_score_min: float = 7.0
@export var prestige_collapse_ambition_min: int = 25
@export var prestige_collapse_soul_max: int = 7
@export var financial_catastrophe_soul_max: int = 3

# --- REPUTATION ECONOMY & STUDIO TIERS ---
# Tier 4 (Legendary Dev) REQUIRES defining_game_unlocked = true PLUS reputation threshold
@export var reputation_defining_game: int = 4
@export var reputation_legendary_jank: int = 3
@export var reputation_surprise_hit: int = 3
@export var reputation_cult_classic: int = 2
@export var reputation_rough_diamond: int = 2
@export var reputation_prestige_collapse: int = 1
@export var reputation_cult_disaster: int = -1
@export var reputation_financial_catastrophe: int = -1
@export var studio_tier_2_reputation_min: int = 6
@export var studio_tier_3_reputation_min: int = 14
@export var studio_tier_4_reputation_min: int = 30
@export var milestone_interval_runs: int = 3

# --- SHIP WINDOW & TIMING BONUSES ---
@export var sweet_spot_runway_min: int = 4
@export var sweet_spot_runway_max: int = 9
@export var sweet_spot_instability_min: int = 35
@export var sweet_spot_instability_max: int = 60
@export var too_early_runway_threshold: int = 14
@export var panic_ship_runway_threshold: int = 2

# --- SHIP WINDOW SCORE MODIFIERS ---
@export var sweet_spot_score_bonus: float = 1.0
@export var too_early_score_penalty: float = -0.4
@export var panic_ship_score_penalty: float = -0.6

# --- JANK STATUS CLASSIFICATION ---
# Categorizes shipped game quality; NOT about development process
@export var polished_instability_max: int = 22
@export var polished_score_min: float = 7.0
@export var broken_instability_min: int = 78
@export var sweet_spot_instability_zone_min: int = 38
@export var sweet_spot_instability_zone_max: int = 62

# --- CARD PROGRESSION ---
@export var initial_card_unlock_count: int = 8
@export var stage_threshold_runways: Array[int] = [15, 10, 5, 0]
@export var legacy_cult_disaster_soul_min: int = 40

# --- ENDING THRESHOLDS (BACKWARD COMPATIBILITY) ---
# Retained for backward compatibility with older saves/content.
@export var cult_classic_soul_min: int = 65
@export var cult_classic_instability_min: int = 45
@export var cult_classic_score_min: float = 6.5
@export var legendary_jank_instability_min: int = 80
@export var legendary_jank_score_min: float = 5.5
@export var financial_catastrophe_score_max: float = 2.5
@export var cult_disaster_soul_min: int = 40
@export var cult_disaster_score_max: float = 3.5

@export var defining_game_soul_threshold: int = 8

# --- OFFER SCHEDULING ---
# How many runway days before re-offering the same popup type
@export var dilemma_offer_interval: int = 6
@export var draft_offer_interval: int = 5
@export var publisher_meeting_interval: int = 7
