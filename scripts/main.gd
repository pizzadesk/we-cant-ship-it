extends Control

const CARD_WIDGET_SCENE: PackedScene = preload("res://scenes/ui/feature_card_widget.tscn")
const BacklogPanelViewType = preload("res://scripts/ui/backlog_panel_view.gd")
const DialogHostViewType = preload("res://scripts/ui/dialog_host_view.gd")
const HeaderBarViewType = preload("res://scripts/ui/header_bar_view.gd")
const MainMenuOverlayViewType = preload("res://scripts/ui/main_menu_overlay_view.gd")
const RunSidebarViewType = preload("res://scripts/ui/run_sidebar_view.gd")
const PostShipPresentation = preload("res://scripts/ui/presenters/post_ship_presentation.gd")
const CARDS_PATH: String = "res://data/cards"
const CUSTOM_CARDS_PATH: String = "res://data/custom_cards"
const DAILY_VISIBLE_CARDS: int = 3
const END_DIALOG_SIZE: Vector2i = Vector2i(760, 360)
const DILEMMA_DIALOG_SIZE: Vector2i = Vector2i(1120, 620)
const DRAFT_DIALOG_SIZE: Vector2i = Vector2i(1180, 660)
const REVIEW_DIALOG_SIZE: Vector2i = Vector2i(1240, 760)
const SYNERGY_TOAST_DURATION: float = 2.5
const _S = preload("res://scripts/ui/ui_strings.gd")
const SYNERGY_TOAST_FADE_IN: float = 0.15
const SYNERGY_TOAST_FADE_OUT: float = 0.4
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

# Dialogs and layers
@onready var _dialog_host_view: DialogHostViewType = $"%DialogHost"
@onready var _review_dialog: AcceptDialog = _dialog_host_view.get_review_dialog()
@onready var _end_run_dialog: ConfirmationDialog = _dialog_host_view.get_end_run_dialog()
@onready var _dilemma_dialog: ConfirmationDialog = _dialog_host_view.get_dilemma_dialog()
@onready var _draft_dialog: ConfirmationDialog = _dialog_host_view.get_draft_dialog()
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

