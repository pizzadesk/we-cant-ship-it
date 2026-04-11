extends RefCounted
class_name ChoiceFlowController

const DialogSetupUtils = preload("res://scripts/ui/dialog_setup_utils.gd")
const OfferDialogTextUtils = preload("res://scripts/ui/offer_dialog_text_utils.gd")
const OfferLogicUtils = preload("res://scripts/ui/offer_logic_utils.gd")
const _S = preload("res://scripts/ui/ui_strings.gd")

var _game_state: Node = null
var _dilemma_dialog: ConfirmationDialog = null
var _draft_dialog: ConfirmationDialog = null
var _draft_pick_c_button: Button = null
var _dilemma_dialog_size: Vector2i = Vector2i.ZERO
var _draft_dialog_size: Vector2i = Vector2i.ZERO

var _pending_dilemma: Dictionary = {}
var _pending_draft_offer: Dictionary = {}
var _choice_context: String = ""
var _choice_base_title: String = ""
var _choice_base_text: String = ""

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
	_pending_dilemma.clear()
	_pending_draft_offer.clear()
	_stop_choice_context()

func on_dilemma_offered(payload: DilemmaOfferPayload, menu_active: bool, run_ended: bool) -> void:
	if menu_active or run_ended:
		return
	_pending_dilemma = payload.to_dictionary()
	var choices: Array[Dictionary] = payload.choices
	if not OfferLogicUtils.has_valid_offer_entries(choices, 2, "label"):
		push_warning("Ignoring malformed dilemma payload")
		return
	var choice_a: Dictionary = choices[0]
	var choice_b: Dictionary = choices[1]
	_dilemma_dialog.title = OfferDialogTextUtils.format_dilemma_title(payload.title)
	var cards: Array[Dictionary] = [
		{
			"title": OfferDialogTextUtils.format_dilemma_choice_label(payload.title, String(choice_a.get("label", "Choice A"))),
			"effects": choice_a.get("effects", {}),
			"on_pick": func(): _dilemma_dialog.get_ok_button().pressed.emit(),
		},
		{
			"title": OfferDialogTextUtils.format_dilemma_choice_label(payload.title, String(choice_b.get("label", "Choice B"))),
			"effects": choice_b.get("effects", {}),
			"on_pick": func(): _dilemma_dialog.get_cancel_button().pressed.emit(),
		},
	]
	_start_choice_context("dilemma", payload.title, payload.description)
	DialogSetupUtils.inject_pick_cards(_dilemma_dialog, payload.description, cards)
	_dilemma_dialog.popup_centered(_dilemma_dialog_size)

func on_draft_offer(payload: DraftOfferPayload, menu_active: bool, run_ended: bool) -> void:
	if menu_active or run_ended:
		return
	_pending_draft_offer = payload.to_dictionary()
	var picks: Array[Dictionary] = payload.picks
	if not OfferLogicUtils.has_valid_offer_entries(picks, 3, "title"):
		push_warning("Ignoring malformed draft payload")
		return
	var pick_a: Dictionary = picks[0]
	var pick_b: Dictionary = picks[1]
	var pick_c: Dictionary = picks[2]
	_draft_dialog.title = payload.title
	if _draft_pick_c_button != null:
		_draft_pick_c_button.visible = false
	var cards: Array[Dictionary] = [
		{
			"title": String(pick_a.get("title", "Pick A")),
			"effects": pick_a.get("effects", {}),
			"on_pick": func(): _draft_dialog.get_ok_button().pressed.emit(),
		},
		{
			"title": String(pick_b.get("title", "Pick B")),
			"effects": pick_b.get("effects", {}),
			"on_pick": func(): _draft_dialog.get_cancel_button().pressed.emit(),
		},
		{
			"title": String(pick_c.get("title", "Pick C")),
			"effects": pick_c.get("effects", {}),
			"on_pick": func():
				_draft_dialog.hide()
				_draft_dialog.custom_action.emit(StringName("pick_c")),
		},
	]
	_start_choice_context("draft", payload.title, payload.description)
	DialogSetupUtils.inject_pick_cards(_draft_dialog, payload.description, cards)
	_draft_dialog.popup_centered(_draft_dialog_size)

func on_dilemma_choice(choice_index: int, log_key: String, append_log: Callable) -> void:
	_stop_choice_context()
	if OfferLogicUtils.apply_choice_if_pending(_game_state, _pending_dilemma, &"apply_dilemma_choice", choice_index):
		append_log.call(_S.get_string("log_messages", log_key))
	_pending_dilemma.clear()

func on_draft_pick(pick_index: int, log_key: String, append_log: Callable) -> void:
	_stop_choice_context()
	if OfferLogicUtils.apply_choice_if_pending(_game_state, _pending_draft_offer, &"apply_draft_pick", pick_index):
		append_log.call(_S.get_string("log_messages", log_key))
	_pending_draft_offer.clear()

func on_draft_custom_action(action: StringName, append_log: Callable) -> void:
	if String(action) != "pick_c":
		return
	_stop_choice_context()
	if OfferLogicUtils.apply_choice_if_pending(_game_state, _pending_draft_offer, &"apply_draft_pick", 2):
		append_log.call(_S.get_string("log_messages", "draft_c"))
		_pending_draft_offer.clear()
	_draft_dialog.hide()

func _start_choice_context(context: String, title: String, body_text: String) -> void:
	_choice_context = context
	_choice_base_title = title
	_choice_base_text = body_text
	_update_choice_dialog_copy()

func _stop_choice_context() -> void:
	_choice_context = ""
	_choice_base_title = ""
	_choice_base_text = ""

func _update_choice_dialog_copy() -> void:
	match _choice_context:
		"draft":
			_draft_dialog.title = _choice_base_title
			_draft_dialog.dialog_text = _choice_base_text
		"dilemma":
			_dilemma_dialog.title = _choice_base_title
			_dilemma_dialog.dialog_text = _choice_base_text