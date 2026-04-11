extends RefCounted
class_name RunOfferFlow

var _offer_scheduler: OfferScheduler = null
var _triggered_thresholds: Dictionary = {}
var _pending_dilemma: Dictionary = {}
var _pending_draft_offer: Dictionary = {}

func setup(offer_scheduler: OfferScheduler) -> void:
	_offer_scheduler = offer_scheduler

func reset() -> void:
	_triggered_thresholds.clear()
	_pending_dilemma.clear()
	_pending_draft_offer.clear()
	if _offer_scheduler != null:
		_offer_scheduler.reset()

func apply_dilemma_choice(choice_index: int, state: Dictionary) -> Dictionary:
	if _pending_dilemma.is_empty():
		return {}
	var choices: Array = _pending_dilemma.get("choices", [])
	if choices.is_empty():
		_pending_dilemma.clear()
		return {}
	var selected: Dictionary = choices[clampi(choice_index, 0, choices.size() - 1)]
	var next_state: Dictionary = _apply_effects_to_state(state, selected.get("effects", {}))
	_pending_dilemma.clear()
	return {
		"state": next_state,
		"threshold_event": {
			"id": "dilemma_choice",
			"message": "Dilemma resolved: %s" % String(selected.get("label", "Choice applied")),
			"effects": selected.get("effects", {}),
			"severity": "info",
		},
	}

func apply_draft_pick(pick_index: int, state: Dictionary) -> Dictionary:
	if _pending_draft_offer.is_empty():
		return {}
	var picks: Array = _pending_draft_offer.get("picks", [])
	if picks.is_empty():
		_pending_draft_offer.clear()
		return {}
	var selected: Dictionary = picks[clampi(pick_index, 0, picks.size() - 1)]
	var next_state: Dictionary = _apply_effects_to_state(state, selected.get("effects", {}))
	_pending_draft_offer.clear()
	return {
		"state": next_state,
		"threshold_event": {
			"id": "draft_pick",
			"message": "Draft pick accepted: %s" % String(selected.get("title", "Unknown pitch")),
			"effects": selected.get("effects", {}),
			"severity": "info",
		},
	}

func maybe_offer_dilemma(
	config: GameConfig,
	offers: Dictionary,
	runway_days: int,
	soul: int,
	current_run: int,
	pressure_modifier: float,
) -> Dictionary:
	if _offer_scheduler == null:
		return {}
	var result: Dictionary = _offer_scheduler.maybe_offer_dilemma(
		config,
		offers,
		runway_days,
		soul,
		current_run,
		pressure_modifier
	)
	if result.is_empty():
		return {}
	_pending_dilemma = result
	return result

func maybe_offer_draft(
	config: GameConfig,
	offers: Dictionary,
	runway_days: int,
	soul: int,
	feature_board_empty: bool,
	current_run: int,
	pressure_modifier: float,
) -> Dictionary:
	if _offer_scheduler == null:
		return {}
	var result: Dictionary = _offer_scheduler.maybe_offer_draft(
		config,
		offers,
		runway_days,
		soul,
		feature_board_empty,
		current_run,
		pressure_modifier
	)
	if result.is_empty():
		return {}
	_pending_draft_offer = result
	return result

func evaluate_threshold_events(threshold_events: Array[Dictionary], state: Dictionary) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var emitted_events: Array[Dictionary] = []
	for threshold_event in threshold_events:
		if threshold_event is not Dictionary:
			continue
		var event_id: String = String(threshold_event.get("id", ""))
		if event_id.is_empty() or _triggered_thresholds.get(event_id, false):
			continue
		if not _is_threshold_reached(threshold_event, next_state):
			continue
		_triggered_thresholds[event_id] = true
		var threshold_effects: Dictionary = threshold_event.get("effects", {}).duplicate(true)
		if threshold_effects.has("runway_days"):
			threshold_effects.erase("runway_days")
		next_state = _apply_effects_to_state(next_state, threshold_effects)
		emitted_events.append({
			"id": event_id,
			"message": String(threshold_event.get("message", "Threshold event triggered.")),
			"effects": threshold_effects,
			"severity": String(threshold_event.get("severity", "info")),
		})
	return {
		"state": next_state,
		"events": emitted_events,
	}

func _is_threshold_reached(threshold_event: Dictionary, state: Dictionary) -> bool:
	var metric_name: String = String(threshold_event.get("metric", ""))
	var threshold_value: int = int(threshold_event.get("threshold", 0))
	var comparison: String = String(threshold_event.get("comparison", "gte"))
	var metric_value: int = int(state.get(metric_name, 0))
	if comparison == "lte":
		return metric_value <= threshold_value
	return metric_value >= threshold_value

func _apply_effects_to_state(state: Dictionary, effects: Variant) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	if effects is not Dictionary:
		return next_state
	next_state["ambition"] = max(int(next_state.get("ambition", 0)) + int(effects.get("ambition", 0)), 0)
	next_state["instability"] = max(int(next_state.get("instability", 0)) + int(effects.get("instability", 0)), 0)
	next_state["runway_days"] = max(int(next_state.get("runway_days", 0)) + int(effects.get("runway_days", 0)), 0)
	next_state["soul"] = max(int(next_state.get("soul", 0)) + int(effects.get("soul", 0)), 0)
	return next_state