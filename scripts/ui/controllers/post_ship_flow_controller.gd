extends RefCounted
class_name PostShipFlowController

const CyclePresentation = preload("res://scripts/ui/presenters/cycle_presentation.gd")
const PostShipPresentation = preload("res://scripts/ui/presenters/post_ship_presentation.gd")
const ReviewPresentation = preload("res://scripts/ui/presenters/review_presentation.gd")
const _S = preload("res://scripts/ui/ui_strings.gd")

var _game_state: Node = null
var _review_dialog: AcceptDialog = null
var _review_content: RichTextLabel = null
var _review_dialog_size: Vector2i = Vector2i.ZERO
var _gap_visualizer_dialog: AcceptDialog = null
var _gap_visualizer_content: RichTextLabel = null
var _jank_discovery_dialog: AcceptDialog = null
var _jank_discovery_content: RichTextLabel = null
var _cycle_legacy_dialog: AcceptDialog = null
var _cycle_legacy_content: RichTextLabel = null
var _end_run_dialog: ConfirmationDialog = null
var _end_dialog_size: Vector2i = Vector2i.ZERO

var _current_ship_results: Dictionary = {}
var _post_ship_sequence: Array[String] = []

func setup(
	game_state: Node,
	review_dialog: AcceptDialog,
	review_content: RichTextLabel,
	review_dialog_size: Vector2i,
	gap_visualizer_dialog: AcceptDialog,
	gap_visualizer_content: RichTextLabel,
	jank_discovery_dialog: AcceptDialog,
	jank_discovery_content: RichTextLabel,
	cycle_legacy_dialog: AcceptDialog,
	cycle_legacy_content: RichTextLabel,
	end_run_dialog: ConfirmationDialog,
	end_dialog_size: Vector2i,
) -> void:
	_game_state = game_state
	_review_dialog = review_dialog
	_review_content = review_content
	_review_dialog_size = review_dialog_size
	_gap_visualizer_dialog = gap_visualizer_dialog
	_gap_visualizer_content = gap_visualizer_content
	_jank_discovery_dialog = jank_discovery_dialog
	_jank_discovery_content = jank_discovery_content
	_cycle_legacy_dialog = cycle_legacy_dialog
	_cycle_legacy_content = cycle_legacy_content
	_end_run_dialog = end_run_dialog
	_end_dialog_size = end_dialog_size

func clear() -> void:
	_current_ship_results.clear()
	_post_ship_sequence.clear()

func on_reviews_generated(payload: ShipResult, update_card_unlock_progress: Callable) -> void:
	_current_ship_results = payload.to_dictionary()
	var is_cycle_end: bool = _game_state != null and _game_state.is_cycle_complete()
	_post_ship_sequence = ["gap", "jank"]
	if is_cycle_end:
		_post_ship_sequence.append("legacy")
	_post_ship_sequence.append("end")

	var review_text: String = ReviewPresentation.build_review_fallout_text(_current_ship_results)
	if _review_content != null:
		_review_content.text = review_text
		_review_content.scroll_to_line(0)
	else:
		_review_dialog.dialog_text = review_text
	_review_dialog.popup_centered(_review_dialog_size)
	update_card_unlock_progress.call()

func advance_sequence(run_ended: bool) -> void:
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
			_show_end_run_dialog(run_ended)

func _show_gap_visualizer_dialog() -> void:
	if _gap_visualizer_dialog == null or _gap_visualizer_content == null:
		advance_sequence(true)
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
	_gap_visualizer_content.scroll_to_line(0)
	_gap_visualizer_dialog.popup_centered(Vector2i(700, 500))

func _show_jank_discovery_dialog() -> void:
	if _jank_discovery_dialog == null or _jank_discovery_content == null:
		advance_sequence(true)
		return
	_jank_discovery_content.text = PostShipPresentation.build_jank_discovery_text(_current_ship_results)
	_jank_discovery_content.scroll_to_line(0)
	_jank_discovery_dialog.popup_centered(Vector2i(900, 600))

func _show_cycle_legacy_dialog() -> void:
	if _cycle_legacy_dialog == null or _game_state == null:
		advance_sequence(true)
		return
	var cycle_state: Dictionary = _game_state.get_cycle_state()
	if _cycle_legacy_content != null:
		_cycle_legacy_content.text = CyclePresentation.build_cycle_legacy_text(cycle_state)
		_cycle_legacy_content.scroll_to_line(0)
	_cycle_legacy_dialog.popup_centered(_cycle_legacy_dialog.min_size)

func _show_end_run_dialog(run_ended: bool) -> void:
	if not run_ended or _end_run_dialog == null or _game_state == null:
		return
	_configure_end_run_dialog()
	_end_run_dialog.popup_centered(_end_dialog_size)

func _configure_end_run_dialog() -> void:
	var completed_run: int = _game_state.get_last_completed_run()
	var is_complete: bool = _game_state.is_cycle_complete()
	_end_run_dialog.get_cancel_button().text = _S.get_string("buttons", "end_run_menu")
	if is_complete:
		_end_run_dialog.title = _S.get_string("popups", "end_run_title_last")
		_end_run_dialog.dialog_text = _S.get_string("popups", "end_run_text_last")
		_end_run_dialog.get_ok_button().text = _S.get_string("buttons", "end_run_continue_cycle")
		return
	match completed_run:
		1:
			_end_run_dialog.title = _S.get_string("popups", "end_run_title_initial")
			_end_run_dialog.dialog_text = _S.get_string("popups", "end_run_text_initial")
			_end_run_dialog.get_ok_button().text = _S.get_string("buttons", "end_run_continue_second")
		2:
			_end_run_dialog.title = _S.get_string("popups", "end_run_title_second")
			_end_run_dialog.dialog_text = _S.get_string("popups", "end_run_text_second")
			_end_run_dialog.get_ok_button().text = _S.get_string("buttons", "end_run_continue_third")
		3:
			_end_run_dialog.title = _S.get_string("popups", "end_run_title_third")
			_end_run_dialog.dialog_text = _S.get_string("popups", "end_run_text_third")
			_end_run_dialog.get_ok_button().text = _S.get_string("buttons", "end_run_continue_last")
		_:
			_end_run_dialog.title = _S.get_string("popups", "end_run_title_default")
			_end_run_dialog.dialog_text = _S.get_string("popups", "end_run_text_default")
			_end_run_dialog.get_ok_button().text = _S.get_string("buttons", "end_run_continue_default")