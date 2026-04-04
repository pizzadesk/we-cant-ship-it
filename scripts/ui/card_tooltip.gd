extends PanelContainer
class_name CardTooltip

const _S = preload("res://scripts/ui/ui_strings.gd")

@onready var _content_label: RichTextLabel = $TooltipPadding/TooltipVBox/ContentLabel
@onready var _show_timer: Timer = $ShowTimer

var _feature_card: Resource = null

func _ready() -> void:
	hide()
	z_index = 100
	_show_timer.timeout.connect(_on_show_timer_timeout)

func show_for_card(card: Resource, card_position: Vector2) -> void:
	_feature_card = card
	_update_content()
	# Keep tooltip on-screen by clamping against current viewport size.
	var desired_pos: Vector2 = card_position + Vector2(20, 0)
	var viewport_size: Vector2 = get_viewport_rect().size
	var tooltip_size: Vector2 = get_combined_minimum_size()
	var clamped_x: float = clampf(desired_pos.x, 8.0, max(8.0, viewport_size.x - tooltip_size.x - 8.0))
	var clamped_y: float = clampf(desired_pos.y, 8.0, max(8.0, viewport_size.y - tooltip_size.y - 8.0))
	global_position = Vector2(clamped_x, clamped_y)
	show()
	_show_timer.stop()

func hide_with_delay() -> void:
	_show_timer.start()

func _on_show_timer_timeout() -> void:
	hide()

func _update_content() -> void:
	if _feature_card == null or not (_feature_card is FeatureCard):
		_content_label.text = _S.get_string("card_ui", "no_card_selected")
		return

	var fc: FeatureCard = _feature_card as FeatureCard

	# Read live archetype state for contextual mismatch display.
	var chosen_archetype: String = ""
	var mismatch_level: int = 0
	var can_place: bool = true
	if AppState != null:
		chosen_archetype = String(AppState.chosen_archetype)
		mismatch_level = int(AppState.get_archetype_mismatch_level(fc))
		can_place = bool(AppState.can_place_card(fc))

	# Tier color: common=grey, uncommon=steel blue, rare=gold.
	var tier_color: String
	match fc.tier.to_lower():
		"uncommon": tier_color = "74c0fc"
		"rare":     tier_color = "ffd43b"
		_:          tier_color = "adb5bd"

	var content: String = ""
	content += "[b]%s[/b]\n" % fc.feature_name
	content += "[color=#%s]%s[/color]\n" % [tier_color, fc.tier.capitalize()]
	if not fc.description.is_empty():
		content += "[color=#bbbbbb][i]%s[/i][/color]\n" % fc.description
	content += "\n"

	content += "[u]Stats[/u]\n"
	content += _S.get_string("card_ui", "ambition_stat_format") % fc.ambition_value + "\n"
	content += _S.get_string("card_ui", "instability_stat_format") % fc.instability_value + "\n"

	if fc.tags.size() > 0:
		content += "\n[u]Tags[/u]\n"
		content += "%s\n" % ", ".join(fc.tags)

	# Archetype section — only meaningful when a genre is active this run.
	if not chosen_archetype.is_empty():
		content += "\n[u]Archetype[/u]\n"
		if fc.archetype_affinity.is_empty():
			content += "[color=#ff6b6b]\u2620 Alien card[/color] — radically off-genre\n"
			content += "+8 Inst, +4 Amb, -3 Soul on placement\n"
			if not can_place:
				var gate: int = AppState.get_game_config().alien_card_soul_gate if AppState != null else 5
				content += "[color=#ff6b6b]Blocked — Soul < %d[/color]\n" % gate
		elif mismatch_level == 0:
			content += "[color=#51cf66]\u2713 On-archetype — no penalty[/color]\n"
		elif mismatch_level == 1:
			content += "[color=#ffd43b]~ Genre stretch[/color] — adjacent genre\n"
			content += "+2 Instability on placement\n"
		else:
			content += "[color=#ff8c42]\u26a0 Wild swing[/color] — specialized, wrong genre\n"
			content += "+4 Inst, +2 Amb, -1 Soul on placement\n"
		content += "\n[color=#555555][i]Card icons: * interaction heat  ~ stretch  \u26a0 wild swing  \u2620 alien[/i][/color]"

	if "[" in fc.feature_name and "]" in fc.feature_name:
		content += "\n" + _S.get_string("card_ui", "variant_note")

	_content_label.text = content
