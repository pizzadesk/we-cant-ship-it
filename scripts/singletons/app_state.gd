extends Node

const INTERACTION_RULES_PATH: String = "res://data/interaction_rules.json"
const THRESHOLD_EVENTS_PATH: String = "res://data/threshold_events.json"
const OFFERS_PATH: String = "res://data/offers.json"
const META_SAVE_PATH: String = "user://meta_progress.json"
const CARDS_PATH: String = "res://data/cards"
const CUSTOM_CARDS_PATH: String = "res://data/custom_cards"
# Card unlock count moved to GameConfig.initial_card_unlock_count (default 8)
const GAME_CONFIG_PATH: String = "res://data/game_config.tres"

# --- Preloads for legacy system classes (avoids class_name scan-order issues) ---
@warning_ignore("shadowed_global_identifier")
const LegacyRecord = preload("res://scripts/data/legacy_record.gd")
@warning_ignore("shadowed_global_identifier")
const LegacyPayload = preload("res://scripts/data/payloads/legacy_payload.gd")
@warning_ignore("shadowed_global_identifier")
const LegacyUtils = preload("res://scripts/ui/legacy_utils.gd")

# --- Preloads for extracted collaborator classes ---
@warning_ignore("shadowed_global_identifier")
const ScoreCalculator = preload("res://scripts/data/score_calculator.gd")
@warning_ignore("shadowed_global_identifier")
const MetaProgressManager = preload("res://scripts/data/meta_progress_manager.gd")
@warning_ignore("shadowed_global_identifier")
const OfferScheduler = preload("res://scripts/data/offer_scheduler.gd")
@warning_ignore("shadowed_global_identifier")
const CardUnlockResolver = preload("res://scripts/data/card_unlock_resolver.gd")

var ambition: int = 0
var instability: int = 0
var runway_days: int = 21
var soul: int = 10
var feature_board: Array[FeatureCard] = []

var _game_config: GameConfig
var _offers: Dictionary = {}
var _interaction_rules: Dictionary = {}
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _event_bus: Node
var _review_generator: Node
var _triggered_thresholds: Dictionary = {}
var _style_points: Dictionary = {"cult_jank": 0, "prestige_collapse": 0, "community_darling": 0}
var _current_identity: String = "Unformed"
var _pending_dilemma: Dictionary = {}
var _pending_draft_offer: Dictionary = {}
var _pending_publisher_meeting: Dictionary = {}
var _publisher_trust_run: int = 0
var _publisher_trust_mode_enabled_run: bool = false
var _meta_progress: Dictionary = {}  # Aliased to _meta_mgr._meta in _ready()
var _all_card_ids: PackedStringArray = PackedStringArray()
var _card_metadata_cache: Dictionary = {}  # {card_id: {"tier": str, "unlock_weight": float}}
var _threshold_events: Array[Dictionary] = []
var _meta_mgr: MetaProgressManager
var _offer_sched: OfferScheduler

func _ready() -> void:
	_rng.randomize()
	_event_bus = GameEvents
	_review_generator = ReviewService
	_meta_mgr = MetaProgressManager.new()
	_offer_sched = OfferScheduler.new(_rng)
	_load_game_config()
	_meta_mgr.load_from_disk()
	_meta_progress = _meta_mgr._meta
	_rebuild_all_card_ids()
	_ensure_card_unlock_state()
	_load_interaction_rules()
	_load_threshold_events()
	_load_offers()
	reset_run()

func reset_run() -> void:
	ambition = 0
	instability = 0
	runway_days = 21
	soul = 10
	feature_board.clear()
	_triggered_thresholds.clear()
	_style_points = {"cult_jank": 0, "prestige_collapse": 0, "community_darling": 0}
	_current_identity = "Unformed"
	_offer_sched.reset()
	_publisher_trust_mode_enabled_run = bool(_meta_progress.get("publisher_trust_mode_enabled", false))
	if _publisher_trust_mode_enabled_run:
		_publisher_trust_run = int(_meta_progress.get("publisher_profile_trust", 0))
	else:
		_publisher_trust_run = 0
	_emit_state()

func get_game_config() -> GameConfig:
	return _game_config

func get_dominant_style_bucket() -> String:
	return _get_dominant_style_bucket()

