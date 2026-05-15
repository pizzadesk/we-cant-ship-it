extends RefCounted
class_name ChoiceFlowController

const ChoiceOverlay = preload("res://scripts/ui/overlays/choice_overlay.gd")
const OfferPresentation = preload("res://scripts/ui/offer_presentation.gd")
const _S = preload("res://scripts/ui/ui_strings.gd")

var _game_state: Node = null
var _choice_overlay: ChoiceOverlay = null
var _append_log: Callable

var _choice_context: String = ""
var _choice_base_title: String = ""
var _dilemma_choice_labels: Array[String] = []
var _draft_pick_titles: Array[String] = []

func setup(
	game_state: Node,
	choice_overlay: ChoiceOverlay,
	append_log: Callable,
) -> void:
	_game_state = game_state
	_choice_overlay = choice_overlay
	_append_log = append_log
	_choice_overlay.choice_made.connect(_on_overlay_choice_made)

func clear() -> void:
	_stop_choice_context()
	if _choice_overlay != null:
		_choice_overlay.close()

func on_dilemma_offered(payload: DilemmaOfferPayload, menu_active: bool, run_ended: bool) -> void:
	if menu_active or run_ended:
		return
	var choices: Array[Dictionary] = payload.choices
	if not OfferPresentation.has_valid_offer_entries(choices, 2, "label"):
		push_warning("Ignoring malformed dilemma payload")
		return
	var choice_a: Dictionary = choices[0]
	var choice_b: Dictionary = choices[1]
	var choice_a_label: String = String(choice_a.get("label", "Choice A"))
	var choice_b_label: String = String(choice_b.get("label", "Choice B"))
	var cards: Array = [
		{
			"title": OfferPresentation.format_dilemma_choice_label(payload.title, choice_a_label),
			"effects": choice_a.get("effects", {}),
		},
		{
			"title": OfferPresentation.format_dilemma_choice_label(payload.title, choice_b_label),
			"effects": choice_b.get("effects", {}),
		},
	]
	_dilemma_choice_labels = [choice_a_label, choice_b_label]
	_start_choice_context("dilemma", payload.title)
	var context_sentence: String = _get_run_context_sentence([choice_a.get("effects", {}), choice_b.get("effects", {})])
	var display_description: String = payload.description
	if not context_sentence.is_empty():
		display_description = "[color=#558855][i]%s[/i][/color]\n\n%s" % [context_sentence, payload.description]
	_choice_overlay.setup_and_show(
		OfferPresentation.format_dilemma_title(payload.title),
		display_description,
		cards
	)

func on_draft_offer(payload: DraftOfferPayload, menu_active: bool, run_ended: bool) -> void:
	if menu_active or run_ended:
		return
	var picks: Array[Dictionary] = payload.picks
	if not OfferPresentation.has_valid_offer_entries(picks, 3, "title"):
		push_warning("Ignoring malformed draft payload")
		return
	var pick_a: Dictionary = picks[0]
	var pick_b: Dictionary = picks[1]
	var pick_c: Dictionary = picks[2]
	var pick_a_title: String = String(pick_a.get("title", "Pick A"))
	var pick_b_title: String = String(pick_b.get("title", "Pick B"))
	var pick_c_title: String = String(pick_c.get("title", "Pick C"))
	var cards: Array = [
		{"title": pick_a_title, "effects": pick_a.get("effects", {})},
		{"title": pick_b_title, "effects": pick_b.get("effects", {})},
		{"title": pick_c_title, "effects": pick_c.get("effects", {})},
	]
	_draft_pick_titles = [pick_a_title, pick_b_title, pick_c_title]
	_start_choice_context("draft", payload.title)
	var draft_context: String = _get_run_context_sentence([
		pick_a.get("effects", {}), pick_b.get("effects", {}), pick_c.get("effects", {})
	])
	var draft_description: String = payload.description
	if not draft_context.is_empty():
		draft_description = "[color=#558855][i]%s[/i][/color]\n\n%s" % [draft_context, payload.description]
	_choice_overlay.setup_and_show(payload.title, draft_description, cards)

func on_dilemma_choice(choice_index: int, append_log: Callable) -> void:
	var log_message: String = _S.get_string("log_messages", "dilemma_choice") % [
		_choice_base_title,
		_get_indexed_text(_dilemma_choice_labels, choice_index, "Choice %d" % (choice_index + 1))
	]
	if OfferPresentation.apply_choice(_game_state, &"apply_dilemma_choice", choice_index):
		append_log.call(log_message)
	_stop_choice_context()

func on_draft_pick(pick_index: int, append_log: Callable) -> void:
	var log_message: String = _S.get_string("log_messages", "draft_pick") % [
		_get_indexed_text(_draft_pick_titles, pick_index, "Pick %d" % (pick_index + 1)),
		_choice_base_title,
	]
	if OfferPresentation.apply_choice(_game_state, &"apply_draft_pick", pick_index):
		append_log.call(log_message)
	_stop_choice_context()

func _on_overlay_choice_made(index: int) -> void:
	if _choice_context == "dilemma":
		on_dilemma_choice(index, _append_log)
	elif _choice_context == "draft":
		on_draft_pick(index, _append_log)

func _start_choice_context(context: String, title: String) -> void:
	_choice_context = context
	_choice_base_title = title

func _stop_choice_context() -> void:
	_choice_context = ""
	_choice_base_title = ""
	_dilemma_choice_labels.clear()
	_draft_pick_titles.clear()

func _get_indexed_text(values: Array[String], index: int, fallback: String) -> String:
	if index >= 0 and index < values.size():
		return values[index]
	return fallback

func _get_run_context_sentence(effects_list: Array) -> String:
	if _game_state == null:
		return ""
	var _cr: Variant = _game_state.get("current_run")
	var current_run: int = int(_cr) if _cr != null else 1
	if current_run <= 1:
		return ""
	var config: GameConfig = _game_state.get_game_config() as GameConfig if _game_state.has_method("get_game_config") else null
	if config == null:
		return ""
	var archetype: String = String(_game_state.get_chosen_archetype()) if _game_state.has_method("get_chosen_archetype") else ""
	var window: Array[int] = ArchetypeRules.get_goldilocks_window_for_archetype(config, archetype)
	var _inst: Variant = _game_state.get("instability")
	var instability: int = int(_inst) if _inst != null else 0
	var _sl: Variant = _game_state.get("soul")
	var soul: int = int(_sl) if _sl != null else 0
	var inst_affected: bool = false
	var soul_affected: bool = false
	for effects in effects_list:
		if effects is Dictionary:
			if int(effects.get("instability", 0)) != 0:
				inst_affected = true
			if int(effects.get("soul", 0)) != 0:
				soul_affected = true
	if instability > window[1] and inst_affected:
		return "Instability is already above the ceiling. Every point added risks the run."
	if soul <= 3 and soul_affected:
		return "Soul is critical. The studio is close to exhaustion."
	if instability < window[0] and inst_affected:
		return "Instability is below the floor. The build is too safe."
	return ""
