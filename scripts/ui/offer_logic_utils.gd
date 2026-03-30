const _S = preload("res://scripts/ui/ui_strings.gd")

static func pick_safe_publisher_stance(options: Array) -> int:
	var best_index: int = 0
	var best_score: int = -999999
	for idx in range(options.size()):
		var option: Dictionary = options[idx]
		var effects: Dictionary = option.get("effects", {})
		var score: int = 0
		score += int(effects.get("runway_days", 0)) * 4
		score += int(effects.get("instability", 0)) * -2
		score += int(effects.get("soul", 0))
		score += int(effects.get("ambition", 0))
		if score > best_score:
			best_score = score
			best_index = idx
	return best_index

static func get_most_unstable_pick_index(picks: Array) -> int:
	var best_index: int = 0
	var best_instability: int = -999999
	for index in range(picks.size()):
		var pick: Dictionary = picks[index]
		var effects: Dictionary = pick.get("effects", {})
		var instability_score: int = int(effects.get("instability", 0))
		if instability_score > best_instability:
			best_instability = instability_score
			best_index = index
	return best_index

static func get_least_favored_choice_index(choices: Array) -> int:
	var worst_index: int = 0
	var worst_score: float = INF
	for index in range(choices.size()):
		var choice: Dictionary = choices[index]
		var effects: Dictionary = choice.get("effects", {})
		var favor_score: float = 0.0
		favor_score += float(int(effects.get("ambition", 0))) * 0.4
		favor_score += float(int(effects.get("soul", 0))) * 0.7
		favor_score += float(int(effects.get("runway_days", 0)))
		favor_score -= float(int(effects.get("instability", 0))) * 0.8
		if favor_score < worst_score:
			worst_score = favor_score
			worst_index = index
	return worst_index

static func format_choice_effects(effects: Dictionary) -> String:
	if effects.is_empty():
		return _S.get_string("popups", "choice_no_effect")
	var parts: PackedStringArray = []
	for key in effects.keys():
		var key_name: String = format_effect_key(String(key))
		var delta: int = int(effects[key])
		if key == "runway_days" and delta < 0:
			parts.append("%s %+d %s" % [key_name, delta, _S.get_string("popups", "choice_budget_hit")])
		else:
			parts.append("%s %+d" % [key_name, delta])
	return ", ".join(parts)

static func format_effect_key(key: String) -> String:
	match key:
		"runway_days":
			return _S.get_string("popups", "stat_runway_days")
		"instability":
			return _S.get_string("popups", "stat_instability")
		"ambition":
			return _S.get_string("popups", "stat_ambition")
		"soul":
			return _S.get_string("popups", "stat_soul")
		_:
			return key.capitalize()

static func build_runway_warning(effect_sets: Array) -> String:
	var worst_delta: int = 0
	for item in effect_sets:
		if item is Dictionary:
			var effects: Dictionary = item
			worst_delta = mini(worst_delta, int(effects.get("runway_days", 0)))
	if worst_delta >= 0:
		return ""
	return _S.get_string("popups", "choice_runway_warning") % worst_delta

static func apply_choice_if_pending(game_state: Node, pending_offer: Dictionary, method_name: StringName, choice_index: int) -> bool:
	if game_state == null or pending_offer.is_empty():
		return false
	if not game_state.has_method(method_name):
		return false
	game_state.call(method_name, choice_index)
	return true

static func has_valid_offer_entries(entries: Array[Dictionary], required_count: int, label_key: String) -> bool:
	if entries.size() < required_count:
		return false
	for index in range(required_count):
		var entry: Dictionary = entries[index]
		if String(entry.get(label_key, "")).strip_edges().is_empty():
			return false
		var effects: Variant = entry.get("effects", {})
		if effects is not Dictionary:
			return false
	return true
