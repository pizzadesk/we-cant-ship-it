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

var _rng: RandomNumberGenerator

func _init(rng: RandomNumberGenerator) -> void:
	_rng = rng

func reset() -> void:
	_last_draft_day_offered = -1
	_dilemma_days_offered.clear()
	_pending_dilemma.clear()
	_pending_draft_offer.clear()
	_popup_offered_on_runway_day = -1

# --- Getters for pending state (AppState reads these) ---

func get_pending_dilemma() -> Dictionary:
	return _pending_dilemma

func get_pending_draft_offer() -> Dictionary:
	return _pending_draft_offer

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
		return {}
	if runway_days > _pressure_start_day_for_run(current_run):
		return {}
	if _popup_offered_on_runway_day == runway_days:
		return {}
	var effective_interval: int = maxi(1, int(float(config.draft_offer_interval) / pressure_modifier))
	if runway_days % effective_interval != 0:
		return {}
	if _last_draft_day_offered == runway_days:
		return {}

	_last_draft_day_offered = runway_days
	var draft_picks: Array = Array((offers.get("draft_picks", {}) as Dictionary).get("base", []))
	var soul_gated: Array = Array((offers.get("draft_picks", {}) as Dictionary).get("soul_gated", []))
	for sg_pick: Variant in soul_gated:
		if int((sg_pick as Dictionary).get("soul_required", 0)) <= soul:
			draft_picks.append(sg_pick)
	_pending_draft_offer = {
		"title": "Feature Pitch Draft",
		"description": "Pick one producer pitch to shape the next stretch.",
		"picks": draft_picks,
	}
	_popup_offered_on_runway_day = runway_days
	return _pending_draft_offer

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
