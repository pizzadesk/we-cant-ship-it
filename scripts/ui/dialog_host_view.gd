extends Node
class_name DialogHostView

@onready var _review_dialog: AcceptDialog = %ReviewDialog
@onready var _end_run_dialog: ConfirmationDialog = %EndRunDialog
@onready var _dilemma_dialog: ConfirmationDialog = %DilemmaDialog
@onready var _draft_dialog: ConfirmationDialog = %DraftDialog
@onready var _ship_summary_dialog: ConfirmationDialog = %ShipSummaryDialog
@onready var _ship_summary_content: RichTextLabel = %ShipSummaryDialog.get_node("Content")
@onready var _jank_discovery_dialog: AcceptDialog = %JankDiscoveryDialog
@onready var _jank_discovery_content: RichTextLabel = %JankDiscoveryDialog.get_node("Content")
@onready var _gap_visualizer_dialog: AcceptDialog = %GapVisualizerDialog
@onready var _gap_visualizer_content: RichTextLabel = %GapVisualizerDialog.get_node("Content")
@onready var _cycle_legacy_dialog: AcceptDialog = %CycleLegacyDialog
@onready var _cycle_legacy_content: RichTextLabel = %CycleLegacyDialog.get_node("Content")
@onready var _previously_on_dialog: AcceptDialog = %PreviouslyOnDialog
@onready var _archetype_select_dialog: ConfirmationDialog = %ArchetypeSelectDialog
@onready var _reset_confirm_dialog: ConfirmationDialog = %ResetConfirmDialog
@onready var _quit_confirm_dialog: ConfirmationDialog = %QuitConfirmDialog

func get_review_dialog() -> AcceptDialog:
	return _review_dialog

func get_end_run_dialog() -> ConfirmationDialog:
	return _end_run_dialog

func get_dilemma_dialog() -> ConfirmationDialog:
	return _dilemma_dialog

func get_draft_dialog() -> ConfirmationDialog:
	return _draft_dialog

func get_ship_summary_dialog() -> ConfirmationDialog:
	return _ship_summary_dialog

func get_ship_summary_content() -> RichTextLabel:
	return _ship_summary_content

func get_jank_discovery_dialog() -> AcceptDialog:
	return _jank_discovery_dialog

func get_jank_discovery_content() -> RichTextLabel:
	return _jank_discovery_content

func get_gap_visualizer_dialog() -> AcceptDialog:
	return _gap_visualizer_dialog

func get_gap_visualizer_content() -> RichTextLabel:
	return _gap_visualizer_content

func get_cycle_legacy_dialog() -> AcceptDialog:
	return _cycle_legacy_dialog

func get_cycle_legacy_content() -> RichTextLabel:
	return _cycle_legacy_content

func get_previously_on_dialog() -> AcceptDialog:
	return _previously_on_dialog

func get_archetype_select_dialog() -> ConfirmationDialog:
	return _archetype_select_dialog

func get_reset_confirm_dialog() -> ConfirmationDialog:
	return _reset_confirm_dialog

func get_quit_confirm_dialog() -> ConfirmationDialog:
	return _quit_confirm_dialog

func get_scene_dialogs() -> Array[Window]:
	return [
		_review_dialog,
		_end_run_dialog,
		_dilemma_dialog,
		_draft_dialog,
		_ship_summary_dialog,
		_jank_discovery_dialog,
		_gap_visualizer_dialog,
		_cycle_legacy_dialog,
		_previously_on_dialog,
		_archetype_select_dialog,
		_reset_confirm_dialog,
		_quit_confirm_dialog,
	]
