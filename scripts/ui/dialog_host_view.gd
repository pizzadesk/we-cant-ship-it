extends CanvasLayer
class_name DialogHostView

const ChoiceOverlay = preload("res://scripts/ui/overlays/choice_overlay.gd")
const EventOverlay = preload("res://scripts/ui/overlays/event_overlay.gd")
const ConfirmOverlay = preload("res://scripts/ui/overlays/confirm_overlay.gd")

@onready var _choice_overlay: ChoiceOverlay = %ChoiceOverlay
@onready var _archetype_overlay: ChoiceOverlay = %ArchetypeOverlay
@onready var _review_overlay: EventOverlay = %ReviewOverlay
@onready var _jank_discovery_overlay: EventOverlay = %JankDiscoveryOverlay
@onready var _gap_visualizer_overlay: EventOverlay = %GapVisualizerOverlay
@onready var _cycle_legacy_overlay: EventOverlay = %CycleLegacyOverlay
@onready var _ship_summary_overlay: EventOverlay = %ShipSummaryOverlay
@onready var _previously_on_overlay: EventOverlay = %PreviouslyOnOverlay
@onready var _end_run_overlay: ConfirmOverlay = %EndRunOverlay
@onready var _reset_confirm_overlay: ConfirmOverlay = %ResetConfirmOverlay
@onready var _quit_confirm_overlay: ConfirmOverlay = %QuitConfirmOverlay

func get_choice_overlay() -> ChoiceOverlay:
	return _choice_overlay

func get_archetype_overlay() -> ChoiceOverlay:
	return _archetype_overlay

func get_review_overlay() -> EventOverlay:
	return _review_overlay

func get_jank_discovery_overlay() -> EventOverlay:
	return _jank_discovery_overlay

func get_gap_visualizer_overlay() -> EventOverlay:
	return _gap_visualizer_overlay

func get_cycle_legacy_overlay() -> EventOverlay:
	return _cycle_legacy_overlay

func get_ship_summary_overlay() -> EventOverlay:
	return _ship_summary_overlay

func get_previously_on_overlay() -> EventOverlay:
	return _previously_on_overlay

func get_end_run_overlay() -> ConfirmOverlay:
	return _end_run_overlay

func get_reset_confirm_overlay() -> ConfirmOverlay:
	return _reset_confirm_overlay

func get_quit_confirm_overlay() -> ConfirmOverlay:
	return _quit_confirm_overlay
