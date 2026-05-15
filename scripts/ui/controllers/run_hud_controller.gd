extends RefCounted
class_name RunHudController

const CardProgressUtils = preload("res://scripts/ui/card_progress_utils.gd")
const HudPresentation = preload("res://scripts/ui/presenters/hud_presentation.gd")
const HudUiUtils = preload("res://scripts/ui/hud_ui_utils.gd")
const _S = preload("res://scripts/ui/ui_strings.gd")

var _game_state: Node = null
var _sidebar_view: RunSidebarView = null

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
var _ambition_status: Label = null
var _ambition_delta: Label = null
var _instability_gauge: ProgressBar = null
var _instability_target_band: ColorRect = null
var _instability_status: Label = null
var _instability_delta: Label = null
var _runway_cells_row: HBoxContainer = null
var _soul_gauge: ProgressBar = null
var _soul_risk_label: Label = null
var _soul_delta: Label = null
var _card_unlock_progress_label: Label = null
var _goldilocks_floor_marker: ColorRect = null
var _goldilocks_ceiling_marker: ColorRect = null
var _stat_guide: Label = null
var _action_help: Label = null

var _instability_visual: float = 0.0
var _instability_ceiling_pressure: float = 0.0
var _chosen_archetype_window: Array[int] = [15, 50]
var _prev_ambition: int = -9999
var _prev_instability: int = -9999
var _prev_soul: int = -9999
var _instability_in_window: bool = false
var _soul_danger_state: int = 0  # 0=safe, 1=at-risk, 2=lost
var _prev_runway_day_count: int = -1
var _ambition_delta_tween: Tween = null
var _instability_delta_tween: Tween = null
var _soul_delta_tween: Tween = null
var _cell_pulse_tweens: Dictionary = {}

