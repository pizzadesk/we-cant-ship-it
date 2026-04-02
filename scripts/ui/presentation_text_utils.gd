const ReviewMarkupUtils = preload("res://scripts/ui/review_markup_utils.gd")
const _S = preload("res://scripts/ui/ui_strings.gd")
const EndingResolver = preload("res://scripts/data/ending_resolver.gd")

## Builds the cycle legacy screen text shown after run 3 ships.
## cycle_state must be the full dictionary from AppState.get_cycle_state()
## after complete_run() has already recorded run_3_ending.
static func build_cycle_legacy_text(cycle_state: Dictionary) -> String:
	var lines: PackedStringArray = PackedStringArray()

	lines.append(_S.get_string("popups", "cycle_legacy_arc_header") + "\n")

	var ending_colors: Dictionary = {
		"defining game":       "51cf66",
		"legendary jank":      "ff8c42",
		"cult classic":        "ff8c42",
		"surprise hit":        "74c0fc",
		"rough diamond":       "adb5bd",
		"cult disaster":       "ff6b6b",
		"prestige collapse":   "cc5de8",
		"financial catastrophe": "ff6b6b",
	}

	var any_defining: bool = false
	for run_num in [1, 2, 3]:
		var ending: String = String(cycle_state.get("run_%d_ending" % run_num, ""))
		var label: String = _S.get_string("popups", "cycle_legacy_run_header") % run_num
		var normalized: String = EndingResolver.normalize_ending_name(ending)
		var color: String = String(ending_colors.get(normalized, "ffffff"))
		var ending_display: String = _extract_ending_label(ending)
		lines.append("%s  [color=#%s]%s[/color]" % [label, color, ending_display if not ending_display.is_empty() else "—"])
		if normalized == "defining game":
			any_defining = true

	lines.append("")

	if any_defining:
		lines.append(_S.get_string("popups", "cycle_legacy_goldilocks_reached"))
	else:
		lines.append(_S.get_string("popups", "cycle_legacy_goldilocks_missed"))
		lines.append(_S.get_string("popups", "cycle_legacy_reset_note"))

	return "\n".join(lines)

static func _extract_ending_label(ending: String) -> String:
	if ending.contains(":"):
		return ending.split(":", false, 1)[0].strip_edges()
	return ending.strip_edges()

static func build_review_roulette_text(results: Dictionary) -> String:
	var review_lines: PackedStringArray = []
	review_lines.append(_S.get_string("popups", "review_roulette_header") + "\n")
	var ending: String = String(results.get("ending", "Rough Diamond"))
	var review_score: float = float(results.get("review_score", 0.0))
	review_lines.append(_build_review_roulette_intro(ending, review_score))
	review_lines.append("")

	var reviews: Array = results.get("reviews", [])
	for review in reviews:
		if review is Dictionary:
			var author: String = ReviewMarkupUtils.normalize_review_markup(String(review.get("author", "Reviewer")))
			var score: String = ReviewMarkupUtils.normalize_review_markup(String(review.get("score", "?")))
			var body: String = ReviewMarkupUtils.normalize_review_markup(String(review.get("text", "")))
			review_lines.append("[b]%s[/b] [%s]" % [author, score])
			review_lines.append(body)
			review_lines.append("")
	return "\n".join(review_lines)

static func build_ship_summary_text(game_state: Node, predicted_score: float, highlights: Array[String]) -> String:
	if game_state == null:
		return ""

	var content: String = ""
	content += _S.get_string("popups", "ship_summary_snapshot_header") + "\n\n"

	content += _S.get_string("popups", "ship_summary_stats_header") + "\n"
	content += _S.get_string("popups", "ship_summary_stats_line1") % [int(game_state.ambition), int(game_state.instability)] + "\n"
	content += _S.get_string("popups", "ship_summary_stats_line2") % [int(game_state.soul), int(game_state.runway_days)] + "\n\n"

	content += _S.get_string("popups", "ship_summary_features_header") % game_state.feature_board.size() + "\n"
	for card in game_state.feature_board:
		if card is FeatureCard:
			var fc: FeatureCard = card as FeatureCard
			content += "* %s (Tags: %s)\n" % [fc.feature_name, ", ".join(fc.tags)]
	content += "\n"

	content += _S.get_string("popups", "ship_summary_prediction_header") + "\n"
	content += _S.get_string("popups", "ship_summary_score_format") % predicted_score + "\n"
	content += _S.get_string("popups", "ship_summary_ending_format") % _predict_ending_label(game_state, predicted_score) + "\n\n"

	if not highlights.is_empty():
		content += _S.get_string("popups", "ship_summary_interactions_header") + "\n"
		for highlight in highlights.slice(0, 4):
			content += "-> %s\n" % highlight
		content += "\n"

	content += _S.get_string("popups", "ship_summary_confirm_note")
	return content

