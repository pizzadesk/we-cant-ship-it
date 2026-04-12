extends RefCounted
class_name OfferScheduler

## Manages dilemma and draft offer scheduling.
## Owns per-run scheduling state (cooldowns, offered-day tracking).
## Instantiated by AppState each run — NOT an autoload.

var _last_draft_day_offered: int = -1
var _dilemma_days_offered: Dictionary = {}
var _popup_offered_on_runway_day: int = -1
var _pending_dilemma: Dictionary = {}
var _pending_draft_offer: Dictionary = {}
var _draft_offer_deferred: bool = false

var _rng: RandomNumberGenerator

func _init(rng: RandomNumberGenerator) -> void:
	_rng = rng

func reset() -> void:
	_last_draft_day_offered = -1
	_dilemma_days_offered.clear()
	_pending_dilemma.clear()
	_pending_draft_offer.clear()
	_draft_offer_deferred = false
	_popup_offered_on_runway_day = -1

# --- Getters for pending state (AppState reads these) ---

func get_pending_dilemma() -> Dictionary:
	return _pending_dilemma

func get_pending_draft_offer() -> Dictionary:
	return _pending_draft_offer

func has_deferred_draft_offer() -> bool:
	return _draft_offer_deferred

func get_popup_offered_on_runway_day() -> int:
	return _popup_offered_on_runway_day

func clear_pending_dilemma() -> void:
	_pending_dilemma.clear()

func clear_pending_draft_offer() -> void:
	_pending_draft_offer.clear()

# --- Dilemma scheduling ---

func maybe_offer_dilemma(
	config: GameConfig,
	offers: Dictionary,
	runway_days: int,
	_soul: int,
	current_run: int,
	pressure_modifier: float,
) -> Dictionary:
	if runway_days <= 0:
		return {}
	if runway_days > _pressure_start_day_for_run(current_run):
		return {}
	if _popup_offered_on_runway_day == runway_days:
		return {}
	var effective_interval: int = maxi(1, int(float(config.dilemma_offer_interval) / pressure_modifier))
	if not (runway_days % effective_interval == 0):
		return {}
	if _dilemma_days_offered.get(runway_days, false):
		return {}

	var dilemmas: Array = offers.get("dilemmas", [])
	if dilemmas.is_empty():
		push_warning("No dilemmas loaded from offers.json — skipping dilemma offer")
		return {}

	_pending_dilemma = _pick_random_dilemma(dilemmas)
	if _pending_dilemma.is_empty():
		return {}
	_pending_dilemma["runway_day"] = runway_days
	_dilemma_days_offered[runway_days] = true
	_popup_offered_on_runway_day = runway_days
	return _pending_dilemma

func _pick_random_dilemma(dilemmas: Array) -> Dictionary:
	var valid: Array[Dictionary] = []
	for raw in dilemmas:
		if raw is Dictionary:
			valid.append(raw as Dictionary)
	if valid.is_empty():
		return {}
	return valid[_rng.randi_range(0, valid.size() - 1)].duplicate(true)

# --- Draft scheduling ---

func maybe_offer_draft(
	config: GameConfig,
	offers: Dictionary,
	runway_days: int,
	soul: int,
	feature_board_empty: bool,
	current_run: int,
	pressure_modifier: float,
) -> Dictionary:
	if runway_days <= 0:
		return {}
	if feature_board_empty:
		_draft_offer_deferred = false
		return {}
	if _draft_offer_deferred:
		if _popup_offered_on_runway_day == runway_days:
			return {}
		_pending_draft_offer = _build_draft_offer(offers, soul)
		if _pending_draft_offer.is_empty():
			_draft_offer_deferred = false
			return {}
		_pending_draft_offer["runway_day"] = runway_days
		_last_draft_day_offered = runway_days
		_popup_offered_on_runway_day = runway_days
		_draft_offer_deferred = false
		return _pending_draft_offer
	if not _is_draft_offer_day(config, runway_days, current_run, pressure_modifier):
		return {}
	if _last_draft_day_offered == runway_days:
		return {}
	if _popup_offered_on_runway_day == runway_days:
		_draft_offer_deferred = true
		return {}

	_pending_draft_offer = _build_draft_offer(offers, soul)
	if _pending_draft_offer.is_empty():
		return {}
	_last_draft_day_offered = runway_days
	_pending_draft_offer["runway_day"] = runway_days
	_popup_offered_on_runway_day = runway_days
	return _pending_draft_offer

func _is_draft_offer_day(
	config: GameConfig,
	runway_days: int,
	current_run: int,
	pressure_modifier: float,
) -> bool:
	if runway_days > _pressure_start_day_for_run(current_run):
		return false
	var effective_interval: int = maxi(1, int(float(config.draft_offer_interval) / pressure_modifier))
	return runway_days % effective_interval == 0

func _build_draft_offer(offers: Dictionary, soul: int) -> Dictionary:
	var draft_config: Dictionary = offers.get("draft_picks", {}) as Dictionary
	var draft_picks: Array[Dictionary] = []
	var base: Array = Array(draft_config.get("base", []))
	for pick in base:
		if pick is Dictionary:
			draft_picks.append((pick as Dictionary).duplicate(true))
	var soul_gated: Array = Array(draft_config.get("soul_gated", []))
	for sg_pick in soul_gated:
		if sg_pick is not Dictionary:
			continue
		var pick_dict: Dictionary = sg_pick as Dictionary
		if int(pick_dict.get("soul_required", 0)) <= soul:
			draft_picks.append(pick_dict.duplicate(true))
	if draft_picks.size() < 3:
		return {}
	var selected_picks: Array[Dictionary] = []
	var available_picks: Array[Dictionary] = draft_picks.duplicate(true)
	while selected_picks.size() < 3 and not available_picks.is_empty():
		var pick_index: int = _rng.randi_range(0, available_picks.size() - 1)
		selected_picks.append((available_picks[pick_index] as Dictionary).duplicate(true))
		available_picks.remove_at(pick_index)
	return {
		"title": "Feature Pitch Draft",
		"description": "Pick one producer pitch to shape the next stretch.",
		"picks": selected_picks,
	}

func _pressure_start_day_for_run(current_run: int) -> int:
	match current_run:
		1:
			return 5
		2:
			return 14
		3:
			return 10
		_:
			return 7
