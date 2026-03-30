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
# Wobble is applied to RootMargin (layout_mode=1, Anchors) whose natural
# rest position is Vector2.ZERO. Writing position on a Container child like
# Shell (layout_mode=2) races against the layout engine; targeting RootMargin
# avoids that conflict. The ±WOBBLE_CLAMP displacement is smaller than the
# 12 px margin, so content never clips outside the Main boundary.
const WOBBLE_CLAMP: float = 10.0
const SCANLINE_SHADER: Shader = preload("res://shaders/scanline.gdshader")

# Stat display labels
@onready var _ambition_value: Label = $"%AmbitionValue"
@onready var _instability_value: Label = $"%InstabilityValue"
@onready var _runway_value: Label = $"%RunwayValue"
@onready var _features_value: Label = $"%FeaturesValue"
@onready var _soul_value: Label = $"%SoulValue"
@onready var _identity_value: Label = $"%IdentityValue"
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
@onready var _publisher_trust_mode_toggle: CheckBox = $"%PublisherTrustModeToggle"

# Visual corruption and UI effects
@onready var _scanline_overlay: ColorRect = $"%ScanlineOverlay"
@onready var _jank_tint: ColorRect = $"%JankTint"
@onready var _wobble_root: MarginContainer = $"%RootMargin"
@onready var _body_split: HSplitContainer = $"%Body"
@onready var _action_panel: PanelContainer = $"%ActionPanel"

# Timer (intentionally disabled for day progression)
@onready var _crunch_timer: Timer = $"%CrunchTimer"

# Autoload references — accessed via global autoload names, no path string needed.
@onready var _game_state: Node = AppState
@onready var _event_bus: Node = GameEvents
@onready var _review_service: Node = ReviewService
var _scanline_material: ShaderMaterial
var _draft_pick_c_button: Button
var _publisher_pick_c_button: Button
var _pending_dilemma: Dictionary = {}
var _pending_draft_offer: Dictionary = {}
var _pending_publisher_meeting: Dictionary = {}
var _latest_meta_progress: Dictionary = {}
var _choice_countdown_remaining: int = 0
var _choice_context: String = ""
var _choice_default_index: int = -1
var _choice_base_title: String = ""
var _choice_base_text: String = ""
var _publisher_alert_active: bool = false
var _ui_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _text_corruption_timer: float = 0.0
var _corruptible_controls: Array[Control] = []
var _base_control_text: Dictionary = {}
var _publisher_flash_style: StyleBoxFlat = null
var _review_content: RichTextLabel
var _synergy_toast: PanelContainer = null
var _synergy_toast_timer: Timer = null
var _ship_summary_dialog: ConfirmationDialog = null
var _help_dialog: AcceptDialog = null
var _ambition_gauge: ProgressBar = null
var _instability_gauge: ProgressBar = null
var _soul_gauge: ProgressBar = null
var _runway_gauge: ProgressBar = null
var _is_first_run: bool = false
var _menu_active: bool = false
var _run_ended: bool = false
var _mechanics_highlights_dialog: AcceptDialog = null
var _mechanics_highlights_content: RichTextLabel = null
var _jank_meter_dialog: AcceptDialog = null
var _jank_meter_content: RichTextLabel = null
var _current_ship_results: Dictionary = {}
var _current_reviews_payload: ReviewsGeneratedPayload = ReviewsGeneratedPayload.new()
var _post_ship_sequence: Array[Callable] = []
var _studio_briefing_dialog: ConfirmationDialog = null
var _studio_briefing_content: RichTextLabel = null
var _briefing_pending_for_completed_run: bool = false
var _backlog_cards: Array[Resource] = []
var _last_offer_runway_day: int = -1
var _template_cards: Array[Resource] = []
var _templates_loaded: bool = false
var _jank_time: float = 0.0
var _glitch_offset: Vector2 = Vector2.ZERO
var _instability_visual: float = 0.0
var _card_unlock_progress_label: Label

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
	_wire_events()
	_show_main_menu()
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_apply_responsive_layout()
	set_process(true)

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
		func(): _resume_crunch_timer_after_dialog(),
		Callable(self, "_on_ship_summary_confirmed"),
		Callable(self, "_on_ship_summary_canceled"),
		Callable(self, "_on_mechanics_highlights_confirmed"),
		Callable(self, "_on_jank_meter_confirmed")
	)
	_help_dialog = refs.help_dialog
	_ship_summary_dialog = refs.ship_summary_dialog
	_mechanics_highlights_dialog = refs.mechanics_dialog
	_mechanics_highlights_content = refs.mechanics_content
	_jank_meter_dialog = refs.jank_dialog
	_jank_meter_content = refs.jank_content
	_review_content = refs.review_content
	_draft_pick_c_button = refs.draft_pick_c_button
	_publisher_pick_c_button = refs.publisher_pick_c_button

	var briefing_parts: Dictionary = DialogSetupUtils.build_studio_briefing_dialog(
		self,
		_on_briefing_keep_legacy,
		_on_briefing_take_legacy
	)
	_studio_briefing_dialog = briefing_parts.get("dialog") as ConfirmationDialog
	_studio_briefing_content = briefing_parts.get("content") as RichTextLabel

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

