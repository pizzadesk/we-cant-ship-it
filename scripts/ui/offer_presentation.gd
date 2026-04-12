const _S = preload("res://scripts/ui/ui_strings.gd")

static func format_dilemma_title(title: String) -> String:
	return title

static func format_dilemma_choice_label(_title: String, label: String) -> String:
	return label

static func build_dilemma_dialog_text(_title: String, description: String, choice_a: Dictionary, choice_b: Dictionary) -> String:
	var label_a: String = String(choice_a.get("label", "Choice A"))
	var label_b: String = String(choice_b.get("label", "Choice B"))
	var base_text: String = "%s\n\n%s) %s\n%s) %s" % [
		description,
		label_a, format_choice_effects(choice_a.get("effects", {})),
		label_b, format_choice_effects(choice_b.get("effects", {}))
	]
	base_text += build_runway_warning([
		choice_a.get("effects", {}),
		choice_b.get("effects", {}),
	])
	return base_text

static func build_draft_dialog_text(description: String, pick_a: Dictionary, pick_b: Dictionary, pick_c: Dictionary) -> String:
	var title_a: String = String(pick_a.get("title", "Pick A"))
	var title_b: String = String(pick_b.get("title", "Pick B"))
	var title_c: String = String(pick_c.get("title", "Pick C"))
	var base_text: String = "%s\n\n%s) %s\n%s) %s\n%s) %s" % [
		description,
		title_a, format_choice_effects(pick_a.get("effects", {})),
		title_b, format_choice_effects(pick_b.get("effects", {})),
		title_c, format_choice_effects(pick_c.get("effects", {}))
	]
	base_text += build_runway_warning([
		pick_a.get("effects", {}),
		pick_b.get("effects", {}),
		pick_c.get("effects", {}),
	])
	return base_text

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

static func apply_choice(game_state: Node, method_name: StringName, choice_index: int) -> bool:
	if game_state == null:
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
