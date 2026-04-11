const OfferLogicUtils = preload("res://scripts/ui/offer_logic_utils.gd")

static func format_dilemma_title(title: String) -> String:
	return title

static func format_dilemma_choice_label(_title: String, label: String) -> String:
	return label

static func build_dilemma_dialog_text(_title: String, description: String, choice_a: Dictionary, choice_b: Dictionary) -> String:
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
