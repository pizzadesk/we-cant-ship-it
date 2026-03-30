const _S = preload("res://scripts/ui/ui_strings.gd")

static func build_help_dialog(owner: Node, on_confirmed: Callable, help_text: String) -> AcceptDialog:
	var help_dialog: AcceptDialog = AcceptDialog.new()
	help_dialog.name = "HelpDialog"
	help_dialog.title = _S.get_string("popups", "help_title")
	help_dialog.set_close_on_escape(true)
	help_dialog.min_size = Vector2i(560, 580)

	help_dialog.get_label().visible = false

	var help_label: RichTextLabel = RichTextLabel.new()
	help_label.bbcode_enabled = true
	help_label.text = help_text
	help_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help_label.scroll_active = false
	help_label.selection_enabled = false
	help_label.add_theme_font_size_override("normal_font_size", 14)
	help_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	help_label.offset_left = 16.0
	help_label.offset_top = 52.0
	help_label.offset_right = -16.0
	help_label.offset_bottom = -66.0
	help_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	help_label.size_flags_vertical = Control.SIZE_EXPAND_FILL

	help_dialog.add_child(help_label)
	help_dialog.get_ok_button().text = _S.get_string("buttons", "help_ok")
	help_dialog.confirmed.connect(on_confirmed)
	owner.add_child(help_dialog)
	return help_dialog

static func build_ship_summary_dialog(owner: Node, on_confirmed: Callable, on_canceled: Callable) -> ConfirmationDialog:
	var dialog: ConfirmationDialog = ConfirmationDialog.new()
	dialog.name = "ShipSummaryDialog"
	dialog.title = _S.get_string("popups", "ship_summary_title")
	dialog.set_close_on_escape(false)
	dialog.min_size = Vector2i(700, 580)
	dialog.get_label().visible = false
	dialog.get_ok_button().text = _S.get_string("buttons", "ship_summary_ok")
	dialog.get_cancel_button().text = _S.get_string("buttons", "ship_summary_cancel")
	dialog.confirmed.connect(on_confirmed)
	dialog.canceled.connect(on_canceled)

	var summary_content: RichTextLabel = RichTextLabel.new()
	summary_content.name = "SummaryContent"
	summary_content.bbcode_enabled = true
	summary_content.scroll_active = true
	summary_content.selection_enabled = false
	summary_content.fit_content = false
	summary_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	summary_content.offset_left = 16.0
	summary_content.offset_top = 52.0
	summary_content.offset_right = -16.0
	summary_content.offset_bottom = -66.0
	summary_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	summary_content.add_theme_font_size_override("normal_font_size", 13)

	dialog.add_child(summary_content)
	owner.add_child(dialog)
	return dialog

static func create_stat_gauge(color: Color, max_value: int, parent: VBoxContainer) -> ProgressBar:
	var gauge: ProgressBar = ProgressBar.new()
	gauge.max_value = float(max_value)
	gauge.value = 0.0
	gauge.custom_minimum_size = Vector2(60.0, 8.0)
	gauge.modulate = color
	gauge.show_percentage = false
	parent.add_child(gauge)
	return gauge

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

static func build_mechanics_highlights_dialog(owner: Node, on_confirmed: Callable) -> Dictionary:
	var dialog: AcceptDialog = AcceptDialog.new()
	dialog.name = "MechanicsHighlightsDialog"
	dialog.title = _S.get_string("popups", "mechanics_title")
	dialog.set_close_on_escape(false)
	dialog.min_size = Vector2i(900, 600)
	dialog.get_label().visible = false

	var content: RichTextLabel = RichTextLabel.new()
	content.name = "MechanicsContent"
	content.bbcode_enabled = true
	content.scroll_active = true
	content.selection_enabled = false
	content.fit_content = false
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 16.0
	content.offset_top = 52.0
	content.offset_right = -16.0
	content.offset_bottom = -66.0
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_font_size_override("normal_font_size", 16)

	dialog.add_child(content)
	owner.add_child(dialog)
	dialog.confirmed.connect(on_confirmed)
	return {
		"dialog": dialog,
		"content": content,
	}

