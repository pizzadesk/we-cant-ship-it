extends CardDisplayBase
class_name FeatureCardWidget

signal card_clicked(card: Resource)

var drag_origin: String = "backlog"
var _base_rotation: float = 0.0
var _hover_tween: Tween
# Drag hint icons — stored on the preview duplicate so they survive _ready() → _update_view().
var _drag_heat_icon: String = ""
var _drag_mismatch_icon: String = ""

func _ready() -> void:
	super()
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)

func _update_view() -> void:
	super._update_view()
	# Drag previews use pre-computed icons set before _ready() fires.
	# Resting backlog cards compute heat live from AppState so the indicator
	# is always current without a separate refresh signal.
	var heat_suffix: String = ""
	if not _drag_heat_icon.is_empty():
		# This is a drag preview duplicate — use the pre-calculated icon.
		heat_suffix = _drag_heat_icon
	elif feature_card is FeatureCard and drag_origin == "backlog" and AppState != null:
		var heat: int = int(AppState.get_interaction_heat(feature_card as FeatureCard, AppState.feature_board))
		var heat_icons: PackedStringArray = PackedStringArray(["", "*", "**", "***"])
		heat_suffix = heat_icons[clampi(heat, 0, 3)]
	var suffix: String = ""
	if not heat_suffix.is_empty():
		suffix += " " + heat_suffix
	if not _drag_mismatch_icon.is_empty():
		suffix += " " + _drag_mismatch_icon
	if not suffix.is_empty():
		_name_label.text += suffix

func set_drag_origin(origin: String) -> void:
	drag_origin = origin

func _get_drag_data(_at_position: Vector2) -> Variant:
	if feature_card == null:
		return null

	# Determine interaction heat level for the hint icon on the drag preview.
	var heat: int = 0
	var mismatch_level: int = 0
	if drag_origin == "backlog" and feature_card is FeatureCard and AppState != null:
		heat = int(AppState.get_interaction_heat(feature_card as FeatureCard, AppState.feature_board))
		mismatch_level = int(AppState.get_archetype_mismatch_level(feature_card as FeatureCard))

	var preview: FeatureCardWidget = duplicate() as FeatureCardWidget
	var preview_size: Vector2 = size
	if preview_size == Vector2.ZERO:
		preview_size = get_combined_minimum_size()
	preview.size_flags_horizontal = 0
	preview.size_flags_vertical = 0
	preview.custom_minimum_size = preview_size
	preview.size = preview_size
	preview.drag_origin = drag_origin
	preview.rotation_degrees = 0.0
	preview.modulate = Color(1.0, 1.0, 1.0, 0.75)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Set icons on the preview widget; _update_view() override appends them after _ready().
	if heat > 0:
		var heat_icons: PackedStringArray = PackedStringArray(["", "*", "**", "***"])
		preview._drag_heat_icon = heat_icons[clampi(heat, 0, 3)]
	if mismatch_level > 0:
		# 1=genre stretch (~), 2=wild swing (⚠), 3=alien (☠)
		var mismatch_icons: PackedStringArray = PackedStringArray(["", "~", "⚠", "☠"])
		preview._drag_mismatch_icon = mismatch_icons[clampi(mismatch_level, 0, 3)]
	set_drag_preview(preview)
	var payload: FeatureCardDragPayload = FeatureCardDragPayload.new()
	payload.card = feature_card
	payload.origin_zone = drag_origin
	return payload.to_dictionary()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if feature_card != null:
			card_clicked.emit(feature_card)
		get_tree().root.set_input_as_handled()

func _apply_janky_look() -> void:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.14 + _rng.randf_range(-0.03, 0.04), 0.11 + _rng.randf_range(-0.02, 0.03), 0.08 + _rng.randf_range(-0.02, 0.03))
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 3
	sb.border_color = Color(0.88 + _rng.randf_range(-0.06, 0.05), 0.70 + _rng.randf_range(-0.08, 0.06), 0.30 + _rng.randf_range(-0.08, 0.06))
	sb.corner_radius_top_left = 3
	sb.corner_radius_top_right = 2
	sb.corner_radius_bottom_left = 2
	sb.corner_radius_bottom_right = 4
	add_theme_stylebox_override("panel", sb)

	_name_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.79))
	_tags_label.add_theme_color_override("font_color", Color(0.79, 0.93, 0.79))
	_base_rotation = _rng.randf_range(-1.6, 1.6)
	rotation_degrees = _base_rotation

func _on_mouse_entered() -> void:
	_play_hover_anim(true)

func _on_mouse_exited() -> void:
	_play_hover_anim(false)

func _play_hover_anim(hovered: bool) -> void:
	if _hover_tween != null:
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.set_trans(Tween.TRANS_CUBIC)
	_hover_tween.set_ease(Tween.EASE_OUT)
	if hovered:
		_hover_tween.tween_property(self, "scale", Vector2(1.03, 1.03), 0.10)
		_hover_tween.parallel().tween_property(self, "rotation_degrees", _base_rotation * 0.35, 0.10)
		_hover_tween.parallel().tween_property(self, "modulate", Color(1.08, 1.08, 1.08, 1.0), 0.10)
	else:
		_hover_tween.tween_property(self, "scale", Vector2.ONE, 0.14)
		_hover_tween.parallel().tween_property(self, "rotation_degrees", _base_rotation, 0.14)
		_hover_tween.parallel().tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.14)