func setup(
	game_state: Node,
	sidebar_view: RunSidebarView,
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
	ambition_status: Label,
	ambition_delta: Label,
	instability_gauge: ProgressBar,
	instability_target_band: ColorRect,
	instability_status: Label,
	instability_delta: Label,
	runway_cells_row: HBoxContainer,
	soul_gauge: ProgressBar,
	soul_risk_label: Label,
	soul_delta: Label,
	goldilocks_floor_marker: ColorRect,
	goldilocks_ceiling_marker: ColorRect,
	stat_guide: Label,
	action_help: Label,
) -> void:
	_game_state = game_state
	_sidebar_view = sidebar_view
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
	_ambition_status = ambition_status
	_ambition_delta = ambition_delta
	_instability_gauge = instability_gauge
	_instability_target_band = instability_target_band
	_instability_status = instability_status
	_instability_delta = instability_delta
	_runway_cells_row = runway_cells_row
	_soul_gauge = soul_gauge
	_soul_risk_label = soul_risk_label
	_soul_delta = soul_delta
	_goldilocks_floor_marker = goldilocks_floor_marker
	_goldilocks_ceiling_marker = goldilocks_ceiling_marker
	_stat_guide = stat_guide
	_action_help = action_help

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
	var config: GameConfig = _game_state.get_game_config() as GameConfig if _game_state != null else null
	var ambition_target: int = config.goldilocks_ambition_min if config != null else 25
	var soul_target: int = config.goldilocks_soul_min if config != null else 7
	var archetype_label: String = _get_archetype_display_name()
	var instability_floor: int = _chosen_archetype_window[0]
	var instability_ceiling: int = _chosen_archetype_window[1]
	var instability_in_range: bool = instability >= instability_floor and instability <= instability_ceiling

	var hud := HudPresentation.build(
		ambition, ambition_target, instability, soul, soul_target,
		_build_action_readout(payload, ambition_target, soul_target, instability_floor, instability_ceiling)
	)

	_sidebar_view.update_stats(ambition, ambition_target, instability, soul, soul_target)
	_instability_value.text = "%d | %d-%d" % [instability, instability_floor, instability_ceiling]
	_runway_value.text = "%d days" % runway_days
	_features_value.text = "%d cards" % payload.features_shipped
	_meta_value.text = _build_meta_label(payload.current_run, archetype_label)
	_update_threshold_status_labels(payload.current_run, ambition, ambition_target, instability, instability_floor, instability_ceiling)
	var thermometer_ratio: float = clampf(float(instability) / float(instability_ceiling) if instability_ceiling > 0 else 0.0, 0.0, 1.0)
	_sidebar_view.update_stat_colors(hud.ambition_met, thermometer_ratio)
	_instability_value.add_theme_color_override(
		"font_color",
		Color(0.400, 0.950, 0.400) if instability_in_range else (Color(1.0, 0.75, 0.20) if instability < instability_floor else Color(1.0, 0.32, 0.28))
	)
	_update_summary_labels(payload, ambition_target, soul_target, instability_floor, instability_ceiling, hud.action_label)

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
		soul_label_color = Color(0.400, 0.950, 0.400)
	_soul_value.add_theme_color_override("font_color", soul_label_color)
	_update_soul_risk_label(soul)

	_update_runway_cells(runway_days, initial_runway_days)
	if _soul_gauge != null:
		_soul_gauge.value = float(soul)

	_fire_stat_deltas(ambition, instability, soul)
	_check_zone_entry(instability, instability_floor, instability_ceiling, payload.current_run)
	var soul_floor: int = config.goldilocks_soul_min if config != null else 7
	_check_soul_danger(soul, soul_floor)

	var runway_empty: bool = runway_days <= 0
	if _card_unlock_progress_label != null:
		_card_unlock_progress_label.visible = run_ended or menu_active
	update_ship_button_danger_cb.call(runway_days, initial_runway_days)
	HudUiUtils.update_action_tooltips(_fix_bugs_button, _dev_log_button, _ship_button, runway_days, instability, soul)
	_update_ship_timing_tooltip(runway_days, instability)
	_apply_emergency_action_hints(payload, instability_floor, instability_ceiling, soul_target, ambition_target, runway_days)
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
	if _instability_target_band != null:
		_instability_target_band.visible = visible_markers
	_goldilocks_floor_marker.visible = visible_markers
	_goldilocks_ceiling_marker.visible = visible_markers
	if not visible_markers:
		return
	if _instability_target_band != null:
		_instability_target_band.anchor_left = floor_val / 100.0
		_instability_target_band.anchor_right = ceiling_val / 100.0
		_instability_target_band.offset_left = 0.0
		_instability_target_band.offset_right = 0.0
	_goldilocks_floor_marker.anchor_left = floor_val / 100.0
	_goldilocks_floor_marker.anchor_right = floor_val / 100.0
	_goldilocks_floor_marker.offset_left = -1.0
	_goldilocks_floor_marker.offset_right = 1.0
	_goldilocks_ceiling_marker.anchor_left = ceiling_val / 100.0
	_goldilocks_ceiling_marker.anchor_right = ceiling_val / 100.0
	_goldilocks_ceiling_marker.offset_left = -1.0
	_goldilocks_ceiling_marker.offset_right = 1.0

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
		_soul_risk_label.text = "Defining Game: out of reach"
		_soul_risk_label.add_theme_color_override("font_color", Color(1.0, 0.22, 0.22))
		_soul_risk_label.visible = true
	elif soul <= soul_floor + fix_cost - 1:
		_soul_risk_label.text = "Defining Game: at risk"
		_soul_risk_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.20))
		_soul_risk_label.visible = true
	else:
		_soul_risk_label.text = "Defining Game: safe"
		_soul_risk_label.add_theme_color_override("font_color", Color(0.400, 0.950, 0.400))
		_soul_risk_label.visible = true

func _update_threshold_status_labels(
	current_run: int,
	ambition: int,
	ambition_target: int,
	instability: int,
	instability_floor: int,
	instability_ceiling: int,
) -> void:
	if _ambition_status != null:
		if current_run <= 1:
			_ambition_status.text = "Finding your voice"
			_ambition_status.add_theme_color_override("font_color", Color(0.600, 0.900, 0.600))
		elif ambition < ambition_target:
			_ambition_status.text = "Need +%d" % (ambition_target - ambition)
			_ambition_status.add_theme_color_override("font_color", Color(1.0, 0.75, 0.20))
		else:
			_ambition_status.text = "On target"
			_ambition_status.add_theme_color_override("font_color", Color(0.400, 0.950, 0.400))
	if _instability_status != null:
		if current_run <= 1:
			_instability_status.text = "Finding your voice"
			_instability_status.add_theme_color_override("font_color", Color(0.600, 0.900, 0.600))
		elif instability < instability_floor:
			_instability_status.text = "Too low by %d" % (instability_floor - instability)
			_instability_status.add_theme_color_override("font_color", Color(1.0, 0.75, 0.20))
		elif instability > instability_ceiling:
			_instability_status.text = "Too high by %d" % (instability - instability_ceiling)
			_instability_status.add_theme_color_override("font_color", Color(1.0, 0.32, 0.28))
		else:
			_instability_status.text = "In range"
			_instability_status.add_theme_color_override("font_color", Color(0.400, 0.950, 0.400))

