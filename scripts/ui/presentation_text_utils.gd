const ReviewMarkupUtils = preload("res://scripts/ui/review_markup_utils.gd")
const _S = preload("res://scripts/ui/ui_strings.gd")
const EndingResolver = preload("res://scripts/data/ending_resolver.gd")

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

static func build_jank_meter_text(results: Dictionary, instability: int, soul: int) -> String:
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
	content += "Instability: %d | Soul: %d\n" % [instability, soul]

	var card_unlock: Dictionary = results.get("card_unlock", {})
	if not card_unlock.is_empty():
		content += "\n" + _S.get_string("popups", "jank_card_unlock_header") + "\n"
		content += "%s (Quality: %.2f)\n" % [
			String(card_unlock.get("card_id", "unknown")),
			float(card_unlock.get("unlock_quality", 0.0))
		]
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
