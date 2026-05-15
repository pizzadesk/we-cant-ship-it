extends RefCounted
class_name PostShipFlowController

const CyclePresentation = preload("res://scripts/ui/presenters/cycle_presentation.gd")
const ConfirmOverlay = preload("res://scripts/ui/overlays/confirm_overlay.gd")

const GAP_CONFIRM_DELAY    := 0.2
const REVIEW_CLOSE_DELAY   := 0.25
const PostShipPresentation = preload("res://scripts/ui/presenters/post_ship_presentation.gd")
const ReviewPresentation = preload("res://scripts/ui/presenters/review_presentation.gd")
const _S = preload("res://scripts/ui/ui_strings.gd")

var _owner: Node = null
var _game_state: Node = null
var _review_dialog: EventOverlay = null
var _review_content: RichTextLabel = null
var _gap_visualizer_dialog: EventOverlay = null
var _gap_visualizer_content: RichTextLabel = null
var _jank_discovery_dialog: EventOverlay = null
var _jank_discovery_content: RichTextLabel = null
var _cycle_legacy_dialog: EventOverlay = null
var _cycle_legacy_content: RichTextLabel = null
var _end_run_overlay: ConfirmOverlay = null
var _ship_summary_overlay: EventOverlay = null
var _run_ended: bool = false
var _on_ship_run_ended: Callable
var _update_card_unlock_progress: Callable

var _current_ship_results: Dictionary = {}
var _post_ship_sequence: Array[String] = []

func setup(
	owner: Node,
	game_state: Node,
	review_dialog: EventOverlay,
	review_content: RichTextLabel,
	gap_visualizer_dialog: EventOverlay,
	gap_visualizer_content: RichTextLabel,
	jank_discovery_dialog: EventOverlay,
	jank_discovery_content: RichTextLabel,
	cycle_legacy_dialog: EventOverlay,
	cycle_legacy_content: RichTextLabel,
	end_run_overlay: ConfirmOverlay,
	ship_summary_overlay: EventOverlay,
	ship_confirmed_cb: Callable,
	ship_canceled_cb: Callable,
	on_ship_run_ended: Callable,
	update_card_unlock_progress: Callable,
) -> void:
	_owner = owner
	_game_state = game_state
	_review_dialog = review_dialog
	_review_content = review_content
	_gap_visualizer_dialog = gap_visualizer_dialog
	_gap_visualizer_content = gap_visualizer_content
	_jank_discovery_dialog = jank_discovery_dialog
	_jank_discovery_content = jank_discovery_content
	_cycle_legacy_dialog = cycle_legacy_dialog
	_cycle_legacy_content = cycle_legacy_content
	_end_run_overlay = end_run_overlay
	_ship_summary_overlay = ship_summary_overlay
	_on_ship_run_ended = on_ship_run_ended
	_update_card_unlock_progress = update_card_unlock_progress
	if _ship_summary_overlay != null:
		_ship_summary_overlay.set_ok_text(_S.get_string("buttons", "ship_summary_ok"))
		_ship_summary_overlay.show_cancel_button(_S.get_string("buttons", "ship_summary_cancel"))
		if not _ship_summary_overlay.confirmed.is_connected(ship_confirmed_cb):
			_ship_summary_overlay.confirmed.connect(ship_confirmed_cb)
		if not _ship_summary_overlay.canceled.is_connected(ship_canceled_cb):
			_ship_summary_overlay.canceled.connect(ship_canceled_cb)
	if _review_dialog != null and not _review_dialog.confirmed.is_connected(_on_review_dialog_closed_internal):
		_review_dialog.confirmed.connect(_on_review_dialog_closed_internal)
	if _jank_discovery_dialog != null and not _jank_discovery_dialog.confirmed.is_connected(on_jank_discovery_confirmed):
		_jank_discovery_dialog.confirmed.connect(on_jank_discovery_confirmed)
	if _gap_visualizer_dialog != null:
		if not _gap_visualizer_dialog.confirmed.is_connected(on_gap_visualizer_confirmed):
			_gap_visualizer_dialog.confirmed.connect(on_gap_visualizer_confirmed)
		if not _gap_visualizer_dialog.custom_action.is_connected(_on_gap_visualizer_skip):
			_gap_visualizer_dialog.custom_action.connect(_on_gap_visualizer_skip)
	if _cycle_legacy_dialog != null and not _cycle_legacy_dialog.confirmed.is_connected(on_cycle_legacy_confirmed):
		_cycle_legacy_dialog.confirmed.connect(on_cycle_legacy_confirmed)
	if GameEvents != null and not GameEvents.reviews_generated.is_connected(_on_reviews_generated_internal):
		GameEvents.reviews_generated.connect(_on_reviews_generated_internal)

