extends Control

const CARD_WIDGET_SCENE: PackedScene = preload("res://scenes/ui/feature_card_widget.tscn")
const OfferLogicUtils = preload("res://scripts/ui/offer_logic_utils.gd")
const PresentationTextUtils = preload("res://scripts/ui/presentation_text_utils.gd")
const CardProgressUtils = preload("res://scripts/ui/card_progress_utils.gd")
const JankVisualUtils = preload("res://scripts/ui/jank_visual_utils.gd")
const HelpContentUtils = preload("res://scripts/ui/help_content_utils.gd")
const OfferDialogTextUtils = preload("res://scripts/ui/offer_dialog_text_utils.gd")
const ThemeUtils = preload("res://scripts/ui/theme_utils.gd")
const DialogSetupUtils = preload("res://scripts/ui/dialog_setup_utils.gd")
const BacklogCatalogUtils = preload("res://scripts/ui/backlog_catalog_utils.gd")
const HudUiUtils = preload("res://scripts/ui/hud_ui_utils.gd")
const SynergyToastUtils = preload("res://scripts/ui/synergy_toast_utils.gd")
const CARDS_PATH: String = "res://data/cards"
const CUSTOM_CARDS_PATH: String = "res://data/custom_cards"
const INITIAL_RUNWAY_DAYS: int = 21
const DAILY_VISIBLE_CARDS: int = 3
const END_DIALOG_SIZE: Vector2i = Vector2i(760, 360)
const DILEMMA_DIALOG_SIZE: Vector2i = Vector2i(1120, 620)
const DRAFT_DIALOG_SIZE: Vector2i = Vector2i(1180, 660)
const PUBLISHER_DIALOG_SIZE: Vector2i = Vector2i(1180, 680)
const REVIEW_DIALOG_SIZE: Vector2i = Vector2i(1240, 760)
const SYNERGY_TOAST_DURATION: float = 2.5
const _S = preload("res://scripts/ui/ui_strings.gd")
const SYNERGY_TOAST_FADE_IN: float = 0.15
const SYNERGY_TOAST_FADE_OUT: float = 0.4
const WOBBLE_CLAMP: float = 10.0
# How many instability points below the archetype ceiling define the danger zone.
# Within this zone wobble intensifies relative to the archetype window edge, so a
# Shooter run (ceiling 42) feels more chaotic at Instability 38 than an RPG run
# (ceiling 55) does at the same value. Adjust to widen or narrow the warning zone.
const INSTABILITY_CEILING_ZONE_SIZE: int = 12
const SCANLINE_SHADER: Shader = preload("res://shaders/scanline.gdshader")

# Stat display labels
@onready var _ambition_value: Label = $"%AmbitionValue"
@onready var _instability_value: Label = $"%InstabilityValue"
@onready var _runway_value: Label = $"%RunwayValue"
@onready var _features_value: Label = $"%FeaturesValue"
@onready var _soul_value: Label = $"%SoulValue"
@onready var _meta_value: Label = $"%MetaValue"

# Card and board references
@onready var _card_list: VBoxContainer = $"%CardList"
@onready var _feature_board: PanelContainer = $"%FeatureBoard"

# Action buttons
@onready var _fix_bugs_button: Button = $"%FixBugsButton"
@onready var _dev_log_button: Button = $"%DevLogButton"
@onready var _ship_button: Button = $"%ShipButton"

# Dialogs and layers
@onready var _review_dialog: AcceptDialog = $"%ReviewDialog"
@onready var _end_run_dialog: ConfirmationDialog = $"%EndRunDialog"
@onready var _dilemma_dialog: ConfirmationDialog = $"%DilemmaDialog"
@onready var _draft_dialog: ConfirmationDialog = $"%DraftDialog"
@onready var _publisher_dialog: ConfirmationDialog = $"%PublisherDialog"
@onready var _main_menu_layer: CanvasLayer = $"%MainMenuLayer"
@onready var _start_run_button: Button = $"%StartRunButton"
@onready var _reset_game_button: Button = $"%ResetGameButton"
@onready var _minimal_text_toggle: CheckBox = $"%MinimalTextToggle"
@onready var _menu_subtitle: Label = $"%MenuSubtitle"
@onready var _quit_button: Button = $"%QuitButton"

# Visual corruption
@onready var _scanline_overlay: ColorRect = $"%ScanlineOverlay"
@onready var _jank_tint: ColorRect = $"%JankTint"
@onready var _wobble_root: MarginContainer = $"%RootMargin"
@onready var _action_panel: PanelContainer = $"%ActionPanel"
@onready var _crunch_timer: Timer = $"%CrunchTimer"

# Autoload references
@onready var _game_state: Node = AppState
@onready var _event_bus: Node = GameEvents

