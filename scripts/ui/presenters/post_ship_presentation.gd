const _S = preload("res://scripts/ui/ui_strings.gd")

static func build_ship_summary_text(game_state: Node, predicted_score: float) -> String:
	if game_state == null:
		return ""

	var rule: String = "\n[color=#1a3d1a]" + "\u2500".repeat(42) + "[/color]\n\n"
	var ending_colors: Dictionary = {
		EndingResolver.DEFINING_GAME_ID: "ff00ff",
		EndingResolver.LEGENDARY_JANK_ID: "ff8c42",
		EndingResolver.SURPRISE_HIT_ID: "66cccc",
		EndingResolver.PRESTIGE_COLLAPSE_ID: "cc5de8",
		EndingResolver.SHIPPED_SOMETHING_ID: "80cc80",
	}

	var content: String = ""
	content += _S.get_string("popups", "ship_summary_snapshot_header") + rule

	var ending_label: String = _predict_ending_label(game_state, predicted_score)
	var normalized: String = EndingResolver.normalize_ending_id(ending_label)
	var ending_hex: String = "#" + String(ending_colors.get(normalized, "80cc80"))
	content += _S.get_string("popups", "ship_summary_prediction_header") + "\n"
	content += _S.get_string("popups", "ship_summary_score_format") % predicted_score + "\n"
	content += "[color=%s]Ending Path: %s[/color]" % [ending_hex, ending_label] + rule

	content += _S.get_string("popups", "ship_summary_stats_header") + "\n"
	content += _S.get_string("popups", "ship_summary_stats_line1") % [int(game_state.ambition), int(game_state.instability)] + "\n"
	content += _S.get_string("popups", "ship_summary_stats_line2") % [int(game_state.soul), int(game_state.runway_days)] + rule

	content += _S.get_string("popups", "ship_summary_features_header") % game_state.feature_board.size() + "\n"
	for card in game_state.feature_board:
		if card is FeatureCard:
			var feature_card: FeatureCard = card as FeatureCard
			if feature_card.tags.is_empty():
				content += "\u2022 %s\n" % feature_card.feature_name
			else:
				content += "\u2022 %s [color=#4a7a4a](%s)[/color]\n" % [feature_card.feature_name, ", ".join(feature_card.tags)]
	content += "\n"
	content += _S.get_string("popups", "ship_summary_confirm_note")
	return content

static func build_jank_discovery_text(results: Dictionary) -> String:
	var lines: PackedStringArray = PackedStringArray()
	var rule: String = "[color=#1a3d1a]" + "\u2500".repeat(42) + "[/color]"
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
		lines.append("[color=#558855][b]JANK DISCOVERY[/b][/color]")
		lines.append("[color=#558855]The studio shipped something solid. Nothing legendary broke.[/color]")

	var card_unlock: Dictionary = results.get("card_unlock", {})
	if not card_unlock.is_empty():
		lines.append(rule)
		lines.append(_S.get_string("popups", "jank_card_unlock_header"))
		lines.append("[b]%s[/b]" % String(card_unlock.get("card_name", card_unlock.get("card_id", "?"))))
		var bonus_card_name: String = String(card_unlock.get("bonus_card_name", ""))
		if not bonus_card_name.is_empty():
			lines.append("Bonus unlock: [b]%s[/b]" % bonus_card_name)
		lines.append("[i]%s[/i]" % _S.get_string("popups", "jank_card_unlock_note"))

	var unfulfilled: Dictionary = results.get("unfulfilled_prospect", {})
	if not unfulfilled.is_empty() and jank_combination.is_empty():
		lines.append(rule)
		lines.append(_S.get_string("popups", "jank_almost_locked_header"))
		lines.append("[color=#558855]%s[/color]" % String(unfulfilled.get("name", "")))
		lines.append("[color=#4a7a4a]%s + %s[/color]" % [
			String(unfulfilled.get("card_a", "")),
			String(unfulfilled.get("card_b", ""))
		])
		lines.append("[i]%s[/i]" % _S.get_string("popups", "jank_almost_locked_note"))

	if bool(results.get("unlock_defining_game", false)) or ending_id == EndingResolver.DEFINING_GAME_ID:
		lines.append(rule)
		lines.append(_S.get_string("popups", "jank_defining_game_label"))
		lines.append(_S.get_string("popups", "jank_defining_game_note"))

	return "\n".join(lines)

static func _build_ending_epilogue(ending: String) -> String:
	var epilogue_key: String = "epilogue_" + _ending_key(ending)
	if _S.has_key("popups", epilogue_key):
		return _S.get_string("popups", epilogue_key)
	return _S.get_string("popups", "epilogue_default")

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
	var has_locked_jank: bool = false
	if game_state.has_method("get_chosen_archetype"):
		archetype = String(game_state.get_chosen_archetype())
	if game_state.has_method("has_locked_signature_jank"):
		has_locked_jank = bool(game_state.has_locked_signature_jank())
	return EndingResolver.resolve_ending_label(config, ambition, instability, soul, archetype, has_locked_jank, current_run)

static func _ending_key(ending: String) -> String:
	return _extract_ending_name(ending).to_lower().replace(" ", "_")

static func _extract_ending_name(ending: String) -> String:
	if ending.contains(":"):
		return String(ending.split(":", false, 1)[0]).strip_edges()
	return ending.strip_edges()

static func _extract_ending_label(ending: String) -> String:
	return _extract_ending_name(ending)