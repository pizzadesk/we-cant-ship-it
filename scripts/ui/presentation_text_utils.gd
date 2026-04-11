const ReviewMarkupUtils = preload("res://scripts/ui/review_markup_utils.gd")
const ArchetypeRules = preload("res://scripts/data/services/archetype_rules.gd")
const EndingResolver = preload("res://scripts/data/ending_resolver.gd")
const _S = preload("res://scripts/ui/ui_strings.gd")

## Builds the cycle legacy screen text shown after run 4 ships.
## cycle_state must be the full dictionary from AppState.get_cycle_state()
## after complete_run() has already recorded run_4_ending.
static func build_cycle_legacy_text(cycle_state: Dictionary) -> String:
	var lines: PackedStringArray = PackedStringArray()
	var rule: String = "[color=#444444]" + "\u2500".repeat(42) + "[/color]"

	lines.append(_S.get_string("popups", "cycle_legacy_arc_header") + "\n")

	var ending_colors: Dictionary = {
		"defining game":       "51cf66",
		"legendary jank":      "ff8c42",
		"surprise hit":        "74c0fc",
		"prestige collapse":   "cc5de8",
		"shipped something":   "adb5bd",
	}

	var any_defining: bool = false
	var first_run: bool = true
	for run_num in [1, 2, 3, 4]:
		if not first_run:
			lines.append(rule)
		first_run = false
		var ending: String = String(cycle_state.get("run_%d_ending" % run_num, ""))
		var raw_summary: Variant = cycle_state.get("run_%d_summary" % run_num, {})
		var summary: Dictionary = raw_summary if raw_summary is Dictionary else {}
		var label: String = _S.get_string("popups", "cycle_legacy_run_header") % run_num
		var normalized: String = String(summary.get("ending_id", EndingResolver.normalize_ending_id(ending)))
		var color: String = String(ending_colors.get(normalized, "ffffff"))
		var ending_display: String = _extract_ending_label(ending)
		lines.append("%s  [color=#%s]%s[/color]" % [label, color, ending_display if not ending_display.is_empty() else "—"])
		var raw_jank_combination: Variant = summary.get("jank_combination", {})
		var jank_combination: Dictionary = raw_jank_combination if raw_jank_combination is Dictionary else {}
		if not jank_combination.is_empty():
			lines.append("  Jank discovered: [color=#ff922b]%s[/color]" % String(jank_combination.get("name", "Unknown Jank")))
			lines.append("  %s" % String(jank_combination.get("description", "")))
		if normalized == EndingResolver.DEFINING_GAME_ID:
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

static func build_review_fallout_text(results: Dictionary) -> String:
	var review_lines: PackedStringArray = []
	review_lines.append(_S.get_string("popups", "review_roulette_header") + "\n")
	var ending: String = String(results.get("ending", "Shipped Something"))
	var review_score: float = float(results.get("review_score", 0.0))
	review_lines.append(_build_review_intro(ending, review_score))
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

static func build_review_roulette_text(results: Dictionary) -> String:
	return build_review_fallout_text(results)