var _scanline_material: ShaderMaterial
var _quit_confirm_dialog: ConfirmationDialog = null
var _draft_pick_c_button: Button
var _publisher_pick_c_button: Button
var _pending_dilemma: Dictionary = {}
var _pending_draft_offer: Dictionary = {}
var _choice_context: String = ""
var _choice_base_title: String = ""
var _choice_base_text: String = ""
var _ui_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _text_corruption_timer: float = 0.0
var _corruptible_controls: Array[Control] = []
var _base_control_text: Dictionary = {}
var _review_content: RichTextLabel
var _synergy_toast: PanelContainer = null
var _synergy_toast_timer: Timer = null
var _ship_summary_dialog: ConfirmationDialog = null
var _help_dialog: AcceptDialog = null
var _archetype_select_dialog: ConfirmationDialog = null
var _ambition_gauge: ProgressBar = null
var _instability_gauge: ProgressBar = null
var _soul_gauge: ProgressBar = null
var _runway_gauge: ProgressBar = null
var _menu_active: bool = false
var _run_ended: bool = false
var _mechanics_highlights_dialog: AcceptDialog = null  # kept for backwards compat; unused
var _mechanics_highlights_content: RichTextLabel = null
var _gap_visualizer_dialog: AcceptDialog = null
var _gap_visualizer_content: RichTextLabel = null
var _previously_on_dialog: AcceptDialog = null
var _cycle_legacy_dialog: AcceptDialog = null
var _cycle_legacy_content: RichTextLabel = null
var _reset_confirm_dialog: ConfirmationDialog = null
var _current_ship_results: Dictionary = {}
var _current_reviews_payload: ReviewsGeneratedPayload = ReviewsGeneratedPayload.new()
var _post_ship_sequence: Array[Callable] = []
var _backlog_cards: Array[Resource] = []
var _last_offer_runway_day: int = -1
var _template_cards: Array[Resource] = []
var _templates_loaded: bool = false
var _jank_time: float = 0.0
var _glitch_offset: Vector2 = Vector2.ZERO
var _instability_visual: float = 0.0
# 0.0–1.0: 0 = at or below the danger zone entry, 1 = at or past the archetype ceiling.
# Drives archetype-aware wobble amplification independently of raw instability level.
var _instability_ceiling_pressure: float = 0.0
# Instability [floor, ceiling] for the current archetype, updated on archetype selection.
# Defaults to Action-Adventure. Used to compute _instability_ceiling_pressure.
var _chosen_archetype_window: Array[int] = [15, 50]
# Shown near the Soul stat when soul is close to or below the Defining Game floor.
var _soul_risk_label: Label = null
var _card_unlock_progress_label: Label
var _goldilocks_floor_marker: ColorRect = null
var _goldilocks_ceiling_marker: ColorRect = null

# -- Scene Lifecycle --
func _ready() -> void:
	_ui_rng.randomize()
	_setup_scanline_shader()
	_apply_janky_ui_theme()
	_setup_card_unlock_progress()
	_setup_dialog_runtime()
	_setup_stat_gauges()
	_cache_corruptible_ui_text()
	_setup_synergy_toast()
	_load_ui_prefs()
	_wire_events()
	_show_main_menu()
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_apply_responsive_layout()
	set_process(true)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Preserve cycle state as-is on quit. Current run will restart next launch;
		# completed runs from prior ships are already saved via complete_run().
		if _game_state != null:
			_game_state.save_cycle_state()
		get_tree().quit()

# -- Setup: Dialogs and HUD --
func _setup_dialog_runtime() -> void:
	var help_text: String = HelpContentUtils.build_help_text()
	var refs: DialogRuntimeRefs = DialogSetupUtils.setup_runtime_dialogs(
		self,
		_review_dialog,
		_end_run_dialog,
		_dilemma_dialog,
		_draft_dialog,
		_publisher_dialog,
		REVIEW_DIALOG_SIZE,
		END_DIALOG_SIZE,
		DILEMMA_DIALOG_SIZE,
		DRAFT_DIALOG_SIZE,
		PUBLISHER_DIALOG_SIZE,
		help_text,
		func(): pass,  # no-op: timer not used for day progression
		Callable(self, "_on_ship_summary_confirmed"),
		Callable(self, "_on_ship_summary_canceled"),
		Callable(self, "_on_mechanics_highlights_confirmed"),
		Callable(self, "_on_gap_visualizer_confirmed")
	)
	_help_dialog = refs.help_dialog
	_ship_summary_dialog = refs.ship_summary_dialog
	_mechanics_highlights_dialog = refs.mechanics_dialog
	_mechanics_highlights_content = refs.mechanics_content
	_gap_visualizer_dialog = refs.jank_dialog
	_gap_visualizer_content = refs.jank_content
	_review_content = refs.review_content
	_draft_pick_c_button = refs.draft_pick_c_button
	_publisher_pick_c_button = refs.publisher_pick_c_button
	_archetype_select_dialog = refs.archetype_dialog
	_cycle_legacy_dialog = _build_cycle_legacy_dialog()
	_previously_on_dialog = _build_previously_on_dialog()
	_reset_confirm_dialog = ConfirmationDialog.new()
	_reset_confirm_dialog.title = "Reset Campaign?"
	_reset_confirm_dialog.dialog_text = "Erase all three-run progress and start a fresh campaign?"
	_reset_confirm_dialog.min_size = Vector2(460, 100)
	add_child(_reset_confirm_dialog)

	_quit_confirm_dialog = ConfirmationDialog.new()
	_quit_confirm_dialog.title = "Quit Game?"
	_quit_confirm_dialog.dialog_text = "Sure you want to quit now?"
	_quit_confirm_dialog.get_ok_button().text = "Yes, Quit"
	_quit_confirm_dialog.get_cancel_button().text = "No, Keep Playing"
	_quit_confirm_dialog.min_size = Vector2(380, 130)
	add_child(_quit_confirm_dialog)
	_quit_confirm_dialog.confirmed.connect(func(): get_tree().quit())

	# Center the built-in dialog text labels on all scene-defined dialogs.
	for _d: Window in [_review_dialog, _end_run_dialog, _dilemma_dialog, _draft_dialog, _publisher_dialog, _reset_confirm_dialog, _quit_confirm_dialog]:
		var _lbl: Label = (_d as AcceptDialog).get_label()
		if _lbl != null:
			_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _setup_stat_gauges() -> void:
	var ambition_block: VBoxContainer = $"%AmbitionBlock"
	var instability_block: VBoxContainer = $"%InstabilityBlock"
	var runway_block: VBoxContainer = $"%RunwayBlock"
	var soul_block: VBoxContainer = $"%SoulBlock"
	var gauges: StatGaugeRefs = HudUiUtils.create_stat_gauges(ambition_block, instability_block, runway_block, soul_block)
	_ambition_gauge = gauges.ambition
	_instability_gauge = gauges.instability
	_runway_gauge = gauges.runway
	_soul_gauge = gauges.soul
	_goldilocks_floor_marker = gauges.goldilocks_floor_marker
	_goldilocks_ceiling_marker = gauges.goldilocks_ceiling_marker

	# Soul floor warning: surfaces when soul is one Fix Bugs away from losing Defining Game eligibility.
	_soul_risk_label = Label.new()
	_soul_risk_label.name = "SoulRiskLabel"
	_soul_risk_label.add_theme_font_size_override("font_size", 11)
	_soul_risk_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_soul_risk_label.visible = false
	soul_block.add_child(_soul_risk_label)