func is_publisher_trust_mode_enabled() -> bool:
	return bool(_meta_progress.get("publisher_trust_mode_enabled", false))

func set_publisher_trust_mode_enabled(enabled: bool) -> void:
	_meta_progress["publisher_trust_mode_enabled"] = enabled
	_save_meta_progress()

func is_tier_available(tier: String) -> bool:
	var normalized_tier: String = tier.to_lower()
	var studio_tier: int = int(_meta_progress.get("studio_tier", 1))
	match normalized_tier:
		"common":
			return true
		"uncommon":
			return studio_tier >= 2
		"rare":
			return studio_tier >= 3 or bool(_meta_progress.get("defining_game_unlocked", false))
		_:
			return true

func has_potential_interaction(card: FeatureCard, board: Array[FeatureCard]) -> bool:
	if card == null:
		return false
	for existing in board:
		if existing == null:
			continue
		for new_tag in card.tags:
			for existing_tag in existing.tags:
				var rule: Dictionary = _get_rule(String(new_tag), String(existing_tag))
				if _is_rule_blocked_by_soul(rule):
					continue
				if String(new_tag) == String(existing_tag) or not rule.is_empty():
					return true
	return false

func add_feature_card(card: Resource) -> void:
	if card == null:
		return
	if runway_days <= 0:
		return
	if card is not FeatureCard:
		return
	var placed_card: FeatureCard = card as FeatureCard

	var interaction_events: Array[Dictionary] = _build_interaction_events(placed_card)
	feature_board.append(placed_card)
	ambition += placed_card.ambition_value
	instability += placed_card.instability_value
	_style_points["prestige_collapse"] += max(placed_card.ambition_value, 0)
	_style_points["cult_jank"] += max(placed_card.instability_value, 0)
	if placed_card.tags.has("lore") or placed_card.tags.has("quest"):
		_style_points["community_darling"] += 2

	for event_data in interaction_events:
		instability += int(event_data.get("instability_delta", 0))
		soul += int(event_data.get("soul_delta", 0))
		if int(event_data.get("soul_delta", 0)) > 0:
			_style_points["community_darling"] += int(event_data.get("soul_delta", 0))
		if int(event_data.get("instability_delta", 0)) > 0:
			_style_points["cult_jank"] += int(event_data.get("instability_delta", 0))
		if _event_bus != null:
			var payload: InteractionEventPayload = InteractionEventPayload.from_dictionary(event_data)
			_event_bus.interaction_triggered.emit(payload)

	soul = max(soul, 0)
	_update_run_identity()
	spend_day("add_feature")
	if _event_bus != null:
		_event_bus.feature_added.emit(placed_card)
	_emit_state()

func fix_bugs() -> void:
	if runway_days <= 0:
		return
	instability = max(instability - _game_config.fix_bugs_instability_reduction, 0)
	soul = max(soul - _game_config.fix_bugs_soul_cost, 0)
	_style_points["prestige_collapse"] += 2
	spend_day("fix_bugs")

func do_dev_log() -> void:
	if runway_days <= 0:
		return
	soul += _game_config.dev_log_soul_gain
	_style_points["community_darling"] += 6
	spend_day("dev_log")

func tick_runway_day() -> void:
	# Intentionally no-op: runway no longer auto-advances on timer ticks.
	# Day spend is reserved for explicit card placement or popup runway effects.
	return

func spend_day(reason: String) -> void:
	runway_days = max(runway_days - 1, 0)
	if _event_bus != null:
		_event_bus.day_spent.emit(DaySpentPayload.build(reason, runway_days))
	var popup_offered: bool = _maybe_offer_publisher_meeting()
	if not popup_offered:
		popup_offered = _maybe_offer_dilemma()
	if not popup_offered:
		popup_offered = _maybe_offer_draft()
	if runway_days == 0:
		if _event_bus != null:
			_event_bus.runway_depleted.emit(RunwayDepletedPayload.build(runway_days))
	_emit_state()

