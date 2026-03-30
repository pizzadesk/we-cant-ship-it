extends CanvasLayer

# DecorationLayer — hosts the active stage's decoration scene as a purely additive overlay.
# Connected to GameEvents.stage_changed; swaps the decoration scene on each stage transition.
#
# Layer 2: renders above gameplay UI (layer 0) and the main menu overlay (layer 1).
# Decoration scenes must NEVER contain Control nodes with layout influence — they are
# visual-only additions. Input is not blocked because non-interactive nodes pass through.

var _active_decoration: Node = null

func _ready() -> void:
	layer = 2
	GameEvents.stage_changed.connect(_on_stage_changed)

func _on_stage_changed(theme: StageTheme) -> void:
	_swap_decoration(theme)

func _swap_decoration(theme: StageTheme) -> void:
	if _active_decoration != null:
		_active_decoration.queue_free()
		_active_decoration = null
	# null decoration_scene is valid — stages may have no decoration during development.
	if theme == null or theme.decoration_scene == null:
		return
	_active_decoration = theme.decoration_scene.instantiate()
	add_child(_active_decoration)