# -- UI Actions --
func _show_ship_summary() -> void:
	if _ship_summary_dialog == null or _game_state == null:
		return
	var predicted_score: float = _game_state.calculate_predicted_score()
	var content: String = PresentationTextUtils.build_ship_summary_text(_game_state, predicted_score)
	var content_label: RichTextLabel = _ship_summary_dialog.get_child(0) as RichTextLabel
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

func _cache_corruptible_ui_text() -> void:
	_corruptible_controls = [
		$"%HeaderTitle",
		$"%HeaderSubtitle",
		$"%BacklogTitle",
		$"%BacklogHelp",
		$"%BacklogFooter",
		$"%StatGuide",
		$"%BoardTitle",
		$"%BoardHelp",
		$"%ActionTitle",
		$"%ActionHelp",
		_fix_bugs_button,
		_dev_log_button,
		_ship_button,
		$"%MenuHint",
	]
	for control in _corruptible_controls:
		if control is Label:
			_base_control_text[control] = (control as Label).text
		elif control is Button:
			_base_control_text[control] = (control as Button).text

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
	_minimal_text_toggle.toggled.connect(_on_minimal_text_toggled)
	_review_dialog.confirmed.connect(_on_review_dialog_closed)
	_end_run_dialog.confirmed.connect(_on_end_run_dialog_new_run)
	_end_run_dialog.canceled.connect(_on_end_run_dialog_menu)
	_dilemma_dialog.confirmed.connect(_on_dilemma_dialog_choice_a)
	_dilemma_dialog.canceled.connect(_on_dilemma_dialog_choice_b)
	_draft_dialog.confirmed.connect(_on_draft_dialog_pick_a)
	_draft_dialog.canceled.connect(_on_draft_dialog_pick_b)
	_draft_dialog.custom_action.connect(_on_draft_dialog_custom_action)
	_publisher_dialog.confirmed.connect(func(): pass)
	_publisher_dialog.canceled.connect(func(): pass)
	_publisher_dialog.custom_action.connect(func(_a: StringName): pass)

	if _event_bus != null:
		_event_bus.state_changed.connect(_on_state_changed)
		_event_bus.feature_added.connect(_on_feature_added)
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

	if _game_state != null:
		_on_state_changed(_snapshot_from_state())

func _populate_card_list() -> void:
	_backlog_cards.clear()
	_last_offer_runway_day = -1
	_ensure_template_cards_loaded()
	_rebuild_daily_offer(true)

func _ensure_template_cards_loaded() -> void:
	var result: TemplateCardsLoadResult = BacklogCatalogUtils.ensure_template_cards_loaded(
		_template_cards,
		_templates_loaded,
		CARDS_PATH,
		CUSTOM_CARDS_PATH,
		Callable(self, "_append_log")
	)
	_template_cards = result.template_cards
	_templates_loaded = result.templates_loaded
	_merge_dynamic_templates()

func _merge_dynamic_templates() -> void:
	if _game_state == null or not _game_state.has_method("get_dynamic_card_templates"):
		return
	var existing: Dictionary = {}
	for template in _template_cards:
		var template_id: String = _card_id_from_resource(template)
		if not template_id.is_empty():
			existing[template_id] = true
	var dynamic_templates: Array = _game_state.get_dynamic_card_templates()
	for template in dynamic_templates:
		if template is not Resource:
			continue
		var resource: Resource = template as Resource
		var template_id: String = _card_id_from_resource(resource)
		if template_id.is_empty() or existing.has(template_id):
			continue
		_template_cards.append(resource)
		existing[template_id] = true

func _rebuild_daily_offer(force: bool = false) -> void:
	if _template_cards.is_empty():
		_backlog_cards.clear()
		_refresh_backlog_list()
		return

	var runway_today: int = INITIAL_RUNWAY_DAYS
	if _game_state != null:
		runway_today = int(_game_state.runway_days)

	if not force and runway_today == _last_offer_runway_day:
		return

	var offer_result: DailyOfferResult = BacklogCatalogUtils.rebuild_daily_offer(
		_template_cards,
		_game_state,
		_last_offer_runway_day,
		INITIAL_RUNWAY_DAYS,
		DAILY_VISIBLE_CARDS,
		_ui_rng,
		Callable(self, "_is_template_unlocked")
	)
	_backlog_cards = offer_result.backlog_cards
	_last_offer_runway_day = offer_result.last_offer_runway_day
	_refresh_backlog_list()

func _is_template_unlocked(template: Resource) -> bool:
	return BacklogCatalogUtils.is_template_unlocked(
		template, CUSTOM_CARDS_PATH, _game_state, Callable(self, "_card_id_from_resource")
	)

func _card_id_from_resource(card: Resource) -> String:
	return BacklogCatalogUtils.card_id_from_resource(card)

func _refresh_backlog_list() -> void:
	BacklogCatalogUtils.refresh_backlog_list(_card_list, _backlog_cards, CARD_WIDGET_SCENE, "backlog")

