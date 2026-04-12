extends PanelContainer
class_name HeaderBarView

@onready var _header_title: Label = %HeaderTitle
@onready var _header_subtitle: Label = %HeaderSubtitle
@onready var _quit_button: Button = %QuitButton

func get_panel() -> PanelContainer:
	return self

func get_quit_button() -> Button:
	return _quit_button

func get_theme_panels() -> Array[Control]:
	return [self]

func get_corruptible_text_nodes() -> Array[Control]:
	return [_header_title, _header_subtitle]