func is_run_ended() -> bool:
	return _run_ended

func clear() -> void:
	_current_ship_results.clear()
	_post_ship_sequence.clear()
	_run_ended = false

func show_ship_summary() -> void:
	if _ship_summary_overlay == null or _game_state == null:
		return
	var predicted_score: float = _game_state.calculate_predicted_score()
	var content: String = PostShipPresentation.build_ship_summary_text(_game_state, predicted_score)
	if _ship_summary_overlay.content != null:
		_ship_summary_overlay.content.text = content
		_ship_summary_overlay.content.scroll_to_line(0)
	_ship_summary_overlay.title = _S.get_string("popups", "ship_summary_title")
	_ship_summary_overlay.popup_centered()

func on_ship_confirmed() -> void:
	if _game_state != null:
		_run_ended = true
		if _on_ship_run_ended.is_valid():
			_on_ship_run_ended.call()
		_game_state.ship_it()

func on_ship_canceled() -> void:
	pass

func on_jank_discovery_confirmed() -> void:
	advance_sequence()

func on_gap_visualizer_confirmed() -> void:
	await _owner.get_tree().create_timer(GAP_CONFIRM_DELAY).timeout
	advance_sequence()

func on_cycle_legacy_confirmed() -> void:
	advance_sequence()

func advance_sequence() -> void:
	if _post_ship_sequence.is_empty():
		return
	var next_step: String = _post_ship_sequence.pop_front()
	match next_step:
		"gap":
			_show_gap_visualizer_dialog()
		"jank":
			_show_jank_discovery_dialog()
		"legacy":
			_show_cycle_legacy_dialog()
		"end":
			_show_end_run_overlay()

func _on_review_dialog_closed_internal() -> void:
	await _owner.get_tree().create_timer(REVIEW_CLOSE_DELAY).timeout
	advance_sequence()

func _on_reviews_generated_internal(payload: ShipResult) -> void:
	_current_ship_results = payload.to_dictionary()
	var is_cycle_end: bool = _game_state != null and _game_state.is_cycle_complete()
	_post_ship_sequence = ["gap", "jank"]
	if is_cycle_end:
		_post_ship_sequence.append("legacy")
	_post_ship_sequence.append("end")
	var ending_label: String = String(_current_ship_results.get("ending", ""))
	if not ending_label.is_empty() and _review_dialog != null:
		_review_dialog.title = ending_label.to_upper()
	var review_text: String = ReviewPresentation.build_review_fallout_text(_current_ship_results)
	if _review_content != null:
		_review_content.text = review_text
		_review_content.visible_ratio = 0.0
		_review_content.scroll_to_line(0)
	_review_dialog.popup_centered()
	if _review_content != null and _owner != null:
		var t: Tween = _owner.create_tween()
		t.tween_property(_review_content, "visible_ratio", 1.0, 0.9)
	if _update_card_unlock_progress.is_valid():
		_update_card_unlock_progress.call()

func _on_gap_visualizer_skip(action: StringName) -> void:
	if String(action) != "skip_recap":
		return
	_gap_visualizer_dialog.hide()
	_post_ship_sequence = ["end"]
	advance_sequence()