# -- UI Actions --
func _show_ship_summary() -> void:
	if _ship_summary_dialog == null or _game_state == null:
		return
	var predicted_score: float = _game_state.calculate_predicted_score()
	var highlights: Array[String] = []
	if _review_service != null and _review_service.has_method("generate_mechanics_highlights"):
		highlights = _review_service.generate_mechanics_highlights(_game_state.feature_board)

	var content: String = PresentationTextUtils.build_ship_summary_text(_game_state, predicted_score, highlights)
	
	var content_label: RichTextLabel = _ship_summary_dialog.get_child(0) as RichTextLabel
	if content_label != null:
		content_label.text = content
		content_label.scroll_to_line(0)
	
	_pause_crunch_timer_for_dialog()
	_ship_summary_dialog.popup_centered(_ship_summary_dialog.min_size)

func _on_ship_summary_confirmed() -> void:
	if _game_state != null:
		_run_ended = true
		_fix_bugs_button.disabled = true
		_dev_log_button.disabled = true
		_ship_button.disabled = true
		_crunch_timer.stop()
		_game_state.ship_it()
		_briefing_pending_for_completed_run = true

func _on_ship_summary_canceled() -> void:
	_resume_crunch_timer_after_dialog()

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
	_crunch_timer.timeout.connect(_on_crunch_timer_timeout)
	_start_run_button.pressed.connect(_on_start_run_pressed)
	_publisher_trust_mode_toggle.toggled.connect(_on_publisher_trust_mode_toggled)
	_review_dialog.confirmed.connect(_on_review_dialog_closed)
	_end_run_dialog.confirmed.connect(_on_end_run_dialog_new_run)
	_end_run_dialog.canceled.connect(_on_end_run_dialog_menu)
	_dilemma_dialog.confirmed.connect(_on_dilemma_dialog_choice_a)
	_dilemma_dialog.canceled.connect(_on_dilemma_dialog_choice_b)
	_draft_dialog.confirmed.connect(_on_draft_dialog_pick_a)
	_draft_dialog.canceled.connect(_on_draft_dialog_pick_b)
	_draft_dialog.custom_action.connect(_on_draft_dialog_custom_action)
	_publisher_dialog.confirmed.connect(_on_publisher_dialog_choice_a)
	_publisher_dialog.canceled.connect(_on_publisher_dialog_choice_b)
	_publisher_dialog.custom_action.connect(_on_publisher_dialog_custom_action)

	if _event_bus != null:
		_event_bus.state_changed.connect(_on_state_changed)
		_event_bus.feature_added.connect(_on_feature_added)
		_event_bus.interaction_triggered.connect(_on_interaction_triggered)
		_event_bus.threshold_event.connect(_on_threshold_event)
		_event_bus.dilemma_offered.connect(_on_dilemma_offered)
		_event_bus.draft_offer.connect(_on_draft_offer)
		_event_bus.publisher_meeting_offered.connect(_on_publisher_meeting_offered)
		_event_bus.run_identity_changed.connect(_on_run_identity_changed)
		_event_bus.meta_progress_updated.connect(_on_meta_progress_updated)
		_event_bus.day_spent.connect(_on_day_spent)
		_event_bus.runway_depleted.connect(_on_runway_depleted)
		_event_bus.reviews_generated.connect(_on_reviews_generated)
		if _event_bus.has_signal("legacy_resolved"):
			_event_bus.legacy_resolved.connect(_on_legacy_resolved)
		if _event_bus.has_signal("milestone_reached"):
			_event_bus.milestone_reached.connect(_on_milestone_reached)

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
		template,
		CUSTOM_CARDS_PATH,
		_game_state,
		Callable(self, "_card_id_from_resource")
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

func _on_crunch_timer_timeout() -> void:
	# Intentionally disabled: runway day progression must only happen from explicit user actions.
	if _crunch_timer != null and not _crunch_timer.is_stopped():
		_crunch_timer.stop()

func _is_blocking_offer_dialog_open() -> bool:
	return _dilemma_dialog.visible or _draft_dialog.visible or _publisher_dialog.visible

func _pause_crunch_timer_for_dialog() -> void:
	if _crunch_timer != null:
		_crunch_timer.stop()

