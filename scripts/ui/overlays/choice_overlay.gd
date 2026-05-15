extends Control
class_name ChoiceOverlay

signal choice_made(index: int)

const DialogSetupUtils = preload("res://scripts/ui/dialog_setup_utils.gd")

@onready var _title_label: Label = %TitleLabel
@onready var _context_hint: Label = %ContextHint
@onready var _description: RichTextLabel = %Description
@onready var _cards_row: HBoxContainer = %CardsRow

func _ready() -> void:
	visible = false

func setup_and_show(title: String, description: String, cards: Array, context_hint: String = "") -> void:
	_title_label.text = title
	_description.text = description
	_context_hint.text = context_hint
	_context_hint.visible = not context_hint.is_empty()
	_rebuild_cards(cards)
	visible = true

func close() -> void:
	visible = false
	_clear_cards()

func _rebuild_cards(cards: Array) -> void:
	_clear_cards()
	for i: int in range(cards.size()):
		var card_data: Dictionary = cards[i] as Dictionary
		var captured: int = i
		var entry: Dictionary = {
			"title": card_data.get("title", "Option %d" % (i + 1)),
			"effects": card_data.get("effects", {}),
			"on_pick": func():
				choice_made.emit(captured)
				close(),
		}
		var panel: Control = DialogSetupUtils._build_pick_card(entry)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_cards_row.add_child(panel)

func _clear_cards() -> void:
	for child: Node in _cards_row.get_children():
		child.queue_free()
