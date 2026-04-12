extends PanelContainer
class_name CardDisplayBase

const _S = preload("res://scripts/ui/ui_strings.gd")

# Shared base for FeatureCardWidget (backlog) and PlacedFeatureTile (board).
# Owns the feature_card data, the three display labels, and _update_view().
# Subclasses override _apply_janky_look() for their distinct visual palette.

@export var feature_card: Resource

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Both child scenes must have this node path: Padding/VBox/NameLabel etc.
@onready var _name_label: Label = $Padding/VBox/NameLabel
@onready var _stats_label: Label = $Padding/VBox/StatsLabel
@onready var _tags_label: Label = $Padding/VBox/TagsLabel
var _risk_label: Label = null
# Optional — present in both scenes, but only populated when the field exists.
var _description_label: Label = null
# When true: stats row is hidden, description (if any) is shown instead.
var _placed_mode: bool = false

func _ready() -> void:
	_rng.randomize()
	_risk_label = get_node_or_null("Padding/VBox/RiskLabel") as Label
	_description_label = get_node_or_null("Padding/VBox/DescriptionLabel") as Label
	_apply_janky_look()
	_update_view()

func set_feature_card(card: Resource) -> void:
	feature_card = card
	if is_inside_tree():
		_update_view()

func _update_view() -> void:
	if feature_card == null:
		_name_label.text = _S.get_string("card_ui", "feature_unknown")
		_stats_label.text = _S.get_string("card_ui", "stats_empty")
		if _risk_label != null:
			_risk_label.text = ""
		_tags_label.text = ""
		return

	_name_label.text = feature_card.feature_name
	_stats_label.visible = not _placed_mode
	if not _placed_mode:
		_stats_label.text = _S.get_string("card_ui", "stats_format") % [feature_card.ambition_value, feature_card.instability_value]
	if _description_label != null:
		var desc: String = feature_card.description if feature_card is FeatureCard else ""
		_description_label.text = desc
		_description_label.visible = not desc.is_empty()
	if _risk_label != null:
		_risk_label.visible = not _placed_mode
	_tags_label.text = ", ".join(feature_card.tags)
	_stats_label.add_theme_color_override("font_color", FeatureCard.get_instability_color(feature_card.instability_value))
	_apply_tier_accent()

# Override in subclasses to apply distinct visual style (colours, borders, rotation).
func _apply_janky_look() -> void:
	# Neutral base style; subclasses layer their own visual identity.
	modulate = Color.WHITE

func _apply_tier_accent() -> void:
	if feature_card == null:
		return
	var sb: StyleBoxFlat = get_theme_stylebox("panel") as StyleBoxFlat
	if sb == null:
		return
	match feature_card.tier.to_lower():
		"uncommon":
			sb.border_color = Color(0.42, 0.68, 0.95)
		"rare":
			sb.border_color = Color(0.96, 0.78, 0.18)
			sb.border_width_left = 4
		"jank":
			sb.border_color = Color(0.85, 0.22, 0.90)
			sb.border_width_left = 4
	add_theme_stylebox_override("panel", sb)
	if feature_card.tier.to_lower() == "jank" and feature_card.archetype_affinity.size() > 0:
		var stamp: String = " [%s]" % feature_card.archetype_affinity[0].to_upper()
		_tags_label.text = ", ".join(feature_card.tags) + stamp
