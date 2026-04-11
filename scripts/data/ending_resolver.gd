extends RefCounted
class_name EndingResolver

const ArchetypeRules = preload("res://scripts/data/services/archetype_rules.gd")

const DEFINING_GAME_ID: String = "defining_game"
const LEGENDARY_JANK_ID: String = "legendary_jank"
const SURPRISE_HIT_ID: String = "surprise_hit"
const PRESTIGE_COLLAPSE_ID: String = "prestige_collapse"
const SHIPPED_SOMETHING_ID: String = "shipped_something"

const _ENDING_LABELS: Dictionary = {
	DEFINING_GAME_ID: "Defining Game",
	LEGENDARY_JANK_ID: "Legendary Jank",
	SURPRISE_HIT_ID: "Surprise Hit",
	PRESTIGE_COLLAPSE_ID: "Prestige Collapse",
	SHIPPED_SOMETHING_ID: "Shipped Something",
}

## Five endings in priority order:
## 1. Defining Game  — conditions met (ambition, per-archetype instability window, soul)
## 2. Legendary Jank — instability ≥ 55 AND a jank combination was found on the board
## 3. Surprise Hit   — soul ≥ 8, ambition in 15–24 (Goldilocks not met)
## 4. Prestige Collapse — ambition ≥ 25, soul ≤ 4
## 5. Shipped... something — everything else
static func resolve_ending_id(
	config: GameConfig,
	ambition: int,
	instability: int,
	soul: int,
	archetype: String,
	has_jank_combination: bool,
	run: int,
) -> String:
	if config == null:
		return SHIPPED_SOMETHING_ID

	# Priority 1: Defining Game conditions
	if ArchetypeRules.is_defining_game_eligible(config, ambition, instability, soul, archetype, run):
		return DEFINING_GAME_ID

	# Priority 2: Legendary Jank
	if instability >= config.legendary_jank_instability_min and has_jank_combination:
		return LEGENDARY_JANK_ID

	# Priority 3: Surprise Hit
	if soul >= config.surprise_hit_soul_min and ambition >= config.surprise_hit_ambition_min and ambition <= config.surprise_hit_ambition_max:
		return SURPRISE_HIT_ID

	# Priority 4: Prestige Collapse
	if ambition >= config.prestige_collapse_ambition_min and soul <= config.prestige_collapse_soul_max:
		return PRESTIGE_COLLAPSE_ID

	# Priority 5: fallback
	return SHIPPED_SOMETHING_ID

static func resolve_ending_label(
	config: GameConfig,
	ambition: int,
	instability: int,
	soul: int,
	archetype: String,
	has_jank_combination: bool,
	run: int,
) -> String:
	return label_for_id(resolve_ending_id(config, ambition, instability, soul, archetype, has_jank_combination, run))

static func label_for_id(ending_id: String) -> String:
	var normalized_id: String = normalize_ending_id(ending_id)
	return String(_ENDING_LABELS.get(normalized_id, _ENDING_LABELS[SHIPPED_SOMETHING_ID]))

static func normalize_ending_id(ending: String) -> String:
	var normalized: String = ending.strip_edges()
	if normalized.contains(":"):
		normalized = String(normalized.split(":", false, 1)[0]).strip_edges()
	normalized = normalized.replace("...", " ")
	normalized = normalized.replace(".", " ")
	normalized = normalized.replace("-", " ")
	normalized = normalized.replace("_", " ")
	while normalized.contains("  "):
		normalized = normalized.replace("  ", " ")
	match normalized.strip_edges().to_lower():
		"defining game":
			return DEFINING_GAME_ID
		"legendary jank":
			return LEGENDARY_JANK_ID
		"surprise hit":
			return SURPRISE_HIT_ID
		"prestige collapse":
			return PRESTIGE_COLLAPSE_ID
		"shipped something":
			return SHIPPED_SOMETHING_ID
		_:
			return normalized.strip_edges().to_lower().replace(" ", "_")
