extends RefCounted
class_name EndingResolver

const _S = preload("res://scripts/ui/ui_strings.gd")

## Returns the full description string for a known ending label (e.g. "Financial Catastrophe").
## Looks up via the same JSON key used by resolve_ending_description.
static func description_for_label(label: String) -> String:
	var key: String = "ending_desc_" + label.to_lower().replace(" ", "_")
	var desc: String = _S.get_string("popups", key)
	if desc.is_empty():
		return _S.get_string("popups", "ending_desc_rough_diamond")
	return desc

static func resolve_ending_description(config: GameConfig, ambition: int, instability: int, soul: int, review_score: float, dominant_bucket: String) -> String:
	var label: String = resolve_ending_label(config, ambition, instability, soul, review_score, dominant_bucket)
	return description_for_label(label)

static func resolve_ending_label(config: GameConfig, ambition: int, instability: int, soul: int, review_score: float, dominant_bucket: String) -> String:
	if config == null:
		return "Rough Diamond"

	# Priority 1: stat-gated endings are bucket-independent.
	if ambition >= config.goldilocks_ambition_min and instability >= config.goldilocks_instability_min and instability <= config.goldilocks_instability_max and soul >= config.goldilocks_soul_min:
		return "Defining Game"
	if instability >= config.cult_disaster_instability_min and soul <= config.cult_disaster_soul_max:
		return "Cult Disaster"
	if ambition <= config.rough_diamond_ambition_max and instability <= config.rough_diamond_instability_max and soul >= config.rough_diamond_soul_min:
		return "Rough Diamond"

	# Priority 2/3: dominant bucket then stat-conditioned branch inside that bucket.
	match dominant_bucket:
		"cult_jank":
			if instability >= config.cult_jank_legendary_instability_min:
				return "Legendary Jank"
			return "Cult Classic"
		"community_darling":
			if soul >= config.community_darling_surprise_hit_soul_min and review_score >= config.community_darling_surprise_hit_score_min:
				return "Surprise Hit"
			return "Cult Classic"
		"prestige_collapse":
			# Financial Catastrophe is bucket-conditioned only — no ambition floor.
			# A studio that grinds Fix Bugs into oblivion (soul ≤ 3) hits this regardless of scope.
			if soul <= config.financial_catastrophe_soul_max:
				return "Financial Catastrophe"
			if ambition >= config.prestige_collapse_ambition_min and soul <= config.prestige_collapse_soul_max:
				return "Prestige Collapse"
			return "Prestige Collapse"
		_:
			# Priority 4 fallback when no bucket dominates.
			return "Rough Diamond"

static func normalize_ending_name(ending: String) -> String:
	if ending.contains(":"):
		return String(ending.split(":", false, 1)[0]).strip_edges().to_lower()
	return ending.strip_edges().to_lower()
