extends CardDisplayBase
class_name FeatureCardWidget

var drag_origin: String = "backlog"
var _base_rotation: float = 0.0
var _hover_tween: Tween
@onready var _risk_label_widget: Label = $Padding/VBox/RiskLabel
# Drag hint icon — stored on the preview duplicate so it survives _ready() → _update_view().
var _drag_mismatch_icon: String = ""

func _ready() -> void:
	super()
	# SIZE_SHRINK_BEGIN (0) prevents this card from expanding beyond its content
	# height when the parent VBoxContainer receives extra space from the
	# ScrollContainer above it. The drag preview (@see _get_drag_data) already
	# does this on the duplicate; the live widget needs the same safeguard.
	# Change to Control.SIZE_FILL (1) or Control.SIZE_EXPAND_FILL (3) here if
	# you deliberately want cards to stretch to fill the available height.
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _update_view() -> void:
	super._update_view()
	# Drag previews use pre-computed icon set before _ready() fires.
	if not _drag_mismatch_icon.is_empty():
		_name_label.text += " " + _drag_mismatch_icon
	if _risk_label_widget != null:
		_risk_label_widget.text = "FIT: On-archetype"
		_risk_label_widget.add_theme_color_override("font_color", Color(0.400, 0.950, 0.400, 1.0))
	tooltip_text = ""
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	# Alien card blocked by soul gate: dim and label so the player knows before dragging.
	if drag_origin == "backlog" and feature_card is FeatureCard and AppState != null:
		var fc: FeatureCard = feature_card as FeatureCard
		var config: GameConfig = AppState.get_game_config() as GameConfig
		var mismatch_level: int = int(AppState.get_archetype_mismatch_level(fc))
		var mismatch_icons: PackedStringArray = PackedStringArray(["", "~", "⚠", "☠"])
		if mismatch_level > 0:
			_name_label.text += " " + mismatch_icons[clampi(mismatch_level, 0, 3)]
		var preview_text: String = _build_mismatch_preview_text(fc, mismatch_level, config)
		var risk_text: String = _build_risk_scan_text(fc, mismatch_level, config)
		if _risk_label_widget != null and not risk_text.is_empty():
			_risk_label_widget.text = risk_text
			_apply_risk_style(mismatch_level, fc, config)
		if not preview_text.is_empty():
			tooltip_text = preview_text
		if fc.archetype_affinity.is_empty() and not AppState.can_place_card(fc):
			modulate = Color(1.0, 0.4, 0.4, 0.6)
			if _risk_label_widget != null:
				_risk_label_widget.text = _build_risk_scan_text(fc, mismatch_level, config, true)
				_apply_risk_style(3, fc, config, true)
			if tooltip_text.is_empty():
				tooltip_text = preview_text
		elif mismatch_level == 3 and not AppState.can_place_card(fc):
			modulate = Color(1.0, 0.4, 0.4, 0.6)
			if _risk_label_widget != null:
				_risk_label_widget.text = "Out of Reach"
				_apply_risk_style(3, fc, config, true)
			if _description_label != null:
				_description_label.text = "The studio does not have the courage for this feature. Not yet."
				_description_label.visible = true

func set_drag_origin(origin: String) -> void:
	drag_origin = origin

func _get_drag_data(_at_position: Vector2) -> Variant:
	if feature_card == null:
		return null

	var mismatch_level: int = 0
	if drag_origin == "backlog" and feature_card is FeatureCard and AppState != null:
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
	if mismatch_level > 0:
		# 1=genre stretch (~), 2=wild swing (⚠), 3=alien (☠)
		var mismatch_icons: PackedStringArray = PackedStringArray(["", "~", "⚠", "☠"])
		preview._drag_mismatch_icon = mismatch_icons[clampi(mismatch_level, 0, 3)]
	set_drag_preview(preview)
	var payload: FeatureCardDragPayload = FeatureCardDragPayload.new()
	payload.card = feature_card
	payload.origin_zone = drag_origin
	return payload.to_dictionary()
