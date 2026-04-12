extends VBoxContainer
class_name RunSidebarView

@onready var _stats_panel: PanelContainer = %StatsPanel
@onready var _action_panel: PanelContainer = %ActionPanel
@onready var _ambition_value: Label = %AmbitionValue
@onready var _instability_value: Label = %InstabilityValue
@onready var _runway_value: Label = %RunwayValue
@onready var _features_value: Label = %FeaturesValue
@onready var _soul_value: Label = %SoulValue
@onready var _meta_value: Label = %MetaValue
@onready var _ambition_gauge: ProgressBar = %AmbitionGauge
@onready var _instability_gauge: ProgressBar = %InstabilityGauge
@onready var _runway_gauge: ProgressBar = %RunwayGauge
@onready var _soul_gauge: ProgressBar = %SoulGauge
@onready var _soul_risk_label: Label = %SoulRiskLabel
@onready var _goldilocks_floor_marker: ColorRect = %GoldilocksFloorMarker
@onready var _goldilocks_ceiling_marker: ColorRect = %GoldilocksCeilingMarker
@onready var _stat_guide: Label = %StatGuide
@onready var _action_title: Label = %ActionTitle
@onready var _action_help: Label = %ActionHelp
@onready var _fix_bugs_button: Button = %FixBugsButton
@onready var _dev_log_button: Button = %DevLogButton
@onready var _ship_button: Button = %ShipButton

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

func get_instability_gauge() -> ProgressBar:
	return _instability_gauge

func get_runway_gauge() -> ProgressBar:
	return _runway_gauge

func get_soul_gauge() -> ProgressBar:
	return _soul_gauge

func get_soul_risk_label() -> Label:
	return _soul_risk_label

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
