extends RefCounted
class_name RunOfferFlow

const ChoiceResolutionType = preload("res://scripts/data/payloads/choice_resolution.gd")
const RunStateDataType = preload("res://scripts/data/payloads/run_state_data.gd")
const ThresholdEvaluationResultType = preload("res://scripts/data/payloads/threshold_evaluation_result.gd")

var _offer_scheduler: OfferScheduler = null
var _triggered_thresholds: Dictionary = {}
var _pending_dilemma: DilemmaOfferPayload = null
var _pending_draft_offer: DraftOfferPayload = null

func setup(offer_scheduler: OfferScheduler) -> void:
	_offer_scheduler = offer_scheduler

func reset() -> void:
	_triggered_thresholds.clear()
	_pending_dilemma = null
	_pending_draft_offer = null
	if _offer_scheduler != null:
		_offer_scheduler.reset()

func has_deferred_draft_offer() -> bool:
	return _offer_scheduler != null and _offer_scheduler.has_deferred_draft_offer()

func apply_dilemma_choice(choice_index: int, state: RunStateDataType) -> ChoiceResolutionType:
	if _pending_dilemma == null:
		return null
	var choices: Array[Dictionary] = _pending_dilemma.choices
	if choices.is_empty():
		_pending_dilemma = null
		return null
	var selected: Dictionary = choices[clampi(choice_index, 0, choices.size() - 1)]
	var resolution: ChoiceResolutionType = ChoiceResolutionType.new()
	resolution.state = _apply_effects_to_state(state, selected.get("effects", {}))
	resolution.threshold_event = ThresholdEventPayload.build(
		"dilemma_choice",
		"Dilemma resolved: %s" % String(selected.get("label", "Choice applied")),
		selected.get("effects", {}),
		"info"
	)
	_pending_dilemma = null
	return resolution

func apply_draft_pick(pick_index: int, state: RunStateDataType) -> ChoiceResolutionType:
	if _pending_draft_offer == null:
		return null
	var picks: Array[Dictionary] = _pending_draft_offer.picks
	if picks.is_empty():
		_pending_draft_offer = null
		return null
	var selected: Dictionary = picks[clampi(pick_index, 0, picks.size() - 1)]
	var resolution: ChoiceResolutionType = ChoiceResolutionType.new()
	resolution.state = _apply_effects_to_state(state, selected.get("effects", {}))
	resolution.threshold_event = ThresholdEventPayload.build(
		"draft_pick",
		"Draft pick accepted: %s" % String(selected.get("title", "Unknown pitch")),
		selected.get("effects", {}),
		"info"
	)
	_pending_draft_offer = null
	return resolution

func maybe_offer_dilemma(
	config: GameConfig,
	offers: Dictionary,
	runway_days: int,
	soul: int,
	current_run: int,
	pressure_modifier: float,
) -> DilemmaOfferPayload:
	if _offer_scheduler == null:
		return null
	var result: Dictionary = _offer_scheduler.maybe_offer_dilemma(
		config,
		offers,
		runway_days,
		soul,
		current_run,
		pressure_modifier
	)
	if result.is_empty():
		return null
	_pending_dilemma = DilemmaOfferPayload.from_dictionary(result)
	return _pending_dilemma

func maybe_offer_draft(
	config: GameConfig,
	offers: Dictionary,
	runway_days: int,
	soul: int,
	feature_board_empty: bool,
	current_run: int,
	pressure_modifier: float,
) -> DraftOfferPayload:
	if _offer_scheduler == null:
		return null
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
		return null
	_pending_draft_offer = DraftOfferPayload.from_dictionary(result)
	return _pending_draft_offer

func evaluate_threshold_events(threshold_events: Array[Dictionary], state: RunStateDataType) -> ThresholdEvaluationResultType:
	var next_state: RunStateDataType = state.duplicate_state() if state != null else RunStateDataType.new()
	var result: ThresholdEvaluationResultType = ThresholdEvaluationResultType.new()
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
		result.events.append(ThresholdEventPayload.build(
			event_id,
			String(threshold_event.get("message", "Threshold event triggered.")),
			threshold_effects,
			String(threshold_event.get("severity", "info"))
		))
	result.state = next_state
	return result

func _is_threshold_reached(threshold_event: Dictionary, state: RunStateDataType) -> bool:
	var metric_name: String = String(threshold_event.get("metric", ""))
	var threshold_value: int = int(threshold_event.get("threshold", 0))
	var comparison: String = String(threshold_event.get("comparison", "gte"))
	var metric_value: int = state.get_metric(metric_name) if state != null else 0
	if comparison == "lte":
		return metric_value <= threshold_value
	return metric_value >= threshold_value

func _apply_effects_to_state(state: RunStateDataType, effects: Variant) -> RunStateDataType:
	if state == null:
		return RunStateDataType.new().apply_effects(effects)
	return state.apply_effects(effects)