var _quit_confirm_dialog: ConfirmationDialog = null
var _draft_pick_c_button: Button
var _ui_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _review_content: RichTextLabel
var _ship_summary_dialog: ConfirmationDialog = null
var _archetype_select_dialog: ConfirmationDialog = null
var _menu_active: bool = false
var _run_ended: bool = false
var _jank_discovery_dialog: AcceptDialog = null
var _jank_discovery_content: RichTextLabel = null
var _gap_visualizer_dialog: AcceptDialog = null
var _gap_visualizer_content: RichTextLabel = null
var _previously_on_dialog: AcceptDialog = null
var _cycle_legacy_dialog: AcceptDialog = null
var _cycle_legacy_content: RichTextLabel = null
var _reset_confirm_dialog: ConfirmationDialog = null

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
	var refs: Dictionary = DialogFactory.configure_scene_dialogs(
		_dialog_host_view,
		_review_dialog,
		_end_run_dialog,
		_dilemma_dialog,
		_draft_dialog,
		REVIEW_DIALOG_SIZE,
		END_DIALOG_SIZE,
		DILEMMA_DIALOG_SIZE,
		DRAFT_DIALOG_SIZE,
		Callable(self, "_on_ship_summary_confirmed"),
		Callable(self, "_on_ship_summary_canceled"),
		Callable(self, "_on_jank_discovery_confirmed"),
		Callable(self, "_on_gap_visualizer_confirmed")
	)
	_ship_summary_dialog = refs.get("ship_summary_dialog") as ConfirmationDialog
	_jank_discovery_dialog = refs.get("jank_discovery_dialog") as AcceptDialog
	_jank_discovery_content = refs.get("jank_discovery_content") as RichTextLabel
	_gap_visualizer_dialog = refs.get("jank_dialog") as AcceptDialog
	_gap_visualizer_content = refs.get("jank_content") as RichTextLabel
	_review_content = refs.get("review_content") as RichTextLabel
	_draft_pick_c_button = refs.get("draft_pick_c_button") as Button
	_archetype_select_dialog = refs.get("archetype_dialog") as ConfirmationDialog
	_cycle_legacy_dialog = refs.get("cycle_legacy_dialog") as AcceptDialog
	_cycle_legacy_content = refs.get("cycle_legacy_content") as RichTextLabel
	_previously_on_dialog = refs.get("previously_on_dialog") as AcceptDialog
	_reset_confirm_dialog = _dialog_host_view.get_reset_confirm_dialog()
	_quit_confirm_dialog = _dialog_host_view.get_quit_confirm_dialog()

	for _d: Window in _dialog_host_view.get_scene_dialogs():
		var _lbl: Label = (_d as AcceptDialog).get_label()
		if _lbl != null:
			_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _setup_controllers() -> void:
	_hud_controller.setup(
		_game_state,
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
		_run_sidebar_view.get_instability_gauge(),
		_run_sidebar_view.get_instability_target_band(),
		_run_sidebar_view.get_instability_status(),
		_run_sidebar_view.get_runway_gauge(),
		_run_sidebar_view.get_soul_gauge(),
		_run_sidebar_view.get_soul_risk_label(),
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
		_dilemma_dialog,
		_draft_dialog,
		_draft_pick_c_button,
		DILEMMA_DIALOG_SIZE,
		DRAFT_DIALOG_SIZE
	)
	_post_ship_flow_controller.setup(
		_game_state,
		_review_dialog,
		_review_content,
		REVIEW_DIALOG_SIZE,
		_gap_visualizer_dialog,
		_gap_visualizer_content,
		_jank_discovery_dialog,
		_jank_discovery_content,
		_cycle_legacy_dialog,
		_cycle_legacy_content,
		_end_run_dialog,
		END_DIALOG_SIZE
	)
	_main_menu_controller.setup(
		_game_state,
		_main_menu_view,
		_start_run_button,
		_reset_game_button,
		_menu_subtitle,
		_archetype_select_dialog,
		_previously_on_dialog
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
	var janky_panels: Array[Control] = [
	]
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

# -- UI Actions --
func _show_ship_summary() -> void:
	if _ship_summary_dialog == null or _game_state == null:
		return
	var predicted_score: float = _game_state.calculate_predicted_score()
	var content: String = PostShipPresentation.build_ship_summary_text(_game_state, predicted_score)
	var content_label: RichTextLabel = _ship_summary_dialog.get_node_or_null("Content") as RichTextLabel
	if content_label == null and _ship_summary_dialog.get_child_count() > 0:
		content_label = _ship_summary_dialog.get_child(0) as RichTextLabel
	if content_label != null:
		content_label.text = content
		content_label.scroll_to_line(0)
	_ship_summary_dialog.popup_centered(_ship_summary_dialog.min_size)

func _on_ship_summary_confirmed() -> void:
	if _game_state != null:
		_run_ended = true
		_fix_bugs_button.disabled = true
		_dev_log_button.disabled = true
		_ship_button.disabled = true
		_crunch_timer.stop()
		_game_state.ship_it()

func _on_ship_summary_canceled() -> void:
	pass

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
	_review_dialog.confirmed.connect(_on_review_dialog_closed)
	_end_run_dialog.confirmed.connect(_on_end_run_dialog_new_run)
	_end_run_dialog.canceled.connect(_on_end_run_dialog_menu)
	_dilemma_dialog.confirmed.connect(_on_dilemma_dialog_choice_a)
	_dilemma_dialog.canceled.connect(_on_dilemma_dialog_choice_b)
	_draft_dialog.confirmed.connect(_on_draft_dialog_pick_a)
	_draft_dialog.canceled.connect(_on_draft_dialog_pick_b)
	_draft_dialog.custom_action.connect(_on_draft_dialog_custom_action)

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
		_event_bus.reviews_generated.connect(_on_reviews_generated)
		_event_bus.archetype_chosen.connect(_on_archetype_chosen_visual)

	if _archetype_select_dialog != null:
		_archetype_select_dialog.confirmed.connect(_on_archetype_dialog_confirmed)
		_archetype_select_dialog.canceled.connect(_on_archetype_dialog_canceled)
		_archetype_select_dialog.custom_action.connect(_on_archetype_dialog_custom_action)

	if _cycle_legacy_dialog != null:
		_cycle_legacy_dialog.confirmed.connect(_on_cycle_legacy_confirmed)

	if _reset_confirm_dialog != null:
		_reset_confirm_dialog.confirmed.connect(_on_reset_game_confirmed)

	if _quit_confirm_dialog != null:
		_quit_confirm_dialog.confirmed.connect(_on_quit_confirmed)

	if _game_state != null:
		_on_state_changed(_snapshot_from_state())

func _populate_card_list() -> void:
	_backlog_controller.reset_run_state()
	_backlog_controller.populate_card_list(Callable(self, "_append_log"))

func _on_card_dropped(data: Dictionary) -> void:
	_backlog_controller.handle_card_dropped(_menu_active, _run_ended, data)

func _on_fix_bugs_pressed() -> void:
	if _menu_active or _run_ended:
		return
	if _game_state != null:
		_game_state.fix_bugs()
	_append_log(_S.get_string("log_messages", "fix_bugs"))

func _on_dev_log_pressed() -> void:
	if _menu_active or _run_ended:
		return
	if _game_state != null:
		_game_state.do_dev_log()
	_append_log(_S.get_string("log_messages", "dev_log"))

func _on_ship_pressed() -> void:
	if _menu_active or _run_ended:
		return
	_show_ship_summary()

func _on_quit_pressed() -> void:
	if _quit_confirm_dialog != null:
		_quit_confirm_dialog.popup_centered(_quit_confirm_dialog.min_size)

func _on_quit_confirmed() -> void:
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _quit_confirm_dialog != null and not _quit_confirm_dialog.visible:
		_quit_confirm_dialog.popup_centered(_quit_confirm_dialog.min_size)
		get_viewport().set_input_as_handled()

func _on_crunch_timer_timeout() -> void:
	if _crunch_timer != null and not _crunch_timer.is_stopped():
		_crunch_timer.stop()

func _is_blocking_offer_dialog_open() -> bool:
	return _dilemma_dialog.visible or _draft_dialog.visible

func _on_state_changed(payload: StateSnapshotPayload) -> void:
	_hud_controller.on_state_changed(
		payload,
		_menu_active,
		_run_ended,
		_get_initial_runway_days(),
		INSTABILITY_CEILING_ZONE_SIZE,
		Callable(_jank_fx_controller, "update_ship_button_danger")
	)

# -- Event Bus: Core Gameplay --
func _on_feature_added(card: FeatureCard) -> void:
	_feature_board.add_feature_to_board(card)
	_refresh_jank_pursuit_display()
	_append_log(_S.get_string("log_messages", "feature_added") % card.feature_name)

func _on_jank_prospect_updated(payload: Dictionary) -> void:
	var title: String = String(payload.get("prospect_title", "Jank Prospect"))
	var message: String = String(payload.get("message", "Something strange is taking shape."))
	_show_synergy_toast(title, "%s\nOne more collision may lock it in." % message, "prospect", 0, JANK_PROSPECT_TOAST_DURATION)
	if _feature_board != null:
		_feature_board.pulse_jank_state("prospect")
	_append_log("[JANK PROSPECT] %s — %s" % [title, message])

func _on_jank_signature_locked(payload: Dictionary) -> void:
	var message: String = String(payload.get("message", "Signature jank locked."))
	var soul_reward: int = int(payload.get("soul_reward", 0))
	_show_synergy_toast("SIGNATURE LOCKED", message, "locked", soul_reward, JANK_LOCKED_TOAST_DURATION)
	if _feature_board != null:
		_feature_board.pulse_jank_state("locked")
	var reward_text: String = ""
	if soul_reward > 0:
		reward_text = " (Soul +%d)" % soul_reward
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
	_choice_flow_controller.on_dilemma_offered(payload, _menu_active, _run_ended)
	_append_log("Dilemma surfaced: %s" % payload.title)

func _on_draft_offer(payload: DraftOfferPayload) -> void:
	_choice_flow_controller.on_draft_offer(payload, _menu_active, _run_ended)
	_append_log("Draft surfaced: %s" % payload.title)

func _on_day_spent(payload: DaySpentPayload) -> void:
	_backlog_controller.on_day_spent(payload)

func _on_runway_depleted(_payload: RunwayDepletedPayload) -> void:
	_append_log(_S.get_string("log_messages", "runway_depleted"))
	if not _menu_active and not _run_ended:
		_fix_bugs_button.disabled = true
		_dev_log_button.disabled = true

func _on_reviews_generated(payload: ShipResult) -> void:
	_post_ship_flow_controller.on_reviews_generated(payload, Callable(_hud_controller, "update_card_unlock_progress"))

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
	if _reset_confirm_dialog != null:
		_reset_confirm_dialog.popup_centered(_reset_confirm_dialog.min_size)

func _on_reset_game_confirmed() -> void:
	if _game_state != null:
		_game_state.start_new_cycle()
	_show_main_menu()

func _on_review_dialog_closed() -> void:
	_post_ship_flow_controller.advance_sequence(_run_ended)

func _on_gap_visualizer_confirmed() -> void:
	_post_ship_flow_controller.advance_sequence(_run_ended)

func _on_jank_discovery_confirmed() -> void:
	_post_ship_flow_controller.advance_sequence(_run_ended)

func _on_cycle_legacy_confirmed() -> void:
	_post_ship_flow_controller.advance_sequence(_run_ended)

func _on_end_run_dialog_new_run() -> void:
	if _game_state != null and _game_state.is_cycle_complete():
		_game_state.start_new_cycle()
	_show_main_menu()

func _on_end_run_dialog_menu() -> void:
	if _game_state != null and _game_state.is_cycle_complete():
		_game_state.start_new_cycle()
	_show_main_menu()

func _on_dilemma_dialog_choice_a() -> void:
	_choice_flow_controller.on_dilemma_choice(0, "dilemma_a", Callable(self, "_append_log"))

func _on_dilemma_dialog_choice_b() -> void:
	_choice_flow_controller.on_dilemma_choice(1, "dilemma_b", Callable(self, "_append_log"))

func _on_draft_dialog_pick_a() -> void:
	_choice_flow_controller.on_draft_pick(0, "draft_a", Callable(self, "_append_log"))

func _on_draft_dialog_pick_b() -> void:
	_choice_flow_controller.on_draft_pick(1, "draft_b", Callable(self, "_append_log"))

func _on_draft_dialog_custom_action(action: StringName) -> void:
	_choice_flow_controller.on_draft_custom_action(action, Callable(self, "_append_log"))

func _start_new_run() -> void:
	if _game_state == null:
		return
	_menu_active = false
	_run_ended = false
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

func _on_archetype_dialog_confirmed() -> void:
	_main_menu_controller.on_archetype_dialog_confirmed()
	_begin_run_gameplay()

func _on_archetype_dialog_canceled() -> void:
	_main_menu_controller.on_archetype_dialog_canceled()
	_begin_run_gameplay()

func _on_archetype_dialog_custom_action(action: StringName) -> void:
	_main_menu_controller.on_archetype_dialog_custom_action(action)
	_begin_run_gameplay()

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
	_menu_active = true
	_run_ended = false
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
	_jank_fx_controller.show_synergy_toast(
		title,
		body,
		stage,
		soul_delta,
		duration,
		SYNERGY_TOAST_FADE_IN,
		Callable(self, "_on_synergy_toast_timeout")
	)

func _on_synergy_toast_timeout() -> void:
	var fade_out_tween: Tween = _jank_fx_controller.fade_out_synergy_toast(SYNERGY_TOAST_FADE_OUT)
	if fade_out_tween == null:
		return
	await fade_out_tween.finished
	_jank_fx_controller.hide_synergy_toast()
	_jank_fx_controller.clear_synergy_toast_timer()

func _refresh_jank_pursuit_display() -> void:
	if _feature_board == null or _game_state == null or not _game_state.has_method("get_jank_pursuit_state"):
		return
	_feature_board.set_jank_pursuit_state(_game_state.get_jank_pursuit_state())