func _on_card_dropped(data: Dictionary) -> void:
	if _menu_active or _run_ended:
		return
	if _game_state == null or _game_state.runway_days <= 0:
		return
	var payload: FeatureCardDragPayload = FeatureCardDragPayload.from_variant(data)
	var card: Resource = payload.card
	if card == null:
		return
	_backlog_cards.erase(card)
	_refresh_backlog_list()
	_game_state.add_feature_card(card)

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

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _quit_confirm_dialog != null and not _quit_confirm_dialog.visible:
		_quit_confirm_dialog.popup_centered(_quit_confirm_dialog.min_size)
		get_viewport().set_input_as_handled()

func _on_crunch_timer_timeout() -> void:
	if _crunch_timer != null and not _crunch_timer.is_stopped():
		_crunch_timer.stop()

func _is_blocking_offer_dialog_open() -> bool:
	return _dilemma_dialog.visible or _draft_dialog.visible or _publisher_dialog.visible

func _on_state_changed(payload: StateSnapshotPayload) -> void:
	var ambition: int = payload.ambition
	var instability: int = payload.instability
	var runway_days: int = payload.runway_days
	var soul: int = payload.soul

	_ambition_value.text = "Ambition: %d" % ambition
	_instability_value.text = "Instability: %d" % instability
	_runway_value.text = "Runway Days: %d" % runway_days
	_features_value.text = "Features: %d" % payload.features_shipped
	_soul_value.text = "Soul: %d" % soul
	_meta_value.text = "Run %d of 3" % payload.current_run
	_instability_visual = clampf(float(instability) / 100.0, 0.0, 1.0)
	# Archetype-aware ceiling pressure: ramps from 0 at the top of the safe zone
	# to 1 at the archetype ceiling. Wobble intensifies near the ceiling independently
	# of raw instability, so a Shooter run (ceiling 42) feels more chaotic at
	# Instability 38 than an RPG run (ceiling 55) does at the same value.
	# Adjust INSTABILITY_CEILING_ZONE_SIZE to change how early the effect begins.
	var _ceiling: float = float(_chosen_archetype_window[1])
	_instability_ceiling_pressure = clampf(
		(float(instability) - (_ceiling - float(INSTABILITY_CEILING_ZONE_SIZE))) / float(INSTABILITY_CEILING_ZONE_SIZE),
		0.0, 1.0
	)
	# Soul label color shifts at the two danger thresholds from the GDD:
	# ≤ 6: exhaustion zone (Fix Bugs tooltip already warns), amber signal.
	# ≤ 3: alarm — one more Fix Bugs destroys financial viability.
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
		_runway_gauge.value = float(clampi(runway_days, 0, 21))
	if _soul_gauge != null:
		_soul_gauge.value = float(clampi(soul, 0, 15))

	var runway_empty: bool = runway_days <= 0
	_update_ship_button_danger(runway_days)
	_update_action_tooltips(payload)
	if not _menu_active and not _run_ended:
		_fix_bugs_button.disabled = runway_empty
		_dev_log_button.disabled = runway_empty
		if runway_empty:
			# Runway depleted — Ship is the only remaining action regardless of board state.
			_ship_button.disabled = false
		else:
			# Ship blocked on empty board unless runway forces it (player must proceed).
			var board_empty: bool = payload.features_shipped == 0
			_ship_button.disabled = board_empty
			if board_empty:
				_ship_button.tooltip_text = _S.get_string("tooltips", "ship_empty")

# -- Event Bus: Core Gameplay --
func _on_feature_added(card: FeatureCard) -> void:
	_feature_board.add_feature_to_board(card)
	_append_log(_S.get_string("log_messages", "feature_added") % card.feature_name)

func _on_threshold_event(payload: ThresholdEventPayload) -> void:
	var effect_parts: PackedStringArray = []
	for key in payload.effects.keys():
		effect_parts.append("%s %+d" % [String(key), int(payload.effects[key])])
	var effect_text: String = ""
	if not effect_parts.is_empty():
		effect_text = " (Effects: %s)" % ", ".join(effect_parts)
	_append_log("[%s] %s%s" % [payload.severity.to_upper(), payload.message, effect_text])

func _on_dilemma_offered(payload: DilemmaOfferPayload) -> void:
	if _menu_active or _run_ended:
		return
	_pending_dilemma = payload.to_dictionary()
	var choices: Array[Dictionary] = payload.choices
	if not OfferLogicUtils.has_valid_offer_entries(choices, 2, "label"):
		push_warning("Ignoring malformed dilemma payload")
		return
	var choice_a: Dictionary = choices[0]
	var choice_b: Dictionary = choices[1]
	_dilemma_dialog.title = OfferDialogTextUtils.format_dilemma_title(payload.title)
	var cards: Array[Dictionary] = [
		{
			"title": OfferDialogTextUtils.format_dilemma_choice_label(payload.title, String(choice_a.get("label", "Choice A"))),
			"effects": choice_a.get("effects", {}),
			"on_pick": func(): _dilemma_dialog.get_ok_button().pressed.emit(),
		},
		{
			"title": OfferDialogTextUtils.format_dilemma_choice_label(payload.title, String(choice_b.get("label", "Choice B"))),
			"effects": choice_b.get("effects", {}),
			"on_pick": func(): _dilemma_dialog.get_cancel_button().pressed.emit(),
		},
	]
	_start_choice_context("dilemma", payload.title, payload.description, payload.title == "Publisher Ultimatum")
	DialogSetupUtils.inject_pick_cards(_dilemma_dialog, payload.description, cards)
	_dilemma_dialog.popup_centered(DILEMMA_DIALOG_SIZE)

