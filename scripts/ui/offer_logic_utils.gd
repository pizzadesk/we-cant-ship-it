const _S = preload("res://scripts/ui/ui_strings.gd")

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
