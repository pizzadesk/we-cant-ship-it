extends RefCounted
class_name EndingResolver

static func resolve_ending_description(config: GameConfig, ambition: int, instability: int, soul: int, review_score: float, dominant_bucket: String) -> String:
	var label: String = resolve_ending_label(config, ambition, instability, soul, review_score, dominant_bucket)
	match label:
		"Defining Game":
			return "Defining Game: A janky masterpiece held together by conviction and duct tape."
		"Cult Disaster":
			return "Cult Disaster: The studio poured everything into a build the market refused to understand."
		"Rough Diamond":
			return "Rough Diamond: Mixed reviews, loyal fans, and enough runway for one more update."
		"Legendary Jank":
			return "Legendary Jank: It barely runs, but speedrunners turn it into religion."
		"Cult Classic":
			return "Cult Classic: Players preserve every bug in community-made museum builds."
		"Surprise Hit":
			return "Surprise Hit: Publishers ask for a sequel before your patch notes are done."
		"Financial Catastrophe":
			return "Financial Catastrophe: The studio survives on contract work and stubborn hope."
		"Prestige Collapse":
			return "Prestige Collapse: It works. Every system works. Nobody can explain why it feels like a eulogy."
		_:
			return "Rough Diamond: Mixed reviews, loyal fans, and enough runway for one more update."

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
			if ambition >= config.prestige_collapse_ambition_min and soul <= config.financial_catastrophe_soul_max:
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
