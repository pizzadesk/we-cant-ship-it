static func setup_synergy_toast(owner: Node) -> PanelContainer:
	var toast: PanelContainer = PanelContainer.new()
	toast.name = "SynergyToast"
	toast.modulate = Color(1.0, 1.0, 1.0, 0.0)
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.anchor_left = 0.5
	toast.anchor_right = 0.5
	toast.anchor_top = 0.0
	toast.anchor_bottom = 0.0
	toast.offset_left = -280.0
	toast.offset_right = 280.0
	toast.offset_top = 18.0
	toast.custom_minimum_size = Vector2(560.0, 0.0)

	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.19, 0.16, 0.12, 0.96)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.95, 0.80, 0.48, 1.0)
	panel_style.corner_radius_top_left = 6
	panel_style.corner_radius_top_right = 6
	panel_style.corner_radius_bottom_left = 6
	panel_style.corner_radius_bottom_right = 6
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	panel_style.shadow_size = 18
	toast.add_theme_stylebox_override("panel", panel_style)

	var margin: MarginContainer = MarginContainer.new()
	margin.name = "ToastMargin"
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 12)

	var content: VBoxContainer = VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 4)

	var title_label: Label = Label.new()
	title_label.name = "Title"
	title_label.text = "PROSPECT FORMING"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color(0.99, 0.84, 0.52, 1.0))

	var body_label: Label = Label.new()
	body_label.name = "Body"
	body_label.text = ""
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_label.add_theme_font_size_override("font_size", 16)
	body_label.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86, 1.0))

	content.add_child(title_label)
	content.add_child(body_label)
	margin.add_child(content)
	toast.add_child(margin)
	owner.add_child(toast)
	toast.hide()
	return toast

static func show_synergy_toast(
	owner: Node,
	toast: PanelContainer,
	existing_timer: Timer,
	title: String,
	body: String,
	stage: String,
	soul_delta: int,
	synergy_toast_duration: float,
	synergy_toast_fade_in: float,
	on_timeout: Callable
) -> Timer:
	if toast == null:
		return existing_timer

	var content: VBoxContainer = toast.get_node_or_null("ToastMargin/Content") as VBoxContainer
	var title_label: Label = content.get_node_or_null("Title") as Label if content != null else null
	var body_label: Label = content.get_node_or_null("Body") as Label if content != null else null
	if title_label != null:
		title_label.text = title
	if body_label != null:
		body_label.text = body

	var style: StyleBoxFlat = toast.get_theme_stylebox("panel") as StyleBoxFlat
	if style != null:
		match stage:
			"locked":
				style.bg_color = Color(0.31, 0.13, 0.08, 0.97)
				style.border_color = Color(1.0, 0.52, 0.24, 1.0)
			"prospect":
				style.bg_color = Color(0.28, 0.20, 0.08, 0.96)
				style.border_color = Color(0.98, 0.77, 0.34, 1.0)
			_:
				style.bg_color = Color(0.19, 0.16, 0.12, 0.96)
				style.border_color = Color(0.95, 0.80, 0.48, 1.0)
	if title_label != null:
		if stage == "locked":
			title_label.add_theme_font_size_override("font_size", 20)
			title_label.add_theme_color_override("font_color", Color(1.0, 0.69, 0.40, 1.0))
		elif stage == "prospect":
			title_label.add_theme_font_size_override("font_size", 24)
			title_label.add_theme_color_override("font_color", Color(0.99, 0.84, 0.52, 1.0))
		else:
			title_label.add_theme_font_size_override("font_size", 18)
			title_label.add_theme_color_override("font_color", Color(0.99, 0.84, 0.52, 1.0))
	if body_label != null:
		body_label.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86, 1.0))
		body_label.add_theme_font_size_override("font_size", 16 if stage == "locked" else 15)
		if soul_delta > 0:
			body_label.text = "%s\nSoul +%d" % [body, soul_delta]

	if existing_timer != null:
		existing_timer.queue_free()

	toast.show()
	toast.modulate = Color(1.0, 1.0, 1.0, 0.0)
	toast.scale = Vector2(0.94, 0.94)
	toast.pivot_offset = Vector2(toast.size.x * 0.5, 0.0)

	var fade_in_tween: Tween = owner.create_tween()
	fade_in_tween.set_trans(Tween.TRANS_BACK)
	fade_in_tween.set_ease(Tween.EASE_OUT)
	fade_in_tween.tween_property(toast, "modulate", Color(1.0, 1.0, 1.0, 1.0), synergy_toast_fade_in)
	fade_in_tween.parallel().tween_property(toast, "scale", Vector2.ONE, synergy_toast_fade_in + 0.08)

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
	fade_out_tween.parallel().tween_property(toast, "scale", Vector2(0.97, 0.97), synergy_toast_fade_out)
	return fade_out_tween