static func build_ship_summary_text(game_state: Node, predicted_score: float) -> String:
	if game_state == null:
		return ""

	var rule: String = "\n[color=#444444]" + "\u2500".repeat(42) + "[/color]\n\n"
	var ending_colors: Dictionary = {
		EndingResolver.DEFINING_GAME_ID: "ff00ff",
		EndingResolver.LEGENDARY_JANK_ID: "ff8c42",
		EndingResolver.SURPRISE_HIT_ID: "74c0fc",
		EndingResolver.PRESTIGE_COLLAPSE_ID: "cc5de8",
		EndingResolver.SHIPPED_SOMETHING_ID: "cccccc",
	}

	var content: String = ""
	content += _S.get_string("popups", "ship_summary_snapshot_header") + rule

	# Prediction first — the key decision the player is about to confirm.
	var ending_label: String = _predict_ending_label(game_state, predicted_score)
	var normalized: String = EndingResolver.normalize_ending_id(ending_label)
	var ending_hex: String = "#" + String(ending_colors.get(normalized, "cccccc"))
	content += _S.get_string("popups", "ship_summary_prediction_header") + "\n"
	content += _S.get_string("popups", "ship_summary_score_format") % predicted_score + "\n"
	content += "[color=%s]Ending Path: %s[/color]" % [ending_hex, ending_label] + rule

	# Stats — color-coded to match the main game UI gauges.
	content += _S.get_string("popups", "ship_summary_stats_header") + "\n"
	content += _S.get_string("popups", "ship_summary_stats_line1") % [int(game_state.ambition), int(game_state.instability)] + "\n"
	content += _S.get_string("popups", "ship_summary_stats_line2") % [int(game_state.soul), int(game_state.runway_days)] + rule

	# Feature list — tags dimmed so card names stay dominant.
	content += _S.get_string("popups", "ship_summary_features_header") % game_state.feature_board.size() + "\n"
	for card in game_state.feature_board:
		if card is FeatureCard:
			var fc: FeatureCard = card as FeatureCard
			if fc.tags.is_empty():
				content += "\u2022 %s\n" % fc.feature_name
			else:
				content += "\u2022 %s [color=#666666](%s)[/color]\n" % [fc.feature_name, ", ".join(fc.tags)]
	content += "\n"

	content += _S.get_string("popups", "ship_summary_confirm_note")
	return content

static func build_gap_visualizer_text(_results: Dictionary, ambition: int, instability: int, soul: int, archetype: String, config: GameConfig, completed_run: int) -> String:
	if config == null:
		return ""
	return _build_goldilocks_gap_section(ambition, instability, soul, archetype, config, completed_run)

static func build_jank_discovery_text(results: Dictionary) -> String:
	var lines: PackedStringArray = PackedStringArray()
	var rule: String = "[color=#444444]" + "\u2500".repeat(42) + "[/color]"
	var ending: String = String(results.get("ending", "Shipped Something"))
	var ending_id: String = String(results.get("ending_id", EndingResolver.normalize_ending_id(ending)))
	lines.append("[b]%s[/b]" % _extract_ending_label(ending))
	lines.append("[i]%s[/i]" % _build_ending_epilogue(ending))
	lines.append(rule)

	var jank_combination: Dictionary = results.get("jank_combination", {})
	if not jank_combination.is_empty():
		lines.append("[color=#ff8c42][b]JANK DISCOVERY[/b][/color]")
		lines.append("[color=#ff8c42]%s[/color]" % String(jank_combination.get("name", "Unknown Combo")))
		lines.append(String(jank_combination.get("description", "")))
	else:
		lines.append("[color=#888888][b]JANK DISCOVERY[/b][/color]")
		lines.append("[color=#888888]The studio shipped something solid. Nothing legendary broke.[/color]")

	var card_unlock: Dictionary = results.get("card_unlock", {})
	if not card_unlock.is_empty():
		lines.append(rule)
		lines.append(_S.get_string("popups", "jank_card_unlock_header"))
		lines.append("[b]%s[/b]" % String(card_unlock.get("card_name", card_unlock.get("card_id", "?"))))
		var bonus_card_name: String = String(card_unlock.get("bonus_card_name", ""))
		if not bonus_card_name.is_empty():
			lines.append("Bonus unlock: [b]%s[/b]" % bonus_card_name)
		lines.append("[i]%s[/i]" % _S.get_string("popups", "jank_card_unlock_note"))

	if bool(results.get("unlock_defining_game", false)) or ending_id == EndingResolver.DEFINING_GAME_ID:
		lines.append(rule)
		lines.append(_S.get_string("popups", "jank_defining_game_label"))
		lines.append(_S.get_string("popups", "jank_defining_game_note"))

	return "\n".join(lines)

