extends CanvasLayer
class_name MainMenuOverlayView

@onready var _start_run_button: Button = %StartRunButton
@onready var _reset_game_button: Button = %ResetGameButton
@onready var _menu_subtitle: Label = %MenuSubtitle
@onready var _menu_hint: Label = %MenuHint
@onready var _cycle_track: HBoxContainer = %CycleTrack

func get_start_run_button() -> Button:
	return _start_run_button

func get_reset_game_button() -> Button:
	return _reset_game_button

func get_menu_subtitle() -> Label:
	return _menu_subtitle

func get_cycle_track() -> HBoxContainer:
	return _cycle_track

func populate_cycle_track(pills: Array[Dictionary]) -> void:
	for child in _cycle_track.get_children():
		child.queue_free()
	var first: bool = true
	for pill_data: Dictionary in pills:
		if not first:
			var sep := Label.new()
			sep.text = "—"
			sep.add_theme_font_size_override("font_size", 13)
			sep.add_theme_color_override("font_color", Color(0.200, 0.380, 0.200, 1.0))
			_cycle_track.add_child(sep)
		first = false
		var pill := Label.new()
		pill.text = pill_data["label"]
		var state: String = pill_data.get("state", "future")
		match state:
			"done":
				pill.add_theme_font_size_override("font_size", 13)
				pill.add_theme_color_override("font_color", Color(0.400, 0.950, 0.400, 1.0))
			"current":
				pill.add_theme_font_size_override("font_size", 14)
				pill.add_theme_color_override("font_color", Color(0.98, 0.84, 0.50, 1.0))
			_:
				pill.add_theme_font_size_override("font_size", 13)
				pill.add_theme_color_override("font_color", Color(0.250, 0.400, 0.250, 1.0))
		_cycle_track.add_child(pill)

func update_for_run(run_num: int) -> void:
	_start_run_button.text = "START RUN %d OF 4" % run_num
	_reset_game_button.visible = run_num > 1
	_reset_game_button.add_theme_color_override("font_color", Color(0.75, 0.45, 0.45))

func get_corruptible_text_nodes() -> Array[Control]:
	return [_menu_hint]
