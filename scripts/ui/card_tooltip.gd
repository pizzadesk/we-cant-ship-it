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
	if _feature_card == null:
		_content_label.text = _S.get_string("card_ui", "no_card_selected")
		return

	var feature_name: String = _feature_card.feature_name
	var ambition: int = int(_feature_card.ambition_value)
	var instability: int = int(_feature_card.instability_value)
	var tags: PackedStringArray = PackedStringArray()
	if _feature_card is FeatureCard:
		tags = (_feature_card as FeatureCard).tags

	var content: String = ""
	content += "[b]%s[/b]\n" % feature_name
	content += "\n[u]Stats:[/u]\n"
	content += _S.get_string("card_ui", "ambition_stat_format") % ambition + "\n"
	content += _S.get_string("card_ui", "instability_stat_format") % instability + "\n"

	if tags.size() > 0:
		content += "\n[u]Tags:[/u]\n"
		content += "%s\n" % ", ".join(tags)

	# If it has a [number], explain the variant system
	if "[" in feature_name and "]" in feature_name:
		content += "\n" + _S.get_string("card_ui", "variant_note")

	_content_label.text = content