func _resume_crunch_timer_after_dialog() -> void:
	# Intentionally no-op: timer is not used for day progression anymore.
	return

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
	# Show style pressure alongside run identity so designers can watch accumulation in play.
	var sp: Dictionary = payload.style_points
	var pressures: String = "(CJ:%d PC:%d CD:%d)" % [sp.get("cult_jank", 0), sp.get("prestige_collapse", 0), sp.get("community_darling", 0)]
	_identity_value.text = "Run Identity: %s %s" % [payload.run_identity, pressures]
	_meta_value.text = "Meta: Tier %d" % payload.meta_studio_tier
	_instability_visual = clampf(float(instability) / 100.0, 0.0, 1.0)
	_soul_value.add_theme_color_override("font_color", Color(0.60, 0.95, 0.72).lerp(Color(1.0, 0.82, 0.48), _instability_visual))

	# Update gauges
	if _ambition_gauge != null:
		_ambition_gauge.value = float(clampi(ambition, 0, 100))
	if _instability_gauge != null:
		_instability_gauge.value = float(clampi(instability, 0, 100))
	if _runway_gauge != null:
		_runway_gauge.value = float(clampi(runway_days, 0, 21))
	if _soul_gauge != null:
		_soul_gauge.value = float(clampi(soul, 0, 100))

	var runway_empty: bool = runway_days <= 0
	_update_ship_button_danger(runway_days)
	_update_action_tooltips(payload)
	if not _menu_active and not _run_ended:
		_fix_bugs_button.disabled = runway_empty
		_dev_log_button.disabled = runway_empty

# -- Event Bus: Core Gameplay --
func _on_feature_added(card: FeatureCard) -> void:
	_feature_board.add_feature_to_board(card)
	_append_log(_S.get_string("log_messages", "feature_added") % card.feature_name)

func _on_interaction_triggered(payload: InteractionEventPayload) -> void:
	_append_log(_S.get_string("log_messages", "interaction") % [payload.flavor, payload.instability_delta, payload.soul_delta])
	_show_synergy_toast(payload.flavor, payload.instability_delta, payload.soul_delta)

func _on_threshold_event(payload: ThresholdEventPayload) -> void:
	var severity: String = payload.severity.to_upper()
	var message: String = payload.message
	var effects: Dictionary = payload.effects

	var effect_parts: PackedStringArray = []
	for key in effects.keys():
		var value: int = int(effects[key])
		effect_parts.append("%s %+d" % [String(key), value])

	var effect_text: String = ""
	if not effect_parts.is_empty():
		effect_text = " (Effects: %s)" % ", ".join(effect_parts)

	_append_log("[%s] %s%s" % [severity, message, effect_text])

func _on_dilemma_offered(payload: DilemmaOfferPayload) -> void:
	if _menu_active or _run_ended:
		return
	_pending_dilemma = payload.to_dictionary()
	var title: String = payload.title
	var description: String = payload.description
	var choices: Array[Dictionary] = payload.choices
	if not OfferLogicUtils.has_valid_offer_entries(choices, 2, "label"):
		push_warning("Ignoring malformed dilemma payload")
		return

	var choice_a: Dictionary = choices[0]
	var choice_b: Dictionary = choices[1]
	_dilemma_dialog.title = OfferDialogTextUtils.format_dilemma_title(title)
	var label_a: String = OfferDialogTextUtils.format_dilemma_choice_label(title, String(choice_a.get("label", "Choice A")))
	var label_b: String = OfferDialogTextUtils.format_dilemma_choice_label(title, String(choice_b.get("label", "Choice B")))
	_dilemma_dialog.get_ok_button().text = label_a
	_dilemma_dialog.get_cancel_button().text = label_b
	var base_text: String = OfferDialogTextUtils.build_dilemma_dialog_text(title, description, choice_a, choice_b)
	_dilemma_dialog.dialog_text = base_text
	_start_choice_countdown("dilemma", title, base_text, _get_least_favored_choice_index(choices), title == "Publisher Ultimatum")
	_pause_crunch_timer_for_dialog()
	_dilemma_dialog.popup_centered(DILEMMA_DIALOG_SIZE)

func _on_draft_offer(payload: DraftOfferPayload) -> void:
	if _menu_active or _run_ended:
		return
	_pending_draft_offer = payload.to_dictionary()
	var title: String = payload.title
	var description: String = payload.description
	var picks: Array[Dictionary] = payload.picks
	if not OfferLogicUtils.has_valid_offer_entries(picks, 3, "title"):
		push_warning("Ignoring malformed draft payload")
		return

	var pick_a: Dictionary = picks[0]
	var pick_b: Dictionary = picks[1]
	var pick_c: Dictionary = picks[2]
	_draft_dialog.title = title
	var title_a: String = String(pick_a.get("title", "Pick A"))
	var title_b: String = String(pick_b.get("title", "Pick B"))
	var title_c: String = String(pick_c.get("title", "Pick C"))
	_draft_dialog.get_ok_button().text = title_a
	_draft_dialog.get_cancel_button().text = title_b
	if _draft_pick_c_button != null:
		_draft_pick_c_button.text = title_c
	var base_text: String = OfferDialogTextUtils.build_draft_dialog_text(description, pick_a, pick_b, pick_c)
	_draft_dialog.dialog_text = base_text
	_start_choice_countdown("draft", title, base_text, _get_most_unstable_pick_index(picks), false)
	_pause_crunch_timer_for_dialog()
	_draft_dialog.popup_centered(DRAFT_DIALOG_SIZE)