func ship_it() -> Dictionary:
	var features_shipped: int = feature_board.size()

	# Validate that at least one feature was shipped (design requirement)
	if features_shipped == 0:
		push_warning("Attempted to ship with 0 features - this is an edge case, defaulting to 'Financial Catastrophe' ending")

	var ship_window: Dictionary = _compute_ship_window()
	var review_score: float = _calculate_final_score(ship_window)
	var jank_status: String = _compute_jank_status(review_score)
	var meeting_quality: float = _average_meeting_quality()
	var ship_window_quality: float = _ship_window_quality(String(ship_window.get("label", "Standard Launch")))
	var reviews: Array[Dictionary] = []
	var mechanics_highlights: Array[String] = []
	if _review_generator != null:
		reviews = _review_generator.generate_reviews(review_score, instability, soul, features_shipped, feature_board, _current_identity, String(ship_window.get("label", "")))
		mechanics_highlights = _review_generator.generate_mechanics_highlights(feature_board)
	var ending: String = _resolve_ending(review_score)
	var unlocked_defining_game: bool = String(ending).begins_with("Defining Game")
	if unlocked_defining_game and not bool(_meta_progress.get("defining_game_unlocked", false)):
		_meta_progress["defining_game_unlocked"] = true
	update_meta_progress(review_score, ending, false, false)
	var card_unlock: Dictionary = _unlock_cards_for_run(ending, jank_status, meeting_quality, ship_window_quality)

	# Crystallise the legacy record now that tier has been updated by update_meta_progress.
	var pending: LegacyRecord = _compute_legacy_record(review_score)
	var active_dict: Variant = _meta_progress.get("active_legacy", {})
	var active: LegacyRecord = LegacyRecord.from_dictionary(active_dict if active_dict is Dictionary else {})
	_meta_progress["pending_legacy"] = pending.to_dictionary()
	_save_meta_progress()
	_emit_meta_progress_updated()

	var result: ShipResult = ShipResult.new()
	result.review_score = review_score
	result.ending = ending
	result.jank_status = jank_status
	result.ship_window = ship_window
	result.publisher_meeting_quality = meeting_quality
	result.publisher_trust = _publisher_trust_run
	result.card_unlock = card_unlock
	result.features_shipped = features_shipped
	result.reviews = reviews
	result.mechanics_highlights = mechanics_highlights
	result.run_identity = _current_identity
	result.unlock_defining_game = unlocked_defining_game
	result.meta_progress = _meta_progress.duplicate(true)

	if _event_bus != null and _event_bus.has_signal("legacy_resolved"):
		var legacy_payload: LegacyPayload = LegacyPayload.build(
			pending, active, int(_meta_progress.get("studio_tier", 1))
		)
		_event_bus.legacy_resolved.emit(legacy_payload)

	if _event_bus != null:
		var payload: ReviewsGeneratedPayload = ReviewsGeneratedPayload.from_dictionary(result.to_dictionary())
		_event_bus.reviews_generated.emit(payload)
	return result.to_dictionary()

# Pure score calculation shared by ship_it() and calculate_predicted_score().
# Delegates to ScoreCalculator for formula logic.
func _calculate_final_score(ship_window: Dictionary) -> float:
	return ScoreCalculator.calculate_final_score(
		_game_config, ambition, instability, soul, feature_board.size(), ship_window
	)

func apply_dilemma_choice(choice_index: int) -> void:
	if _pending_dilemma.is_empty():
		return

	var choices: Array = _pending_dilemma.get("choices", [])
	if choices.is_empty():
		_pending_dilemma.clear()
		return

	var selected_index: int = clampi(choice_index, 0, choices.size() - 1)
	var selected: Dictionary = choices[selected_index]
	_apply_threshold_effects(selected.get("effects", {}))
	_emit_threshold_event(
		"dilemma_choice",
		"Dilemma resolved: %s" % String(selected.get("label", "Choice applied")),
		selected.get("effects", {})
	)
	_pending_dilemma.clear()
	_emit_state()

func apply_draft_pick(pick_index: int) -> void:
	if _pending_draft_offer.is_empty():
		return

	var picks: Array = _pending_draft_offer.get("picks", [])
	if picks.is_empty():
		_pending_draft_offer.clear()
		return

	var selected_index: int = clampi(pick_index, 0, picks.size() - 1)
	var selected: Dictionary = picks[selected_index]
	_apply_threshold_effects(selected.get("effects", {}))
	_emit_threshold_event(
		"draft_pick",
		"Draft pick accepted: %s" % String(selected.get("title", "Unknown pitch")),
		selected.get("effects", {})
	)
	_pending_draft_offer.clear()
	_emit_state()

