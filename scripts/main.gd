extends Control

const CARD_WIDGET_SCENE: PackedScene = preload("res://scenes/ui/feature_card_widget.tscn")
const BacklogPanelViewType = preload("res://scripts/ui/backlog_panel_view.gd")
const DialogHostViewType = preload("res://scripts/ui/dialog_host_view.gd")
const HeaderBarViewType = preload("res://scripts/ui/header_bar_view.gd")
const MainMenuOverlayViewType = preload("res://scripts/ui/main_menu_overlay_view.gd")
const RunSidebarViewType = preload("res://scripts/ui/run_sidebar_view.gd")
const ConfirmOverlay = preload("res://scripts/ui/overlays/confirm_overlay.gd")
const CARDS_PATH: String = "res://data/cards"
const CUSTOM_CARDS_PATH: String = "res://data/custom_cards"
const DAILY_VISIBLE_CARDS: int = 3
const SYNERGY_TOAST_DURATION: float = 2.5
const _S = preload("res://scripts/ui/ui_strings.gd")
const JANK_PROSPECT_TOAST_DURATION: float = 4.0
const JANK_LOCKED_TOAST_DURATION: float = 4.4
const WOBBLE_CLAMP: float = 10.0
# How many instability points below the archetype ceiling define the danger zone.
# Within this zone wobble intensifies relative to the archetype window edge, so a
# Shooter run (ceiling 42) feels more chaotic at Instability 38 than an RPG run
# (ceiling 55) does at the same value. Adjust to widen or narrow the warning zone.
const INSTABILITY_CEILING_ZONE_SIZE: int = 12
const SCANLINE_SHADER: Shader = preload("res://shaders/scanline.gdshader")

# HUD layout references
@onready var _header_view: HeaderBarViewType = $"%HeaderPanel"
@onready var _backlog_view: BacklogPanelViewType = $"%LeftColumn"
@onready var _run_sidebar_view: RunSidebarViewType = $"%RightColumn"

# Stat display labels
@onready var _ambition_value: Label = _run_sidebar_view.get_ambition_value()
@onready var _instability_value: Label = _run_sidebar_view.get_instability_value()
@onready var _runway_value: Label = _run_sidebar_view.get_runway_value()
@onready var _features_value: Label = _run_sidebar_view.get_features_value()
@onready var _soul_value: Label = _run_sidebar_view.get_soul_value()
@onready var _meta_value: Label = _run_sidebar_view.get_meta_value()

# Card and board references
@onready var _card_list: VBoxContainer = _backlog_view.get_card_list()
@onready var _feature_board: FeatureBoard = $"%FeatureBoard"

# Action buttons
@onready var _fix_bugs_button: Button = _run_sidebar_view.get_fix_bugs_button()
@onready var _dev_log_button: Button = _run_sidebar_view.get_dev_log_button()
@onready var _ship_button: Button = _run_sidebar_view.get_ship_button()

# Dialog host and main menu
@onready var _dialog_host_view: DialogHostViewType = $"%DialogHost"
@onready var _main_menu_view: MainMenuOverlayViewType = $"%MainMenuLayer"
@onready var _start_run_button: Button = _main_menu_view.get_start_run_button()
@onready var _reset_game_button: Button = _main_menu_view.get_reset_game_button()
@onready var _menu_subtitle: Label = _main_menu_view.get_menu_subtitle()
@onready var _quit_button: Button = _header_view.get_quit_button()

# Visual corruption
@onready var _scanline_overlay: ColorRect = $"%ScanlineOverlay"
@onready var _jank_tint: ColorRect = $"%JankTint"
@onready var _wobble_root: MarginContainer = $"%RootMargin"
@onready var _action_panel: PanelContainer = _run_sidebar_view.get_action_panel()
@onready var _crunch_timer: Timer = $"%CrunchTimer"

# Autoload references
@onready var _game_state: Node = AppState
@onready var _event_bus: Node = GameEvents

var _ui_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _menu_active: bool = false

