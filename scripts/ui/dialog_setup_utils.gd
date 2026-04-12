static func setup_review_dialog_content(review_dialog: AcceptDialog, review_dialog_size: Vector2i) -> Dictionary:
	if review_dialog.has_node("ReviewScroll"):
		var existing_scroll: ScrollContainer = review_dialog.get_node("ReviewScroll") as ScrollContainer
		if existing_scroll != null and existing_scroll.has_node("ReviewContent"):
			return {
				"scroll": existing_scroll,
				"content": existing_scroll.get_node("ReviewContent") as RichTextLabel,
			}
		return {
			"scroll": existing_scroll,
			"content": null,
		}

	review_dialog.get_label().visible = false
	review_dialog.min_size = review_dialog_size

	var review_scroll: ScrollContainer = ScrollContainer.new()
	review_scroll.name = "ReviewScroll"
	review_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	review_scroll.offset_left = 16.0
	review_scroll.offset_top = 52.0
	review_scroll.offset_right = -16.0
	review_scroll.offset_bottom = -66.0
	review_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	review_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var review_content: RichTextLabel = RichTextLabel.new()
	review_content.name = "ReviewContent"
	review_content.bbcode_enabled = true
	review_content.fit_content = false
	review_content.scroll_active = false
	review_content.selection_enabled = true
	review_content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	review_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	review_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	review_content.add_theme_font_size_override("normal_font_size", 18)

	review_scroll.add_child(review_content)
	review_dialog.add_child(review_scroll)
	return {
		"scroll": review_scroll,
		"content": review_content,
	}

## Replaces a dialog's built-in text body + action buttons with a row of
## card-style click targets. Each entry in |cards| must have:
##   title:   String  — large heading on the card
##   effects: Dictionary — {stat_key: int_delta}  (may be empty)
##   on_pick: Callable — called when the player clicks the card
## description is shown above the cards as context; may be empty.
static func inject_pick_cards(dialog: AcceptDialog, description: String, cards: Array[Dictionary]) -> void:
	const PANEL_NAME: String = "PickCardsPanel"
	var old: Node = dialog.get_node_or_null(PANEL_NAME)
	if old != null:
		dialog.remove_child(old)
		old.queue_free()

	dialog.get_label().visible = false
	dialog.get_ok_button().visible = false
	var ok_parent: Node = dialog.get_ok_button().get_parent()
	if ok_parent != null and ok_parent != dialog:
		(ok_parent as Control).visible = false
	if dialog is ConfirmationDialog:
		(dialog as ConfirmationDialog).get_cancel_button().visible = false

	var root: VBoxContainer = VBoxContainer.new()
	root.name = PANEL_NAME
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 12.0
	root.offset_top = 52.0
	root.offset_right = -12.0
	root.offset_bottom = -12.0
	root.add_theme_constant_override("separation", 10)
	dialog.add_child(root)

	if not description.is_empty():
		var desc: RichTextLabel = RichTextLabel.new()
		desc.bbcode_enabled = true
		desc.text = description
		desc.fit_content = true
		desc.scroll_active = false
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.add_theme_font_size_override("normal_font_size", 17)
		desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		root.add_child(desc)
		var sep: HSeparator = HSeparator.new()
		root.add_child(sep)

	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 10)
	root.add_child(row)

	for card_data: Dictionary in cards:
		var card: Control = _build_pick_card(card_data)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		row.add_child(card)

static func _build_pick_card(data: Dictionary) -> Control:
	var title: String = String(data.get("title", ""))
	var effects: Dictionary = data.get("effects", {})
	var on_pick: Callable = data.get("on_pick", Callable())

	var normal_style: StyleBoxFlat = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.09, 0.11, 0.15)
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = Color(0.28, 0.36, 0.52)
	normal_style.corner_radius_top_left = 6
	normal_style.corner_radius_top_right = 6
	normal_style.corner_radius_bottom_left = 6
	normal_style.corner_radius_bottom_right = 6

	var hover_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.14, 0.17, 0.24)
	hover_style.border_color = Color(1.0, 0.67, 0.26)
	hover_style.shadow_color = Color(1.0, 0.67, 0.26, 0.28)
	hover_style.shadow_size = 8

	var press_style: StyleBoxFlat = hover_style.duplicate() as StyleBoxFlat
	press_style.bg_color = Color(0.19, 0.23, 0.32)

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
		key_lbl.add_theme_color_override("font_color", Color(0.72, 0.78, 0.86))
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
		no_eff.add_theme_color_override("font_color", Color(0.48, 0.54, 0.62))
		no_eff.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		inner.add_child(no_eff)

	var spacer: Control = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.add_child(spacer)

	var hint: Label = Label.new()
	hint.text = "▶  Pick this"
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.40, 0.48, 0.60))
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
			return Color(1.0, 0.45, 0.18) if delta > 0 else Color(0.36, 0.84, 0.50)
		"runway_days":
			return Color(0.92, 0.24, 0.24) if delta < 0 else Color(0.36, 0.84, 0.50)
		_:
			return Color(0.36, 0.84, 0.50) if delta > 0 else Color(0.92, 0.24, 0.24)

static func configure_locked_dialog(
	dlg: AcceptDialog,
	end_run_dialog: AcceptDialog,
	dilemma_dialog: AcceptDialog,
	draft_dialog: AcceptDialog,
	end_dialog_size: Vector2i,
	dilemma_dialog_size: Vector2i,
	draft_dialog_size: Vector2i
) -> void:
	if dlg == null:
		return
	dlg.set_close_on_escape(false)
	dlg.exclusive = true
	dlg.popup_window = true
	dlg.unresizable = true
	var dialog_label: Label = dlg.get_label()
	dialog_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	dialog_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog_label.add_theme_font_size_override("font_size", 19)
	dlg.get_ok_button().add_theme_font_size_override("font_size", 20)
	if dlg is ConfirmationDialog:
		(dlg as ConfirmationDialog).get_cancel_button().add_theme_font_size_override("font_size", 20)

	if dlg == end_run_dialog:
		dlg.min_size = end_dialog_size
	elif dlg == dilemma_dialog:
		dlg.min_size = dilemma_dialog_size
	elif dlg == draft_dialog:
		dlg.min_size = draft_dialog_size
