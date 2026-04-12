extends RefCounted
class_name DialogFactory

const DialogSetupUtils = preload("res://scripts/ui/dialog_setup_utils.gd")
const _JsonDataLoader = preload("res://scripts/data/json_data_loader.gd")
const _S = preload("res://scripts/ui/ui_strings.gd")

static func configure_scene_dialogs(
	dialog_host: DialogHostView,
	review_dialog: AcceptDialog,
	end_run_dialog: ConfirmationDialog,
	dilemma_dialog: ConfirmationDialog,
	draft_dialog: ConfirmationDialog,
	review_dialog_size: Vector2i,
	end_dialog_size: Vector2i,
	dilemma_dialog_size: Vector2i,
	draft_dialog_size: Vector2i,
	on_ship_confirmed: Callable,
	on_ship_canceled: Callable,
	on_jank_discovery_confirmed: Callable,
	on_jank_confirmed: Callable,
) -> Dictionary:
	var ship_summary_dialog: ConfirmationDialog = dialog_host.get_ship_summary_dialog()
	var ship_summary_content: RichTextLabel = _configure_confirmation_dialog(
		ship_summary_dialog,
		_S.get_string("popups", "ship_summary_title"),
		Vector2i(700, 580),
		_S.get_string("buttons", "ship_summary_ok"),
		_S.get_string("buttons", "ship_summary_cancel"),
		15,
		true,
		true,
		false
	)
	if ship_summary_dialog != null:
		if not ship_summary_dialog.confirmed.is_connected(on_ship_confirmed):
			ship_summary_dialog.confirmed.connect(on_ship_confirmed)
		if not ship_summary_dialog.canceled.is_connected(on_ship_canceled):
			ship_summary_dialog.canceled.connect(on_ship_canceled)

	var jank_discovery_dialog: AcceptDialog = dialog_host.get_jank_discovery_dialog()
	var jank_discovery_content: RichTextLabel = _configure_accept_dialog(
		jank_discovery_dialog,
		_S.get_string("popups", "mechanics_title"),
		Vector2i(900, 600),
		"Continue",
		16,
		false,
		true,
		false
	)
	if jank_discovery_dialog != null and not jank_discovery_dialog.confirmed.is_connected(on_jank_discovery_confirmed):
		jank_discovery_dialog.confirmed.connect(on_jank_discovery_confirmed)

	var gap_visualizer_dialog: AcceptDialog = dialog_host.get_gap_visualizer_dialog()
	var gap_visualizer_content: RichTextLabel = _configure_accept_dialog(
		gap_visualizer_dialog,
		"Gap Visualizer",
		Vector2i(700, 500),
		"Continue",
		18,
		false,
		true,
		false
	)
	if gap_visualizer_dialog != null and not gap_visualizer_dialog.confirmed.is_connected(on_jank_confirmed):
		gap_visualizer_dialog.confirmed.connect(on_jank_confirmed)

	var cycle_legacy_dialog: AcceptDialog = dialog_host.get_cycle_legacy_dialog()
	var cycle_legacy_content: RichTextLabel = _configure_accept_dialog(
		cycle_legacy_dialog,
		_S.get_string("popups", "cycle_legacy_title"),
		Vector2i(760, 480),
		"Continue",
		16,
		false,
		true,
		false
	)

	var previously_on_dialog: AcceptDialog = dialog_host.get_previously_on_dialog()
	_configure_accept_dialog(
		previously_on_dialog,
		"Previously On...",
		Vector2i(700, 460),
		"Continue",
		15,
		false,
		true,
		true
	)

	var archetype_dialog: ConfirmationDialog = dialog_host.get_archetype_select_dialog()
	_configure_archetype_select_dialog(archetype_dialog)
	var draft_pick_c_button: Button = _ensure_dialog_button(draft_dialog, _S.get_string("buttons", "draft_pick_c"), "pick_c")

	for dialog: AcceptDialog in [review_dialog, end_run_dialog, dilemma_dialog, draft_dialog, ship_summary_dialog, jank_discovery_dialog, gap_visualizer_dialog]:
		DialogSetupUtils.configure_locked_dialog(
			dialog,
			end_run_dialog,
			dilemma_dialog,
			draft_dialog,
			end_dialog_size,
			dilemma_dialog_size,
			draft_dialog_size
		)

	var review_parts: Dictionary = DialogSetupUtils.setup_review_dialog_content(review_dialog, review_dialog_size)
	return {
		"ship_summary_dialog": ship_summary_dialog,
		"ship_summary_content": ship_summary_content,
		"jank_discovery_dialog": jank_discovery_dialog,
		"jank_discovery_content": jank_discovery_content,
		"jank_dialog": gap_visualizer_dialog,
		"jank_content": gap_visualizer_content,
		"review_content": review_parts.get("content") as RichTextLabel,
		"draft_pick_c_button": draft_pick_c_button,
		"archetype_dialog": archetype_dialog,
		"cycle_legacy_dialog": cycle_legacy_dialog,
		"cycle_legacy_content": cycle_legacy_content,
		"previously_on_dialog": previously_on_dialog,
	}

