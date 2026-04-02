extends Resource
class_name GameConfig

## Central game mechanics and balance configuration resource.
## This is the SINGLE ENTRY POINT for all tunable game parameters.
##
## Access: var config: GameConfig = AppState.get_game_config()
## Edit: Open data/game_config.tres in Inspector and adjust parameters.
## Save: Changes take effect immediately in running game (no recompilation).
##
## Design: NO magic numbers in code; all thresholds/coefficients live here.

# --- SCORING FORMULA COEFFICIENTS ---
@export var score_base: float = 5.0
@export var ambition_coefficient: float = 0.14
@export var instability_coefficient: float = 0.05
@export var soul_coefficient: float = 0.15
@export var soul_mitigation_factor: float = 40.0

# --- ACTION ECONOMY ---
# Fix Bugs is intentionally punishing: 3 soul per use, 3 dev logs to recover.
# There is no winning line that uses Fix Bugs — players discover this themselves.
@export var soul_start: int = 12
@export var soul_max: int = 15
@export var fix_bugs_instability_reduction: int = 12
@export var fix_bugs_soul_cost: int = 3
@export var dev_log_soul_gain: int = 1

# --- GOLDILOCKS GATE (DEFINING GAME ENDING) ---
# Apex achievement; requires ALL thresholds simultaneously for meaningful jank with soul.
# Instability floor set high enough that passive common-card play cannot accidentally qualify.
@export var goldilocks_ambition_min: int = 25
@export var goldilocks_instability_min: int = 18
@export var goldilocks_instability_max: int = 42
@export var goldilocks_soul_min: int = 7

# --- STAT-GATED ENDINGS (BUCKET-INDEPENDENT) ---
@export var cult_disaster_instability_min: int = 41
@export var cult_disaster_soul_max: int = 4
@export var rough_diamond_ambition_max: int = 14
@export var rough_diamond_instability_max: int = 14
@export var rough_diamond_soul_min: int = 8

# --- BUCKET-WEIGHTED ENDING THRESHOLDS ---
@export var cult_jank_legendary_instability_min: int = 52
@export var community_darling_surprise_hit_soul_min: int = 8
@export var community_darling_surprise_hit_score_min: float = 6.5
@export var prestige_collapse_ambition_min: int = 25
@export var prestige_collapse_soul_max: int = 6
@export var financial_catastrophe_soul_max: int = 3

# --- SHIP WINDOW & TIMING BONUSES ---
@export var sweet_spot_runway_min: int = 4
@export var sweet_spot_runway_max: int = 9
@export var sweet_spot_instability_min: int = 18
@export var sweet_spot_instability_max: int = 45
@export var too_early_runway_threshold: int = 13
@export var panic_ship_runway_threshold: int = 2

# --- SHIP WINDOW SCORE MODIFIERS ---
@export var sweet_spot_score_bonus: float = 1.2
@export var too_early_score_penalty: float = -0.5
@export var panic_ship_score_penalty: float = -0.4

# --- JANK STATUS CLASSIFICATION ---
@export var polished_instability_max: int = 22
@export var polished_score_min: float = 7.0
@export var broken_instability_min: int = 78
@export var sweet_spot_instability_zone_min: int = 38
@export var sweet_spot_instability_zone_max: int = 62

# --- CARD PROGRESSION ---
@export var initial_card_unlock_count: int = 8
@export var stage_threshold_runways: Array[int] = [15, 10, 5, 0]

# --- ARCHETYPE SYSTEM ---
# Mismatch: card has some affinity but not the chosen archetype.
# Alien: card has no archetype affinity (archetype_affinity is empty).
# Alien cards are soul-gated — placing requires soul >= alien_card_soul_gate.
@export var genre_stretch_instability_bonus: int = 2   # 2/3 affinity coverage — adjacent genre
@export var archetype_mismatch_instability_bonus: int = 4  # 1/3 affinity coverage — wild swing
@export var archetype_mismatch_ambition_bonus: int = 2
@export var archetype_mismatch_soul_penalty: int = 1
@export var alien_card_instability_bonus: int = 8          # 0/3 affinity coverage — alien card
@export var alien_card_ambition_bonus: int = 4
@export var alien_card_soul_penalty: int = 3
@export var alien_card_soul_gate: int = 5

# --- OFFER SCHEDULING ---
# Base intervals; scaled per run by OfferScheduler using cycle pressure_modifier.
@export var dilemma_offer_interval: int = 6
@export var draft_offer_interval: int = 5
@export var publisher_meeting_interval: int = 7
