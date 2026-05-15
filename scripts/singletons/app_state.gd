extends Node

@warning_ignore("shadowed_global_identifier")
const ScoreCalculator = preload("res://scripts/data/score_calculator.gd")
@warning_ignore("shadowed_global_identifier")
const CycleStateManager = preload("res://scripts/data/cycle_state_manager.gd")
@warning_ignore("shadowed_global_identifier")
const OfferScheduler = preload("res://scripts/data/offer_scheduler.gd")
@warning_ignore("shadowed_global_identifier")
const JankResolver = preload("res://scripts/data/jank_resolver.gd")
const ChoiceResolutionType = preload("res://scripts/data/payloads/choice_resolution.gd")
const RunStateDataType = preload("res://scripts/data/payloads/run_state_data.gd")
const RunResolutionOutcomeType = preload("res://scripts/data/payloads/run_resolution_outcome.gd")
const ThresholdEvaluationResultType = preload("res://scripts/data/payloads/threshold_evaluation_result.gd")

# --- Run state ---
var ambition: int = 0
var instability: int = 0
var runway_days: int = 21
var soul: int = 12
var feature_board: Array[FeatureCard] = []
var chosen_archetype: String = ""

# Cycle-level state visible to UI.
var current_run: int = 1

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _event_bus: Node
var _review_generator: Node
var _cycle_mgr: CycleStateManager
var _offer_sched: OfferScheduler
var _content_repository: AppContentRepository
var _archetype_rules: ArchetypeRules
var _offer_flow: RunOfferFlow
var _run_resolution: RunResolutionService
# Transient: which run was just completed via ship_it(). Used by UI post-ship dialogs.
var _last_completed_run: int = 0
var _current_prospect_jank_id: String = ""
var _current_prospect_jank: Dictionary = {}
var _hinted_prospect_jank_ids: Dictionary = {}
var _locked_signature_jank: Dictionary = {}
var _signature_jank_reward_granted: bool = false

func _ready() -> void:
	_rng.randomize()
	_event_bus = GameEvents
	_review_generator = ReviewService
	_cycle_mgr = CycleStateManager.new()
	_offer_sched = OfferScheduler.new(_rng)
	_content_repository = AppContentRepository.new()
	_content_repository.initialize()
	_archetype_rules = ArchetypeRules.new()
	_offer_flow = RunOfferFlow.new()
	_offer_flow.setup(_offer_sched)
	_run_resolution = RunResolutionService.new()
	_run_resolution.setup(_content_repository, _cycle_mgr, _review_generator, _rng)
	_cycle_mgr.load_from_disk()
	current_run = _cycle_mgr.get_current_run()
	_cycle_mgr.ensure_initial_card_unlock_state(
		_content_repository.get_all_card_ids(), Callable(self, "_get_card_tier"), _content_repository.get_game_config().initial_card_unlock_count
	)
	reset_run()

func reset_run() -> void:
	ambition = 0
	instability = 0
	current_run = _cycle_mgr.get_current_run()
	runway_days = get_initial_runway_days_for_run(current_run)
	soul = _content_repository.get_game_config().soul_start
	feature_board.clear()
	chosen_archetype = ""
	_current_prospect_jank_id = ""
	_current_prospect_jank.clear()
	_hinted_prospect_jank_ids.clear()
	_locked_signature_jank.clear()
	_signature_jank_reward_granted = false
	_offer_flow.reset()
	_emit_state()

func get_game_config() -> GameConfig:
	return _content_repository.get_game_config()

func get_cycle_state() -> Dictionary:
	return _cycle_mgr.get_cycle_state()

func get_run_summary(run_number: int) -> Dictionary:
	return _cycle_mgr.get_run_summary(run_number)

func get_cycle_jank_card_ids() -> PackedStringArray:
	return _cycle_mgr.get_jank_card_ids()

func get_last_completed_run() -> int:
	return _last_completed_run

func get_initial_runway_days() -> int:
	return get_initial_runway_days_for_run(current_run)

