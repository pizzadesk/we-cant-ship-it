static func setup_synergy_toast(owner: Node) -> PanelContainer:
	var toast: PanelContainer = PanelContainer.new()
	toast.name = "SynergyToast"
	toast.modulate = Color(1.0, 1.0, 1.0, 0.0)
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.set_anchors_preset(Control.PRESET_TOP_LEFT)
	toast.offset_left = 24.0
	toast.offset_top = 24.0
	toast.custom_minimum_size = Vector2(420.0, 0.0)

	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.22, 0.62, 0.28, 0.95)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.60, 0.95, 0.72, 1.0)
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel_style.corner_radius_bottom_right = 4
	toast.add_theme_stylebox_override("panel", panel_style)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)

	var label: Label = Label.new()
	label.text = ""
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.92, 0.98, 0.95, 1.0))

	margin.add_child(label)
	toast.add_child(margin)
	owner.add_child(toast)
	toast.hide()
	return toast

static func show_synergy_toast(
	owner: Node,
	toast: PanelContainer,
	existing_timer: Timer,
	flavor: String,
	instability_delta: int,
	soul_delta: int,
	synergy_toast_duration: float,
	synergy_toast_fade_in: float,
	on_timeout: Callable
) -> Timer:
	if toast == null:
		return existing_timer

	var toast_parts: PackedStringArray = [flavor]
	if instability_delta != 0:
		toast_parts.append("Inst %+d" % instability_delta)
	if soul_delta != 0:
		toast_parts.append("Soul %+d" % soul_delta)
	var toast_text: String = " | ".join(toast_parts)

	var label: Label = toast.get_child(0).get_child(0) as Label
	if label != null:
		label.text = toast_text

	if existing_timer != null:
		existing_timer.queue_free()

	toast.show()
	toast.modulate = Color(1.0, 1.0, 1.0, 0.0)

	var fade_in_tween: Tween = owner.create_tween()
	fade_in_tween.set_trans(Tween.TRANS_QUAD)
	fade_in_tween.set_ease(Tween.EASE_OUT)
	fade_in_tween.tween_property(toast, "modulate", Color(1.0, 1.0, 1.0, 1.0), synergy_toast_fade_in)

	var timer: Timer = Timer.new()
	timer.wait_time = synergy_toast_duration
	timer.one_shot = true
	timer.timeout.connect(on_timeout)
	owner.add_child(timer)
	timer.start()
	return timer

static func fade_out_synergy_toast(owner: Node, toast: PanelContainer, synergy_toast_fade_out: float) -> Tween:
	if toast == null:
		return null
	var fade_out_tween: Tween = owner.create_tween()
	fade_out_tween.set_trans(Tween.TRANS_QUAD)
	fade_out_tween.set_ease(Tween.EASE_IN)
	fade_out_tween.tween_property(toast, "modulate", Color(1.0, 1.0, 1.0, 0.0), synergy_toast_fade_out)
	return fade_out_tween
