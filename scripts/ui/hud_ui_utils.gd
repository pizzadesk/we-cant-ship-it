const _S = preload("res://scripts/ui/ui_strings.gd")

static func create_card_unlock_progress_label(left_column: Control) -> Label:
	var label: Label = Label.new()
	label.name = "CardUnlockProgress"
	label.text = _S.get_string("card_ui", "deck_loading")
	label.add_theme_color_override("font_color", Color(0.85, 0.95, 0.72, 0.9))
	label.add_theme_font_size_override("font_size", 13)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	label.offset_left = 28.0
	label.offset_bottom = -284.0
	label.size = Vector2(200.0, 20.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	left_column.add_child(label)
	return label

static func update_action_tooltips(fix_bugs_button: Button, dev_log_button: Button, ship_button: Button, runway_days: int, instability: int, soul: int = 0) -> void:
	if runway_days <= 0:
		fix_bugs_button.tooltip_text = _S.get_string("tooltips", "fix_bugs_depleted")
		dev_log_button.tooltip_text = _S.get_string("tooltips", "dev_log_depleted")
	elif soul <= 6:
		# GDD: tooltip shifts at Soul ≤ 6 to signal exhaustion without explaining the trap.
		fix_bugs_button.tooltip_text = _S.get_string("tooltips", "fix_bugs_exhausted")
		dev_log_button.tooltip_text = _S.get_string("tooltips", "dev_log_active")
	else:
		fix_bugs_button.tooltip_text = _S.get_string("tooltips", "fix_bugs_active")
		dev_log_button.tooltip_text = _S.get_string("tooltips", "dev_log_active")

	if instability >= 70:
		ship_button.tooltip_text = _S.get_string("tooltips", "ship_overloaded")
	elif instability <= 25:
		ship_button.tooltip_text = _S.get_string("tooltips", "ship_underloaded")
	else:
		ship_button.tooltip_text = _S.get_string("tooltips", "ship_default")

static func create_stat_gauges(
	ambition_block: VBoxContainer,
	instability_block: VBoxContainer,
	runway_block: VBoxContainer,
	soul_block: VBoxContainer
) -> StatGaugeRefs:
	var refs: StatGaugeRefs = StatGaugeRefs.new()
	refs.ambition = _create_stat_gauge(Color(0.2, 0.8, 0.3), 100, ambition_block)
	_create_instability_gauge_with_markers(instability_block, refs)
	refs.runway = _create_stat_gauge(Color(0.3, 0.6, 1.0), 21, runway_block)
	refs.soul = _create_stat_gauge(Color(1.0, 0.6, 0.8), 20, soul_block)
	return refs

static func _create_stat_gauge(color: Color, max_value: int, parent: VBoxContainer) -> ProgressBar:
	var gauge: ProgressBar = ProgressBar.new()
	gauge.max_value = float(max_value)
	gauge.value = 0.0
	gauge.custom_minimum_size = Vector2(60.0, 8.0)
	gauge.modulate = color
	gauge.show_percentage = false
	parent.add_child(gauge)
	return gauge

static func _create_instability_gauge_with_markers(instability_block: VBoxContainer, refs: StatGaugeRefs) -> void:
	var container: Control = Control.new()
	container.custom_minimum_size = Vector2(60.0, 10.0)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	instability_block.add_child(container)

	var gauge: ProgressBar = ProgressBar.new()
	gauge.max_value = 100.0
	gauge.value = 0.0
	gauge.show_percentage = false
	gauge.modulate = Color(1.0, 0.3, 0.2)
	gauge.set_anchors_preset(Control.PRESET_FULL_RECT)
	gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(gauge)
	refs.instability = gauge

	var floor_marker: ColorRect = ColorRect.new()
	floor_marker.color = Color(0.35, 0.88, 0.45, 0.90)
	floor_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	floor_marker.anchor_left = 0.15
	floor_marker.anchor_right = 0.15
	floor_marker.anchor_top = 0.0
	floor_marker.anchor_bottom = 1.0
	floor_marker.offset_left = 0.0
	floor_marker.offset_right = 2.0
	floor_marker.offset_top = 0.0
	floor_marker.offset_bottom = 0.0
	floor_marker.visible = false
	container.add_child(floor_marker)
	refs.goldilocks_floor_marker = floor_marker

	var ceiling_marker: ColorRect = ColorRect.new()
	ceiling_marker.color = Color(0.92, 0.22, 0.18, 0.90)
	ceiling_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ceiling_marker.anchor_left = 0.50
	ceiling_marker.anchor_right = 0.50
	ceiling_marker.anchor_top = 0.0
	ceiling_marker.anchor_bottom = 1.0
	ceiling_marker.offset_left = 0.0
	ceiling_marker.offset_right = 2.0
	ceiling_marker.offset_top = 0.0
	ceiling_marker.offset_bottom = 0.0
	ceiling_marker.visible = false
	container.add_child(ceiling_marker)
	refs.goldilocks_ceiling_marker = ceiling_marker