static func _configure_archetype_select_dialog(dialog: ConfirmationDialog) -> void:
	if dialog == null:
		return
	var archetypes: Array = _JsonDataLoader.load_array("res://data/archetypes.json", "archetypes")
	if archetypes.is_empty():
		archetypes = [
			{"label": "RPG", "key": "rpg", "description": "Deep systems, faction rep, narrative weight"},
			{"label": "Shooter", "key": "shooter", "description": "Kinetic action, destruction, co-op"},
			{"label": "Action-Adventure", "key": "action_adventure", "description": "Open world, exploration, physics"},
		]
	var content: RichTextLabel = _configure_confirmation_dialog(
		dialog,
		"Target Genre",
		Vector2i(560, 360),
		"",
		"",
		15,
		false,
		false,
		false
	)
	if content == null:
		return
	var first: Dictionary = archetypes[0]
	dialog.get_ok_button().text = String(first.get("label", "RPG"))
	dialog.get_ok_button().add_theme_font_size_override("font_size", 20)
	dialog.set_meta("ok_archetype_key", first.get("key", "rpg"))
	dialog.get_cancel_button().hide()
	if not dialog.has_meta("archetype_buttons_configured") or not bool(dialog.get_meta("archetype_buttons_configured")):
		for i in range(1, archetypes.size()):
			var arch: Dictionary = archetypes[i]
			var button: Button = dialog.add_button(String(arch.get("label", "")), false, String(arch.get("key", "")))
			button.add_theme_font_size_override("font_size", 20)
		dialog.set_meta("archetype_buttons_configured", true)
	content.scroll_active = false
	content.selection_enabled = false
	content.offset_bottom = -90.0
	var body: String = _S.get_string("popups", "archetype_dialog_intro") + "\n\n"
	for arch in archetypes:
		body += "[b]%s[/b] — %s\n" % [String(arch.get("label", "")), String(arch.get("description", ""))]
	content.text = body

static func _configure_accept_dialog(
	dialog: AcceptDialog,
	title: String,
	min_size: Vector2i,
	ok_text: String,
	normal_font_size: int,
	selection_enabled: bool,
	scroll_active: bool,
	close_on_escape: bool,
	) -> RichTextLabel:
	if dialog == null:
		return null
	var content: RichTextLabel = dialog.get_node_or_null("Content") as RichTextLabel
	_configure_dialog_base(dialog, title, min_size, close_on_escape)
	if content != null:
		_configure_content_node(content, normal_font_size, selection_enabled, scroll_active)
	if not ok_text.is_empty():
		dialog.get_ok_button().text = ok_text
	return content

static func _configure_confirmation_dialog(
	dialog: ConfirmationDialog,
	title: String,
	min_size: Vector2i,
	ok_text: String,
	cancel_text: String,
	normal_font_size: int,
	selection_enabled: bool,
	scroll_active: bool,
	close_on_escape: bool,
	) -> RichTextLabel:
	if dialog == null:
		return null
	var content: RichTextLabel = dialog.get_node_or_null("Content") as RichTextLabel
	_configure_dialog_base(dialog, title, min_size, close_on_escape)
	if content != null:
		_configure_content_node(content, normal_font_size, selection_enabled, scroll_active)
	if not ok_text.is_empty():
		dialog.get_ok_button().text = ok_text
	if not cancel_text.is_empty():
		dialog.get_cancel_button().text = cancel_text
	return content

static func _configure_dialog_base(dialog: AcceptDialog, title: String, min_size: Vector2i, close_on_escape: bool) -> void:
	dialog.title = title
	dialog.min_size = min_size
	dialog.set_close_on_escape(close_on_escape)
	dialog.exclusive = true
	dialog.popup_window = true
	dialog.unresizable = true
	var label: Label = dialog.get_label()
	if label != null:
		label.visible = false
	dialog.get_ok_button().add_theme_font_size_override("font_size", 20)
	if dialog is ConfirmationDialog:
		(dialog as ConfirmationDialog).get_cancel_button().add_theme_font_size_override("font_size", 20)

static func _ensure_dialog_button(dialog: AcceptDialog, button_text: String, action: StringName) -> Button:
	if dialog == null:
		return null
	var meta_key: String = "extra_button_%s" % String(action)
	var existing: Variant = null
	if dialog.has_meta(meta_key):
		existing = dialog.get_meta(meta_key)
	if existing is Button and is_instance_valid(existing):
		return existing as Button
	var button: Button = dialog.add_button(button_text, false, action)
	dialog.set_meta(meta_key, button)
	return button

static func _configure_content_node(content: RichTextLabel, normal_font_size: int, selection_enabled: bool, scroll_active: bool) -> void:
	content.bbcode_enabled = true
	content.fit_content = false
	content.scroll_active = scroll_active
	content.selection_enabled = selection_enabled
	content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_theme_font_size_override("normal_font_size", normal_font_size)
