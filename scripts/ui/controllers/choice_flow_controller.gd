extends RefCounted
class_name ChoiceFlowController

const DialogSetupUtils = preload("res://scripts/ui/dialog_setup_utils.gd")
const OfferPresentation = preload("res://scripts/ui/offer_presentation.gd")
const _S = preload("res://scripts/ui/ui_strings.gd")

var _game_state: Node = null
var _dilemma_dialog: ConfirmationDialog = null
var _draft_dialog: ConfirmationDialog = null
var _draft_pick_c_button: Button = null
var _dilemma_dialog_size: Vector2i = Vector2i.ZERO
var _draft_dialog_size: Vector2i = Vector2i.ZERO

var _choice_context: String = ""
var _choice_base_title: String = ""
var _choice_base_text: String = ""
var _dilemma_choice_labels: Array[String] = []
var _draft_pick_titles: Array[String] = []

func setup(
	game_state: Node,
	dilemma_dialog: ConfirmationDialog,
	draft_dialog: ConfirmationDialog,
	draft_pick_c_button: Button,
	dilemma_dialog_size: Vector2i,
	draft_dialog_size: Vector2i,
) -> void:
	_game_state = game_state
	_dilemma_dialog = dilemma_dialog
	_draft_dialog = draft_dialog
	_draft_pick_c_button = draft_pick_c_button
	_dilemma_dialog_size = dilemma_dialog_size
	_draft_dialog_size = draft_dialog_size

func clear() -> void:
	_stop_choice_context()

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
	_dilemma_dialog.title = OfferPresentation.format_dilemma_title(payload.title)
	var cards: Array[Dictionary] = [
		{
			"title": OfferPresentation.format_dilemma_choice_label(payload.title, choice_a_label),
			"effects": choice_a.get("effects", {}),
			"on_pick": func(): _dilemma_dialog.get_ok_button().pressed.emit(),
		},
		{
			"title": OfferPresentation.format_dilemma_choice_label(payload.title, choice_b_label),
			"effects": choice_b.get("effects", {}),
			"on_pick": func(): _dilemma_dialog.get_cancel_button().pressed.emit(),
		},
	]
	_dilemma_choice_labels = [choice_a_label, choice_b_label]
	_start_choice_context("dilemma", payload.title, payload.description)
	DialogSetupUtils.inject_pick_cards(_dilemma_dialog, payload.description, cards)
	_dilemma_dialog.popup_centered(_dilemma_dialog_size)

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
	_draft_dialog.title = payload.title
	if _draft_pick_c_button != null:
		_draft_pick_c_button.visible = false
	var cards: Array[Dictionary] = [
		{
			"title": pick_a_title,
			"effects": pick_a.get("effects", {}),
			"on_pick": func(): _draft_dialog.get_ok_button().pressed.emit(),
		},
		{
			"title": pick_b_title,
			"effects": pick_b.get("effects", {}),
			"on_pick": func(): _draft_dialog.get_cancel_button().pressed.emit(),
		},
		{
			"title": pick_c_title,
			"effects": pick_c.get("effects", {}),
			"on_pick": func():
				_draft_dialog.hide()
				_draft_dialog.custom_action.emit(StringName("pick_c")),
		},
	]
	_draft_pick_titles = [pick_a_title, pick_b_title, pick_c_title]
	_start_choice_context("draft", payload.title, payload.description)
	DialogSetupUtils.inject_pick_cards(_draft_dialog, payload.description, cards)
	_draft_dialog.popup_centered(_draft_dialog_size)

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

func on_draft_custom_action(action: StringName, append_log: Callable) -> void:
	if String(action) != "pick_c":
		return
	var log_message: String = _S.get_string("log_messages", "draft_pick") % [
		_get_indexed_text(_draft_pick_titles, 2, "Pick 3"),
		_choice_base_title,
	]
	if OfferPresentation.apply_choice(_game_state, &"apply_draft_pick", 2):
		append_log.call(log_message)
	_draft_dialog.hide()
	_stop_choice_context()

func _start_choice_context(context: String, title: String, body_text: String) -> void:
	_choice_context = context
	_choice_base_title = title
	_choice_base_text = body_text
	_update_choice_dialog_copy()

func _stop_choice_context() -> void:
	_choice_context = ""
	_choice_base_title = ""
	_choice_base_text = ""
	_dilemma_choice_labels.clear()
	_draft_pick_titles.clear()

func _get_indexed_text(values: Array[String], index: int, fallback: String) -> String:
	if index >= 0 and index < values.size():
		return values[index]
	return fallback

func _update_choice_dialog_copy() -> void:
	match _choice_context:
		"draft":
			_draft_dialog.title = _choice_base_title
			_draft_dialog.dialog_text = _choice_base_text
		"dilemma":
			_dilemma_dialog.title = _choice_base_title
			_dilemma_dialog.dialog_text = _choice_base_text