static func build_previously_on_text(run_summary: Dictionary, current_run: int, config: GameConfig) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("[b]RUN %d OF 4[/b]" % current_run)
	if current_run == 2:
		lines.append("[color=#888888]The five-day tutorial sprint is over. The studio found its voice. Now it has to ship on purpose.[/color]")
	else:
		lines.append("[color=#888888]A new sprint begins.[/color]")
	lines.append("")
	if run_summary.is_empty():
		lines.append("[i]The studio remembers the bruises, not the details.[/i]")
		return "\n".join(lines)

	var ending: String = String(run_summary.get("ending", ""))
	var ending_id: String = String(run_summary.get("ending_id", EndingResolver.normalize_ending_id(ending)))
	if not ending.is_empty():
		var last_time_color: String = "74c0fc" if ending_id != EndingResolver.PRESTIGE_COLLAPSE_ID else "cc5de8"
		lines.append("Last time: [color=#%s]%s[/color]" % [last_time_color, _extract_ending_label(ending)])
		lines.append("")

	if config != null:
		lines.append(_build_goldilocks_gap_section(
			int(run_summary.get("ambition", 0)),
			int(run_summary.get("instability", 0)),
			int(run_summary.get("soul", 0)),
			String(run_summary.get("archetype", "")),
			config,
			int(run_summary.get("run", maxi(1, current_run - 1))),
		))

	var raw_jank_combination: Variant = run_summary.get("jank_combination", {})
	var jank_combination: Dictionary = raw_jank_combination if raw_jank_combination is Dictionary else {}
	if not jank_combination.is_empty():
		lines.append("")
		lines.append("[b]Discovered jank[/b]")
		var src_a: String = String(jank_combination.get("card_a", ""))
		var src_b: String = String(jank_combination.get("card_b", ""))
		if not src_a.is_empty() and not src_b.is_empty():
			lines.append("%s + %s" % [src_a, src_b])
		lines.append("[color=#ff922b]\u2192 %s[/color]" % String(jank_combination.get("name", "Unknown Combo")))
		lines.append(String(jank_combination.get("description", "")))

	return "\n".join(lines)

static func _build_review_intro(ending: String, review_score: float) -> String:
	var intro_key: String = "roulette_intro_" + _ending_key(ending)
	if _S.has_key("popups", intro_key):
		return _S.get_string("popups", intro_key)
	# Score-based fallback when no specific key exists for this ending.
	if review_score >= 7.0:
		return _S.get_string("popups", "roulette_intro_high_score")
	if review_score <= 3.0:
		return _S.get_string("popups", "roulette_intro_low_score")
	return _S.get_string("popups", "roulette_intro_default")

static func _build_review_roulette_intro(ending: String, review_score: float) -> String:
	return _build_review_intro(ending, review_score)

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

static func _predict_ending_label(game_state: Node, _predicted_score: float) -> String:
	if game_state == null or not game_state.has_method("get_game_config"):
		return "Shipped Something"

	var config: GameConfig = game_state.get_game_config() as GameConfig
	if config == null:
		return "Shipped Something"
	var ambition: int = int(game_state.ambition)
	var instability: int = int(game_state.instability)
	var soul: int = int(game_state.soul)
	var archetype: String = ""
	var current_run: int = int(game_state.current_run)
	if game_state.has_method("get_chosen_archetype"):
		archetype = String(game_state.get_chosen_archetype())
	return EndingResolver.resolve_ending_label(config, ambition, instability, soul, archetype, false, current_run)

