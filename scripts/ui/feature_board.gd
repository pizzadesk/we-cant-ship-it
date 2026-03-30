extends PanelContainer
class_name FeatureBoard

const PLACED_FEATURE_TILE_SCENE: PackedScene = preload("res://scenes/ui/placed_feature_tile.tscn")

signal card_dropped(data: Dictionary)

@onready var _drop_cue_label: Label = $BoardPadding/BoardVBox/BoardDropCue
@onready var _empty_state_label: Label = $BoardPadding/BoardVBox/BoardEmptyState
@onready var _placed_features_scroll: ScrollContainer = $BoardPadding/BoardVBox/PlacedFeaturesScroll
@onready var _placed_features_list: HBoxContainer = $BoardPadding/BoardVBox/PlacedFeaturesScroll/PlacedFeaturesRow

@export var base_style: StyleBoxFlat
@export var highlight_style: StyleBoxFlat
var _is_highlighted: bool = false

func _ready() -> void:
	set_process(true)
	if base_style != null:
		add_theme_stylebox_override("panel", base_style)
	_drop_cue_label.hide()

func _process(_delta: float) -> void:
	var viewport: Viewport = get_viewport()
	var dragging: bool = viewport.gui_is_dragging()
	var drag_data: Variant = viewport.gui_get_drag_data()
	var valid_drag: bool = dragging and FeatureCardDragPayload.matches_variant(drag_data)

	if valid_drag == _is_highlighted:
		return

	_is_highlighted = valid_drag
	if _is_highlighted:
		add_theme_stylebox_override("panel", highlight_style)
		_drop_cue_label.show()
	else:
		add_theme_stylebox_override("panel", base_style)
		_drop_cue_label.hide()

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return FeatureCardDragPayload.matches_variant(data)

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(_at_position, data):
		return
	card_dropped.emit(data)

func add_feature_to_board(card: Resource) -> void:
	if _empty_state_label.visible:
		_empty_state_label.hide()

	var tile: PlacedFeatureTile = PLACED_FEATURE_TILE_SCENE.instantiate() as PlacedFeatureTile
	tile.set_feature_card(card)
	_placed_features_list.add_child(tile)
	call_deferred("_scroll_to_latest_feature")

func clear_board() -> void:
	for child in _placed_features_list.get_children():
		child.queue_free()
	_empty_state_label.show()
	if _placed_features_scroll != null:
		_placed_features_scroll.scroll_horizontal = 0

func _scroll_to_latest_feature() -> void:
	if _placed_features_scroll == null:
		return
	_placed_features_scroll.scroll_horizontal = int(_placed_features_scroll.get_h_scroll_bar().max_value)