func _build_interaction_events(new_card: FeatureCard) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	for existing_card in feature_board:
		if existing_card == null:
			continue

		for new_tag in new_card.tags:
			for existing_tag in existing_card.tags:
				var maybe_event: Dictionary = _create_event_for_tag_pair(new_card, existing_card, String(new_tag), String(existing_tag))
				if not maybe_event.is_empty():
					events.append(maybe_event)
	return events

func _create_event_for_tag_pair(new_card: FeatureCard, existing_card: FeatureCard, new_tag: String, existing_tag: String) -> Dictionary:
	var has_overlap: bool = new_tag == existing_tag
	var rule: Dictionary = _get_rule(new_tag, existing_tag)

	# Soul gate suppresses the entire pair interaction until enough conviction is accumulated.
	if _is_rule_blocked_by_soul(rule):
		return {}

	if not has_overlap and rule.is_empty():
		return {}

	var instability_delta: int = 0
	var soul_delta: int = 0

	if has_overlap:
		instability_delta += 2
		instability_delta += new_card.get_interaction_delta(new_tag, "instability")
		instability_delta += existing_card.get_interaction_delta(existing_tag, "instability")
		soul_delta += new_card.get_interaction_delta(new_tag, "soul")
		soul_delta += existing_card.get_interaction_delta(existing_tag, "soul")

	if not rule.is_empty():
		instability_delta += int(rule.get("instability_delta", 0))
		soul_delta += int(rule.get("soul_delta", 0))

	var flavor: String = _pick_interaction_flavor(rule, new_card, existing_card, new_tag, existing_tag)
	return {
		"new_feature": new_card.feature_name,
		"existing_feature": existing_card.feature_name,
		"instability_delta": instability_delta,
		"soul_delta": soul_delta,
		"flavor": flavor
	}

func _pick_interaction_flavor(rule: Dictionary, new_card: FeatureCard, existing_card: FeatureCard, new_tag: String, existing_tag: String) -> String:
	if new_tag == existing_tag:
		var new_flavor: String = new_card.get_interaction_flavor_for_tag(new_tag)
		if not new_flavor.is_empty():
			return new_flavor
		var existing_flavor: String = existing_card.get_interaction_flavor_for_tag(existing_tag)
		if not existing_flavor.is_empty():
			return existing_flavor

	var flavors: Array = []
	if not rule.is_empty():
		flavors = rule.get("flavors", [])

	if flavors.is_empty():
		return "%s + %s = Build monitor now shows six warning colors." % [new_card.feature_name, existing_card.feature_name]

	var picked: String = String(flavors[_rng.randi_range(0, flavors.size() - 1)])
	picked = picked.replace("{new_feature}", new_card.feature_name)
	picked = picked.replace("{existing_feature}", existing_card.feature_name)
	picked = picked.replace("{tag_a}", new_tag)
	picked = picked.replace("{tag_b}", existing_tag)
	return picked

func _get_rule(tag_a: String, tag_b: String) -> Dictionary:
	var key_a: String = "%s|%s" % [tag_a, tag_b]
	var key_b: String = "%s|%s" % [tag_b, tag_a]
	if _interaction_rules.has(key_a):
		return _interaction_rules[key_a]
	if _interaction_rules.has(key_b):
		return _interaction_rules[key_b]
	return {}

func _is_rule_blocked_by_soul(rule: Dictionary) -> bool:
	if rule.is_empty():
		return false
	return soul < int(rule.get("soul_required", 0))

func _load_game_config() -> void:
	_game_config = load(GAME_CONFIG_PATH) as GameConfig
	if _game_config == null:
		push_warning("GameConfig not found at %s — falling back to defaults" % GAME_CONFIG_PATH)
		_game_config = GameConfig.new()

func _load_offers() -> void:
	_offers = JsonDataLoader.load_dictionary(OFFERS_PATH, "Offers")

func _load_interaction_rules() -> void:
	var interaction_data: Dictionary = JsonDataLoader.load_dictionary(INTERACTION_RULES_PATH, "Interaction rules")
	var rules: Variant = interaction_data.get("rules", [])
	if rules is not Array:
		return

	for rule_entry in rules:
		if rule_entry is Dictionary:
			var tags: Variant = rule_entry.get("tags", [])
			if tags is Array and tags.size() == 2:
				var key: String = "%s|%s" % [String(tags[0]), String(tags[1])]
				_interaction_rules[key] = rule_entry