func get_initial_runway_days_for_run(run_number: int) -> int:
	var game_config: GameConfig = _content_repository.get_game_config()
	if game_config == null:
		return 21
	if run_number <= 1:
		return game_config.tutorial_runway_days
	return game_config.standard_runway_days

func get_dynamic_card_templates() -> Array[Resource]:
	return _content_repository.get_dynamic_card_templates()

func is_cycle_complete() -> bool:
	return _cycle_mgr.is_cycle_complete()

func start_new_cycle() -> void:
	_cycle_mgr.reset_cycle()
	_cycle_mgr.ensure_initial_card_unlock_state(
		_content_repository.get_all_card_ids(), Callable(self, "_get_card_tier"), _content_repository.get_game_config().initial_card_unlock_count
	)
	current_run = 1
	reset_run()

func save_cycle_state() -> void:
	_cycle_mgr.save()

## Returns true when a card is placeable. Alien cards (no archetype_affinity) are blocked
## below the soul gate when an archetype has been chosen.
func can_place_card(card: FeatureCard) -> bool:
	return _archetype_rules.can_place_card(card, chosen_archetype, soul, _content_repository.get_game_config())

func set_archetype(archetype: String) -> void:
	chosen_archetype = archetype
	if _event_bus != null:
		_event_bus.archetype_chosen.emit(archetype)

func get_chosen_archetype() -> String:
	return chosen_archetype

func has_locked_signature_jank() -> bool:
	return not _locked_signature_jank.is_empty()

func get_locked_signature_jank() -> Dictionary:
	return _locked_signature_jank.duplicate(true)

func get_active_prospect_offer_targets() -> PackedStringArray:
	var targets: PackedStringArray = PackedStringArray()
	if _current_prospect_jank.is_empty() or not _locked_signature_jank.is_empty():
		return targets
	var board_ids: PackedStringArray = _collect_feature_board_ids()
	var card_a: String = _normalize_feature_name(String(_current_prospect_jank.get("card_a", "")))
	var card_b: String = _normalize_feature_name(String(_current_prospect_jank.get("card_b", "")))
	if card_a.is_empty() or card_b.is_empty():
		return targets
	var has_a: bool = board_ids.has(card_a)
	var has_b: bool = board_ids.has(card_b)
	if has_a and not has_b:
		targets.append(card_b)
	elif has_b and not has_a:
		targets.append(card_a)
	return targets

func get_jank_pursuit_state() -> Dictionary:
	if not _locked_signature_jank.is_empty():
		return {
			"stage": "locked",
			"display_title": "Signature Locked: %s" % String(_locked_signature_jank.get("name", "Unknown Jank")),
			"display_body": String(_locked_signature_jank.get("lock_in_line", "This run has become something irreversible.")),
		}
	if not _current_prospect_jank.is_empty():
		return {
			"stage": "prospect",
			"display_title": "Prospect Forming: %s" % String(_current_prospect_jank.get("prospect_title", "Jank Prospect")),
			"display_body": String(_current_prospect_jank.get("prospect_hint", "Something strange is taking shape.")),
		}
	return {
		"stage": "idle",
		"display_title": "No Signature Yet",
		"display_body": "Combine features and watch for collisions that feel a little too meaningful.",
	}

func get_daily_offer_context() -> Dictionary:
	return {
		"ambition": ambition,
		"instability": instability,
		"runway_days": runway_days,
		"soul": soul,
		"board_size": feature_board.size(),
		"board_tags": _collect_feature_board_tags(),
	}

## Tier availability is gated by current run number in the four-run cycle.
func is_tier_available(tier: String) -> bool:
	match tier.to_lower():
		"common":
			return true
		"uncommon":
			return current_run >= 2
		"rare":
			return current_run >= 3
		"jank":
			return current_run >= 2
		_:
			return true