func _on_publisher_meeting_offered(payload: PublisherMeetingOfferPayload) -> void:
	if _menu_active or _run_ended:
		return
	_pending_publisher_meeting = payload.to_dictionary()
	var title: String = payload.title
	var summary: String = payload.summary
	var topic: String = payload.topic
	var grade: String = payload.grade
	var options: Array[Dictionary] = payload.options
	if not OfferLogicUtils.has_valid_offer_entries(options, 3, "label"):
		push_warning("Ignoring malformed publisher meeting payload")
		return

	var option_a: Dictionary = options[0]
	var option_b: Dictionary = options[1]
	var option_c: Dictionary = options[2]
	_publisher_dialog.title = OfferDialogTextUtils.format_publisher_title(title)
	var stance_a: String = OfferDialogTextUtils.format_publisher_stance_label(String(option_a.get("label", "Stance A")))
	var stance_b: String = OfferDialogTextUtils.format_publisher_stance_label(String(option_b.get("label", "Stance B")))
	var stance_c: String = OfferDialogTextUtils.format_publisher_stance_label(String(option_c.get("label", "Stance C")))
	_publisher_dialog.get_ok_button().text = stance_a
	_publisher_dialog.get_cancel_button().text = stance_b
	if _publisher_pick_c_button != null:
		_publisher_pick_c_button.text = stance_c

	var base_text: String = OfferDialogTextUtils.build_publisher_dialog_text(topic, grade, summary, option_a, option_b, option_c)
	_publisher_dialog.dialog_text = base_text
	_start_choice_countdown("publisher_meeting", title, base_text, _pick_safe_publisher_stance(options), false)
	_pause_crunch_timer_for_dialog()
	_publisher_dialog.popup_centered(PUBLISHER_DIALOG_SIZE)

func _on_publisher_dialog_choice_a() -> void:
	_stop_choice_countdown()
	if OfferLogicUtils.apply_choice_if_pending(_game_state, _pending_publisher_meeting, &"apply_publisher_meeting_choice", 0):
		_append_log(_S.get_string("log_messages", "publisher_a"))
	_pending_publisher_meeting.clear()
	_resume_crunch_timer_after_dialog.call_deferred()

func _on_publisher_dialog_choice_b() -> void:
	_stop_choice_countdown()
	if OfferLogicUtils.apply_choice_if_pending(_game_state, _pending_publisher_meeting, &"apply_publisher_meeting_choice", 1):
		_append_log(_S.get_string("log_messages", "publisher_b"))
	_pending_publisher_meeting.clear()
	_resume_crunch_timer_after_dialog.call_deferred()

func _on_publisher_dialog_custom_action(action: StringName) -> void:
	if String(action) != "pick_c":
		return
	_stop_choice_countdown()
	if OfferLogicUtils.apply_choice_if_pending(_game_state, _pending_publisher_meeting, &"apply_publisher_meeting_choice", 2):
		_append_log(_S.get_string("log_messages", "publisher_c"))
		_pending_publisher_meeting.clear()
	_publisher_dialog.hide()
	_resume_crunch_timer_after_dialog()

func _pick_safe_publisher_stance(options: Array) -> int:
	return OfferLogicUtils.pick_safe_publisher_stance(options)

func _on_run_identity_changed(payload: RunIdentityPayload) -> void:
	_append_log(_S.get_string("log_messages", "run_identity") % payload.identity)

func _on_meta_progress_updated(payload: MetaProgressPayload) -> void:
	_latest_meta_progress = payload.to_dictionary()
	_append_log(_S.get_string("log_messages", "meta_updated") % [
		payload.runs_played,
		payload.best_review_score,
		payload.studio_tier,
	])
	_update_card_unlock_progress()

func _on_day_spent(payload: DaySpentPayload) -> void:
	_rebuild_daily_offer()
	_append_log(_S.get_string("log_messages", "day_spent") % [payload.reason, payload.runway_days])

func _on_runway_depleted(_payload: RunwayDepletedPayload) -> void:
	_append_log(_S.get_string("log_messages", "runway_depleted"))
	if not _menu_active and not _run_ended:
		_fix_bugs_button.disabled = true
		_dev_log_button.disabled = true

func _on_reviews_generated(payload: ReviewsGeneratedPayload) -> void:
	# Store results for use in mechanics and jank meter dialogs.
	# Build the post-ship sequence here so the order is explicit and easy to change.
	_current_reviews_payload = payload
	_current_ship_results = payload.to_dictionary()
	_post_ship_sequence = [
		_show_mechanics_highlights_dialog,
		_show_jank_meter_dialog,
		_show_end_run_dialog,
	]

	var review_text: String = PresentationTextUtils.build_review_roulette_text(payload.raw_results)
	if _review_content != null:
		_review_content.text = review_text
		_review_content.scroll_to_line(0)
	else:
		_review_dialog.dialog_text = review_text
	_review_dialog.popup_centered(REVIEW_DIALOG_SIZE)

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
	
	# Get unlocked card count
	var unlocked_count: int = 0
	var total_count: int = 0
	
	if _game_state.has_method("get_all_card_ids") and _game_state.has_method("get_unlocked_card_ids"):
		var all_cards: PackedStringArray = _game_state.get_all_card_ids()
		var unlocked_ids: PackedStringArray = _game_state.get_unlocked_card_ids()
		total_count = all_cards.size()
		for card_id in unlocked_ids:
			if all_cards.has(card_id):
				unlocked_count += 1
	elif _template_cards.size() > 0:
		# Fallback: count template cards
		total_count = _template_cards.size()
		for template in _template_cards:
			if _is_template_unlocked(template):
				unlocked_count += 1
	
	_card_unlock_progress_label.text = CardProgressUtils.build_progress_text(unlocked_count, total_count)
