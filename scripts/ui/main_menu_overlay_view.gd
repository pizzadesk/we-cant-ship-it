extends CanvasLayer
class_name MainMenuOverlayView

@onready var _start_run_button: Button = %StartRunButton
@onready var _reset_game_button: Button = %ResetGameButton
@onready var _menu_subtitle: Label = %MenuSubtitle
@onready var _menu_hint: Label = %MenuHint

func get_start_run_button() -> Button:
	return _start_run_button

func get_reset_game_button() -> Button:
	return _reset_game_button

func get_menu_subtitle() -> Label:
	return _menu_subtitle

func get_corruptible_text_nodes() -> Array[Control]:
	return [_menu_hint]