func add_feature_card(card: Resource) -> void:
	if card == null or runway_days <= 0:
		return
	if card is not FeatureCard:
		return
	var placed_card: FeatureCard = card as FeatureCard

	if not can_place_card(placed_card):
		push_warning("add_feature_card: placement blocked by soul gate for alien card")
		return

	feature_board.append(placed_card)
	ambition += placed_card.ambition_value
	instability += placed_card.instability_value
	_apply_archetype_mismatch(placed_card)
	var jank_feedback: Array[Dictionary] = _evaluate_jank_prospecting(placed_card)
	soul = maxi(soul, 0)
	spend_day("add_feature")
	if _event_bus != null:
		_event_bus.feature_added.emit(placed_card)
		for feedback in jank_feedback:
			match String(feedback.get("stage", "")):
				"prospect":
					_event_bus.jank_prospect_updated.emit(feedback)
				"locked":
					_event_bus.jank_signature_locked.emit(feedback)

func fix_bugs() -> void:
	if runway_days <= 0:
		return
	var game_config: GameConfig = _content_repository.get_game_config()
	instability = max(instability - game_config.fix_bugs_instability_reduction, 0)
	ambition = max(ambition - game_config.fix_bugs_ambition_penalty, 0)
	soul = max(soul - game_config.fix_bugs_soul_cost, 0)
	spend_day("fix_bugs")

func do_dev_log() -> void:
	if runway_days <= 0:
		return
	var config: GameConfig = _content_repository.get_game_config()
	var bonus: int = config.dev_log_large_board_soul_bonus if feature_board.size() >= config.dev_log_large_board_threshold else 0
	soul += config.dev_log_soul_gain + bonus
	spend_day("dev_log")

func spend_day(reason: String) -> void:
	runway_days = max(runway_days - 1, 0)
	if _event_bus != null:
		_event_bus.day_spent.emit(DaySpentPayload.build(reason, runway_days))
	var popup_offered: bool = false
	if _offer_flow != null and _offer_flow.has_deferred_draft_offer():
		popup_offered = _maybe_offer_draft()
		if not popup_offered:
			popup_offered = _maybe_offer_dilemma()
	else:
		popup_offered = _maybe_offer_dilemma()
		if not popup_offered:
			popup_offered = _maybe_offer_draft()
	_maybe_inject_tutorial_prospect()
	if runway_days == 0:
		if _event_bus != null:
			_event_bus.runway_depleted.emit(RunwayDepletedPayload.build(runway_days))
	_emit_state()

func ship_it() -> ShipResult:
	var unfulfilled: Dictionary = {}
	if not _current_prospect_jank.is_empty() and _locked_signature_jank.is_empty():
		unfulfilled = _current_prospect_jank.duplicate(true)
	var outcome: RunResolutionOutcomeType = _run_resolution.resolve_and_commit_run(
		ambition,
		instability,
		runway_days,
		soul,
		feature_board,
		chosen_archetype,
		current_run,
		_locked_signature_jank,
		unfulfilled
	)
	if outcome == null:
		outcome = RunResolutionOutcomeType.new()
	_last_completed_run = outcome.last_completed_run
	current_run = outcome.current_run
	var result: ShipResult = outcome.ship_result
	if result == null:
		result = ShipResult.new()
	if _event_bus != null:
		_event_bus.reviews_generated.emit(result)
	return result

func apply_dilemma_choice(choice_index: int) -> void:
	var outcome: ChoiceResolutionType = _offer_flow.apply_dilemma_choice(choice_index, _capture_run_state())
	if outcome == null or outcome.is_empty():
		return
	_apply_run_state(outcome.state)
	_emit_threshold_event(outcome.threshold_event)
	_emit_state()

func apply_draft_pick(pick_index: int) -> void:
	var outcome: ChoiceResolutionType = _offer_flow.apply_draft_pick(pick_index, _capture_run_state())
	if outcome == null or outcome.is_empty():
		return
	_apply_run_state(outcome.state)
	_emit_threshold_event(outcome.threshold_event)
	_emit_state()

func calculate_predicted_score() -> float:
	return _run_resolution.calculate_predicted_score(
		ambition,
		instability,
		runway_days,
		soul,
		feature_board.size()
	)

func get_unlocked_card_ids() -> PackedStringArray:
	return _cycle_mgr.get_unlocked_card_ids()

func get_all_card_ids() -> PackedStringArray:
	return _content_repository.get_all_card_ids()

func is_card_unlocked(card_id: String) -> bool:
	if card_id.is_empty():
		return false
	return _cycle_mgr.get_unlocked_card_ids().has(card_id)

