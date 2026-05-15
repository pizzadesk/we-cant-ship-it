extends Control
class_name EventOverlay

signal confirmed
signal canceled
signal custom_action(action_name: StringName)

var title: String = "":
	set(v):
		title = v
		if _title_label != null:
			_title_label.text = v

@onready var _title_label: Label = %TitleLabel
@onready var _extra_row: HBoxContainer = %ExtraRow
@onready var _ok_button: Button = %OkButton
@onready var _cancel_button: Button = %CancelButton

var content: RichTextLabel = null

func _ready() -> void:
	visible = false
	content = %Content
	_title_label.text = title
	_ok_button.pressed.connect(_on_confirmed)
	_cancel_button.visible = false
	_cancel_button.pressed.connect(_on_canceled)

func popup_centered(_size: Vector2i = Vector2i.ZERO) -> void:
	visible = true

func set_ok_text(text: String) -> void:
	_ok_button.text = text

func show_cancel_button(text: String) -> void:
	_cancel_button.text = text
	_cancel_button.visible = true

func add_button(text: String, _right: bool, action: StringName) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 16)
	var captured: StringName = action
	btn.pressed.connect(func(): custom_action.emit(captured))
	_extra_row.add_child(btn)
	return btn

func _on_confirmed() -> void:
	visible = false
	confirmed.emit()

func _on_canceled() -> void:
	visible = false
	canceled.emit()
