extends Resource
class_name StageTheme

# Data resource describing the visual identity of one sprint stage.
# Populate in the Godot inspector via data/stage_themes/*.tres.
# All nullable fields are safe to leave null during development — systems guard against null.

@export var stage_index: int = 0
@export var stage_name: String = ""

# Applied to the scene root when this stage becomes active; propagates automatically
# down the full node tree via Godot's Theme inheritance.
# Null = no theme override for this stage (inherits project default).
@export var ui_theme: Theme = null

# Instantiated into DecorationLayer on stage entry; freed on stage exit.
# Must be purely additive — no Control nodes with layout influence, no size containers.
# Null = no decoration for this stage (valid during development).
@export var decoration_scene: PackedScene = null

# Modulates how strongly the instability corruption system reads visually on this stage.
# 1.0 = full corruption strength. Lower values soften it for stages with built-in visual chaos.
@export_range(0.0, 1.0) var corruption_intensity_scale: float = 1.0