func _apply_janky_look() -> void:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.035 + _rng.randf_range(-0.01, 0.020), 0.094 + _rng.randf_range(-0.015, 0.020), 0.035 + _rng.randf_range(-0.01, 0.020))
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 3
	sb.border_color = Color(0.133 + _rng.randf_range(-0.04, 0.05), 0.600 + _rng.randf_range(-0.06, 0.07), 0.133 + _rng.randf_range(-0.04, 0.05))
	sb.corner_radius_top_left = 3
	sb.corner_radius_top_right = 2
	sb.corner_radius_bottom_left = 2
	sb.corner_radius_bottom_right = 4
	add_theme_stylebox_override("panel", sb)

	_name_label.add_theme_color_override("font_color", Color(0.659, 0.910, 0.659))
	_tags_label.add_theme_color_override("font_color", Color(0.400, 0.750, 0.400))
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

func _build_mismatch_preview_text(card: FeatureCard, mismatch_level: int, config: GameConfig) -> String:
	if card == null or AppState == null:
		return ""
	match mismatch_level:
		0:
			return "On-archetype: no penalty"
		1:
			var stretch_inst: int = config.genre_stretch_instability_bonus if config != null else 2
			return "Genre stretch: +%d Inst" % stretch_inst
		2:
			var wild_inst: int = config.archetype_mismatch_instability_bonus if config != null else 4
			var wild_amb: int = config.archetype_mismatch_ambition_bonus if config != null else 2
			var wild_soul: int = config.archetype_mismatch_soul_penalty if config != null else 1
			return "Wild swing: +%d Inst, +%d Amb, -%d Soul" % [wild_inst, wild_amb, wild_soul]
		3:
			var alien_inst: int = config.alien_card_instability_bonus if config != null else 8
			var alien_amb: int = config.alien_card_ambition_bonus if config != null else 4
			var alien_soul: int = config.alien_card_soul_penalty if config != null else 3
			var soul_gate: int = config.alien_card_soul_gate if config != null else 5
			if AppState.can_place_card(card):
				return "Alien card: +%d Inst, +%d Amb, -%d Soul" % [alien_inst, alien_amb, alien_soul]
			return "Alien card: Soul %d+, +%d Inst, +%d Amb, -%d Soul" % [soul_gate, alien_inst, alien_amb, alien_soul]
		_:
			return ""

func _build_risk_scan_text(card: FeatureCard, mismatch_level: int, config: GameConfig, blocked: bool = false) -> String:
	if card == null:
		return ""
	match mismatch_level:
		0:
			return "FIT: On-archetype"
		1:
			return "~ RISK: Genre stretch"
		2:
			return "⚠ RISK: Wild swing"
		3:
			var soul_gate: int = config.alien_card_soul_gate if config != null else 5
			if blocked:
				return "☠ RISK: Alien card | Soul %d+" % soul_gate
			return "☠ RISK: Alien card"
		_:
			return ""

func _apply_risk_style(mismatch_level: int, _card: FeatureCard, _config: GameConfig, blocked: bool = false) -> void:
	if _risk_label_widget == null:
		return
	match mismatch_level:
		0:
			_risk_label_widget.add_theme_color_override("font_color", Color(0.400, 0.950, 0.400, 1.0))
		1:
			_risk_label_widget.add_theme_color_override("font_color", Color(0.96, 0.87, 0.54, 1.0))
		2:
			_risk_label_widget.add_theme_color_override("font_color", Color(1.0, 0.72, 0.42, 1.0))
		3:
			_risk_label_widget.add_theme_color_override("font_color", Color(1.0, 0.48, 0.48, 1.0) if blocked else Color(0.97, 0.62, 0.62, 1.0))
		_:
			_risk_label_widget.add_theme_color_override("font_color", Color(0.659, 0.910, 0.659, 1.0))

func apply_prospect_target_style(jank_name: String) -> void:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.16, 0.13, 0.06)
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 3
	sb.border_color = Color(0.98, 0.77, 0.34, 1.0)
	sb.corner_radius_top_left = 3
	sb.corner_radius_top_right = 3
	sb.corner_radius_bottom_left = 3
	sb.corner_radius_bottom_right = 3
	sb.shadow_color = Color(0.98, 0.65, 0.18, 0.35)
	sb.shadow_size = 6
	add_theme_stylebox_override("panel", sb)
	if _risk_label_widget != null:
		_risk_label_widget.text = "◆ PROSPECT: %s" % jank_name
		_risk_label_widget.add_theme_color_override("font_color", Color(0.98, 0.77, 0.34, 1.0))

func clear_prospect_target_style() -> void:
	remove_theme_stylebox_override("panel")
	_update_view()
