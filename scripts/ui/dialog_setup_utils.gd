static func _build_pick_card(data: Dictionary) -> Control:
	var title: String = String(data.get("title", ""))
	var effects: Dictionary = data.get("effects", {})
	var on_pick: Callable = data.get("on_pick", Callable())

	var normal_style: StyleBoxFlat = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.035, 0.082, 0.035)
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = Color(0.102, 0.380, 0.102)
	normal_style.corner_radius_top_left = 6
	normal_style.corner_radius_top_right = 6
	normal_style.corner_radius_bottom_left = 6
	normal_style.corner_radius_bottom_right = 6

	var hover_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.059, 0.137, 0.059)
	hover_style.border_color = Color(1.0, 0.67, 0.26)
	hover_style.shadow_color = Color(1.0, 0.67, 0.26, 0.28)
	hover_style.shadow_size = 8

	var press_style: StyleBoxFlat = hover_style.duplicate() as StyleBoxFlat
	press_style.bg_color = Color(0.082, 0.176, 0.082)

	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", normal_style)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.mouse_entered.connect(func(): panel.add_theme_stylebox_override("panel", hover_style))
	panel.mouse_exited.connect(func(): panel.add_theme_stylebox_override("panel", normal_style))
	panel.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton:
			var mbe: InputEventMouseButton = event as InputEventMouseButton
			if mbe.button_index == MOUSE_BUTTON_LEFT:
				if mbe.pressed:
					panel.add_theme_stylebox_override("panel", press_style)
				else:
					panel.add_theme_stylebox_override("panel", hover_style)
					if on_pick.is_valid():
						on_pick.call()
	)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var inner: VBoxContainer = VBoxContainer.new()
	inner.add_theme_constant_override("separation", 7)
	inner.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(inner)

	var title_lbl: Label = Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(title_lbl)

	var card_sep: HSeparator = HSeparator.new()
	inner.add_child(card_sep)

	var effect_order: Array[String] = ["ambition", "soul", "instability", "runway_days"]
	var has_effect: bool = false
	for key: String in effect_order:
		if not effects.has(key):
			continue
		var delta: int = int(effects[key])
		if delta == 0:
			continue
		has_effect = true
		var eff_row: HBoxContainer = HBoxContainer.new()
		eff_row.add_theme_constant_override("separation", 4)
		inner.add_child(eff_row)

		var key_lbl: Label = Label.new()
		key_lbl.text = _pick_key_name(key)
		key_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		key_lbl.add_theme_font_size_override("font_size", 16)
		key_lbl.add_theme_color_override("font_color", Color(0.518, 0.784, 0.518))
		eff_row.add_child(key_lbl)

		var val_lbl: Label = Label.new()
		val_lbl.text = "%+d" % delta
		val_lbl.add_theme_font_size_override("font_size", 18)
		val_lbl.add_theme_color_override("font_color", _pick_effect_color(key, delta))
		eff_row.add_child(val_lbl)

	if not has_effect:
		var no_eff: Label = Label.new()
		no_eff.text = "No stat change"
		no_eff.add_theme_font_size_override("font_size", 15)
		no_eff.add_theme_color_override("font_color", Color(0.290, 0.478, 0.290))
		no_eff.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		inner.add_child(no_eff)

	var spacer: Control = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.add_child(spacer)

	var hint: Label = Label.new()
	hint.text = "▶  Pick this"
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.250, 0.420, 0.250))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(hint)

	return panel

static func _pick_key_name(key: String) -> String:
	match key:
		"runway_days": return "Days"
		"instability": return "Instability"
		"ambition": return "Ambition"
		"soul": return "Soul"
		_: return key.capitalize()

static func _pick_effect_color(key: String, delta: int) -> Color:
	match key:
		"instability":
			return Color(1.0, 0.45, 0.18) if delta > 0 else Color(0.400, 0.950, 0.400)
		"runway_days":
			return Color(0.92, 0.24, 0.24) if delta < 0 else Color(0.400, 0.950, 0.400)
		_:
			return Color(0.400, 0.950, 0.400) if delta > 0 else Color(0.92, 0.24, 0.24)
