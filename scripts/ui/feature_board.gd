extends PanelContainer
class_name FeatureBoard

const PLACED_FEATURE_TILE_SCENE: PackedScene = preload("res://scenes/ui/placed_feature_tile.tscn")

signal card_dropped(data: Dictionary)

@onready var _board_title_label: Label = %BoardTitle
@onready var _board_help_label: Label = %BoardHelp
@onready var _drop_cue_label: Label = $BoardPadding/BoardVBox/BoardDropCue
@onready var _empty_state_label: Label = $BoardPadding/BoardVBox/BoardEmptyState
@onready var _placed_features_scroll: ScrollContainer = $BoardPadding/BoardVBox/PlacedFeaturesScroll
@onready var _placed_features_list: GridContainer = $BoardPadding/BoardVBox/PlacedFeaturesScroll/PlacedFeaturesRow

# Maps feature_name -> PlacedFeatureTile for stack tracking.
var _tile_by_name: Dictionary = {}

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

	var key: String = card.feature_name if card != null else ""
	if not key.is_empty() and _tile_by_name.has(key):
		var existing: PlacedFeatureTile = _tile_by_name[key] as PlacedFeatureTile
		existing.increment_stack()
		return

	var tile: PlacedFeatureTile = PLACED_FEATURE_TILE_SCENE.instantiate() as PlacedFeatureTile
	tile.set_feature_card(card)
	_placed_features_list.add_child(tile)
	if not key.is_empty():
		_tile_by_name[key] = tile
	call_deferred("_scroll_to_latest_feature")

func clear_board() -> void:
	for child in _placed_features_list.get_children():
		child.queue_free()
	_tile_by_name.clear()
	_empty_state_label.show()
	if _placed_features_scroll != null:
		_placed_features_scroll.scroll_vertical = 0

func get_corruptible_text_nodes() -> Array[Control]:
	return [_board_title_label, _board_help_label]

func _scroll_to_latest_feature() -> void:
	if _placed_features_scroll == null:
		return
	_placed_features_scroll.scroll_vertical = int(_placed_features_scroll.get_v_scroll_bar().max_value)