static func build_jank_meter_dialog(owner: Node, on_confirmed: Callable) -> Dictionary:
	var dialog: AcceptDialog = AcceptDialog.new()
	dialog.name = "JankMeterDialog"
	dialog.title = _S.get_string("popups", "jank_meter_title")
	dialog.set_close_on_escape(false)
	dialog.min_size = Vector2i(700, 500)
	dialog.get_label().visible = false

	var content: RichTextLabel = RichTextLabel.new()
	content.name = "JankMeterContent"
	content.bbcode_enabled = true
	content.scroll_active = true
	content.selection_enabled = false
	content.fit_content = false
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 16.0
	content.offset_top = 52.0
	content.offset_right = -16.0
	content.offset_bottom = -66.0
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_font_size_override("normal_font_size", 18)

	dialog.add_child(content)
	owner.add_child(dialog)
	dialog.confirmed.connect(on_confirmed)
	return {
		"dialog": dialog,
		"content": content,
	}

static func build_studio_briefing_dialog(owner: Node, on_keep: Callable, on_replace: Callable) -> Dictionary:
	# ConfirmationDialog: OK = "Keep Current Legacy", Cancel = "Take New Legacy".
	# Only shown when a pending_legacy exists in meta_progress.
	var dialog: ConfirmationDialog = ConfirmationDialog.new()
	dialog.name = "StudioBriefingDialog"
	dialog.title = _S.get_string("popups", "studio_briefing_title")
	dialog.set_close_on_escape(false)
	dialog.min_size = Vector2i(680, 480)
	dialog.get_label().visible = false
	dialog.get_ok_button().text = _S.get_string("buttons", "studio_briefing_ok")
	dialog.get_cancel_button().text = _S.get_string("buttons", "studio_briefing_cancel")
	dialog.confirmed.connect(on_keep)
	dialog.canceled.connect(on_replace)

	var content: RichTextLabel = RichTextLabel.new()
	content.name = "BriefingContent"
	content.bbcode_enabled = true
	content.scroll_active = true
	content.selection_enabled = false
	content.fit_content = false
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 16.0
	content.offset_top = 52.0
	content.offset_right = -16.0
	content.offset_bottom = -66.0
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_font_size_override("normal_font_size", 15)

	dialog.add_child(content)
	owner.add_child(dialog)
	return {
		"dialog": dialog,
		"content": content,
	}