func _on_draft_offer(payload: DraftOfferPayload) -> void:
	if _menu_active or _run_ended:
		return
	_pending_draft_offer = payload.to_dictionary()
	var picks: Array[Dictionary] = payload.picks
	if not OfferLogicUtils.has_valid_offer_entries(picks, 3, "title"):
		push_warning("Ignoring malformed draft payload")
		return
	var pick_a: Dictionary = picks[0]
	var pick_b: Dictionary = picks[1]
	var pick_c: Dictionary = picks[2]
	_draft_dialog.title = payload.title
	if _draft_pick_c_button != null:
		_draft_pick_c_button.visible = false
	var cards: Array[Dictionary] = [
		{
			"title": String(pick_a.get("title", "Pick A")),
			"effects": pick_a.get("effects", {}),
			"on_pick": func(): _draft_dialog.get_ok_button().pressed.emit(),
		},
		{
			"title": String(pick_b.get("title", "Pick B")),
			"effects": pick_b.get("effects", {}),
			"on_pick": func(): _draft_dialog.get_cancel_button().pressed.emit(),
		},
		{
			"title": String(pick_c.get("title", "Pick C")),
			"effects": pick_c.get("effects", {}),
			"on_pick": func():
				_draft_dialog.hide()
				_draft_dialog.custom_action.emit(StringName("pick_c")),
		},
	]
	_start_choice_context("draft", payload.title, payload.description, false)
	DialogSetupUtils.inject_pick_cards(_draft_dialog, payload.description, cards)
	_draft_dialog.popup_centered(DRAFT_DIALOG_SIZE)

func _on_day_spent(payload: DaySpentPayload) -> void:
	if payload.reason == "add_feature" or payload.runway_days <= 0:
		_rebuild_daily_offer()

func _on_runway_depleted(_payload: RunwayDepletedPayload) -> void:
	_append_log(_S.get_string("log_messages", "runway_depleted"))
	if not _menu_active and not _run_ended:
		_fix_bugs_button.disabled = true
		_dev_log_button.disabled = true

func _on_reviews_generated(payload: ReviewsGeneratedPayload) -> void:
	_current_reviews_payload = payload
	_current_ship_results = payload.to_dictionary()
	var is_cycle_end: bool = _game_state != null and _game_state.is_cycle_complete()
	if is_cycle_end:
		_post_ship_sequence = [
			_show_gap_visualizer_dialog,
			_show_mechanics_highlights_dialog,
			_show_cycle_legacy_dialog,
			_show_end_run_dialog,
		]
	else:
		_post_ship_sequence = [
			_show_gap_visualizer_dialog,
			_show_mechanics_highlights_dialog,
			_show_end_run_dialog,
		]
	var review_text: String = PresentationTextUtils.build_review_roulette_text(payload.raw_results)
	if _review_content != null:
		_review_content.text = review_text
		_review_content.scroll_to_line(0)
	else:
		_review_dialog.dialog_text = review_text
	_review_dialog.popup_centered(REVIEW_DIALOG_SIZE)
	_update_card_unlock_progress()

func _advance_post_ship_sequence() -> void:
	if _post_ship_sequence.is_empty():
		return
	var next: Callable = _post_ship_sequence.pop_front()
	next.call()

func _append_log(message: String) -> void:
	print(message)

func _setup_card_unlock_progress() -> void:
	_card_unlock_progress_label = HudUiUtils.create_card_unlock_progress_label($"%LeftColumn")

func _update_card_unlock_progress() -> void:
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

func _on_viewport_size_changed() -> void:
	_apply_responsive_layout()

func _apply_responsive_layout() -> void:
	_action_panel.custom_minimum_size = Vector2.ZERO

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_select") and not _menu_active and not _run_ended and not _is_blocking_offer_dialog_open():
		_show_help_dialog()

	if _menu_active:
		_wobble_root.position = Vector2.ZERO
		_wobble_root.modulate = Color(1.0, 1.0, 1.0)
		_jank_tint.visible = false
		_scanline_overlay.visible = false
		_restore_ui_texts()
		return

	_jank_time += delta
	# Wobble + glitch — activate above 0.25 instability visual.
	if _instability_visual >= 0.25:
		_glitch_offset = JankVisualUtils.next_glitch_offset(_glitch_offset, _instability_visual, delta, _ui_rng, _instability_ceiling_pressure)
		_wobble_root.position = JankVisualUtils.compute_wobble_position(_jank_time, _instability_visual, _glitch_offset, WOBBLE_CLAMP, _instability_ceiling_pressure)
		_wobble_root.modulate = JankVisualUtils.compute_wobble_modulate(_instability_visual)
	else:
		_glitch_offset = Vector2.ZERO
		_wobble_root.position = Vector2.ZERO
		_wobble_root.modulate = Color.WHITE

	# Screen tint — activate above 0.25.
	_jank_tint.visible = _instability_visual >= 0.25
	if _instability_visual >= 0.25:
		_jank_tint.color = JankVisualUtils.compute_jank_tint_color(_instability_visual)

	# Scanlines — activate above 0.45.
	_scanline_overlay.visible = _instability_visual >= 0.45
	if _instability_visual >= 0.45 and _scanline_material != null:
		_scanline_material.set_shader_parameter("opacity", JankVisualUtils.compute_scanline_opacity(_instability_visual))
		_scanline_material.set_shader_parameter("speed", JankVisualUtils.compute_scanline_speed(_instability_visual))
		_scanline_material.set_shader_parameter("density", JankVisualUtils.compute_scanline_density(_instability_visual))

	# Text corruption — gated at 0.65 inside JankVisualUtils.step_text_corruption_timer.
	var text_step: Dictionary = JankVisualUtils.step_text_corruption_timer(_text_corruption_timer, delta, _instability_visual)
	_text_corruption_timer = float(text_step.get("timer", _text_corruption_timer))
	if bool(text_step.get("apply_corruption", false)):
		_apply_ui_corruption()
	elif bool(text_step.get("restore_text", false)):
		_restore_ui_texts()

func _setup_scanline_shader() -> void:
	_scanline_material = ShaderMaterial.new()
	_scanline_material.shader = SCANLINE_SHADER
	_scanline_overlay.material = _scanline_material