func _update_summary_labels(
	payload: StateSnapshotPayload,
	ambition_target: int,
	soul_target: int,
	instability_floor: int,
	instability_ceiling: int,
	action_label: String,
) -> void:
	if _stat_guide != null:
		if payload.current_run <= 1:
			_stat_guide.text = "Finding your voice — Defining Game is locked this run."
		else:
			var amb_ok: bool = payload.ambition >= ambition_target
			var inst_ok: bool = payload.instability >= instability_floor and payload.instability <= instability_ceiling
			var soul_ok: bool = payload.soul >= soul_target
			var met: int = (1 if amb_ok else 0) + (1 if inst_ok else 0) + (1 if soul_ok else 0)
			match met:
				3:
					_stat_guide.text = "Defining Game: all conditions met"
				2:
					_stat_guide.text = "Defining Game: 2 of 3 conditions met"
				1:
					_stat_guide.text = "Defining Game: 1 condition met"
				_:
					_stat_guide.text = "Defining Game: no conditions met"
	if _action_help != null:
		_action_help.text = action_label

func _build_action_readout(
	payload: StateSnapshotPayload,
	ambition_target: int,
	soul_target: int,
	instability_floor: int,
	instability_ceiling: int,
) -> String:
	if payload.runway_days <= 0:
		return "The runway is gone. Only shipping remains."
	if payload.features_shipped <= 0:
		return "Place at least one feature to start shaping the game's identity."

	var jank_state: Dictionary = {}
	if _game_state != null and _game_state.has_method("get_jank_pursuit_state"):
		jank_state = _game_state.get_jank_pursuit_state()
	var jank_stage: String = String(jank_state.get("stage", "idle"))
	var jank_hint: String = String(jank_state.get("display_body", ""))

	if payload.current_run <= 1:
		if jank_stage == "locked":
			return "You found a signature. Decide whether to stabilize it or keep feeding the beautiful mistake."
		if jank_stage == "prospect" and not jank_hint.is_empty():
			return "%s Decide whether to complete it or let the run settle." % jank_hint
		return "Chase a signature, not perfection. This run is about discovering what the studio makes under pressure."

	if payload.instability > instability_ceiling:
		return "Instability is too high. Use Fix Bugs or ship the mess on purpose before the run falls apart."
	if payload.soul < soul_target:
		return "Soul is too low. Protect sincerity now or accept that Defining Game is out of reach."
	if payload.ambition < ambition_target:
		if jank_stage == "prospect" and not jank_hint.is_empty():
			return "%s Completing it adds Instability — weigh that against the Ambition gap." % jank_hint
		return "You need more Ambition. Add scope unless Instability is already too high to afford it."
	if payload.instability < instability_floor:
		if jank_stage == "prospect" and not jank_hint.is_empty():
			return "%s Completing it may push Instability into the Defining Game range." % jank_hint
		return "Instability is too low for Defining Game. Safe additions may keep the build clean and cost it its character."
	if jank_stage == "prospect" and not jank_hint.is_empty():
		return "%s Completing it may push Instability above the ceiling." % jank_hint
	if jank_stage == "locked":
		return "In Defining Game range with a locked signature. Ship now or risk one more improvement."
	return "In range. Ship now if the run feels complete, or push harder if there is more jank to find."

func _build_meta_label(run: int, archetype_label: String) -> String:
	var arch_part: String = " • %s" % archetype_label if not archetype_label.is_empty() else ""
	var context_part: String
	match run:
		1:
			context_part = " • Tutorial"
		2:
			context_part = " • First Attempt"
		3:
			context_part = " • Second Attempt"
		4:
			context_part = " • Final Attempt"
		_:
			context_part = ""
	return "Run %d of 4%s%s" % [run, context_part, arch_part]

func _get_archetype_display_name() -> String:
	if _game_state == null or not _game_state.has_method("get_chosen_archetype"):
		return ""
	match String(_game_state.get_chosen_archetype()):
		"rpg":
			return "RPG"
		"shooter":
			return "Shooter"
		"action_adventure":
			return "Action-Adventure"
		_:
			return ""

func _update_ship_timing_tooltip(runway_days: int, instability: int) -> void:
	if _ship_button == null or _game_state == null:
		return
	var config: GameConfig = _game_state.get_game_config() as GameConfig
	if config == null:
		return
	var timing_line: String = _get_ship_timing_line(runway_days, instability, config)
	if timing_line.is_empty():
		return
	_ship_button.tooltip_text = _ship_button.tooltip_text + "\n\n" + timing_line