func _load_threshold_events() -> void:
	var parse_result: Array = JsonDataLoader.load_array(THRESHOLD_EVENTS_PATH, "Threshold events")
	var loaded_events: Array[Dictionary] = []
	for event_entry in parse_result:
		if event_entry is Dictionary:
			loaded_events.append(event_entry)

	_threshold_events = loaded_events

func _resolve_ending(review_score: float) -> String:
	return EndingResolver.resolve_ending_description(
		_game_config,
		ambition,
		instability,
		soul,
		review_score,
		_get_dominant_style_bucket()
	)

func _is_defining_game_gate_met() -> bool:
	return ambition >= _game_config.goldilocks_ambition_min \
		and instability >= _game_config.goldilocks_instability_min \
		and instability <= _game_config.goldilocks_instability_max \
		and soul >= _game_config.goldilocks_soul_min

func _is_cult_disaster_gate_met() -> bool:
	return instability >= _game_config.cult_disaster_instability_min and soul <= _game_config.cult_disaster_soul_max

func _is_rough_diamond_gate_met() -> bool:
	return ambition <= _game_config.rough_diamond_ambition_max \
		and instability <= _game_config.rough_diamond_instability_max \
		and soul >= _game_config.rough_diamond_soul_min

func _normalize_ending_name(ending: String) -> String:
	return EndingResolver.normalize_ending_name(ending)

func _get_dominant_style_bucket() -> String:
	var cult: int = int(_style_points.get("cult_jank", 0))
	var prestige: int = int(_style_points.get("prestige_collapse", 0))
	var community: int = int(_style_points.get("community_darling", 0))
	var top_score: int = maxi(cult, maxi(prestige, community))
	if top_score <= 0:
		return ""
	var top_count: int = 0
	if cult == top_score:
		top_count += 1
	if prestige == top_score:
		top_count += 1
	if community == top_score:
		top_count += 1
	if top_count > 1:
		return ""
	if cult == top_score:
		return "cult_jank"
	if prestige == top_score:
		return "prestige_collapse"
	return "community_darling"

func _emit_state() -> void:
	_evaluate_threshold_events()
	_update_run_identity()
	if _event_bus != null:
		var snapshot: StateSnapshotPayload = StateSnapshotPayload.new()
		snapshot.ambition = ambition
		snapshot.instability = instability
		snapshot.runway_days = runway_days
		snapshot.soul = soul
		snapshot.features_shipped = feature_board.size()
		snapshot.run_identity = _current_identity
		snapshot.meta_studio_tier = int(_meta_progress.get("studio_tier", 1))
		snapshot.style_points = _style_points.duplicate(true)
		_event_bus.state_changed.emit(snapshot)

func _update_run_identity() -> void:
	var new_identity: String = "Unformed"
	if _style_points["cult_jank"] > _style_points["prestige_collapse"] and _style_points["cult_jank"] > _style_points["community_darling"]:
		new_identity = "Cult Jank"
	elif _style_points["prestige_collapse"] > _style_points["community_darling"]:
		new_identity = "Prestige Collapse"
	elif _style_points["community_darling"] > 0:
		new_identity = "Community Darling"

	if new_identity != _current_identity:
		_current_identity = new_identity
		if _event_bus != null and _event_bus.has_signal("run_identity_changed"):
			var payload: RunIdentityPayload = RunIdentityPayload.new()
			payload.identity = _current_identity
			payload.style_points = _style_points.duplicate(true)
			_event_bus.run_identity_changed.emit(payload)

func _compute_ship_window() -> Dictionary:
	return ScoreCalculator.compute_ship_window(_game_config, runway_days, instability)

func _compute_jank_status(review_score: float) -> String:
	return ScoreCalculator.compute_jank_status(_game_config, instability, review_score)

func _unlock_cards_for_run(ending: String, jank_status: String, meeting_quality: float, ship_window_quality: float) -> Dictionary:
	var unlocked: PackedStringArray = get_unlocked_card_ids()
	var result: Dictionary = CardUnlockResolver.resolve_unlock(
		_all_card_ids, unlocked, ending, jank_status,
		meeting_quality, ship_window_quality,
		_card_metadata_cache, _rng, Callable(self, "_load_card_by_id")
	)
	if result.is_empty():
		return {}
	_meta_progress["unlocked_card_ids"] = result.get("new_unlocked_ids", unlocked)
	result.erase("new_unlocked_ids")
	return result