func _show_gap_visualizer_dialog() -> void:
	if _gap_visualizer_dialog == null or _gap_visualizer_content == null:
		advance_sequence()
		return
	var ambition: int = _game_state.ambition if _game_state != null else 0
	var instability: int = _game_state.instability if _game_state != null else 0
	var soul: int = _game_state.soul if _game_state != null else 0
	var archetype: String = ""
	if _game_state != null and _game_state.has_method("get_chosen_archetype"):
		archetype = String(_game_state.get_chosen_archetype())
	var completed_run: int = _game_state.get_last_completed_run() if _game_state != null else 1
	var config: GameConfig = _game_state.get_game_config() if _game_state != null else null
	_gap_visualizer_content.text = CyclePresentation.build_gap_visualizer_text(
		_current_ship_results,
		ambition,
		instability,
		soul,
		archetype,
		config,
		completed_run
	)
	_gap_visualizer_content.visible_ratio = 0.0
	_gap_visualizer_content.scroll_to_line(0)
	var skip_meta: String = "gap_skip_button"
	if not _gap_visualizer_dialog.has_meta(skip_meta):
		var skip_btn: Button = _gap_visualizer_dialog.add_button("Enough. Start the next run.", false, "skip_recap")
		_gap_visualizer_dialog.set_meta(skip_meta, skip_btn)
	var btn: Variant = _gap_visualizer_dialog.get_meta(skip_meta)
	if btn is Button:
		(btn as Button).visible = completed_run >= 3
	_gap_visualizer_dialog.title = _S.get_string("popups", "gap_visualizer_title") if _S.has_key("popups", "gap_visualizer_title") else "Gap Visualizer"
	_gap_visualizer_dialog.popup_centered()
	if _owner != null:
		var t: Tween = _owner.create_tween()
		t.tween_property(_gap_visualizer_content, "visible_ratio", 1.0, 0.7)

func _show_jank_discovery_dialog() -> void:
	if _jank_discovery_dialog == null or _jank_discovery_content == null:
		advance_sequence()
		return
	_jank_discovery_content.text = PostShipPresentation.build_jank_discovery_text(_current_ship_results)
	_jank_discovery_content.visible_ratio = 0.0
	_jank_discovery_content.scroll_to_line(0)
	var ending_label: String = String(_current_ship_results.get("ending", ""))
	_jank_discovery_dialog.title = ending_label.to_upper() if not ending_label.is_empty() else "How The Machine Works"
	_jank_discovery_dialog.popup_centered()
	if _owner != null:
		var t: Tween = _owner.create_tween()
		t.tween_property(_jank_discovery_content, "visible_ratio", 1.0, 0.6)

func _show_cycle_legacy_dialog() -> void:
	if _cycle_legacy_dialog == null or _game_state == null:
		advance_sequence()
		return
	var cycle_state: Dictionary = _game_state.get_cycle_state()
	if _cycle_legacy_content != null:
		_cycle_legacy_content.text = CyclePresentation.build_cycle_legacy_text(cycle_state)
		_cycle_legacy_content.scroll_to_line(0)
	_cycle_legacy_dialog.title = _S.get_string("popups", "cycle_legacy_title")
	_cycle_legacy_dialog.popup_centered()

func _show_end_run_overlay() -> void:
	if not _run_ended or _end_run_overlay == null or _game_state == null:
		return
	_configure_end_run_overlay()
	_end_run_overlay.popup_centered()

func _configure_end_run_overlay() -> void:
	var completed_run: int = _game_state.get_last_completed_run()
	var is_complete: bool = _game_state.is_cycle_complete()
	_end_run_overlay.cancel_button_text = _S.get_string("buttons", "end_run_menu")
	if is_complete:
		_end_run_overlay.title = _S.get_string("popups", "end_run_title_last")
		_end_run_overlay.dialog_text = _S.get_string("popups", "end_run_text_last")
		_end_run_overlay.ok_button_text = _S.get_string("buttons", "end_run_continue_cycle")
		return
	match completed_run:
		1:
			_end_run_overlay.title = _S.get_string("popups", "end_run_title_initial")
			_end_run_overlay.dialog_text = _S.get_string("popups", "end_run_text_initial")
			_end_run_overlay.ok_button_text = _S.get_string("buttons", "end_run_continue_second")
		2:
			_end_run_overlay.title = _S.get_string("popups", "end_run_title_second")
			_end_run_overlay.dialog_text = _S.get_string("popups", "end_run_text_second")
			_end_run_overlay.ok_button_text = _S.get_string("buttons", "end_run_continue_third")
		3:
			_end_run_overlay.title = _S.get_string("popups", "end_run_title_third")
			_end_run_overlay.dialog_text = _S.get_string("popups", "end_run_text_third")
			_end_run_overlay.ok_button_text = _S.get_string("buttons", "end_run_continue_last")
		_:
			_end_run_overlay.title = _S.get_string("popups", "end_run_title_default")
			_end_run_overlay.dialog_text = _S.get_string("popups", "end_run_text_default")
			_end_run_overlay.ok_button_text = _S.get_string("buttons", "end_run_continue_default")
