extends RefCounted
class_name RunHudController

const CardProgressUtils = preload("res://scripts/ui/card_progress_utils.gd")
const HudUiUtils = preload("res://scripts/ui/hud_ui_utils.gd")
const _S = preload("res://scripts/ui/ui_strings.gd")

var _game_state: Node = null

var _ambition_value: Label = null
var _instability_value: Label = null
var _runway_value: Label = null
var _features_value: Label = null
var _soul_value: Label = null
var _meta_value: Label = null

var _fix_bugs_button: Button = null
var _dev_log_button: Button = null
var _ship_button: Button = null

var _ambition_gauge: ProgressBar = null
var _instability_gauge: ProgressBar = null
var _runway_gauge: ProgressBar = null
var _soul_gauge: ProgressBar = null
var _soul_risk_label: Label = null
var _card_unlock_progress_label: Label = null
var _goldilocks_floor_marker: ColorRect = null
var _goldilocks_ceiling_marker: ColorRect = null

var _instability_visual: float = 0.0
var _instability_ceiling_pressure: float = 0.0
var _chosen_archetype_window: Array[int] = [15, 50]

func setup(
	game_state: Node,
	ambition_value: Label,
	instability_value: Label,
	runway_value: Label,
	features_value: Label,
	soul_value: Label,
	meta_value: Label,
	card_unlock_progress_label: Label,
	fix_bugs_button: Button,
	dev_log_button: Button,
	ship_button: Button,
	ambition_gauge: ProgressBar,
	instability_gauge: ProgressBar,
	runway_gauge: ProgressBar,
	soul_gauge: ProgressBar,
	soul_risk_label: Label,
	goldilocks_floor_marker: ColorRect,
	goldilocks_ceiling_marker: ColorRect,
) -> void:
	_game_state = game_state
	_ambition_value = ambition_value
	_instability_value = instability_value
	_runway_value = runway_value
	_features_value = features_value
	_soul_value = soul_value
	_meta_value = meta_value
	_card_unlock_progress_label = card_unlock_progress_label
	_fix_bugs_button = fix_bugs_button
	_dev_log_button = dev_log_button
	_ship_button = ship_button
	_ambition_gauge = ambition_gauge
	_instability_gauge = instability_gauge
	_runway_gauge = runway_gauge
	_soul_gauge = soul_gauge
	_soul_risk_label = soul_risk_label
	_goldilocks_floor_marker = goldilocks_floor_marker
	_goldilocks_ceiling_marker = goldilocks_ceiling_marker

func update_card_unlock_progress() -> void:
	if _card_unlock_progress_label == null or _game_state == null:
		return
	var all_cards: PackedStringArray = _game_state.get_all_card_ids()
	var unlocked_ids: PackedStringArray = _game_state.get_unlocked_card_ids()
	var total_count: int = all_cards.size()
	var unlocked_count: int = 0
	for card_id in unlocked_ids:
		if all_cards.has(card_id):
			unlocked_count += 1
	_card_unlock_progress_label.text = CardProgressUtils.build_progress_text(unlocked_count, total_count)