func _get_card_unlock_weight(card_id: String) -> float:
	if _card_metadata_cache.has(card_id):
		return float(_card_metadata_cache[card_id].get("unlock_weight", 1.0))
	return 1.0

func _get_card_tier(card_id: String) -> String:
	if _card_metadata_cache.has(card_id):
		return String(_card_metadata_cache[card_id].get("tier", "common"))
	return "common"

func _load_card_by_id(card_id: String) -> FeatureCard:
	var card_path: String = "%s/%s.tres" % [CARDS_PATH, card_id]
	var card: FeatureCard = load(card_path) as FeatureCard
	if card == null:
		card_path = "%s/%s.tres" % [CUSTOM_CARDS_PATH, card_id]
		card = load(card_path) as FeatureCard
	return card

func _average_meeting_quality() -> float:
	return _offer_sched.average_meeting_quality()

func _ship_window_quality(label: String) -> float:
	return ScoreCalculator.ship_window_quality(label)

func _maybe_offer_dilemma() -> bool:
	var result: Dictionary = _offer_sched.maybe_offer_dilemma(
		_game_config, _offers, runway_days, soul,
		_publisher_trust_mode_enabled_run, _publisher_trust_run,
		int(_meta_progress.get("runs_played", 0))
	)
	if result.is_empty():
		return false
	_pending_dilemma = result
	if _event_bus != null:
		var payload: DilemmaOfferPayload = DilemmaOfferPayload.from_dictionary(_pending_dilemma)
		_event_bus.dilemma_offered.emit(payload)
	return true

func _maybe_offer_draft() -> bool:
	var result: Dictionary = _offer_sched.maybe_offer_draft(
		_game_config, _offers, runway_days, soul, feature_board.is_empty()
	)
	if result.is_empty():
		return false
	_pending_draft_offer = result
	if _event_bus != null:
		var payload: DraftOfferPayload = DraftOfferPayload.from_dictionary(_pending_draft_offer)
		_event_bus.draft_offer.emit(payload)
	return true

func _maybe_offer_publisher_meeting() -> bool:
	var result: Dictionary = _offer_sched.maybe_offer_publisher_meeting(
		_game_config, runway_days, instability, soul, feature_board.size(),
		_publisher_trust_mode_enabled_run, _publisher_trust_run,
		int(_meta_progress.get("runs_played", 0))
	)
	if result.is_empty():
		return false
	_pending_publisher_meeting = result
	if _event_bus != null:
		var payload: PublisherMeetingOfferPayload = PublisherMeetingOfferPayload.from_dictionary(_pending_publisher_meeting)
		_event_bus.publisher_meeting_offered.emit(payload)
	return true

func apply_publisher_meeting_choice(choice_index: int) -> void:
	if _pending_publisher_meeting.is_empty():
		return

	var options: Array = _pending_publisher_meeting.get("options", [])
	if options.is_empty():
		_pending_publisher_meeting.clear()
		return

	var selected_index: int = clampi(choice_index, 0, options.size() - 1)
	var selected: Dictionary = options[selected_index]
	_apply_threshold_effects(selected.get("effects", {}))

	_publisher_trust_run += int(_pending_publisher_meeting.get("grade_trust_delta", 0))
	_publisher_trust_run += int(selected.get("trust_delta", 0))
	_publisher_trust_run = clampi(_publisher_trust_run, -100, 100)
	if _publisher_trust_mode_enabled_run:
		_meta_progress["publisher_profile_trust"] = _publisher_trust_run

	_offer_sched.record_meeting_quality(float(_pending_publisher_meeting.get("grade_quality", 0.5)))

	_emit_threshold_event(
		"publisher_meeting_choice",
		"Publisher meeting stance chosen: %s" % String(selected.get("label", "Unknown")),
		selected.get("effects", {})
	)

	_pending_publisher_meeting.clear()
	_emit_state()