static func build_mechanics_highlights_text(mechanics_highlights: Array) -> String:
	if mechanics_highlights.is_empty():
		return _S.get_string("popups", "mechanics_no_interactions")

	var content: String = _S.get_string("popups", "mechanics_header") + "\n\n"
	for i in range(mechanics_highlights.size()):
		var highlight: String = String(mechanics_highlights[i])
		var rank: String = "Legendary"
		if i >= mechanics_highlights.size() - 1:
			rank = "Common"
		elif i >= mechanics_highlights.size() * 0.75:
			rank = "Rare"
		elif i >= mechanics_highlights.size() * 0.5:
			rank = "Epic"
		content += "[color=#ff9900][%s][/color] %s\n\n" % [rank, highlight]
	return content

static func build_jank_meter_text(results: Dictionary, ambition: int, instability: int, soul: int, config: GameConfig) -> String:
	var review_score: float = float(results.get("review_score", 0.0))
	var jank_status: String = String(results.get("jank_status", "volatile"))
	var ending: String = String(results.get("ending", "Unknown"))

	var score_color: String = "ff6b6b"
	if review_score >= 8.5:
		score_color = "51cf66"
	elif review_score >= 7.0:
		score_color = "74c0fc"
	elif review_score >= 5.0:
		score_color = "ffd43b"

	var content: String = ""
	content += "[center][b][color=#%s]FINAL SCORE: %.1f/10[/color][/b][/center]\n\n" % [score_color, review_score]

	var status_label: String = "Status"
	var status_flavor: String = _S.get_string("popups", "jank_default_flavor")
	var status_color: String = "ffffff"
	match jank_status:
		"polished":
			status_color = "74c0fc"
			status_label = _S.get_string("popups", "jank_polished_label")
			status_flavor = _S.get_string("popups", "jank_polished_flavor")
		"sweet_spot":
			status_color = "51cf66"
			status_label = _S.get_string("popups", "jank_sweet_spot_label")
			status_flavor = _S.get_string("popups", "jank_sweet_spot_flavor")
		"volatile":
			status_color = "ffd43b"
			status_label = _S.get_string("popups", "jank_volatile_label")
			status_flavor = _S.get_string("popups", "jank_volatile_flavor")
		"broken":
			status_color = "ff8c42"
			status_label = _S.get_string("popups", "jank_broken_label")
			status_flavor = _S.get_string("popups", "jank_broken_flavor")

	content += "[color=#%s]%s[/color]\n" % [status_color, status_label]
	content += "[i]%s[/i]\n\n" % status_flavor
	content += _S.get_string("popups", "jank_ending_path_header") + "\n"
	content += "%s\n\n" % ending
	content += "[i]%s[/i]\n\n" % _build_ending_epilogue(ending)
	content += _S.get_string("popups", "jank_postmortem_header") + "\n"
	content += "Instability: %d | Soul: %d\n\n" % [instability, soul]

	if config != null:
		content += _build_goldilocks_gap_section(ambition, instability, soul, config) + "\n"

	var card_unlock: Dictionary = results.get("card_unlock", {})
	if not card_unlock.is_empty():
		content += "\n" + _S.get_string("popups", "jank_card_unlock_header") + "\n"
		var card_display_name: String = String(card_unlock.get("card_name", card_unlock.get("card_id", "?")))
		content += "%s  (quality: %.0f%%)\n" % [card_display_name, float(card_unlock.get("unlock_quality", 0.0)) * 100.0]
		content += _S.get_string("popups", "jank_card_unlock_note") + "\n"

	var defining_unlock: bool = bool(results.get("unlock_defining_game", false))
	# Backward compatibility for older run result payloads from pre-rename saves.
	if not defining_unlock:
		defining_unlock = bool(results.get("unlock_gothic_mode", false))

	if defining_unlock:
		content += "\n" + _S.get_string("popups", "jank_defining_game_label") + "\n"
		content += _S.get_string("popups", "jank_defining_game_note")

	return content

