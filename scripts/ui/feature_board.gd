extends PanelContainer
class_name FeatureBoard

const PLACED_FEATURE_TILE_SCENE: PackedScene = preload("res://scenes/ui/placed_feature_tile.tscn")

signal card_dropped(data: Dictionary)

@onready var _board_title_label: Label = %BoardTitle
@onready var _board_help_label: Label = %BoardHelp
@onready var _jank_state_box: PanelContainer = $BoardPadding/BoardVBox/JankStateBox
@onready var _jank_state_title_label: Label = %JankStateTitle
@onready var _jank_state_body_label: Label = %JankStateBody
@onready var _drop_cue_label: Label = $BoardPadding/BoardVBox/BoardDropCue
@onready var _empty_state_label: Label = $BoardPadding/BoardVBox/BoardEmptyState
@onready var _placed_features_scroll: ScrollContainer = $BoardPadding/BoardVBox/PlacedFeaturesScroll
@onready var _placed_features_list: GridContainer = $BoardPadding/BoardVBox/PlacedFeaturesScroll/PlacedFeaturesRow

# Maps feature_name -> PlacedFeatureTile for stack tracking.
var _tile_by_name: Dictionary = {}

@export var base_style: StyleBoxFlat
@export var highlight_style: StyleBoxFlat
@export var idle_state_style: StyleBoxFlat
@export var prospect_state_style: StyleBoxFlat
@export var locked_state_style: StyleBoxFlat
var _is_highlighted: bool = false
var _jank_state_tween: Tween = null

func _ready() -> void:
	set_process(true)
	if base_style != null:
		add_theme_stylebox_override("panel", base_style)
	if idle_state_style != null and _jank_state_box != null:
		_jank_state_box.add_theme_stylebox_override("panel", idle_state_style)
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
	set_jank_pursuit_state({})
	if _placed_features_scroll != null:
		_placed_features_scroll.scroll_vertical = 0

func get_corruptible_text_nodes() -> Array[Control]:
	return [_board_title_label, _board_help_label, _jank_state_title_label, _jank_state_body_label]

func set_jank_pursuit_state(state: Dictionary) -> void:
	var stage: String = String(state.get("stage", "idle"))
	match stage:
		"prospect":
			_jank_state_title_label.text = String(state.get("display_title", "Prospect Forming"))
			_jank_state_body_label.text = String(state.get("display_body", "Something strange is taking shape."))
			_jank_state_title_label.add_theme_color_override("font_color", Color(0.95, 0.80, 0.48, 1.0))
			_jank_state_body_label.add_theme_color_override("font_color", Color(0.90, 0.86, 0.74, 1.0))
			if prospect_state_style != null and _jank_state_box != null:
				_jank_state_box.add_theme_stylebox_override("panel", prospect_state_style)
		"locked":
			_jank_state_title_label.text = String(state.get("display_title", "Signature Locked"))
			_jank_state_body_label.text = String(state.get("display_body", "This run has become something irreversible."))
			_jank_state_title_label.add_theme_color_override("font_color", Color(0.98, 0.63, 0.34, 1.0))
			_jank_state_body_label.add_theme_color_override("font_color", Color(0.98, 0.90, 0.80, 1.0))
			if locked_state_style != null and _jank_state_box != null:
				_jank_state_box.add_theme_stylebox_override("panel", locked_state_style)
		_:
			_jank_state_title_label.text = String(state.get("display_title", "No Signature Yet"))
			_jank_state_body_label.text = String(state.get("display_body", "Combine features and watch for collisions that feel a little too meaningful."))
			_jank_state_title_label.add_theme_color_override("font_color", Color(0.95, 0.88, 0.66, 1.0))
			_jank_state_body_label.add_theme_color_override("font_color", Color(0.80, 0.85, 0.92, 1.0))
			if idle_state_style != null and _jank_state_box != null:
				_jank_state_box.add_theme_stylebox_override("panel", idle_state_style)

func pulse_jank_state(stage: String) -> void:
	if _jank_state_box == null:
		return
	if _jank_state_tween != null:
		_jank_state_tween.kill()
	_jank_state_box.pivot_offset = _jank_state_box.size * 0.5
	_jank_state_box.scale = Vector2.ONE
	var flash_color: Color = Color(1.0, 1.0, 1.0, 1.0)
	match stage:
		"prospect":
			flash_color = Color(1.18, 1.08, 0.88, 1.0)
		"locked":
			flash_color = Color(1.24, 0.98, 0.90, 1.0)
	_jank_state_tween = create_tween()
	_jank_state_tween.set_trans(Tween.TRANS_BACK)
	_jank_state_tween.set_ease(Tween.EASE_OUT)
	_jank_state_tween.tween_property(_jank_state_box, "scale", Vector2(1.03, 1.03), 0.14)
	_jank_state_tween.parallel().tween_property(_jank_state_box, "modulate", flash_color, 0.14)
	_jank_state_tween.tween_property(_jank_state_box, "scale", Vector2.ONE, 0.24)
	_jank_state_tween.parallel().tween_property(_jank_state_box, "modulate", Color.WHITE, 0.24)

func _scroll_to_latest_feature() -> void:
	if _placed_features_scroll == null:
		return
	_placed_features_scroll.scroll_vertical = int(_placed_features_scroll.get_v_scroll_bar().max_value)