var _choice_overlay: ChoiceOverlay = null
var _archetype_overlay: ChoiceOverlay = null
var _review_overlay: EventOverlay = null
var _jank_discovery_overlay: EventOverlay = null
var _gap_visualizer_overlay: EventOverlay = null
var _cycle_legacy_overlay: EventOverlay = null
var _ship_summary_overlay: EventOverlay = null
var _previously_on_overlay: EventOverlay = null
var _end_run_overlay: ConfirmOverlay = null
var _reset_confirm_overlay: ConfirmOverlay = null
var _quit_confirm_overlay: ConfirmOverlay = null

var _runway_narrative_checkpoints: Dictionary = {}
var _backlog_footer_state: String = ""
const _BACKLOG_FOOTER_DEFAULT: String = "Watch for risky fits, off-archetype pulls, and cards that feel like they want each other."

var _hud_controller: RunHudController = RunHudController.new()
var _backlog_controller: BacklogController = BacklogController.new()
var _choice_flow_controller: ChoiceFlowController = ChoiceFlowController.new()
var _post_ship_flow_controller: PostShipFlowController = PostShipFlowController.new()
var _main_menu_controller: MainMenuController = MainMenuController.new()
var _jank_fx_controller: JankFxController = JankFxController.new()

# -- Scene Lifecycle --
func _ready() -> void:
	_ui_rng.randomize()
	_setup_dialogs()
	_setup_controllers()
	_wire_events()
	_show_main_menu()
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_hud_controller.apply_responsive_layout(_action_panel)
	set_process(true)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Preserve cycle state as-is on quit. Current run will restart next launch;
		# completed runs from prior ships are already saved via complete_run().
		if _game_state != null:
			_game_state.save_cycle_state()
		get_tree().quit()

# -- Setup: Dialogs and HUD --
func _setup_dialogs() -> void:
	_choice_overlay = _dialog_host_view.get_choice_overlay()
	_archetype_overlay = _dialog_host_view.get_archetype_overlay()
	_review_overlay = _dialog_host_view.get_review_overlay()
	_jank_discovery_overlay = _dialog_host_view.get_jank_discovery_overlay()
	_gap_visualizer_overlay = _dialog_host_view.get_gap_visualizer_overlay()
	_cycle_legacy_overlay = _dialog_host_view.get_cycle_legacy_overlay()
	_ship_summary_overlay = _dialog_host_view.get_ship_summary_overlay()
	_previously_on_overlay = _dialog_host_view.get_previously_on_overlay()
	_end_run_overlay = _dialog_host_view.get_end_run_overlay()
	_reset_confirm_overlay = _dialog_host_view.get_reset_confirm_overlay()
	_quit_confirm_overlay = _dialog_host_view.get_quit_confirm_overlay()