static func _build_review_roulette_intro(ending: String, review_score: float) -> String:
	var intro_key: String = "roulette_intro_" + _ending_key(ending)
	if _S.has_key("popups", intro_key):
		return _S.get_string("popups", intro_key)
	# Score-based fallback when no specific key exists for this ending.
	if review_score >= 7.0:
		return _S.get_string("popups", "roulette_intro_high_score")
	if review_score <= 3.0:
		return _S.get_string("popups", "roulette_intro_low_score")
	return _S.get_string("popups", "roulette_intro_default")

static func _build_ending_epilogue(ending: String) -> String:
	var epilogue_key: String = "epilogue_" + _ending_key(ending)
	if _S.has_key("popups", epilogue_key):
		return _S.get_string("popups", epilogue_key)
	return _S.get_string("popups", "epilogue_default")

static func _extract_ending_name(ending: String) -> String:
	if ending.contains(":"):
		return ending.split(":", false, 1)[0].strip_edges()
	return ending.strip_edges()

static func _ending_key(ending: String) -> String:
	# "Surprise Hit" -> "surprise_hit"; strips suffix annotations like "Cult Classic: The Build Endures".
	return _extract_ending_name(ending).to_lower().replace(" ", "_")

static func _predict_ending_label(game_state: Node, predicted_score: float) -> String:
	if game_state == null or not game_state.has_method("get_game_config"):
		return "Rough Diamond"

	var config: GameConfig = game_state.get_game_config() as GameConfig
	if config == null:
		return "Rough Diamond"
	var ambition: int = int(game_state.ambition)
	var instability: int = int(game_state.instability)
	var soul: int = int(game_state.soul)

	var bucket: String = ""
	if game_state.has_method("get_dominant_style_bucket"):
		bucket = String(game_state.get_dominant_style_bucket())
	return EndingResolver.resolve_ending_label(config, ambition, instability, soul, predicted_score, bucket)

## Renders the Goldilocks gap visualizer — proportional bars, no numbers.
## Shown in the jank meter after every run so the player learns the gap intuitively.
static func _build_goldilocks_gap_section(ambition: int, instability: int, soul: int, cfg: GameConfig) -> String:
	const BAR_LEN: int = 14
	var lines: PackedStringArray = PackedStringArray()
	lines.append("[b]GOLDILOCKS GAP[/b]")
	lines.append("[i]How close you came to the Defining Game gate.[/i]")
	lines.append("")

	# Ambition: must reach goldilocks_ambition_min
	var amb_ratio: float = clampf(float(ambition) / float(cfg.goldilocks_ambition_min), 0.0, 1.0)
	var amb_label: String
	if ambition >= cfg.goldilocks_ambition_min:
		amb_label = "\u2713"
	elif amb_ratio >= 0.80:
		amb_label = "close"
	else:
		amb_label = "needs more"
	lines.append("AMBITION    %s  %s" % [_gap_bar(amb_ratio, BAR_LEN), amb_label])

	# Instability: must land in [goldilocks_instability_min, goldilocks_instability_max]
	var inst_ratio: float
	var inst_label: String
	if instability < cfg.goldilocks_instability_min:
		inst_ratio = clampf(float(instability) / float(cfg.goldilocks_instability_min), 0.0, 1.0)
		inst_label = "close" if inst_ratio >= 0.70 else "too low"
	elif instability > cfg.goldilocks_instability_max:
		inst_ratio = 1.0
		inst_label = "too high"
	else:
		inst_ratio = 1.0
		inst_label = "\u2713"
	lines.append("INSTABILITY %s  %s" % [_gap_bar(inst_ratio, BAR_LEN), inst_label])

	# Soul: must reach goldilocks_soul_min
	var soul_ratio: float = clampf(float(soul) / float(cfg.goldilocks_soul_min), 0.0, 1.0)
	var soul_label: String
	if soul >= cfg.goldilocks_soul_min:
		soul_label = "\u2713"
	elif soul_ratio >= 0.80:
		soul_label = "close"
	else:
		soul_label = "needs more"
	lines.append("SOUL        %s  %s" % [_gap_bar(soul_ratio, BAR_LEN), soul_label])
	return "\n".join(lines)

static func _gap_bar(ratio: float, length: int) -> String:
	var filled: int = clampi(int(round(ratio * float(length))), 0, length)
	return "\u2588".repeat(filled) + "\u2591".repeat(length - filled)
