extends VBoxContainer
class_name RunSidebarView

@export var runway_cell_height: int = 12
@export var runway_cell_min_width: int = 8

func get_runway_cell_size() -> Vector2:
	return Vector2(runway_cell_min_width, runway_cell_height)

@onready var _stats_panel: PanelContainer = %StatsPanel
@onready var _action_panel: PanelContainer = %ActionPanel
@onready var _ambition_value: Label = %AmbitionValue
@onready var _instability_value: Label = %InstabilityValue
@onready var _runway_value: Label = %RunwayValue
@onready var _features_value: Label = %FeaturesValue
@onready var _soul_value: Label = %SoulValue
@onready var _meta_value: Label = %MetaValue
@onready var _ambition_gauge: ProgressBar = %AmbitionGauge
@onready var _ambition_status: Label = %AmbitionStatus
@onready var _ambition_delta: Label = %AmbitionDelta
@onready var _instability_gauge: ProgressBar = %InstabilityGauge
@onready var _instability_target_band: ColorRect = %InstabilityTargetBand
@onready var _instability_status: Label = %InstabilityStatus
@onready var _instability_delta: Label = %InstabilityDelta
@onready var _runway_cells_row: HBoxContainer = %RunwayCellsRow
@onready var _soul_gauge: ProgressBar = %SoulGauge
@onready var _soul_risk_label: Label = %SoulRiskLabel
@onready var _soul_delta: Label = %SoulDelta
@onready var _goldilocks_floor_marker: ColorRect = %GoldilocksFloorMarker
@onready var _goldilocks_ceiling_marker: ColorRect = %GoldilocksCeilingMarker
@onready var _stat_guide: Label = %StatGuide
@onready var _action_title: Label = %ActionTitle
@onready var _action_help: Label = %ActionHelp
@onready var _fix_bugs_button: Button = %FixBugsButton
@onready var _dev_log_button: Button = %DevLogButton
@onready var _ship_button: Button = %ShipButton

func update_stats(ambition: int, ambition_target: int, instability: int,
		soul: int, soul_target: int) -> void:
	_ambition_value.text     = "%d / %d+" % [ambition, ambition_target]
	_ambition_gauge.value    = float(clampi(ambition, 0, 100))
	_instability_gauge.value = float(clampi(instability, 0, 100))
	_soul_value.text         = "%d / %d+" % [soul, soul_target]

func update_stat_colors(ambition_met: bool, instability_ratio: float) -> void:
	_ambition_value.add_theme_color_override(
		"font_color",
		Color(0.400, 0.950, 0.400) if ambition_met else Color(1.0, 0.75, 0.20))
	_apply_instability_color(instability_ratio)

func _apply_instability_color(ratio: float) -> void:
	if _instability_gauge == null:
		return
	var fill_color: Color
	if ratio < 0.5:
		fill_color = Color(0.200, 0.800, 0.200).lerp(Color(0.95, 0.75, 0.18), ratio * 2.0)
	elif ratio < 0.85:
		fill_color = Color(0.95, 0.75, 0.18).lerp(Color(1.0, 0.38, 0.12), (ratio - 0.5) / 0.35)
	else:
		fill_color = Color(1.0, 0.38, 0.12).lerp(Color(0.95, 0.10, 0.10), (ratio - 0.85) / 0.15)
	_instability_gauge.modulate = fill_color

func get_stats_panel() -> PanelContainer:
	return _stats_panel

func get_action_panel() -> PanelContainer:
	return _action_panel

func get_ambition_value() -> Label:
	return _ambition_value

func get_instability_value() -> Label:
	return _instability_value

func get_runway_value() -> Label:
	return _runway_value

func get_features_value() -> Label:
	return _features_value

func get_soul_value() -> Label:
	return _soul_value

func get_meta_value() -> Label:
	return _meta_value

func get_ambition_gauge() -> ProgressBar:
	return _ambition_gauge

func get_ambition_status() -> Label:
	return _ambition_status

func get_instability_gauge() -> ProgressBar:
	return _instability_gauge

func get_instability_target_band() -> ColorRect:
	return _instability_target_band

func get_instability_status() -> Label:
	return _instability_status

func get_runway_cells_row() -> HBoxContainer:
	return _runway_cells_row

func get_ambition_delta() -> Label:
	return _ambition_delta

func get_instability_delta() -> Label:
	return _instability_delta

func get_soul_gauge() -> ProgressBar:
	return _soul_gauge

func get_soul_risk_label() -> Label:
	return _soul_risk_label

func get_soul_delta() -> Label:
	return _soul_delta

func get_stat_guide() -> Label:
	return _stat_guide

func get_action_help() -> Label:
	return _action_help

func get_goldilocks_floor_marker() -> ColorRect:
	return _goldilocks_floor_marker

func get_goldilocks_ceiling_marker() -> ColorRect:
	return _goldilocks_ceiling_marker

func get_fix_bugs_button() -> Button:
	return _fix_bugs_button

func get_dev_log_button() -> Button:
	return _dev_log_button

func get_ship_button() -> Button:
	return _ship_button

func get_theme_panels() -> Array[Control]:
	return [_stats_panel, _action_panel]

func get_corruptible_text_nodes() -> Array[Control]:
	return [_stat_guide, _action_title, _action_help]
