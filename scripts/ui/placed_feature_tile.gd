extends CardDisplayBase
class_name PlacedFeatureTile

var _spawn_tween: Tween
var _stack_count: int = 1

func _ready() -> void:
	_placed_mode = true
	super()
	# SIZE_SHRINK_BEGIN (0) prevents tiles from stretching to fill extra row
	# height when the GridContainer is inflated by its parent ScrollContainer.
	# Change to Control.SIZE_FILL (1) or Control.SIZE_EXPAND_FILL (3) if you
	# want tiles to grow with the available grid cell height.
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_play_spawn_pop()

func increment_stack() -> void:
	_stack_count += 1
	_refresh_name_label()
	_play_spawn_pop()

func _refresh_name_label() -> void:
	if feature_card == null:
		return
	_name_label.text = feature_card.feature_name if _stack_count <= 1 else "%s  ×%d" % [feature_card.feature_name, _stack_count]
func _update_view() -> void:
	super._update_view()
	_refresh_name_label()
func _apply_janky_look() -> void:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.09 + _rng.randf_range(-0.02, 0.03), 0.14 + _rng.randf_range(-0.03, 0.04), 0.12 + _rng.randf_range(-0.03, 0.04))
	sb.border_width_left = 2
	sb.border_width_top = 3
	sb.border_width_right = 2
	sb.border_width_bottom = 3
	sb.border_color = Color(0.44 + _rng.randf_range(-0.08, 0.08), 0.90 + _rng.randf_range(-0.08, 0.06), 0.74 + _rng.randf_range(-0.08, 0.06))
	sb.corner_radius_top_left = 2
	sb.corner_radius_top_right = 5
	sb.corner_radius_bottom_left = 5
	sb.corner_radius_bottom_right = 2
	add_theme_stylebox_override("panel", sb)

	_name_label.add_theme_color_override("font_color", Color(0.93, 0.98, 0.90))
	_tags_label.add_theme_color_override("font_color", Color(0.72, 0.91, 0.82))
	rotation_degrees = _rng.randf_range(-1.4, 1.4)

func _play_spawn_pop() -> void:
	if _spawn_tween != null:
		_spawn_tween.kill()
	scale = Vector2(0.92, 0.92)
	modulate = Color(1.0, 1.0, 1.0, 0.0)
	_spawn_tween = create_tween()
	_spawn_tween.set_trans(Tween.TRANS_BACK)
	_spawn_tween.set_ease(Tween.EASE_OUT)
	_spawn_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.16)
	_spawn_tween.parallel().tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)