func _on_viewport_size_changed() -> void:
	_apply_responsive_layout()

func _apply_responsive_layout() -> void:
	# Hardcoded 1080p layout for deterministic bounds and no overflow.
	_body_split.split_offset = 296
	_action_panel.custom_minimum_size = Vector2(0.0, 208.0)

func _process(delta: float) -> void:
	# Pause/Help toggle
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
	_glitch_offset = JankVisualUtils.next_glitch_offset(_glitch_offset, _instability_visual, delta, _ui_rng)
	_wobble_root.position = JankVisualUtils.compute_wobble_position(_jank_time, _instability_visual, _glitch_offset, WOBBLE_CLAMP)
	_wobble_root.modulate = JankVisualUtils.compute_wobble_modulate(_instability_visual)

	_jank_tint.visible = true
	_jank_tint.color = JankVisualUtils.compute_jank_tint_color(_instability_visual)

	_scanline_overlay.visible = JankVisualUtils.should_show_scanline(_instability_visual)
	if _scanline_material != null:
		_scanline_material.set_shader_parameter("opacity", JankVisualUtils.compute_scanline_opacity(_instability_visual))

	var text_step: Dictionary = JankVisualUtils.step_text_corruption_timer(_text_corruption_timer, delta, _instability_visual)
	_text_corruption_timer = float(text_step.get("timer", _text_corruption_timer))
	if bool(text_step.get("apply_corruption", false)):
		_apply_ui_corruption()
	elif bool(text_step.get("restore_text", false)):
		_restore_ui_texts()

	if _publisher_alert_active and _dilemma_dialog.visible:
		_update_publisher_flash()

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
	_apply_run_start_settings()
	_start_new_run()

func _on_publisher_trust_mode_toggled(enabled: bool) -> void:
	if _game_state != null and _game_state.has_method("set_publisher_trust_mode_enabled"):
		_game_state.set_publisher_trust_mode_enabled(enabled)

func _apply_run_start_settings() -> void:
	if _game_state == null:
		return
	if _game_state.has_method("set_publisher_trust_mode_enabled"):
		_game_state.set_publisher_trust_mode_enabled(_publisher_trust_mode_toggle.button_pressed)

func _sync_run_start_settings() -> void:
	if _publisher_trust_mode_toggle == null:
		return
	if _game_state != null and _game_state.has_method("is_publisher_trust_mode_enabled"):
		_publisher_trust_mode_toggle.button_pressed = bool(_game_state.is_publisher_trust_mode_enabled())

func _on_review_dialog_closed() -> void:
	_advance_post_ship_sequence()

func _show_mechanics_highlights_dialog() -> void:
	if _mechanics_highlights_dialog == null or _mechanics_highlights_content == null:
		return

	var mechanics_highlights: Array[String] = _current_reviews_payload.mechanics_highlights
	var content: String = PresentationTextUtils.build_mechanics_highlights_text(mechanics_highlights)
	
	_mechanics_highlights_content.text = content
	_mechanics_highlights_content.scroll_to_line(0)
	_mechanics_highlights_dialog.popup_centered(Vector2i(900, 600))

func _on_mechanics_highlights_confirmed() -> void:
	_advance_post_ship_sequence()

func _show_jank_meter_dialog() -> void:
	if _jank_meter_dialog == null or _jank_meter_content == null:
		return

	var instability: int = _game_state.instability if _game_state != null else 0
	var soul: int = _game_state.soul if _game_state != null else 0

	var content: String = PresentationTextUtils.build_jank_meter_text(_current_ship_results, instability, soul)
	
	_jank_meter_content.text = content
	_jank_meter_content.scroll_to_line(0)
	_jank_meter_dialog.popup_centered(Vector2i(700, 500))

func _on_jank_meter_confirmed() -> void:
	_advance_post_ship_sequence()

func _show_end_run_dialog() -> void:
	if _run_ended:
		_configure_end_run_dialog_for_progression()
		_end_run_dialog.popup_centered(END_DIALOG_SIZE)

