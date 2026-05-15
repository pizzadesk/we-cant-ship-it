extends RefCounted
class_name MainMenuController

const CyclePresentation = preload("res://scripts/ui/presenters/cycle_presentation.gd")
const _JsonDataLoader = preload("res://scripts/data/json_data_loader.gd")
const _S = preload("res://scripts/ui/ui_strings.gd")

var _game_state: Node = null
var _main_menu_layer: CanvasLayer = null
var _view: MainMenuOverlayView = null
var _start_run_button: Button = null
var _reset_game_button: Button = null
var _menu_subtitle: Label = null
var _cycle_track: HBoxContainer = null
var _archetype_overlay: ChoiceOverlay = null
var _previously_on_overlay: EventOverlay = null
var _pending_archetypes: Array = []
var _begin_run_callback: Callable = Callable()

func setup(
	game_state: Node,
	main_menu_layer: CanvasLayer,
	start_run_button: Button,
	reset_game_button: Button,
	menu_subtitle: Label,
	cycle_track: HBoxContainer,
	archetype_overlay: ChoiceOverlay,
	previously_on_overlay: EventOverlay,
) -> void:
	_game_state = game_state
	_main_menu_layer = main_menu_layer
	_view = main_menu_layer as MainMenuOverlayView
	_start_run_button = start_run_button
	_reset_game_button = reset_game_button
	_menu_subtitle = menu_subtitle
	_cycle_track = cycle_track
	_archetype_overlay = archetype_overlay
	_previously_on_overlay = previously_on_overlay
	if _archetype_overlay != null and not _archetype_overlay.choice_made.is_connected(_on_archetype_choice):
		_archetype_overlay.choice_made.connect(_on_archetype_choice)

func show_main_menu(append_log: Callable) -> void:
	if _game_state != null and _game_state.is_cycle_complete() and _game_state.get_last_completed_run() == 0:
		_game_state.start_new_cycle()
	_main_menu_layer.visible = true
	append_log.call(_S.get_string("log_messages", "main_menu"))
	if _game_state != null and _start_run_button != null:
		var run_num: int = _game_state.current_run
		if _view != null:
			_view.update_for_run(run_num)
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
	_populate_cycle_track()

func _populate_cycle_track() -> void:
	if _view == null or _game_state == null:
		return
	var current_run: int = _game_state.current_run
	var pills: Array[Dictionary] = []
	for run_num: int in range(1, 5):
		var state: String
		var label: String
		if run_num < current_run:
			state = "done"
			label = "Run %d ✓" % run_num
		elif run_num == current_run:
			state = "current"
			label = "Run %d ►" % run_num
		else:
			state = "future"
			label = "Run %d" % run_num
		pills.append({"label": label, "state": state})
	_view.populate_cycle_track(pills)

func show_archetype_select_dialog(on_run_begin: Callable) -> void:
	if _archetype_overlay == null:
		on_run_begin.call()
		return
	_begin_run_callback = on_run_begin
	_pending_archetypes = _JsonDataLoader.load_array("res://data/archetypes.json", "archetypes")
	if _pending_archetypes.is_empty():
		_pending_archetypes = [
			{"label": "RPG", "key": "rpg", "description": "Deep systems, faction rep, narrative weight"},
			{"label": "Shooter", "key": "shooter", "description": "Kinetic action, destruction, co-op"},
			{"label": "Action-Adventure", "key": "action_adventure", "description": "Open world, exploration, physics"},
		]
	var body: String = (_S.get_string("popups", "archetype_dialog_intro") if _S.has_key("popups", "archetype_dialog_intro") else "Choose your target genre.") + "\n\n"
	for arch: Dictionary in _pending_archetypes:
		var note: String = String(arch.get("instability_note", ""))
		var hint: String = String(arch.get("dialog_hint", ""))
		var note_line: String = "\n   [color=#558855]%s[/color]" % note if not note.is_empty() else ""
		var hint_line: String = "\n   [color=#7ab87a][i]%s[/i][/color]" % hint if not hint.is_empty() else ""
		body += "[b]%s[/b] — %s%s%s\n" % [String(arch.get("label", "")), String(arch.get("description", "")), note_line, hint_line]
	var cards: Array = []
	for arch: Dictionary in _pending_archetypes:
		cards.append({"title": String(arch.get("label", "")), "effects": {}})
	_archetype_overlay.setup_and_show("Target Genre", body, cards)

func _on_archetype_choice(index: int) -> void:
	if _game_state != null:
		if index >= 0 and index < _pending_archetypes.size():
			_game_state.set_archetype(String(_pending_archetypes[index].get("key", "rpg")))
		else:
			_game_state.set_archetype("rpg")
	if _begin_run_callback.is_valid():
		_begin_run_callback.call()

func show_previously_on() -> void:
	if _previously_on_overlay == null or _game_state == null:
		return
	var cycle: Dictionary = _game_state.get_cycle_state()
	var current_run: int = int(cycle.get("current_run", 1))
	if current_run <= 1:
		return
	var prev_run: int = current_run - 1
	var run_summary: Dictionary = _game_state.get_run_summary(prev_run) if _game_state.has_method("get_run_summary") else {}
	var config: GameConfig = _game_state.get_game_config() if _game_state != null else null
	_previously_on_overlay.title = "Previously On..."
	_previously_on_overlay.content.text = CyclePresentation.build_previously_on_text(run_summary, current_run, config)
	_previously_on_overlay.content.scroll_to_line(0)
	_previously_on_overlay.popup_centered()
