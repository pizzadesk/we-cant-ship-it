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

func _ready() -> void:
	_rng.randomize()
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
		_tags_label.text = ""
		return

	_name_label.text = feature_card.feature_name
	_stats_label.text = _S.get_string("card_ui", "stats_format") % [feature_card.ambition_value, feature_card.instability_value]
	_tags_label.text = ", ".join(feature_card.tags)
	_stats_label.add_theme_color_override("font_color", FeatureCard.get_instability_color(feature_card.instability_value))

# Override in subclasses to apply distinct visual style (colours, borders, rotation).
func _apply_janky_look() -> void:
	# Neutral base style; subclasses layer their own visual identity.
	modulate = Color.WHITE
