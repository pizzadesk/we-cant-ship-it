extends Control
class_name ConfirmOverlay

signal confirmed
signal canceled

var title: String = "":
	set(v):
		title = v
		if _title_label != null:
			_title_label.text = v

var dialog_text: String = "":
	set(v):
		dialog_text = v
		if _body_label != null:
			_body_label.text = v

var ok_button_text: String = "OK":
	set(v):
		ok_button_text = v
		if _ok_button != null:
			_ok_button.text = v

var cancel_button_text: String = "Cancel":
	set(v):
		cancel_button_text = v
		if _cancel_button != null:
			_cancel_button.text = v

@onready var _title_label: Label = %TitleLabel
@onready var _body_label: Label = %BodyLabel
@onready var _ok_button: Button = %OkButton
@onready var _cancel_button: Button = %CancelButton

func _ready() -> void:
	visible = false
	_title_label.text = title
	_body_label.text = dialog_text
	_ok_button.text = ok_button_text
	_cancel_button.text = cancel_button_text
	_ok_button.pressed.connect(_on_ok)
	_cancel_button.pressed.connect(_on_cancel)

func popup_centered(_size: Vector2i = Vector2i.ZERO) -> void:
	visible = true

func _on_ok() -> void:
	visible = false
	confirmed.emit()

func _on_cancel() -> void:
	visible = false
	canceled.emit()