func on_state_changed(
	payload: StateSnapshotPayload,
	menu_active: bool,
	run_ended: bool,
	initial_runway_days: int,
	instability_ceiling_zone_size: int,
	update_ship_button_danger_cb: Callable,
) -> void:
	var ambition: int = payload.ambition
	var instability: int = payload.instability
	var runway_days: int = payload.runway_days
	var soul: int = payload.soul

	_ambition_value.text = "Ambition: %d" % ambition
	_instability_value.text = "Instability: %d" % instability
	_runway_value.text = "Runway Days: %d" % runway_days
	_features_value.text = "Features: %d" % payload.features_shipped
	_soul_value.text = "Soul: %d" % soul
	_meta_value.text = "Run %d of 4" % payload.current_run

	_instability_visual = clampf(float(instability) / 100.0, 0.0, 1.0)
	var ceiling: float = float(_chosen_archetype_window[1])
	_instability_ceiling_pressure = clampf(
		(float(instability) - (ceiling - float(instability_ceiling_zone_size))) / float(instability_ceiling_zone_size),
		0.0,
		1.0
	)

	var soul_label_color: Color
	if soul <= 3:
		soul_label_color = Color(1.0, 0.22, 0.22)
	elif soul <= 6:
		soul_label_color = Color(1.0, 0.75, 0.20)
	else:
		soul_label_color = Color(0.72, 0.96, 0.80)
	_soul_value.add_theme_color_override("font_color", soul_label_color)
	_update_soul_risk_label(soul)

	if _ambition_gauge != null:
		_ambition_gauge.value = float(clampi(ambition, 0, 100))
	if _instability_gauge != null:
		_instability_gauge.value = float(clampi(instability, 0, 100))
	if _runway_gauge != null:
		_runway_gauge.max_value = float(initial_runway_days)
		_runway_gauge.value = float(clampi(runway_days, 0, initial_runway_days))
	if _soul_gauge != null:
		_soul_gauge.value = float(soul)

	var runway_empty: bool = runway_days <= 0
	update_ship_button_danger_cb.call(runway_days, initial_runway_days)
	HudUiUtils.update_action_tooltips(_fix_bugs_button, _dev_log_button, _ship_button, runway_days, instability, soul)
	if not menu_active and not run_ended:
		_fix_bugs_button.disabled = runway_empty
		_dev_log_button.disabled = runway_empty
		if runway_empty:
			_ship_button.disabled = false
		else:
			var board_empty: bool = payload.features_shipped == 0
			_ship_button.disabled = board_empty
			if board_empty:
				_ship_button.tooltip_text = _S.get_string("tooltips", "ship_empty")

func on_archetype_chosen_visual(archetype: String) -> void:
	if _game_state == null:
		return
	var config: GameConfig = _game_state.get_game_config() as GameConfig
	if config == null:
		return
	var window: Array[int] = ArchetypeRules.get_goldilocks_window_for_archetype(config, archetype)
	_chosen_archetype_window = window
	_update_goldilocks_markers(window[0], window[1])

func snapshot_from_state() -> StateSnapshotPayload:
	var payload: StateSnapshotPayload = StateSnapshotPayload.new()
	if _game_state == null:
		return payload
	payload.ambition = _game_state.ambition
	payload.instability = _game_state.instability
	payload.runway_days = _game_state.runway_days
	payload.soul = _game_state.soul
	payload.features_shipped = _game_state.feature_board.size()
	payload.current_run = _game_state.current_run
	return payload

func apply_responsive_layout(action_panel: PanelContainer) -> void:
	if action_panel != null:
		action_panel.custom_minimum_size = Vector2.ZERO

func get_instability_visual() -> float:
	return _instability_visual

func get_instability_ceiling_pressure() -> float:
	return _instability_ceiling_pressure

func _update_goldilocks_markers(floor_val: int, ceiling_val: int) -> void:
	if _goldilocks_floor_marker == null or _goldilocks_ceiling_marker == null:
		return
	var visible_markers: bool = _game_state != null and _game_state.current_run > 1
	_goldilocks_floor_marker.visible = visible_markers
	_goldilocks_ceiling_marker.visible = visible_markers
	if not visible_markers:
		return
	_goldilocks_floor_marker.anchor_left = floor_val / 100.0
	_goldilocks_floor_marker.anchor_right = floor_val / 100.0
	_goldilocks_ceiling_marker.anchor_left = ceiling_val / 100.0
	_goldilocks_ceiling_marker.anchor_right = ceiling_val / 100.0

func _update_soul_risk_label(soul: int) -> void:
	if _soul_risk_label == null or _game_state == null:
		return
	if _game_state.current_run <= 1:
		_soul_risk_label.visible = false
		return
	var config: GameConfig = _game_state.get_game_config() as GameConfig
	var soul_floor: int = config.goldilocks_soul_min if config != null else 7
	var fix_cost: int = config.fix_bugs_soul_cost if config != null else 2
	if soul < soul_floor:
		_soul_risk_label.text = "Defining Game: lost"
		_soul_risk_label.add_theme_color_override("font_color", Color(1.0, 0.22, 0.22))
		_soul_risk_label.visible = true
	elif soul <= soul_floor + fix_cost - 1:
		_soul_risk_label.text = "Defining Game: at risk"
		_soul_risk_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.20))
		_soul_risk_label.visible = true
	else:
		_soul_risk_label.visible = false