extends RefCounted
class_name BacklogController

const BacklogCatalogUtils = preload("res://scripts/ui/backlog_catalog_utils.gd")

var _game_state: Node = null
var _card_list: VBoxContainer = null
var _card_widget_scene: PackedScene = null
var _cards_path: String = ""
var _custom_cards_path: String = ""
var _daily_visible_cards: int = 3
var _ui_rng: RandomNumberGenerator = null

var _backlog_cards: Array[Resource] = []
var _last_offer_runway_day: int = -1
var _run_offered_paths: PackedStringArray = PackedStringArray()
var _recent_offer_days: Array = []
var _template_cards: Array[Resource] = []
var _templates_loaded: bool = false

func setup(
	game_state: Node,
	card_list: VBoxContainer,
	card_widget_scene: PackedScene,
	cards_path: String,
	custom_cards_path: String,
	daily_visible_cards: int,
	ui_rng: RandomNumberGenerator,
) -> void:
	_game_state = game_state
	_card_list = card_list
	_card_widget_scene = card_widget_scene
	_cards_path = cards_path
	_custom_cards_path = custom_cards_path
	_daily_visible_cards = daily_visible_cards
	_ui_rng = ui_rng

func populate_card_list(append_log: Callable) -> void:
	_backlog_cards.clear()
	_last_offer_runway_day = -1
	_run_offered_paths = PackedStringArray()
	_recent_offer_days.clear()
	_ensure_template_cards_loaded(append_log)
	_rebuild_daily_offer(true)

func refresh_backlog_list() -> void:
	BacklogCatalogUtils.refresh_backlog_list(_card_list, _backlog_cards, _card_widget_scene, "backlog")

func clear_visible_backlog() -> void:
	_backlog_cards.clear()
	refresh_backlog_list()

func reset_run_state() -> void:
	_backlog_cards.clear()
	_last_offer_runway_day = -1
	_run_offered_paths = PackedStringArray()
	_recent_offer_days.clear()

func handle_card_dropped(menu_active: bool, run_ended: bool, data: Dictionary) -> void:
	if menu_active or run_ended:
		return
	if _game_state == null or _game_state.runway_days <= 0:
		return
	var payload: FeatureCardDragPayload = FeatureCardDragPayload.from_variant(data)
	var card: Resource = payload.card
	if card == null:
		return
	_backlog_cards.erase(card)
	refresh_backlog_list()
	_game_state.add_feature_card(card)

func on_day_spent(payload: DaySpentPayload) -> void:
	if payload.runway_days > 0:
		_rebuild_daily_offer()

func _ensure_template_cards_loaded(append_log: Callable) -> void:
	var result: TemplateCardsLoadResult = BacklogCatalogUtils.ensure_template_cards_loaded(
		_template_cards,
		_templates_loaded,
		_cards_path,
		_custom_cards_path,
		append_log
	)
	_template_cards = result.template_cards
	_templates_loaded = result.templates_loaded
	_merge_dynamic_templates()

func _merge_dynamic_templates() -> void:
	if _game_state == null or not _game_state.has_method("get_dynamic_card_templates"):
		return
	var existing: Dictionary = {}
	for template in _template_cards:
		var template_id: String = BacklogCatalogUtils.card_id_from_resource(template)
		if not template_id.is_empty():
			existing[template_id] = true
	var dynamic_templates: Array = _game_state.get_dynamic_card_templates()
	for template in dynamic_templates:
		if template is not Resource:
			continue
		var resource: Resource = template as Resource
		var template_id: String = BacklogCatalogUtils.card_id_from_resource(resource)
		if template_id.is_empty() or existing.has(template_id):
			continue
		_template_cards.append(resource)
		existing[template_id] = true

func _rebuild_daily_offer(force: bool = false) -> void:
	if _template_cards.is_empty():
		_backlog_cards.clear()
		refresh_backlog_list()
		return

	var runway_today: int = _get_initial_runway_days()
	if _game_state != null:
		runway_today = int(_game_state.runway_days)

	if not force and runway_today == _last_offer_runway_day:
		return

	var offer_result: DailyOfferResult = BacklogCatalogUtils.rebuild_daily_offer(
		_template_cards,
		_game_state,
		_last_offer_runway_day,
		_get_initial_runway_days(),
		_daily_visible_cards,
		_ui_rng,
		Callable(self, "_is_template_unlocked"),
		_run_offered_paths,
		_recent_offer_days
	)
	_backlog_cards = offer_result.backlog_cards
	_last_offer_runway_day = offer_result.last_offer_runway_day
	if not offer_result.offered_paths.is_empty():
		_recent_offer_days.append(offer_result.offered_paths.duplicate())
		while _recent_offer_days.size() > 3:
			_recent_offer_days.remove_at(0)
	if offer_result.pool_reset:
		_run_offered_paths = offer_result.offered_paths.duplicate()
	elif not offer_result.offered_paths.is_empty():
		_run_offered_paths.append_array(offer_result.offered_paths)
	refresh_backlog_list()

func _get_initial_runway_days() -> int:
	if _game_state != null and _game_state.has_method("get_initial_runway_days"):
		return int(_game_state.get_initial_runway_days())
	return 21

func _is_template_unlocked(template: Resource) -> bool:
	return BacklogCatalogUtils.is_template_unlocked(
		template,
		_custom_cards_path,
		_game_state,
		Callable(BacklogCatalogUtils, "card_id_from_resource")
	)