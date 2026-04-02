extends RefCounted
class_name ScoreCalculator

## Pure scoring and ship-window computations extracted from AppState.
## All methods are static — no instance state required.

static func calculate_final_score(
	config: GameConfig,
	ambition: int,
	instability: int,
	soul: int,
	features_shipped: int,
	ship_window: Dictionary
) -> float:
	# Nothing shipped = nothing reviewable; bypass all positive contributions.
	if features_shipped == 0:
		return 0.1
	var base_score: float = config.score_base
	var soul_factor: float = float(soul) / float(soul + config.soul_mitigation_factor)
	var instability_penalty: float = -config.instability_coefficient * float(instability) * (1.0 - soul_factor)
	return clampf(
		base_score
		+ (ambition * config.ambition_coefficient)
		+ instability_penalty
		+ (soul * config.soul_coefficient)
		+ float(ship_window.get("score_bonus", 0.0)),
		1.0, 10.0
	)

static func compute_ship_window(config: GameConfig, runway_days: int, instability: int) -> Dictionary:
	if runway_days >= config.sweet_spot_runway_min and runway_days <= config.sweet_spot_runway_max and instability >= config.sweet_spot_instability_min and instability <= config.sweet_spot_instability_max:
		return {
			"label": "Sweet Spot",
			"score_bonus": config.sweet_spot_score_bonus,
			"message": "You shipped at peak chaos without total collapse.",
		}
	if runway_days <= config.panic_ship_runway_threshold:
		return {
			"label": "Last-Minute Panic",
			"score_bonus": config.panic_ship_score_penalty,
			"message": "You shipped in full panic mode.",
		}
	if runway_days >= config.too_early_runway_threshold:
		return {
			"label": "Too Early",
			"score_bonus": config.too_early_score_penalty,
			"message": "You shipped before the jank had time to become culture.",
		}
	return {
		"label": "Standard Launch",
		"score_bonus": 0.0,
		"message": "A normal release window by your very low standards.",
	}

static func compute_jank_status(config: GameConfig, instability: int, review_score: float) -> String:
	if instability <= config.polished_instability_max and review_score >= config.polished_score_min:
		return "polished"
	if instability >= config.broken_instability_min:
		return "broken"
	if instability >= config.sweet_spot_instability_zone_min and instability <= config.sweet_spot_instability_zone_max and review_score >= 6.5:
		return "sweet_spot"
	return "volatile"

static func ship_window_quality(label: String) -> float:
	match label:
		"Sweet Spot":
			return 1.0
		"Standard Launch":
			return 0.55
		"Too Early":
			return 0.35
		"Last-Minute Panic":
			return 0.20
		_:
			return 0.50