func _configure_end_run_dialog_for_progression() -> void:
	if _end_run_dialog == null or _game_state == null:
		return
	var meta: Dictionary = _game_state.get_meta_progress()
	var runs_played: int = int(meta.get("runs_played", 0))
	var runs_since_milestone: int = int(meta.get("runs_since_milestone", 0))

	_end_run_dialog.get_cancel_button().text = _S.get_string("buttons", "end_run_menu")
	
	# Milestone cycle runs every 3 runs. Track position in cycle:
	# runs_since_milestone cycles: 1 → 2 → 0 (reset) → 1 → 2 → 0 (reset) ...
	# Special case: runs_played==1 is the very first run ever, shown only once.
	
	# First run ever in the game — unique message (runs_played == 1 only once in game lifetime)
	if runs_played == 1:
		_end_run_dialog.title = _S.get_string("popups", "end_run_title_initial")
		_end_run_dialog.dialog_text = _S.get_string("popups", "end_run_text_initial")
		_end_run_dialog.get_ok_button().text = _S.get_string("buttons", "end_run_continue_second")
		return
	
	# Runs after the first: position in the 3-run milestone cycle determines message
	match runs_since_milestone:
		0:
			# Just completed the 3rd run of a cycle and triggered a milestone reset
			_end_run_dialog.title = _S.get_string("popups", "end_run_title_last")
			_end_run_dialog.dialog_text = _S.get_string("popups", "end_run_text_last")
			_end_run_dialog.get_ok_button().text = _S.get_string("buttons", "end_run_continue_cycle")
		1:
			# First run of a new cycle (runs 4, 7, 10, ...). Show like new cycle start.
			_end_run_dialog.title = _S.get_string("popups", "end_run_title_initial")
			_end_run_dialog.dialog_text = _S.get_string("popups", "end_run_text_initial")
			_end_run_dialog.get_ok_button().text = _S.get_string("buttons", "end_run_continue_second")
		2:
			# Second run in the 3-run cycle (runs 2, 5, 8, ...)
			_end_run_dialog.title = _S.get_string("popups", "end_run_title_second")
			_end_run_dialog.dialog_text = _S.get_string("popups", "end_run_text_second")
			_end_run_dialog.get_ok_button().text = _S.get_string("buttons", "end_run_continue_last")
		_:
			# Defensive: should not occur with proper initialization, but handle gracefully
			push_warning("Unexpected runs_since_milestone value: %d" % runs_since_milestone)
			_end_run_dialog.title = _S.get_string("popups", "end_run_title_default")
			_end_run_dialog.dialog_text = _S.get_string("popups", "end_run_text_default")
			_end_run_dialog.get_ok_button().text = _S.get_string("buttons", "end_run_continue_default")

func _on_end_run_dialog_new_run() -> void:
	# Continue to next run: briefing should fire if pending legacy exists.
	# Flag remains true so _show_main_menu() will display briefing.
	_show_main_menu()

func _on_end_run_dialog_menu() -> void:
	# Menu button: user chose to return to menu WITHOUT continuing run.
	# Clear flag so briefing does NOT fire. Player can start fresh or load different run.
	_briefing_pending_for_completed_run = false
	_show_main_menu()

func _on_dilemma_dialog_choice_a() -> void:
	_stop_choice_countdown()
	if OfferLogicUtils.apply_choice_if_pending(_game_state, _pending_dilemma, &"apply_dilemma_choice", 0):
		_append_log(_S.get_string("log_messages", "dilemma_a"))
	_pending_dilemma.clear()
	_resume_crunch_timer_after_dialog.call_deferred()

func _on_dilemma_dialog_choice_b() -> void:
	_stop_choice_countdown()
	if OfferLogicUtils.apply_choice_if_pending(_game_state, _pending_dilemma, &"apply_dilemma_choice", 1):
		_append_log(_S.get_string("log_messages", "dilemma_b"))
	_pending_dilemma.clear()
	_resume_crunch_timer_after_dialog.call_deferred()

func _on_draft_dialog_pick_a() -> void:
	_stop_choice_countdown()
	if OfferLogicUtils.apply_choice_if_pending(_game_state, _pending_draft_offer, &"apply_draft_pick", 0):
		_append_log(_S.get_string("log_messages", "draft_a"))
	_pending_draft_offer.clear()
	_resume_crunch_timer_after_dialog.call_deferred()

func _on_draft_dialog_pick_b() -> void:
	_stop_choice_countdown()
	if OfferLogicUtils.apply_choice_if_pending(_game_state, _pending_draft_offer, &"apply_draft_pick", 1):
		_append_log(_S.get_string("log_messages", "draft_b"))
	_pending_draft_offer.clear()
	_resume_crunch_timer_after_dialog.call_deferred()

func _on_draft_dialog_custom_action(action: StringName) -> void:
	if String(action) != "pick_c":
		return
	_stop_choice_countdown()
	if OfferLogicUtils.apply_choice_if_pending(_game_state, _pending_draft_offer, &"apply_draft_pick", 2):
		_append_log(_S.get_string("log_messages", "draft_c"))
		_pending_draft_offer.clear()
	# Custom action buttons do not auto-close like OK/Cancel, so close explicitly.
	_draft_dialog.hide()
	_resume_crunch_timer_after_dialog()