func _apply_janky_ui_theme() -> void:
	var panels: Array[Node] = [
		$"%HeaderPanel",
		$"%LeftColumn",
		$"%StatsPanel",
		$"%ActionPanel",
	]
	ThemeUtils.apply_janky_panel_theme(panels, _ui_rng)

func _update_ship_button_danger(runway_days: int) -> void:
	JankVisualUtils.update_ship_button_danger(_ship_button, runway_days, INITIAL_RUNWAY_DAYS)

func _on_start_run_pressed() -> void:
	_start_new_run()

func _on_reset_game_button_pressed() -> void:
	if _reset_confirm_dialog != null:
		_reset_confirm_dialog.popup_centered(_reset_confirm_dialog.min_size)

func _on_reset_game_confirmed() -> void:
	if _game_state != null:
		_game_state.start_new_cycle()
	_show_main_menu()

func _on_minimal_text_toggled(_enabled: bool) -> void:
	UiStrings.set_minimal_mode(_minimal_text_toggle.button_pressed)
	_save_ui_prefs()

func _sync_run_start_settings() -> void:
	if _minimal_text_toggle != null:
		_minimal_text_toggle.button_pressed = UiStrings.is_minimal_mode()

func _save_ui_prefs() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("ui", "minimal_text", UiStrings.is_minimal_mode())
	cfg.save("user://ui_prefs.cfg")

func _load_ui_prefs() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load("user://ui_prefs.cfg") == OK:
		UiStrings.set_minimal_mode(bool(cfg.get_value("ui", "minimal_text", false)))

func _on_review_dialog_closed() -> void:
	_advance_post_ship_sequence()

func _show_gap_visualizer_dialog() -> void:
	if _gap_visualizer_dialog == null or _gap_visualizer_content == null:
		_advance_post_ship_sequence()
		return
	var ambition: int = _game_state.ambition if _game_state != null else 0
	var instability: int = _game_state.instability if _game_state != null else 0
	var soul: int = _game_state.soul if _game_state != null else 0
	var archetype: String = ""
	if _game_state != null and _game_state.has_method("get_chosen_archetype"):
		archetype = String(_game_state.get_chosen_archetype())
	var completed_run: int = _game_state.get_last_completed_run() if _game_state != null else 1
	var config: GameConfig = _game_state.get_game_config() if _game_state != null else null
	var content: String = PresentationTextUtils.build_gap_visualizer_text(
		_current_ship_results, ambition, instability, soul, archetype, config, completed_run
	)
	_gap_visualizer_content.text = content
	_gap_visualizer_content.scroll_to_line(0)
	_gap_visualizer_dialog.popup_centered(Vector2i(700, 500))

func _on_gap_visualizer_confirmed() -> void:
	_advance_post_ship_sequence()

func _show_mechanics_highlights_dialog() -> void:
	if _mechanics_highlights_dialog == null or _mechanics_highlights_content == null:
		_advance_post_ship_sequence()
		return
	_mechanics_highlights_content.text = PresentationTextUtils.build_jank_discovery_text(_current_ship_results)
	_mechanics_highlights_content.scroll_to_line(0)
	_mechanics_highlights_dialog.popup_centered(Vector2i(900, 600))

func _on_mechanics_highlights_confirmed() -> void:
	_advance_post_ship_sequence()

func _build_previously_on_dialog() -> AcceptDialog:
	var dialog: AcceptDialog = AcceptDialog.new()
	dialog.name = "PreviouslyOnDialog"
	dialog.title = "Previously On..."
	dialog.min_size = Vector2i(700, 460)
	dialog.set_close_on_escape(true)
	dialog.get_ok_button().text = "Continue"
	dialog.get_ok_button().add_theme_font_size_override("font_size", 20)
	dialog.get_label().visible = false
	var content: RichTextLabel = RichTextLabel.new()
	content.name = "PreviouslyOnContent"
	content.bbcode_enabled = true
	content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.scroll_active = true
	content.selection_enabled = false
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 16.0
	content.offset_top = 52.0
	content.offset_right = -16.0
	content.offset_bottom = -60.0
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_font_size_override("normal_font_size", 15)
	dialog.add_child(content)
	add_child(dialog)
	return dialog

func _show_previously_on(cycle: Dictionary) -> void:
	if _previously_on_dialog == null:
		return
	var current_run: int = int(cycle.get("current_run", 1))
	if current_run <= 1:
		return

	var content_node: RichTextLabel = _previously_on_dialog.get_node_or_null("PreviouslyOnContent") as RichTextLabel
	if content_node == null:
		return
	var prev_run: int = current_run - 1
	var run_summary: Dictionary = _game_state.get_run_summary(prev_run) if _game_state != null and _game_state.has_method("get_run_summary") else {}
	var config: GameConfig = _game_state.get_game_config() if _game_state != null else null
	content_node.text = PresentationTextUtils.build_previously_on_text(run_summary, current_run, config)
	content_node.scroll_to_line(0)
	_previously_on_dialog.popup_centered(_previously_on_dialog.min_size)

func _build_cycle_legacy_dialog() -> AcceptDialog:
	var dialog: AcceptDialog = AcceptDialog.new()
	dialog.title = _S.get_string("popups", "cycle_legacy_title")
	dialog.min_size = Vector2i(760, 480)
	dialog.set_close_on_escape(false)
	dialog.get_ok_button().text = "Continue"
	dialog.get_ok_button().add_theme_font_size_override("font_size", 20)
	dialog.get_label().visible = false
	var content: RichTextLabel = RichTextLabel.new()
	content.name = "CycleLegacyContent"
	content.bbcode_enabled = true
	content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.scroll_active = true
	content.selection_enabled = false
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 16.0
	content.offset_top = 52.0
	content.offset_right = -16.0
	content.offset_bottom = -60.0
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_font_size_override("normal_font_size", 16)
	dialog.add_child(content)
	_cycle_legacy_content = content
	add_child(dialog)
	return dialog