## Renders the Gap Visualizer — proportional bars vs per-archetype Goldilocks window.
## Shown after every run so the player learns the gap intuitively.
## Runs 2-3 show whether the Defining Game status was open or locked.
static func _build_goldilocks_gap_section(ambition: int, instability: int, soul: int, archetype: String, cfg: GameConfig, current_run: int) -> String:
	const BAR_LEN: int = 14
	var lines: PackedStringArray = PackedStringArray()
	lines.append("[b]GAP VISUALIZER[/b]  [color=#555555]Run %d[/color]" % current_run)

	var gate_line: String
	if current_run <= 1:
		gate_line = "[color=#888888]DEFINING GAME: LOCKED \u2014 this run was about learning the shape of the chaos.[/color]"
	else:
		var gw: Array[int] = ArchetypeRules.get_goldilocks_window_for_archetype(cfg, archetype)
		var ambition_ok: bool = ambition >= cfg.goldilocks_ambition_min
		var inst_ok: bool = instability >= gw[0] and instability <= gw[1]
		var soul_ok: bool = soul >= cfg.goldilocks_soul_min
		if ambition_ok and inst_ok and soul_ok:
			gate_line = "[color=#51cf66][b]\u2713 DEFINING GAME: ACHIEVED![/b][/color]"
		else:
			gate_line = "[color=#ffd43b]DEFINING GAME: NOT QUITE THERE YET[/color]"
	lines.append(gate_line)
	lines.append("")

	var amb_ratio: float = clampf(float(ambition) / float(cfg.goldilocks_ambition_min), 0.0, 1.0)
	var amb_bar_color: String
	var amb_label: String
	if ambition >= cfg.goldilocks_ambition_min:
		amb_bar_color = "51cf66"
		amb_label = "[color=#51cf66]\u2713[/color]"
	elif amb_ratio >= 0.80:
		amb_bar_color = "ffd43b"
		amb_label = "[color=#ffd43b]close[/color]"
	else:
		amb_bar_color = "ff922b"
		amb_label = "[color=#ff922b]needs more[/color]"
	lines.append("AMBITION    %s  %s" % [_gap_bar_colored(amb_ratio, BAR_LEN, amb_bar_color), amb_label])

	var window: Array[int] = ArchetypeRules.get_goldilocks_window_for_archetype(cfg, archetype)
	var inst_ratio: float
	var inst_bar_color: String
	var inst_label: String
	if instability < window[0]:
		inst_ratio = clampf(float(instability) / float(window[0]), 0.0, 1.0)
		if inst_ratio >= 0.70:
			inst_bar_color = "ffd43b"
			inst_label = "[color=#ffd43b]close[/color]"
		else:
			inst_bar_color = "ff922b"
			inst_label = "[color=#ff922b]too low[/color]"
	elif instability > window[1]:
		inst_ratio = 1.0
		inst_bar_color = "ff6b6b"
		inst_label = "[color=#ff6b6b]too high[/color]"
	else:
		inst_ratio = 1.0
		inst_bar_color = "51cf66"
		inst_label = "[color=#51cf66]\u2713[/color]"
	lines.append("INSTABILITY %s  %s" % [_gap_bar_colored(inst_ratio, BAR_LEN, inst_bar_color), inst_label])

	var soul_ratio: float = clampf(float(soul) / float(cfg.goldilocks_soul_min), 0.0, 1.0)
	var soul_bar_color: String
	var soul_label: String
	if soul >= cfg.goldilocks_soul_min:
		soul_bar_color = "51cf66"
		soul_label = "[color=#51cf66]\u2713[/color]"
	elif soul_ratio >= 0.80:
		soul_bar_color = "ffd43b"
		soul_label = "[color=#ffd43b]close[/color]"
	else:
		soul_bar_color = "ff922b"
		soul_label = "[color=#ff922b]needs more[/color]"
	lines.append("SOUL        %s  %s" % [_gap_bar_colored(soul_ratio, BAR_LEN, soul_bar_color), soul_label])
	return "\n".join(lines)

static func _gap_bar(ratio: float, length: int) -> String:
	var filled: int = clampi(int(round(ratio * float(length))), 0, length)
	return "\u2588".repeat(filled) + "\u2591".repeat(length - filled)

static func _gap_bar_colored(ratio: float, length: int, bar_color: String) -> String:
	var filled: int = clampi(int(round(ratio * float(length))), 0, length)
	var empty: int = length - filled
	var result: String = ""
	if filled > 0:
		result += "[color=#%s]%s[/color]" % [bar_color, "\u2588".repeat(filled)]
	if empty > 0:
		result += "[color=#444444]%s[/color]" % "\u2591".repeat(empty)
	return result
