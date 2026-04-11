extends RefCounted
class_name MainMenuController

const PresentationTextUtils = preload("res://scripts/ui/presentation_text_utils.gd")
const _S = preload("res://scripts/ui/ui_strings.gd")

var _game_state: Node = null
var _main_menu_layer: CanvasLayer = null
var _start_run_button: Button = null
var _reset_game_button: Button = null
var _menu_subtitle: Label = null
var _archetype_select_dialog: ConfirmationDialog = null
var _previously_on_dialog: AcceptDialog = null

func setup(
	game_state: Node,
	main_menu_layer: CanvasLayer,
	start_run_button: Button,
	reset_game_button: Button,
	menu_subtitle: Label,
	archetype_select_dialog: ConfirmationDialog,
	previously_on_dialog: AcceptDialog,
) -> void:
	_game_state = game_state
	_main_menu_layer = main_menu_layer
	_start_run_button = start_run_button
	_reset_game_button = reset_game_button
	_menu_subtitle = menu_subtitle
	_archetype_select_dialog = archetype_select_dialog
	_previously_on_dialog = previously_on_dialog

func show_main_menu(append_log: Callable) -> void:
	if _game_state != null and _game_state.is_cycle_complete() and _game_state.get_last_completed_run() == 0:
		_game_state.start_new_cycle()
	_main_menu_layer.visible = true
	append_log.call(_S.get_string("log_messages", "main_menu"))
	if _game_state != null and _start_run_button != null:
		var run_num: int = _game_state.current_run
		_start_run_button.text = "START RUN %d OF 4" % run_num
		if _reset_game_button != null:
			_reset_game_button.visible = run_num > 1
			_reset_game_button.add_theme_color_override("font_color", Color(0.75, 0.45, 0.45))
	if _menu_subtitle != null and _game_state != null:
		match _game_state.current_run:
			1:
				_menu_subtitle.text = "Five days. Find the studio voice. Learn what kind of beautiful mistake this team makes under pressure."
			2:
				_menu_subtitle.text = "First real attempt. The target is live now."
			3:
				_menu_subtitle.text = "Second real attempt. You know enough to make sharper mistakes."
			_:
				_menu_subtitle.text = "Final real attempt. Ship the Defining Game or the cycle resets."

func show_archetype_select_dialog(on_missing: Callable) -> void:
	if _archetype_select_dialog == null:
		on_missing.call()
		return
	_archetype_select_dialog.popup_centered(Vector2i(560, 360))

func on_archetype_dialog_confirmed() -> void:
	if _game_state != null:
		var key: String = _archetype_select_dialog.get_meta("ok_archetype_key", "rpg")
		_game_state.set_archetype(key)

func on_archetype_dialog_canceled() -> void:
	if _game_state != null:
		_game_state.set_archetype("rpg")

func on_archetype_dialog_custom_action(action: StringName) -> void:
	if _game_state != null:
		_game_state.set_archetype(String(action))
	_archetype_select_dialog.hide()

func show_previously_on() -> void:
	if _previously_on_dialog == null or _game_state == null:
		return
	var cycle: Dictionary = _game_state.get_cycle_state()
	var current_run: int = int(cycle.get("current_run", 1))
	if current_run <= 1:
		return
	var content_node: RichTextLabel = _previously_on_dialog.get_node_or_null("PreviouslyOnContent") as RichTextLabel
	if content_node == null:
		return
	var prev_run: int = current_run - 1
	var run_summary: Dictionary = _game_state.get_run_summary(prev_run) if _game_state.has_method("get_run_summary") else {}
	var config: GameConfig = _game_state.get_game_config() if _game_state != null else null
	content_node.text = PresentationTextUtils.build_previously_on_text(run_summary, current_run, config)
	content_node.scroll_to_line(0)
	_previously_on_dialog.popup_centered(_previously_on_dialog.min_size)