func _show_cycle_legacy_dialog() -> void:
	if _cycle_legacy_dialog == null or _game_state == null:
		_advance_post_ship_sequence()
		return
	var cycle_state: Dictionary = _game_state.get_cycle_state()
	var text: String = PresentationTextUtils.build_cycle_legacy_text(cycle_state)
	if _cycle_legacy_content != null:
		_cycle_legacy_content.text = text
		_cycle_legacy_content.scroll_to_line(0)
	_cycle_legacy_dialog.popup_centered(_cycle_legacy_dialog.min_size)

func _on_cycle_legacy_confirmed() -> void:
	_advance_post_ship_sequence()

func _show_end_run_dialog() -> void:
	if _run_ended:
		_configure_end_run_dialog()
		_end_run_dialog.popup_centered(END_DIALOG_SIZE)

func _configure_end_run_dialog() -> void:
	if _end_run_dialog == null or _game_state == null:
		return
	var completed_run: int = _game_state.get_last_completed_run()
	var is_complete: bool = _game_state.is_cycle_complete()

	_end_run_dialog.get_cancel_button().text = _S.get_string("buttons", "end_run_menu")

	if is_complete:
		_end_run_dialog.title = _S.get_string("popups", "end_run_title_last")
		_end_run_dialog.dialog_text = _S.get_string("popups", "end_run_text_last")
		_end_run_dialog.get_ok_button().text = _S.get_string("buttons", "end_run_continue_cycle")
		return

	match completed_run:
		1:
			_end_run_dialog.title = _S.get_string("popups", "end_run_title_initial")
			_end_run_dialog.dialog_text = _S.get_string("popups", "end_run_text_initial")
			_end_run_dialog.get_ok_button().text = _S.get_string("buttons", "end_run_continue_second")
		2:
			_end_run_dialog.title = _S.get_string("popups", "end_run_title_second")
			_end_run_dialog.dialog_text = _S.get_string("popups", "end_run_text_second")
			_end_run_dialog.get_ok_button().text = _S.get_string("buttons", "end_run_continue_last")
		_:
			_end_run_dialog.title = _S.get_string("popups", "end_run_title_default")
			_end_run_dialog.dialog_text = _S.get_string("popups", "end_run_text_default")
			_end_run_dialog.get_ok_button().text = _S.get_string("buttons", "end_run_continue_default")

func _on_end_run_dialog_new_run() -> void:
	# If cycle is complete, reset before starting next.
	if _game_state != null and _game_state.is_cycle_complete():
		_game_state.start_new_cycle()
	_show_main_menu()

func _on_end_run_dialog_menu() -> void:
	# Cycle is resolved — reset before returning so the menu shows Run 1 of 3.
	# Mid-cycle menu returns (runs 1 and 2) skip this; cycle state is preserved.
	if _game_state != null and _game_state.is_cycle_complete():
		_game_state.start_new_cycle()
	_show_main_menu()

func _on_dilemma_dialog_choice_a() -> void:
	_stop_choice_context()
	if OfferLogicUtils.apply_choice_if_pending(_game_state, _pending_dilemma, &"apply_dilemma_choice", 0):
		_append_log(_S.get_string("log_messages", "dilemma_a"))
	_pending_dilemma.clear()

func _on_dilemma_dialog_choice_b() -> void:
	_stop_choice_context()
	if OfferLogicUtils.apply_choice_if_pending(_game_state, _pending_dilemma, &"apply_dilemma_choice", 1):
		_append_log(_S.get_string("log_messages", "dilemma_b"))
	_pending_dilemma.clear()

func _on_draft_dialog_pick_a() -> void:
	_stop_choice_context()
	if OfferLogicUtils.apply_choice_if_pending(_game_state, _pending_draft_offer, &"apply_draft_pick", 0):
		_append_log(_S.get_string("log_messages", "draft_a"))
	_pending_draft_offer.clear()

func _on_draft_dialog_pick_b() -> void:
	_stop_choice_context()
	if OfferLogicUtils.apply_choice_if_pending(_game_state, _pending_draft_offer, &"apply_draft_pick", 1):
		_append_log(_S.get_string("log_messages", "draft_b"))
	_pending_draft_offer.clear()

func _on_draft_dialog_custom_action(action: StringName) -> void:
	if String(action) != "pick_c":
		return
	_stop_choice_context()
	if OfferLogicUtils.apply_choice_if_pending(_game_state, _pending_draft_offer, &"apply_draft_pick", 2):
		_append_log(_S.get_string("log_messages", "draft_c"))
		_pending_draft_offer.clear()
	_draft_dialog.hide()

func _start_new_run() -> void:
	if _game_state == null:
		return
	_menu_active = false
	_run_ended = false
	_main_menu_layer.visible = false
	_feature_board.clear_board()
	_game_state.reset_run()
	_update_card_unlock_progress()
	_stop_choice_context()
	_fix_bugs_button.disabled = false
	_dev_log_button.disabled = false
	_ship_button.disabled = false
	if _crunch_timer != null:
		_crunch_timer.stop()
	# Show archetype picker before revealing the card backlog.
	_show_archetype_select_dialog()

func _show_archetype_select_dialog() -> void:
	if _archetype_select_dialog == null:
		_begin_run_gameplay()
		return
	_archetype_select_dialog.popup_centered(Vector2i(560, 360))

func _on_archetype_dialog_confirmed() -> void:
	if _game_state != null:
		var key: String = _archetype_select_dialog.get_meta("ok_archetype_key", "rpg")
		_game_state.set_archetype(key)
	_begin_run_gameplay()