## Returns pre-placement mismatch level against the chosen archetype.
## 0 = no mismatch (none chosen, universal card, or on-archetype)
## 1 = genre stretch   (2/3 affinity, chosen archetype not included)
## 2 = wild swing      (1/3 affinity, chosen archetype not included)
## 3 = alien card      (0/3 affinity, soul-gated)
func get_archetype_mismatch_level(card: FeatureCard) -> int:
	return _archetype_rules.get_mismatch_level(card, chosen_archetype)

func _apply_archetype_mismatch(card: FeatureCard) -> void:
	var mismatch: Dictionary = _archetype_rules.build_mismatch_result(
		card,
		chosen_archetype,
		soul,
		_content_repository.get_game_config()
	)
	if mismatch.is_empty():
		return
	ambition = max(ambition + int(mismatch.get("ambition_delta", 0)), 0)
	instability = max(instability + int(mismatch.get("instability_delta", 0)), 0)
	soul = max(soul + int(mismatch.get("soul_delta", 0)), 0)
	_emit_threshold_event_from_dictionary(mismatch)

func _emit_state() -> void:
	var threshold_result: ThresholdEvaluationResultType = _offer_flow.evaluate_threshold_events(
		_content_repository.get_threshold_events(),
		_capture_run_state()
	)
	if threshold_result != null:
		_apply_run_state(threshold_result.state)
		for event_payload: ThresholdEventPayload in threshold_result.events:
			_emit_threshold_event(event_payload)
	if _event_bus != null:
		var snapshot: StateSnapshotPayload = StateSnapshotPayload.new()
		snapshot.ambition = ambition
		snapshot.instability = instability
		snapshot.runway_days = runway_days
		snapshot.soul = soul
		snapshot.features_shipped = feature_board.size()
		snapshot.current_run = current_run
		_event_bus.state_changed.emit(snapshot)

func _maybe_offer_dilemma() -> bool:
	var result: DilemmaOfferPayload = _offer_flow.maybe_offer_dilemma(
		_content_repository.get_game_config(), _content_repository.get_offers(), runway_days, soul,
		current_run,
		_cycle_mgr.get_pressure_modifier()
	)
	if result == null:
		return false
	if _event_bus != null:
		_event_bus.dilemma_offered.emit(result)
	return true

func _maybe_offer_draft() -> bool:
	var result: DraftOfferPayload = _offer_flow.maybe_offer_draft(
		_content_repository.get_game_config(), _content_repository.get_offers(), runway_days, soul, feature_board.is_empty(),
		current_run,
		_cycle_mgr.get_pressure_modifier()
	)
	if result == null:
		return false
	if _event_bus != null:
		_event_bus.draft_offer.emit(result)
	return true

func _emit_threshold_event(payload: ThresholdEventPayload) -> void:
	if _event_bus == null or payload == null:
		return
	_event_bus.threshold_event.emit(payload)

func _get_card_tier(card_id: String) -> String:
	return _content_repository.get_card_tier(card_id)

func _load_card_by_id(card_id: String) -> FeatureCard:
	return _content_repository.load_card_by_id(card_id)

func _capture_run_state() -> RunStateDataType:
	return RunStateDataType.from_values(ambition, instability, runway_days, soul)

func _apply_run_state(state: RunStateDataType) -> void:
	if state == null:
		return
	ambition = state.ambition
	instability = state.instability
	runway_days = state.runway_days
	soul = state.soul

func _emit_threshold_event_from_dictionary(event_data: Dictionary) -> void:
	if event_data.is_empty():
		return
	_emit_threshold_event(ThresholdEventPayload.build(
		String(event_data.get("event_id", event_data.get("id", ""))),
		String(event_data.get("message", "Threshold event triggered.")),
		event_data.get("effects", {}),
		String(event_data.get("severity", "info"))
	))

