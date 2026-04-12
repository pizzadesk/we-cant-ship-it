extends PanelContainer
class_name BacklogPanelView

@onready var _backlog_title: Label = %BacklogTitle
@onready var _backlog_help: Label = %BacklogHelp
@onready var _card_list: VBoxContainer = %CardList
@onready var _card_unlock_progress_label: Label = %CardUnlockProgress
@onready var _backlog_footer: Label = %BacklogFooter

func get_panel() -> PanelContainer:
	return self

func get_card_list() -> VBoxContainer:
	return _card_list

func get_card_unlock_progress_label() -> Label:
	return _card_unlock_progress_label

func get_theme_panels() -> Array[Control]:
	return [self]

func get_corruptible_text_nodes() -> Array[Control]:
	return [_backlog_title, _backlog_help, _backlog_footer]