func _get_ship_timing_line(runway_days: int, instability: int, config: GameConfig) -> String:
	if runway_days <= config.panic_ship_runway_threshold:
		return _S.get_string("tooltips", "ship_timing_panic")
	if runway_days >= config.too_early_runway_threshold:
		return _S.get_string("tooltips", "ship_timing_too_early")
	var is_sweet: bool = (
		runway_days >= config.sweet_spot_runway_min
		and runway_days <= config.sweet_spot_runway_max
		and instability >= config.sweet_spot_instability_min
		and instability <= config.sweet_spot_instability_max
	)
	if is_sweet:
		return _S.get_string("tooltips", "ship_timing_sweet_spot")
	return ""

# -- F4: Runway day cells --
func _update_runway_cells(days: int, max_days: int) -> void:
	if _runway_cells_row == null or max_days <= 0:
		return
	var children: Array[Node] = _runway_cells_row.get_children()
	var need_rebuild: bool = children.size() != max_days
	if need_rebuild:
		for t: Tween in _cell_pulse_tweens.values():
			if t != null and t.is_valid():
				t.kill()
		_cell_pulse_tweens.clear()
		for child in children:
			child.queue_free()
		for i: int in range(max_days):
			var cell: ColorRect = ColorRect.new()
			cell.custom_minimum_size = _sidebar_view.get_runway_cell_size()
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_runway_cells_row.add_child(cell)
	var remaining: int = clampi(days, 0, max_days)
	if not need_rebuild and days == _prev_runway_day_count:
		return
	_prev_runway_day_count = days
	var urgent_threshold: int = 2
	var amber_threshold: int = 5
	for i: int in range(max_days):
		var cell_node: Node = _runway_cells_row.get_child(i)
		if cell_node is not ColorRect:
			continue
		var cell: ColorRect = cell_node as ColorRect
		var day_index: int = max_days - i
		if day_index > remaining:
			cell.color = Color(0.039, 0.078, 0.039, 0.6)
		elif day_index <= urgent_threshold:
			cell.color = Color(0.95, 0.22, 0.15, 0.95)
			_animate_cell_pulse(cell, day_index)
		elif day_index <= amber_threshold:
			cell.color = Color(0.95, 0.65, 0.18, 0.90)
		else:
			cell.color = Color(0.200, 0.800, 0.200, 0.85)

func _animate_cell_pulse(cell: ColorRect, _day_index: int) -> void:
	if not cell.is_inside_tree():
		return
	var id: int = cell.get_instance_id()
	var existing: Tween = _cell_pulse_tweens.get(id, null) as Tween
	if existing != null and existing.is_valid():
		return
	var t: Tween = cell.create_tween()
	t.set_loops()
	t.set_trans(Tween.TRANS_SINE)
	t.set_ease(Tween.EASE_IN_OUT)
	t.tween_property(cell, "modulate:a", 0.55, 0.5)
	t.tween_property(cell, "modulate:a", 1.0, 0.5)
	_cell_pulse_tweens[id] = t

# -- F2: Floating stat delta labels --
func _fire_stat_deltas(ambition: int, instability: int, soul: int) -> void:
	if _prev_ambition != -9999 and ambition != _prev_ambition:
		_ambition_delta_tween = _animate_delta(_ambition_delta, ambition - _prev_ambition, Color(0.400, 0.950, 0.400), _ambition_delta_tween)
	if _prev_instability != -9999 and instability != _prev_instability:
		_instability_delta_tween = _animate_delta(_instability_delta, instability - _prev_instability, Color(1.0, 0.72, 0.42), _instability_delta_tween)
	if _prev_soul != -9999 and soul != _prev_soul:
		_soul_delta_tween = _animate_delta(_soul_delta, soul - _prev_soul, Color(0.700, 0.600, 1.000), _soul_delta_tween)
	_prev_ambition = ambition
	_prev_instability = instability
	_prev_soul = soul

func _animate_delta(label: Label, delta: int, positive_color: Color, prev_tween: Tween) -> Tween:
	if label == null:
		return null
	if prev_tween != null and prev_tween.is_valid():
		prev_tween.kill()
	label.text = "%+d" % delta
	var col: Color = positive_color if delta > 0 else Color(1.0, 0.38, 0.38)
	label.add_theme_color_override("font_color", Color(col.r, col.g, col.b, 1.0))
	var t: Tween = label.create_tween()
	t.set_trans(Tween.TRANS_CUBIC)
	t.set_ease(Tween.EASE_OUT)
	t.tween_property(label, "theme_override_colors/font_color:a", 0.0, 0.9).set_delay(0.35)
	return t