func update_meta_progress(review_score: float, ending: String, persist: bool = true, emit_event: bool = true) -> void:
	var milestone_data: Dictionary = _meta_mgr.update_progress(_game_config, review_score, ending)

	if not milestone_data.is_empty():
		if _event_bus != null and _event_bus.has_signal("milestone_reached"):
			var payload: MilestonePayload = MilestonePayload.from_dictionary(milestone_data)
			_event_bus.milestone_reached.emit(payload)

	if persist:
		_save_meta_progress()
	if emit_event:
		_emit_meta_progress_updated()

func _emit_meta_progress_updated() -> void:
	if _event_bus == null or not _event_bus.has_signal("meta_progress_updated"):
		return
	var payload: MetaProgressPayload = MetaProgressPayload.from_dictionary(_meta_progress)
	_event_bus.meta_progress_updated.emit(payload)

func _reputation_for_ending(ending: String) -> int:
	return MetaProgressManager.reputation_for_ending(_game_config, ending)

func _compute_studio_tier() -> int:
	return _meta_mgr.compute_studio_tier(_game_config)

func _maybe_record_milestone(ending: String) -> void:
	# Delegation kept for any remaining callers; primary path is via update_meta_progress.
	var milestone_data: Dictionary = _meta_mgr._maybe_record_milestone(_game_config, ending)
	if not milestone_data.is_empty():
		if _event_bus != null and _event_bus.has_signal("milestone_reached"):
			var payload: MilestonePayload = MilestonePayload.from_dictionary(milestone_data)
			_event_bus.milestone_reached.emit(payload)

func _compute_legacy_record(review_score: float) -> LegacyRecord:
	var legacy_type: String = LegacyUtils.determine_legacy_type(
		review_score, soul, instability, ambition, _current_identity
	)
	var runs_played: int = int(_meta_progress.get("runs_played", 0))
	var record: LegacyRecord = LegacyRecord.new()
	record.name = LegacyUtils.generate_legacy_name(legacy_type, _rng)
	record.type = legacy_type
	record.tier = int(_meta_progress.get("studio_tier", 1))
	record.run_identity = _current_identity
	record.review_score = review_score
	record.era_label = LegacyUtils.generate_era_label(runs_played, _rng)
	return record

func _load_meta_progress() -> void:
	_meta_mgr.load_from_disk()
	_meta_progress = _meta_mgr._meta

func _save_meta_progress() -> void:
	_meta_mgr.save()

func get_unlocked_card_ids() -> PackedStringArray:
	var ids: PackedStringArray = PackedStringArray(_meta_progress.get("unlocked_card_ids", PackedStringArray()))
	return ids

func get_all_card_ids() -> PackedStringArray:
	return _all_card_ids.duplicate()

func get_meta_progress() -> Dictionary:
	return _meta_progress.duplicate(true)

func get_active_legacy() -> LegacyRecord:
	return LegacyRecord.from_dictionary(_meta_mgr.get_active_legacy())

func get_pending_legacy() -> LegacyRecord:
	return LegacyRecord.from_dictionary(_meta_mgr.get_pending_legacy())

# Called from main.gd after the player makes a displacement choice in the studio briefing.
# keep_current = true  → discard pending, retain active
# keep_current = false → pending becomes active, pending cleared
func resolve_legacy_displacement(keep_current: bool) -> void:
	_meta_mgr.resolve_legacy_displacement(keep_current)

func calculate_predicted_score() -> float:
	# Calls the same calculation as ship_it() — formula drift is impossible.
	return _calculate_final_score(_compute_ship_window())

func is_card_unlocked(card_id: String) -> bool:
	if card_id.is_empty():
		return false
	var unlocked: PackedStringArray = get_unlocked_card_ids()
	return unlocked.has(card_id)

func _ensure_card_unlock_state() -> void:
	_meta_mgr.ensure_card_unlock_state(_game_config, _all_card_ids, _get_card_tier)

func _evaluate_threshold_events() -> void:
	for threshold_event in _threshold_events:
		if threshold_event is not Dictionary:
			continue

		var event_id: String = String(threshold_event.get("id", ""))
		if event_id.is_empty() or _triggered_thresholds.get(event_id, false):
			continue

		if not _is_threshold_reached(threshold_event):
			continue

		_triggered_thresholds[event_id] = true
		var threshold_effects: Dictionary = threshold_event.get("effects", {}).duplicate(true)
		# Safety invariant: threshold events are automatic; they must never move runway days.
		if threshold_effects.has("runway_days"):
			threshold_effects.erase("runway_days")
		_apply_threshold_effects(threshold_effects)

		_emit_threshold_event(
			event_id,
			String(threshold_event.get("message", "Threshold event triggered.")),
			threshold_effects,
			String(threshold_event.get("severity", "info"))
		)