func _setup_controllers() -> void:
	_hud_controller.setup(
		_game_state,
		_run_sidebar_view,
		_ambition_value,
		_instability_value,
		_runway_value,
		_features_value,
		_soul_value,
		_meta_value,
		_backlog_view.get_card_unlock_progress_label(),
		_fix_bugs_button,
		_dev_log_button,
		_ship_button,
		_run_sidebar_view.get_ambition_gauge(),
		_run_sidebar_view.get_ambition_status(),
		_run_sidebar_view.get_ambition_delta(),
		_run_sidebar_view.get_instability_gauge(),
		_run_sidebar_view.get_instability_target_band(),
		_run_sidebar_view.get_instability_status(),
		_run_sidebar_view.get_instability_delta(),
		_run_sidebar_view.get_runway_cells_row(),
		_run_sidebar_view.get_soul_gauge(),
		_run_sidebar_view.get_soul_risk_label(),
		_run_sidebar_view.get_soul_delta(),
		_run_sidebar_view.get_goldilocks_floor_marker(),
		_run_sidebar_view.get_goldilocks_ceiling_marker(),
		_run_sidebar_view.get_stat_guide(),
		_run_sidebar_view.get_action_help()
	)
	_backlog_controller.setup(
		_game_state,
		_card_list,
		CARD_WIDGET_SCENE,
		CARDS_PATH,
		CUSTOM_CARDS_PATH,
		DAILY_VISIBLE_CARDS,
		_ui_rng
	)
	_choice_flow_controller.setup(
		_game_state,
		_choice_overlay,
		Callable(self, "_append_log")
	)
	_post_ship_flow_controller.setup(
		self,
		_game_state,
		_review_overlay,
		_review_overlay.content,
		_gap_visualizer_overlay,
		_gap_visualizer_overlay.content,
		_jank_discovery_overlay,
		_jank_discovery_overlay.content,
		_cycle_legacy_overlay,
		_cycle_legacy_overlay.content,
		_end_run_overlay,
		_ship_summary_overlay,
		Callable(_post_ship_flow_controller, "on_ship_confirmed"),
		Callable(_post_ship_flow_controller, "on_ship_canceled"),
		Callable(self, "_on_ship_run_ended"),
		Callable(_hud_controller, "update_card_unlock_progress")
	)
	_main_menu_controller.setup(
		_game_state,
		_main_menu_view,
		_start_run_button,
		_reset_game_button,
		_menu_subtitle,
		_main_menu_view.get_cycle_track(),
		_archetype_overlay,
		_previously_on_overlay
	)
	_jank_fx_controller.setup(
		self,
		_ui_rng,
		SCANLINE_SHADER,
		_scanline_overlay,
		_jank_tint,
		_wobble_root,
		_ship_button
	)
	var janky_panels: Array[Control] = []
	janky_panels.append_array(_header_view.get_theme_panels())
	janky_panels.append_array(_backlog_view.get_theme_panels())
	janky_panels.append_array(_run_sidebar_view.get_theme_panels())
	_jank_fx_controller.apply_janky_ui_theme(janky_panels)
	var corruptible_ui: Array[Control] = [
		_fix_bugs_button,
		_dev_log_button,
		_ship_button,
	]
	corruptible_ui.append_array(_header_view.get_corruptible_text_nodes())
	corruptible_ui.append_array(_backlog_view.get_corruptible_text_nodes())
	corruptible_ui.append_array(_feature_board.get_corruptible_text_nodes())
	corruptible_ui.append_array(_run_sidebar_view.get_corruptible_text_nodes())
	corruptible_ui.append_array(_main_menu_view.get_corruptible_text_nodes())
	_jank_fx_controller.cache_corruptible_ui_text(corruptible_ui)
	_jank_fx_controller.setup_synergy_toast()

func _on_ship_run_ended() -> void:
	_fix_bugs_button.disabled = true
	_dev_log_button.disabled = true
	_ship_button.disabled = true
	_crunch_timer.stop()