# -- F2: Zone-entry border pulse on instability gauge --
func _check_zone_entry(instability: int, floor_val: int, ceiling_val: int, current_run: int) -> void:
	if _instability_gauge == null or current_run <= 1:
		return
	var now_in: bool = instability >= floor_val and instability <= ceiling_val
	if now_in == _instability_in_window:
		return
	_instability_in_window = now_in
	var flash_col: Color = Color(0.400, 0.950, 0.400, 1.0) if now_in else Color(1.0, 0.65, 0.20, 1.0)
	var base_col: Color = _instability_gauge.modulate
	var t: Tween = _instability_gauge.create_tween()
	t.set_trans(Tween.TRANS_CUBIC)
	t.set_ease(Tween.EASE_OUT)
	t.tween_property(_instability_gauge, "modulate", flash_col, 0.12)
	t.tween_property(_instability_gauge, "modulate", base_col, 0.30)

# -- F2: Soul danger border (gauge modulate flash) --
func _check_soul_danger(soul: int, soul_floor: int) -> void:
	if _soul_gauge == null:
		return
	var new_state: int
	if soul < soul_floor:
		new_state = 2
	elif soul <= soul_floor + 1:
		new_state = 1
	else:
		new_state = 0
	if new_state == _soul_danger_state:
		return
	_soul_danger_state = new_state
	var target_color: Color
	match new_state:
		2:
			target_color = Color(1.0, 0.22, 0.22, 1.0)
		1:
			target_color = Color(1.0, 0.75, 0.20, 1.0)
		_:
			target_color = Color(1.0, 0.6, 0.8, 1.0)
	var t: Tween = _soul_gauge.create_tween()
	t.set_trans(Tween.TRANS_CUBIC)
	t.set_ease(Tween.EASE_OUT)
	t.tween_property(_soul_gauge, "modulate", target_color, 0.18)
	t.tween_property(_soul_gauge, "modulate", Color(1.0, 0.6, 0.8, 1.0), 0.45)

# -- F5: Action button feedback callables --
func animate_fix_bugs_feedback() -> void:
	if _instability_gauge == null:
		return
	var t: Tween = _instability_gauge.create_tween()
	t.set_trans(Tween.TRANS_CUBIC)
	t.set_ease(Tween.EASE_OUT)
	t.tween_property(_instability_gauge, "scale", Vector2(1.0, 0.85), 0.08)
	t.tween_property(_instability_gauge, "scale", Vector2.ONE, 0.32)
	if _instability_delta != null:
		_instability_delta_tween = _animate_delta(_instability_delta, -10, Color(0.400, 0.950, 0.400), _instability_delta_tween)

func _apply_emergency_action_hints(
	payload: StateSnapshotPayload,
	instability_floor: int,
	instability_ceiling: int,
	soul_target: int,
	ambition_target: int,
	runway_days: int,
) -> void:
	if payload.current_run <= 1 or runway_days <= 0:
		return
	var instability: int = payload.instability
	var soul: int = payload.soul
	var ambition: int = payload.ambition
	if _fix_bugs_button != null and instability > instability_ceiling:
		_fix_bugs_button.tooltip_text = "Instability is above the ceiling. The team is already overwhelmed. This is the only thing that helps."
	if _dev_log_button != null and soul <= 3:
		_dev_log_button.tooltip_text = "Soul is critically low. The log is not enough, but it is something."
	if _ship_button != null:
		var all_met: bool = (
			ambition >= ambition_target
			and instability >= instability_floor
			and instability <= instability_ceiling
			and soul >= soul_target
		)
		if all_met:
			_ship_button.tooltip_text = "Ambition is there. Instability is in window. Soul is present. This is the run."
		elif runway_days == 1:
			_ship_button.tooltip_text = "One day remains. This is the version that ships, ready or not."

func animate_dev_log_feedback() -> void:
	if _soul_gauge == null:
		return
	var base_mod: Color = _soul_gauge.modulate
	var warm: Color = Color(1.4, 1.1, 0.9, 1.0)
	var t: Tween = _soul_gauge.create_tween()
	t.set_trans(Tween.TRANS_SINE)
	t.set_ease(Tween.EASE_IN_OUT)
	t.tween_property(_soul_gauge, "modulate", warm, 0.18)
	t.tween_property(_soul_gauge, "modulate", base_mod, 0.35)
	if _soul_delta != null:
		_soul_delta_tween = _animate_delta(_soul_delta, 1, Color(1.0, 0.6, 0.8), _soul_delta_tween)