static func setup_runtime_dialogs(
	owner: Node,
	review_dialog: AcceptDialog,
	end_run_dialog: ConfirmationDialog,
	dilemma_dialog: ConfirmationDialog,
	draft_dialog: ConfirmationDialog,
	publisher_dialog: ConfirmationDialog,
	review_dialog_size: Vector2i,
	end_dialog_size: Vector2i,
	dilemma_dialog_size: Vector2i,
	draft_dialog_size: Vector2i,
	publisher_dialog_size: Vector2i,
	help_text: String,
	on_help_confirmed: Callable,
	on_ship_confirmed: Callable,
	on_ship_canceled: Callable,
	on_mechanics_confirmed: Callable,
	on_jank_confirmed: Callable
) -> DialogRuntimeRefs:
	var refs: DialogRuntimeRefs = DialogRuntimeRefs.new()
	var help_dialog: AcceptDialog = build_help_dialog(owner, on_help_confirmed, help_text)
	var ship_summary_dialog: ConfirmationDialog = build_ship_summary_dialog(owner, on_ship_confirmed, on_ship_canceled)

	var mechanics_parts: Dictionary = build_mechanics_highlights_dialog(owner, on_mechanics_confirmed)
	var mechanics_dialog: AcceptDialog = mechanics_parts.get("dialog") as AcceptDialog
	var mechanics_content: RichTextLabel = mechanics_parts.get("content") as RichTextLabel

	var jank_parts: Dictionary = build_jank_meter_dialog(owner, on_jank_confirmed)
	var jank_dialog: AcceptDialog = jank_parts.get("dialog") as AcceptDialog
	var jank_content: RichTextLabel = jank_parts.get("content") as RichTextLabel

	var draft_pick_c_button: Button = draft_dialog.add_button(_S.get_string("buttons", "draft_pick_c"), false, "pick_c")
	var publisher_pick_c_button: Button = publisher_dialog.add_button(_S.get_string("buttons", "publisher_stance_c"), false, "pick_c")

	configure_locked_dialog(
		review_dialog,
		end_run_dialog,
		dilemma_dialog,
		draft_dialog,
		publisher_dialog,
		end_dialog_size,
		dilemma_dialog_size,
		draft_dialog_size,
		publisher_dialog_size
	)
	configure_locked_dialog(
		end_run_dialog,
		end_run_dialog,
		dilemma_dialog,
		draft_dialog,
		publisher_dialog,
		end_dialog_size,
		dilemma_dialog_size,
		draft_dialog_size,
		publisher_dialog_size
	)
	configure_locked_dialog(
		dilemma_dialog,
		end_run_dialog,
		dilemma_dialog,
		draft_dialog,
		publisher_dialog,
		end_dialog_size,
		dilemma_dialog_size,
		draft_dialog_size,
		publisher_dialog_size
	)
	configure_locked_dialog(
		draft_dialog,
		end_run_dialog,
		dilemma_dialog,
		draft_dialog,
		publisher_dialog,
		end_dialog_size,
		dilemma_dialog_size,
		draft_dialog_size,
		publisher_dialog_size
	)
	configure_locked_dialog(
		publisher_dialog,
		end_run_dialog,
		dilemma_dialog,
		draft_dialog,
		publisher_dialog,
		end_dialog_size,
		dilemma_dialog_size,
		draft_dialog_size,
		publisher_dialog_size
	)
	configure_locked_dialog(
		mechanics_dialog,
		end_run_dialog,
		dilemma_dialog,
		draft_dialog,
		publisher_dialog,
		end_dialog_size,
		dilemma_dialog_size,
		draft_dialog_size,
		publisher_dialog_size
	)
	configure_locked_dialog(
		jank_dialog,
		end_run_dialog,
		dilemma_dialog,
		draft_dialog,
		publisher_dialog,
		end_dialog_size,
		dilemma_dialog_size,
		draft_dialog_size,
		publisher_dialog_size
	)

	var review_parts: Dictionary = setup_review_dialog_content(review_dialog, review_dialog_size)
	var review_scroll: ScrollContainer = review_parts.get("scroll") as ScrollContainer
	var review_content: RichTextLabel = review_parts.get("content") as RichTextLabel

	refs.help_dialog = help_dialog
	refs.ship_summary_dialog = ship_summary_dialog
	refs.mechanics_dialog = mechanics_dialog
	refs.mechanics_content = mechanics_content
	refs.jank_dialog = jank_dialog
	refs.jank_content = jank_content
	refs.review_scroll = review_scroll
	refs.review_content = review_content
	refs.draft_pick_c_button = draft_pick_c_button
	refs.publisher_pick_c_button = publisher_pick_c_button
	return refs

static func configure_locked_dialog(
	dlg: AcceptDialog,
	end_run_dialog: AcceptDialog,
	dilemma_dialog: AcceptDialog,
	draft_dialog: AcceptDialog,
	publisher_dialog: AcceptDialog,
	end_dialog_size: Vector2i,
	dilemma_dialog_size: Vector2i,
	draft_dialog_size: Vector2i,
	publisher_dialog_size: Vector2i
) -> void:
	if dlg == null:
		return
	dlg.set_close_on_escape(false)
	dlg.close_requested.connect(func(): dlg.call_deferred("show"))
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
	elif dlg == publisher_dialog:
		dlg.min_size = publisher_dialog_size