func _wire_events() -> void:
	if _feature_board.has_signal("card_dropped"):
		_feature_board.card_dropped.connect(_on_card_dropped)
	_fix_bugs_button.pressed.connect(_on_fix_bugs_pressed)
	_dev_log_button.pressed.connect(_on_dev_log_pressed)
	_ship_button.pressed.connect(_on_ship_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_crunch_timer.timeout.connect(_on_crunch_timer_timeout)
	_start_run_button.pressed.connect(_on_start_run_pressed)
	_reset_game_button.pressed.connect(_on_reset_game_button_pressed)

	if _end_run_overlay != null:
		_end_run_overlay.confirmed.connect(_on_end_run_dismissed)
		_end_run_overlay.canceled.connect(_on_end_run_dismissed)
	if _reset_confirm_overlay != null:
		_reset_confirm_overlay.dialog_text = "Erase all four-run progress and start a fresh campaign?"
		_reset_confirm_overlay.ok_button_text = "Reset"
		_reset_confirm_overlay.confirmed.connect(_on_reset_game_confirmed)
	if _quit_confirm_overlay != null:
		_quit_confirm_overlay.title = "Quit Game?"
		_quit_confirm_overlay.dialog_text = "Sure you want to quit now?"
		_quit_confirm_overlay.ok_button_text = "Yes, Quit"
		_quit_confirm_overlay.cancel_button_text = "No, Keep Playing"
		_quit_confirm_overlay.confirmed.connect(_on_quit_confirmed)

	if _event_bus != null:
		_event_bus.state_changed.connect(_on_state_changed)
		_event_bus.feature_added.connect(_on_feature_added)
		_event_bus.jank_prospect_updated.connect(_on_jank_prospect_updated)
		_event_bus.jank_signature_locked.connect(_on_jank_signature_locked)
		_event_bus.threshold_event.connect(_on_threshold_event)
		_event_bus.dilemma_offered.connect(_on_dilemma_offered)
		_event_bus.draft_offer.connect(_on_draft_offer)
		_event_bus.day_spent.connect(_on_day_spent)
		_event_bus.runway_depleted.connect(_on_runway_depleted)
		_event_bus.archetype_chosen.connect(_on_archetype_chosen_visual)

	if _game_state != null:
		_on_state_changed(_snapshot_from_state())

func _populate_card_list() -> void:
	_backlog_controller.reset_run_state()
	_backlog_controller.populate_card_list(Callable(self, "_append_log"))

func _on_card_dropped(data: Dictionary) -> void:
	_backlog_controller.handle_card_dropped(_menu_active, _post_ship_flow_controller.is_run_ended(), data)

func _on_fix_bugs_pressed() -> void:
	if _menu_active or _post_ship_flow_controller.is_run_ended():
		return
	if _game_state != null:
		_game_state.fix_bugs()
	_hud_controller.animate_fix_bugs_feedback()
	_append_log(_S.get_string("log_messages", "fix_bugs"))

func _on_dev_log_pressed() -> void:
	if _menu_active or _post_ship_flow_controller.is_run_ended():
		return
	if _game_state != null:
		_game_state.do_dev_log()
	_hud_controller.animate_dev_log_feedback()
	_append_log(_S.get_string("log_messages", "dev_log"))

func _on_ship_pressed() -> void:
	if _menu_active or _post_ship_flow_controller.is_run_ended():
		return
	_breathe_in_then_ship()

func _breathe_in_then_ship() -> void:
	var t: Tween = create_tween()
	t.set_trans(Tween.TRANS_SINE)
	t.set_ease(Tween.EASE_IN_OUT)
	t.tween_property(_wobble_root, "scale", Vector2(0.984, 0.984), 0.18)
	t.tween_property(_wobble_root, "scale", Vector2.ONE, 0.22)
	await t.finished
	_post_ship_flow_controller.show_ship_summary()

func _on_quit_pressed() -> void:
	if _quit_confirm_overlay != null:
		_quit_confirm_overlay.popup_centered()

func _on_quit_confirmed() -> void:
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _quit_confirm_overlay != null and not _quit_confirm_overlay.visible:
		_quit_confirm_overlay.popup_centered()
		get_viewport().set_input_as_handled()

func _on_crunch_timer_timeout() -> void:
	if _crunch_timer != null and not _crunch_timer.is_stopped():
		_crunch_timer.stop()

func _is_blocking_offer_dialog_open() -> bool:
	return _choice_overlay != null and _choice_overlay.visible

func _on_state_changed(payload: StateSnapshotPayload) -> void:
	_hud_controller.on_state_changed(
		payload,
		_menu_active,
		_post_ship_flow_controller.is_run_ended(),
		_get_initial_runway_days(),
		INSTABILITY_CEILING_ZONE_SIZE,
		Callable(_jank_fx_controller, "update_ship_button_danger")
	)
	_refresh_jank_pursuit_display()
	_check_runway_narrative(payload.runway_days, payload.current_run)
	_update_backlog_footer(payload)

# -- Event Bus: Core Gameplay --
func _on_feature_added(card: FeatureCard) -> void:
	_feature_board.add_feature_to_board(card)
	_refresh_jank_pursuit_display()
	_append_log(_S.get_string("log_messages", "feature_added") % card.feature_name)

func _on_jank_prospect_updated(payload: Dictionary) -> void:
	var title: String = String(payload.get("prospect_title", "Jank Prospect"))
	var message: String = String(payload.get("message", "Something strange is taking shape."))
	var prospect_card_a: String = String(payload.get("card_a", ""))
	_refresh_jank_pursuit_display()
	_show_synergy_toast(title, "%s\nOne more collision may lock it in." % message, "prospect", 0, JANK_PROSPECT_TOAST_DURATION)
	if _feature_board != null:
		_feature_board.pulse_jank_state("prospect")
		if not prospect_card_a.is_empty():
			_feature_board.pulse_prospect_tile(prospect_card_a)
	if _backlog_controller != null:
		_backlog_controller.refresh_prospect_highlighting()
	_append_log(_S.get_string("log_messages", "jank_prospect") % message)

func _on_jank_signature_locked(payload: Dictionary) -> void:
	var message: String = String(payload.get("message", "Signature jank locked."))
	var soul_reward: int = int(payload.get("soul_reward", 0))
	var card_a: String = String(payload.get("card_a", ""))
	var card_b: String = String(payload.get("card_b", ""))
	var jank_name: String = String(payload.get("name", ""))
	_refresh_jank_pursuit_display()
	_jank_fx_controller.flash_jank_lock()
	var toast_title: String = jank_name.to_upper() if not jank_name.is_empty() else "SIGNATURE LOCKED"
	_show_synergy_toast(toast_title, message, "locked", soul_reward, JANK_LOCKED_TOAST_DURATION)
	if _feature_board != null:
		_feature_board.pulse_jank_state("locked")
		if not card_a.is_empty() or not card_b.is_empty():
			_feature_board.flash_jank_tiles(card_a, card_b)
	if _backlog_controller != null:
		_backlog_controller.refresh_prospect_highlighting()
	var reward_text: String = " (Soul +%d)" % soul_reward if soul_reward > 0 else ""
	if not card_a.is_empty() and not card_b.is_empty() and not jank_name.is_empty():
		_append_log(_S.get_string("log_messages", "jank_locked") % [card_a, card_b, jank_name, message + reward_text])
	else:
		_append_log("[JANK LOCKED] %s%s" % [message, reward_text])

func _on_threshold_event(payload: ThresholdEventPayload) -> void:
	var effect_parts: PackedStringArray = []
	for key in payload.effects.keys():
		effect_parts.append("%s %+d" % [String(key), int(payload.effects[key])])
	var effect_text: String = ""
	if not effect_parts.is_empty():
		effect_text = " (Effects: %s)" % ", ".join(effect_parts)
	_append_log("[%s] %s%s" % [payload.severity.to_upper(), payload.message, effect_text])

func _on_dilemma_offered(payload: DilemmaOfferPayload) -> void:
	_choice_flow_controller.on_dilemma_offered(payload, _menu_active, _post_ship_flow_controller.is_run_ended())
	_append_log(_S.get_string("log_messages", "dilemma_surfaced") % payload.title)

func _on_draft_offer(payload: DraftOfferPayload) -> void:
	_choice_flow_controller.on_draft_offer(payload, _menu_active, _post_ship_flow_controller.is_run_ended())
	_append_log(_S.get_string("log_messages", "draft_surfaced") % payload.title)

func _on_day_spent(payload: DaySpentPayload) -> void:
	_backlog_controller.on_day_spent(payload)

func _on_runway_depleted(_payload: RunwayDepletedPayload) -> void:
	_append_log(_S.get_string("log_messages", "runway_depleted"))
	if not _menu_active and not _post_ship_flow_controller.is_run_ended():
		_fix_bugs_button.disabled = true
		_dev_log_button.disabled = true

func _append_log(message: String) -> void:
	if _feature_board != null and _feature_board.has_method("append_log_entry"):
		_feature_board.append_log_entry(message)
	print(message)

func _on_viewport_size_changed() -> void:
	_hud_controller.apply_responsive_layout(_action_panel)

func _process(delta: float) -> void:
	_jank_fx_controller.process(
		delta,
		_menu_active,
		_hud_controller.get_instability_visual(),
		_hud_controller.get_instability_ceiling_pressure(),
		WOBBLE_CLAMP
	)

func _on_start_run_pressed() -> void:
	_start_new_run()

func _on_reset_game_button_pressed() -> void:
	if _reset_confirm_overlay != null:
		_reset_confirm_overlay.popup_centered()

func _on_reset_game_confirmed() -> void:
	if _game_state != null:
		_game_state.start_new_cycle()
	_show_main_menu()

func _on_end_run_dismissed() -> void:
	if _game_state != null and _game_state.is_cycle_complete():
		_game_state.start_new_cycle()
	_show_main_menu()

func _update_backlog_footer(payload: StateSnapshotPayload) -> void:
	if _menu_active or _backlog_view == null:
		return
	var footer: Label = _backlog_view.get_backlog_footer()
	if footer == null:
		return
	var run_ended: bool = _post_ship_flow_controller.is_run_ended()
	var new_state: String
	if not run_ended and payload.soul <= 3:
		new_state = "soul_critical"
	elif not run_ended and payload.runway_days == 1:
		new_state = "runway_final"
	else:
		new_state = "default"
	if new_state == _backlog_footer_state:
		return
	_backlog_footer_state = new_state
	match new_state:
		"soul_critical":
			footer.text = "There is not enough left in this studio for everything it is trying to build."
		"runway_final":
			footer.text = "There is no more time to be careful about this."
		_:
			footer.text = _BACKLOG_FOOTER_DEFAULT

func _check_runway_narrative(runway_days: int, current_run: int) -> void:
	if _menu_active or _post_ship_flow_controller.is_run_ended() or current_run <= 1:
		return
	var checkpoints: Dictionary = {
		5: "Five days. The team is still debating scope.",
		3: "Three days. The build is not what anyone planned.",
		1: "One day. This is the version that ships.",
	}
	for threshold in checkpoints:
		if runway_days <= threshold and not _runway_narrative_checkpoints.has(threshold):
			_runway_narrative_checkpoints[threshold] = true
			_append_log(checkpoints[threshold])

func _start_new_run() -> void:
	if _game_state == null:
		return
	_runway_narrative_checkpoints.clear()
	_backlog_footer_state = ""
	_menu_active = false
	_main_menu_view.visible = false
	_feature_board.clear_board()
	_game_state.reset_run()
	_refresh_jank_pursuit_display()
	_hud_controller.update_card_unlock_progress()
	_choice_flow_controller.clear()
	_post_ship_flow_controller.clear()
	_backlog_controller.reset_run_state()
	_fix_bugs_button.disabled = false
	_dev_log_button.disabled = false
	_ship_button.disabled = false
	if _crunch_timer != null:
		_crunch_timer.stop()
	_main_menu_controller.show_archetype_select_dialog(Callable(self, "_begin_run_gameplay"))

func _begin_run_gameplay() -> void:
	var cycle: Dictionary = _game_state.get_cycle_state()
	var is_first_of_cycle: bool = int(cycle.get("current_run", 1)) == 1 and String(cycle.get("run_1_ending", "")) == ""
	if is_first_of_cycle:
		_append_log(_S.get_string("log_messages", "onboarding_0"))
		_append_log(_S.get_string("log_messages", "onboarding_1"))
		_append_log(_S.get_string("log_messages", "onboarding_2"))
		_append_log(_S.get_string("log_messages", "onboarding_3"))
		_populate_card_list()
	else:
		_append_log(_S.get_string("log_messages", "run_started"))
		_populate_card_list()
		_main_menu_controller.show_previously_on()

func _show_main_menu() -> void:
	_backlog_footer_state = ""
	_menu_active = true
	_fix_bugs_button.disabled = true
	_dev_log_button.disabled = true
	_ship_button.disabled = true
	_crunch_timer.stop()
	_feature_board.clear_board()
	_refresh_jank_pursuit_display()
	_choice_flow_controller.clear()
	_post_ship_flow_controller.clear()
	_backlog_controller.clear_visible_backlog()
	_main_menu_controller.show_main_menu(Callable(self, "_append_log"))

func _get_initial_runway_days() -> int:
	if _game_state != null and _game_state.has_method("get_initial_runway_days"):
		return int(_game_state.get_initial_runway_days())
	return 21

func _on_archetype_chosen_visual(archetype: String) -> void:
	_hud_controller.on_archetype_chosen_visual(archetype)

func _snapshot_from_state() -> StateSnapshotPayload:
	return _hud_controller.snapshot_from_state()

func _show_synergy_toast(title: String, body: String, stage: String, soul_delta: int, duration: float = SYNERGY_TOAST_DURATION) -> void:
	_jank_fx_controller.show_synergy_toast(title, body, stage, soul_delta, duration)

func _refresh_jank_pursuit_display() -> void:
	if _feature_board == null or _game_state == null or not _game_state.has_method("get_jank_pursuit_state"):
		return
	_feature_board.set_jank_pursuit_state(_game_state.get_jank_pursuit_state())