func _start_new_run() -> void:
	if _game_state == null:
		return

	_menu_active = false
	_run_ended = false
	_main_menu_layer.visible = false
	_feature_board.clear_board()
	_game_state.reset_run()
	_populate_card_list()
	_update_card_unlock_progress()
	_stop_choice_countdown()
	_fix_bugs_button.disabled = false
	_dev_log_button.disabled = false
	_ship_button.disabled = false
	if _crunch_timer != null:
		_crunch_timer.stop()
	
	# First-run onboarding
	_is_first_run = _game_state.get_meta_progress().get("runs_played", 0) == 0
	if _is_first_run:
		_append_log(_S.get_string("log_messages", "onboarding_0"))
		_append_log(_S.get_string("log_messages", "onboarding_1"))
		_append_log(_S.get_string("log_messages", "onboarding_2"))
		_append_log(_S.get_string("log_messages", "onboarding_3"))
		_add_tutorial_card_to_backlog()
	else:
		_append_log(_S.get_string("log_messages", "run_started"))

func _add_tutorial_card_to_backlog() -> void:
	# Create a tutorial card dynamically for the first run
	var tutorial_card: FeatureCard = FeatureCard.new()
	tutorial_card.feature_name = "Tutorial: Basic UI [Learning]"
	tutorial_card.ambition_value = 1
	tutorial_card.instability_value = 0
	tutorial_card.tags = PackedStringArray(["ui", "tutorial"])
	tutorial_card.interactions = {}
	
	# Clear backlog and add only the tutorial card
	_backlog_cards.clear()
	_backlog_cards.append(tutorial_card)
	_refresh_backlog_list()

func _show_main_menu() -> void:
	_menu_active = true
	_run_ended = false
	_main_menu_layer.visible = true
	_fix_bugs_button.disabled = true
	_dev_log_button.disabled = true
	_ship_button.disabled = true
	_crunch_timer.stop()
	_feature_board.clear_board()
	_stop_choice_countdown()
	_backlog_cards.clear()
	_refresh_backlog_list()
	_sync_run_start_settings()
	_append_log(_S.get_string("log_messages", "main_menu"))
	# Show briefing once after each completed run.
	if _briefing_pending_for_completed_run:
		_show_studio_briefing.call_deferred()

# --- Legacy / Studio Briefing ---

func _on_legacy_resolved(_payload: LegacyPayload) -> void:
	# Data already written into AppState meta by ship_it().
	# Briefing fires the next time the player reaches the main menu.
	pass

func _on_milestone_reached(payload: MilestonePayload) -> void:
	_append_log(_S.get_string("log_messages", "milestone_reached") % [
		payload.milestone_index,
		payload.studio_tier,
		payload.reputation_total,
	])

func _show_studio_briefing() -> void:
	if _studio_briefing_dialog == null or _game_state == null:
		return
	var meta: Dictionary = _game_state.get_meta_progress()
	var runs_played: int = int(meta.get("runs_played", 0))
	if runs_played <= 0:
		_briefing_pending_for_completed_run = false
		return

	var pending: LegacyRecord = _game_state.get_pending_legacy()
	var active: LegacyRecord = _game_state.get_active_legacy()
	_studio_briefing_content.text = LegacyUtils.build_briefing_text(active, pending, meta)

	var has_pending_legacy: bool = not pending.is_empty()
	# Hide replacement controls when no pending legacy is available.
	_studio_briefing_dialog.get_ok_button().visible = has_pending_legacy and not active.is_empty()
	_studio_briefing_dialog.get_cancel_button().visible = has_pending_legacy
	_studio_briefing_dialog.popup_centered(_studio_briefing_dialog.min_size)
	_briefing_pending_for_completed_run = false

func _on_briefing_keep_legacy() -> void:
	if _game_state != null:
		_game_state.resolve_legacy_displacement(true)

func _on_briefing_take_legacy() -> void:
	if _game_state != null:
		_game_state.resolve_legacy_displacement(false)

# --- HUD helpers ---

func _update_action_tooltips(payload: StateSnapshotPayload) -> void:
	var runway_days: int = payload.runway_days
	var instability: int = payload.instability
	HudUiUtils.update_action_tooltips(_fix_bugs_button, _dev_log_button, _ship_button, runway_days, instability)

func _snapshot_from_state() -> StateSnapshotPayload:
	var payload: StateSnapshotPayload = StateSnapshotPayload.new()
	if _game_state == null:
		payload.ambition = 0
		payload.instability = 0
		payload.runway_days = INITIAL_RUNWAY_DAYS
		payload.soul = 10
		payload.features_shipped = 0
		return payload

	payload.ambition = _game_state.ambition
	payload.instability = _game_state.instability
	payload.runway_days = _game_state.runway_days
	payload.soul = _game_state.soul
	payload.features_shipped = _game_state.feature_board.size()
	return payload