func _evaluate_jank_prospecting(placed_card: FeatureCard) -> Array[Dictionary]:
	var feedback: Array[Dictionary] = []
	if placed_card == null or _content_repository == null:
		return feedback
	if not _locked_signature_jank.is_empty():
		return feedback
	var combinations: Array = _content_repository.get_jank_combinations()
	if combinations.is_empty():
		return feedback

	var lock_match: Dictionary = JankResolver.find_combination(feature_board, chosen_archetype, combinations)
	if not lock_match.is_empty():
		_locked_signature_jank = lock_match.duplicate(true)
		_current_prospect_jank.clear()
		_current_prospect_jank_id = String(lock_match.get("jank_card_id", ""))
		var locked_payload: Dictionary = lock_match.duplicate(true)
		locked_payload["stage"] = "locked"
		locked_payload["message"] = String(locked_payload.get(
			"lock_in_line",
			"Signature jank locked: %s." % String(locked_payload.get("name", "Unknown Jank"))
		))
		var soul_reward: int = 0
		if not _signature_jank_reward_granted:
			soul += 1
			_signature_jank_reward_granted = true
			soul_reward = 1
		locked_payload["soul_reward"] = soul_reward
		feedback.append(locked_payload)
		return feedback

	var prospect: Dictionary = JankResolver.find_prospect(feature_board, chosen_archetype, placed_card, combinations)
	if prospect.is_empty():
		_current_prospect_jank_id = ""
		_current_prospect_jank.clear()
		return feedback

	var prospect_id: String = String(prospect.get("jank_card_id", ""))
	if prospect_id.is_empty():
		_current_prospect_jank.clear()
		return feedback
	_current_prospect_jank_id = prospect_id
	_current_prospect_jank = prospect.duplicate(true)
	if bool(_hinted_prospect_jank_ids.get(prospect_id, false)):
		return feedback
	_hinted_prospect_jank_ids[prospect_id] = true
	var prospect_payload: Dictionary = prospect.duplicate(true)
	prospect_payload["stage"] = "prospect"
	prospect_payload["message"] = String(prospect_payload.get("prospect_hint", "Something strange is taking shape."))
	feedback.append(prospect_payload)
	return feedback

func _collect_feature_board_ids() -> PackedStringArray:
	var board_ids: PackedStringArray = PackedStringArray()
	for card in feature_board:
		if card is FeatureCard:
			board_ids.append(_normalize_feature_name(String((card as FeatureCard).feature_name)))
	return board_ids

func _collect_feature_board_tags() -> PackedStringArray:
	var seen: Dictionary = {}
	var board_tags: PackedStringArray = PackedStringArray()
	for card in feature_board:
		if card is not FeatureCard:
			continue
		for tag in (card as FeatureCard).tags:
			var tag_name: String = String(tag)
			if tag_name.is_empty() or seen.has(tag_name):
				continue
			seen[tag_name] = true
			board_tags.append(tag_name)
	return board_tags

func _normalize_feature_name(raw: String) -> String:
	return raw.to_lower().strip_edges().replace(" ", "_").replace("-", "_")

func _maybe_inject_tutorial_prospect() -> void:
	if current_run != 1:
		return
	if not _current_prospect_jank.is_empty() or not _locked_signature_jank.is_empty():
		return
	var initial_days: int = _content_repository.get_game_config().tutorial_runway_days
	if runway_days > initial_days - 2:
		return
	var combinations: Array = _content_repository.get_jank_combinations()
	var candidates: Array = []
	for combo in combinations:
		if bool(combo.get("tutorial_prospect", false)):
			candidates.append(combo)
	if candidates.is_empty():
		return
	var pick: Dictionary = candidates[_rng.randi_range(0, candidates.size() - 1)]
	var prospect_id: String = String(pick.get("jank_card_id", ""))
	if prospect_id.is_empty() or bool(_hinted_prospect_jank_ids.get(prospect_id, false)):
		return
	_current_prospect_jank_id = prospect_id
	_current_prospect_jank = pick.duplicate(true)
	_hinted_prospect_jank_ids[prospect_id] = true
	if _event_bus != null:
		var payload: Dictionary = pick.duplicate(true)
		payload["stage"] = "prospect"
		payload["message"] = String(pick.get("prospect_hint", "Something strange is taking shape."))
		_event_bus.jank_prospect_updated.emit(payload)