func _on_archetype_dialog_canceled() -> void:
	# Cancel button is hidden; this handler is a safety fallback — default to RPG.
	if _game_state != null:
		_game_state.set_archetype("rpg")
	_begin_run_gameplay()

func _on_archetype_dialog_custom_action(action: StringName) -> void:
	if _game_state != null:
		_game_state.set_archetype(String(action))
	_archetype_select_dialog.hide()
	_begin_run_gameplay()

func _begin_run_gameplay() -> void:
	_backlog_cards.clear()
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
		_show_previously_on(cycle)

func _show_main_menu() -> void:
	if _game_state != null and _game_state.is_cycle_complete() and _game_state.get_last_completed_run() == 0:
		_game_state.start_new_cycle()
	_menu_active = true
	_run_ended = false
	_main_menu_layer.visible = true
	_fix_bugs_button.disabled = true
	_dev_log_button.disabled = true
	_ship_button.disabled = true
	_crunch_timer.stop()
	_feature_board.clear_board()
	_stop_choice_context()
	_backlog_cards.clear()
	_refresh_backlog_list()
	_sync_run_start_settings()
	_append_log(_S.get_string("log_messages", "main_menu"))

	# Show cycle position on the start button.
	if _game_state != null and _start_run_button != null:
		var run_num: int = _game_state.current_run
		_start_run_button.text = "START RUN %d OF 3" % run_num
		# Reset button only makes sense once there is a campaign in progress.
		if _reset_game_button != null:
			_reset_game_button.visible = run_num > 1
			_reset_game_button.add_theme_color_override("font_color", Color(0.75, 0.45, 0.45))

	# Update subtitle with tone-appropriate copy per run.
	if _menu_subtitle != null and _game_state != null:
		var run_num_copy: int = _game_state.current_run
		match run_num_copy:
			1:
				_menu_subtitle.text = "Three sprints. Ship something ambitious, a little broken, made with love."
			2:
				_menu_subtitle.text = "You know enough to make meaningful mistakes."
			_:
				_menu_subtitle.text = "Racing a known target. This is the one."

# --- HUD helpers ---

func _update_action_tooltips(payload: StateSnapshotPayload) -> void:
	HudUiUtils.update_action_tooltips(_fix_bugs_button, _dev_log_button, _ship_button, payload.runway_days, payload.instability, payload.soul)

func _on_archetype_chosen_visual(archetype: String) -> void:
	if _game_state == null:
		return
	var config: GameConfig = _game_state.get_game_config() as GameConfig
	if config == null:
		return
	var window: Array[int] = EndingResolver.get_goldilocks_window_for_archetype(config, archetype)
	_chosen_archetype_window = window
	_update_goldilocks_markers(window[0], window[1])

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
	# Defining Game is locked in Run 1 — suppress the warning to avoid misleading the player.
	if _game_state.current_run <= 1:
		_soul_risk_label.visible = false
		return
	var config: GameConfig = _game_state.get_game_config() as GameConfig
	# Soul floor and Fix Bugs cost read from GameConfig so they stay in sync with balance edits.
	var soul_floor: int = config.goldilocks_soul_min if config != null else 7
	var fix_cost: int = config.fix_bugs_soul_cost if config != null else 2
	# Lost: soul is already below the Defining Game floor — ineligible this run.
	# At risk: soul is ≤ floor+cost-1, meaning one more Fix Bugs would drop below the floor.
	# Adjust soul_floor and fix_cost in game_config.tres to move these thresholds.
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

func _snapshot_from_state() -> StateSnapshotPayload:
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

func _setup_synergy_toast() -> void:
	_synergy_toast = SynergyToastUtils.setup_synergy_toast(self)

func _show_synergy_toast(flavor: String, instability_delta: int, soul_delta: int) -> void:
	_synergy_toast_timer = SynergyToastUtils.show_synergy_toast(
		self, _synergy_toast, _synergy_toast_timer,
		flavor, instability_delta, soul_delta,
		SYNERGY_TOAST_DURATION, SYNERGY_TOAST_FADE_IN,
		Callable(self, "_on_synergy_toast_timeout")
	)

func _on_synergy_toast_timeout() -> void:
	if _synergy_toast == null:
		return
	var fade_out_tween: Tween = SynergyToastUtils.fade_out_synergy_toast(self, _synergy_toast, SYNERGY_TOAST_FADE_OUT)
	if fade_out_tween == null:
		return
	await fade_out_tween.finished
	_synergy_toast.hide()
	if _synergy_toast_timer != null:
		_synergy_toast_timer.queue_free()
		_synergy_toast_timer = null

func _show_help_dialog() -> void:
	if _help_dialog == null or _menu_active or _run_ended or _is_blocking_offer_dialog_open():
		return
	_help_dialog.popup_centered(_help_dialog.min_size)

func _apply_ui_corruption() -> void:
	JankVisualUtils.apply_ui_corruption(_corruptible_controls, _base_control_text, _ui_rng, _instability_visual)

func _restore_ui_texts() -> void:
	JankVisualUtils.restore_ui_texts(_corruptible_controls, _base_control_text)

## Sets up tracking for the active dialog choice context (dilemma/draft).
func _start_choice_context(context: String, title: String, body_text: String, _publisher_alert: bool) -> void:
	_choice_context = context
	_choice_base_title = title
	_choice_base_text = body_text
	_update_choice_dialog_copy()

func _stop_choice_context() -> void:
	_choice_context = ""
	_choice_base_title = ""
	_choice_base_text = ""

func _update_choice_dialog_copy() -> void:
	match _choice_context:
		"draft":
			_draft_dialog.title = _choice_base_title
			_draft_dialog.dialog_text = _choice_base_text
		"dilemma":
			_dilemma_dialog.title = _choice_base_title
			_dilemma_dialog.dialog_text = _choice_base_text