func _update_publisher_flash() -> void:
	if _publisher_flash_style == null:
		_publisher_flash_style = StyleBoxFlat.new()
		_publisher_flash_style.border_width_left = 3
		_publisher_flash_style.border_width_top = 3
		_publisher_flash_style.border_width_right = 3
		_publisher_flash_style.border_width_bottom = 3
		_publisher_flash_style.corner_radius_top_left = 4
		_publisher_flash_style.corner_radius_top_right = 4
		_publisher_flash_style.corner_radius_bottom_left = 4
		_publisher_flash_style.corner_radius_bottom_right = 4
		_dilemma_dialog.get_ok_button().add_theme_color_override("font_color", Color(1.0, 0.94, 0.94))
		_dilemma_dialog.get_cancel_button().add_theme_color_override("font_color", Color(1.0, 0.94, 0.94))
	var pulse: float = 0.5 + (sin(_jank_time * 12.0) * 0.5)
	_publisher_flash_style.bg_color = Color(0.35, 0.04, 0.04).lerp(Color(0.90, 0.08, 0.08), pulse)
	_publisher_flash_style.border_color = Color(1.0, 0.75, 0.75).lerp(Color(1.0, 0.15, 0.15), pulse)
	_dilemma_dialog.get_ok_button().add_theme_stylebox_override("normal", _publisher_flash_style)
	_dilemma_dialog.get_cancel_button().add_theme_stylebox_override("normal", _publisher_flash_style)

func _clear_publisher_flash() -> void:
	if _dilemma_dialog == null:
		return
	_dilemma_dialog.get_ok_button().remove_theme_stylebox_override("normal")
	_dilemma_dialog.get_cancel_button().remove_theme_stylebox_override("normal")
	_dilemma_dialog.get_ok_button().remove_theme_color_override("font_color")
	_dilemma_dialog.get_cancel_button().remove_theme_color_override("font_color")

func _setup_synergy_toast() -> void:
	_synergy_toast = SynergyToastUtils.setup_synergy_toast(self)

func _show_synergy_toast(flavor: String, instability_delta: int, soul_delta: int) -> void:
	_synergy_toast_timer = SynergyToastUtils.show_synergy_toast(
		self,
		_synergy_toast,
		_synergy_toast_timer,
		flavor,
		instability_delta,
		soul_delta,
		SYNERGY_TOAST_DURATION,
		SYNERGY_TOAST_FADE_IN,
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
	
	# Clean up timer
	if _synergy_toast_timer != null:
		_synergy_toast_timer.queue_free()
		_synergy_toast_timer = null

func _show_help_dialog() -> void:
	if _help_dialog == null or _menu_active or _run_ended or _is_blocking_offer_dialog_open():
		return
	_pause_crunch_timer_for_dialog()
	_help_dialog.popup_centered(_help_dialog.min_size)

func _apply_ui_corruption() -> void:
	JankVisualUtils.apply_ui_corruption(_corruptible_controls, _base_control_text, _ui_rng, _instability_visual)

func _restore_ui_texts() -> void:
	JankVisualUtils.restore_ui_texts(_corruptible_controls, _base_control_text)

func _start_choice_countdown(context: String, title: String, body_text: String, default_index: int, publisher_alert: bool) -> void:
	_choice_context = context
	_choice_base_title = title
	_choice_base_text = body_text
	_choice_default_index = default_index
	_choice_countdown_remaining = -1
	_publisher_alert_active = publisher_alert
	_update_choice_dialog_copy()

func _stop_choice_countdown() -> void:
	_choice_context = ""
	_choice_base_title = ""
	_choice_base_text = ""
	_choice_default_index = -1
	_choice_countdown_remaining = 0
	_publisher_alert_active = false
	_clear_publisher_flash()

func _update_choice_dialog_copy() -> void:
	match _choice_context:
		"draft":
			_draft_dialog.title = _choice_base_title
			_draft_dialog.dialog_text = _choice_base_text
		"dilemma":
			_dilemma_dialog.title = _choice_base_title
			_dilemma_dialog.dialog_text = _choice_base_text
		"publisher_meeting":
			_publisher_dialog.title = _choice_base_title
			_publisher_dialog.dialog_text = _choice_base_text

func _auto_resolve_choice() -> void:
	match _choice_context:
		"draft":
			if _game_state != null and not _pending_draft_offer.is_empty():
				_game_state.apply_draft_pick(_choice_default_index)
				_append_log(_S.get_string("log_messages", "auto_draft"))
			_draft_dialog.hide()
			_pending_draft_offer.clear()
		"dilemma":
			if _game_state != null and not _pending_dilemma.is_empty():
				_game_state.apply_dilemma_choice(_choice_default_index)
				_append_log(_S.get_string("log_messages", "auto_dilemma"))
			_dilemma_dialog.hide()
			_pending_dilemma.clear()
		"publisher_meeting":
			if _game_state != null and not _pending_publisher_meeting.is_empty():
				_game_state.apply_publisher_meeting_choice(_choice_default_index)
				_append_log(_S.get_string("log_messages", "auto_publisher"))
			_publisher_dialog.hide()
			_pending_publisher_meeting.clear()
	_stop_choice_countdown()

func _get_most_unstable_pick_index(picks: Array) -> int:
	return OfferLogicUtils.get_most_unstable_pick_index(picks)

func _get_least_favored_choice_index(choices: Array) -> int:
	return OfferLogicUtils.get_least_favored_choice_index(choices)