func _emit_threshold_event(event_id: String, message: String, effects: Variant, severity: String = "info") -> void:
	if _event_bus == null or not _event_bus.has_signal("threshold_event"):
		return
	var safe_effects: Dictionary = {}
	if effects is Dictionary:
		safe_effects = (effects as Dictionary).duplicate(true)
	var payload: ThresholdEventPayload = ThresholdEventPayload.from_dictionary({
		"id": event_id,
		"severity": severity,
		"message": message,
		"effects": safe_effects,
	})
	_event_bus.threshold_event.emit(payload)

func _is_threshold_reached(threshold_event: Dictionary) -> bool:
	var metric_name: String = String(threshold_event.get("metric", ""))
	var threshold_value: int = int(threshold_event.get("threshold", 0))
	var comparison: String = String(threshold_event.get("comparison", "gte"))
	var current_value: int = _get_metric_value(metric_name)

	if comparison == "lte":
		return current_value <= threshold_value
	return current_value >= threshold_value

func _get_metric_value(metric_name: String) -> int:
	match metric_name:
		"ambition":
			return ambition
		"instability":
			return instability
		"runway_days":
			return runway_days
		"soul":
			return soul
		_:
			return 0

func _apply_threshold_effects(effects: Variant) -> void:
	if effects is not Dictionary:
		return

	var ambition_delta: int = int(effects.get("ambition", 0))
	var instability_delta: int = int(effects.get("instability", 0))
	var soul_delta: int = int(effects.get("soul", 0))

	ambition += ambition_delta
	instability += instability_delta
	runway_days += int(effects.get("runway_days", 0))
	soul += soul_delta

	if ambition_delta > 0:
		_style_points["prestige_collapse"] += ambition_delta
	if instability_delta > 0:
		_style_points["cult_jank"] += instability_delta
	if soul_delta > 0:
		_style_points["community_darling"] += soul_delta

	ambition = max(ambition, 0)
	instability = max(instability, 0)
	runway_days = max(runway_days, 0)
	soul = max(soul, 0)

func _rebuild_all_card_ids() -> void:
	_all_card_ids.clear()
	_card_metadata_cache.clear()
	_append_card_ids_from_directory(CARDS_PATH)
	_append_card_ids_from_directory(CUSTOM_CARDS_PATH)
	_all_card_ids.sort()
	_populate_card_metadata_cache()

func _append_card_ids_from_directory(directory_path: String) -> void:
	var directory: DirAccess = DirAccess.open(directory_path)
	if directory == null:
		return
	directory.list_dir_begin()
	var file_name: String = directory.get_next()
	while file_name != "":
		if not directory.current_is_dir() and _is_unlockable_card_file(file_name):
			var card_id: String = _card_id_from_file_name(file_name)
			if not card_id.is_empty() and not _all_card_ids.has(card_id):
				_all_card_ids.append(card_id)
		file_name = directory.get_next()
	directory.list_dir_end()

func _is_unlockable_card_file(file_name: String) -> bool:
	var normalized: String = file_name.to_lower()
	if normalized.begins_with("readme") or normalized.begins_with("tutorial"):
		return false
	if normalized.contains("template"):
		return false
	if normalized.begins_with("debug"):
		return false
	return true

func _card_id_from_file_name(file_name: String) -> String:
	if file_name.ends_with(".tres.remap"):
		return file_name.trim_suffix(".tres.remap")
	if file_name.ends_with(".res.remap"):
		return file_name.trim_suffix(".res.remap")
	if file_name.ends_with(".tres"):
		return file_name.trim_suffix(".tres")
	if file_name.ends_with(".res"):
		return file_name.trim_suffix(".res")
	return ""

func _populate_card_metadata_cache() -> void:
	# Load tier and unlock_weight for all cards into O(1) cache
	for card_id in _all_card_ids:
		var card: FeatureCard = _load_card_by_id(card_id)
		if card == null:
			continue
		_card_metadata_cache[card_id] = {
			"tier": String(card.tier).to_lower(),
			"unlock_weight": float(card.unlock_weight)
		}
