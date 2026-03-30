const OfferLogicUtils = preload("res://scripts/ui/offer_logic_utils.gd")
const _S = preload("res://scripts/ui/ui_strings.gd")

const PUBLISHER_ULTIMATUM_TITLE: String = "Publisher Ultimatum"

static func format_dilemma_title(title: String) -> String:
	# Publisher Ultimatum display title is configurable in data/strings/publisher.json.
	if title == PUBLISHER_ULTIMATUM_TITLE:
		return _S.get_string("publisher", "ultimatum_display_title", "Publisher Ultimatum")
	return title

static func format_dilemma_choice_label(title: String, label: String) -> String:
	if title == PUBLISHER_ULTIMATUM_TITLE:
		return _get_publisher_label(label)
	return label

static func format_publisher_title(title: String) -> String:
	# Titles originate from offers.json in English; return as-is.
	if title.is_empty():
		return _S.get_string("publisher", "meeting_title_fallback")
	return title

static func format_publisher_stance_label(label: String) -> String:
	return _get_publisher_label(label)

static func build_dilemma_dialog_text(title: String, description: String, choice_a: Dictionary, choice_b: Dictionary) -> String:
	if title == PUBLISHER_ULTIMATUM_TITLE:
		return _build_publisher_ultimatum_text(description, choice_a, choice_b)

	var label_a: String = String(choice_a.get("label", "Choice A"))
	var label_b: String = String(choice_b.get("label", "Choice B"))
	var base_text: String = "%s\n\n%s) %s\n%s) %s" % [
		description,
		label_a, OfferLogicUtils.format_choice_effects(choice_a.get("effects", {})),
		label_b, OfferLogicUtils.format_choice_effects(choice_b.get("effects", {}))
	]
	base_text += OfferLogicUtils.build_runway_warning([
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
		title_a, OfferLogicUtils.format_choice_effects(pick_a.get("effects", {})),
		title_b, OfferLogicUtils.format_choice_effects(pick_b.get("effects", {})),
		title_c, OfferLogicUtils.format_choice_effects(pick_c.get("effects", {}))
	]
	base_text += OfferLogicUtils.build_runway_warning([
		pick_a.get("effects", {}),
		pick_b.get("effects", {}),
		pick_c.get("effects", {}),
	])
	return base_text

static func build_publisher_dialog_text(topic: String, grade: String, summary: String, option_a: Dictionary, option_b: Dictionary, option_c: Dictionary) -> String:
	var stance_a: String = _get_publisher_label(String(option_a.get("label", "Stance A")))
	var stance_b: String = _get_publisher_label(String(option_b.get("label", "Stance B")))
	var stance_c: String = _get_publisher_label(String(option_c.get("label", "Stance C")))
	var base_text: String = "[b]%s[/b]\n%s %s\n%s %s\n\n%s\n\nA) %s: %s\nB) %s: %s\nC) %s: %s" % [
		_S.get_string("publisher", "memorandum_header"),
		_S.get_string("publisher", "case_reference_label"),
		_get_publisher_topic(topic),
		_S.get_string("publisher", "assessment_label"),
		_get_publisher_grade(grade),
		_get_publisher_summary(summary),
		stance_a, _format_publisher_effects(option_a.get("effects", {})),
		stance_b, _format_publisher_effects(option_b.get("effects", {})),
		stance_c, _format_publisher_effects(option_c.get("effects", {})),
	]
	base_text += _build_publisher_runway_warning([
		option_a.get("effects", {}),
		option_b.get("effects", {}),
		option_c.get("effects", {}),
	])
	return base_text

static func _build_publisher_ultimatum_text(description: String, choice_a: Dictionary, choice_b: Dictionary) -> String:
	var label_a: String = _get_publisher_label(String(choice_a.get("label", "Choice A")))
	var label_b: String = _get_publisher_label(String(choice_b.get("label", "Choice B")))
	var base_text: String = "[b]%s[/b]\n\n%s\n\nA) %s: %s\nB) %s: %s" % [
		_S.get_string("publisher", "ultimatum_header"),
		_get_publisher_summary(description),
		label_a, _format_publisher_effects(choice_a.get("effects", {})),
		label_b, _format_publisher_effects(choice_b.get("effects", {})),
	]
	base_text += _build_publisher_runway_warning([
		choice_a.get("effects", {}),
		choice_b.get("effects", {}),
	])
	return base_text

static func _get_publisher_topic(topic: String) -> String:
	return String(_S.get_dict("publisher", "topics").get(topic, topic))

static func _get_publisher_grade(grade: String) -> String:
	return String(_S.get_dict("publisher", "grades").get(grade, grade))

static func _get_publisher_summary(summary: String) -> String:
	return String(_S.get_dict("publisher", "summaries").get(summary, summary))

static func _get_publisher_label(label: String) -> String:
	return String(_S.get_dict("publisher", "labels").get(label, label))

static func _format_publisher_effects(effects: Variant) -> String:
	if effects is not Dictionary:
		return _S.get_string("publisher", "no_effect")
	var effect_dict: Dictionary = effects
	if effect_dict.is_empty():
		return _S.get_string("publisher", "no_effect")

	var ordered_keys: PackedStringArray = PackedStringArray(["ambition", "instability", "soul", "runway_days"])
	var parts: PackedStringArray = []
	var effect_names: Dictionary = _S.get_dict("publisher", "effect_names")

	for key in ordered_keys:
		if not effect_dict.has(key):
			continue
		var delta: int = int(effect_dict.get(key, 0))
		var effect_name: String = String(effect_names.get(key, key.capitalize()))
		if key == "runway_days" and delta < 0:
			parts.append("%s %+d %s" % [effect_name, delta, _S.get_string("publisher", "budget_impact_note")])
		else:
			parts.append("%s %+d" % [effect_name, delta])

	for raw_key in effect_dict.keys():
		var extra_key: String = String(raw_key)
		if ordered_keys.has(extra_key):
			continue
		parts.append("%s %+d" % [extra_key.capitalize(), int(effect_dict.get(extra_key, 0))])

	if parts.is_empty():
		return _S.get_string("publisher", "no_effect")
	return ", ".join(parts)

static func _build_publisher_runway_warning(effect_sets: Array) -> String:
	var worst_delta: int = 0
	for item in effect_sets:
		if item is Dictionary:
			var effects: Dictionary = item
			worst_delta = mini(worst_delta, int(effects.get("runway_days", 0)))
	if worst_delta >= 0:
		return ""
	return _S.get_string("publisher", "runway_warning") % worst_delta
