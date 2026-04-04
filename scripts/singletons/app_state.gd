extends Node

const THRESHOLD_EVENTS_PATH: String = "res://data/threshold_events.json"
const OFFERS_PATH: String = "res://data/offers.json"
const CARDS_PATH: String = "res://data/cards"
const CUSTOM_CARDS_PATH: String = "res://data/custom_cards"
const GAME_CONFIG_PATH: String = "res://data/game_config.tres"
const JANK_COMBINATIONS_PATH: String = "res://data/jank_combinations.json"
var GAME_CONFIG_OVERRIDE_PATHS: Array[String] = [
	"res://data/game_config_override.json",
	"user://game_config_override.json",
]

@warning_ignore("shadowed_global_identifier")
const ScoreCalculator = preload("res://scripts/data/score_calculator.gd")
@warning_ignore("shadowed_global_identifier")
const CycleStateManager = preload("res://scripts/data/cycle_state_manager.gd")
@warning_ignore("shadowed_global_identifier")
const OfferScheduler = preload("res://scripts/data/offer_scheduler.gd")
@warning_ignore("shadowed_global_identifier")
const CardUnlockResolver = preload("res://scripts/data/card_unlock_resolver.gd")
@warning_ignore("shadowed_global_identifier")
const JankResolver = preload("res://scripts/data/jank_resolver.gd")
@warning_ignore("shadowed_global_identifier")
const EndingResolver = preload("res://scripts/data/ending_resolver.gd")
const _S = preload("res://scripts/ui/ui_strings.gd")

# --- Run state ---
var ambition: int = 0
var instability: int = 0
var runway_days: int = 21
var soul: int = 12
var feature_board: Array[FeatureCard] = []
var chosen_archetype: String = ""

# Cycle-level state visible to UI.
var current_run: int = 1

var _game_config: GameConfig
var _offers: Dictionary = {}
var _jank_combinations: Array = []
var _jank_combo_index: Dictionary = {}
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _event_bus: Node
var _review_generator: Node
var _triggered_thresholds: Dictionary = {}
var _pending_dilemma: Dictionary = {}
var _pending_draft_offer: Dictionary = {}
var _all_card_ids: PackedStringArray = PackedStringArray()
var _card_metadata_cache: Dictionary = {}
var _threshold_events: Array[Dictionary] = []
var _cycle_mgr: CycleStateManager
var _offer_sched: OfferScheduler
# Transient: which run was just completed via ship_it(). Used by UI post-ship dialogs.
var _last_completed_run: int = 0

func _ready() -> void:
	_rng.randomize()
	_event_bus = GameEvents
	_review_generator = ReviewService
	_cycle_mgr = CycleStateManager.new()
	_offer_sched = OfferScheduler.new(_rng)
	_load_game_config()
	_cycle_mgr.load_from_disk()
	current_run = _cycle_mgr.get_current_run()
	_jank_combinations = JankResolver.load_combinations()
	_index_jank_combinations()
	_rebuild_all_card_ids()
	_cycle_mgr.ensure_initial_card_unlock_state(
		_all_card_ids, Callable(self, "_get_card_tier"), _game_config.initial_card_unlock_count
	)
	_load_threshold_events()
	_load_offers()
	reset_run()

func reset_run() -> void:
	ambition = 0
	instability = 0
	runway_days = 21
	soul = _game_config.soul_start
	feature_board.clear()
	_triggered_thresholds.clear()
	chosen_archetype = ""
	current_run = _cycle_mgr.get_current_run()
	_offer_sched.reset()
	_emit_state()

func get_game_config() -> GameConfig:
	return _game_config

func get_cycle_state() -> Dictionary:
	return _cycle_mgr.get_cycle_state()

func get_run_summary(run_number: int) -> Dictionary:
	return _cycle_mgr.get_run_summary(run_number)

func get_cycle_jank_card_ids() -> PackedStringArray:
	return _cycle_mgr.get_jank_card_ids()

func get_last_completed_run() -> int:
	return _last_completed_run

func get_dynamic_card_templates() -> Array[Resource]:
	var templates: Array[Resource] = []
	for card_id in _jank_combo_index.keys():
		var card: FeatureCard = _build_virtual_jank_card(String(card_id))
		if card != null:
			templates.append(card)
	return templates

func get_run_identity() -> String:
	return ""

func is_cycle_complete() -> bool:
	return _cycle_mgr.is_cycle_complete()

func start_new_cycle() -> void:
	_cycle_mgr.reset_cycle()
	# Re-seed common cards so the new cycle always starts with a playable deck.
	_cycle_mgr.ensure_initial_card_unlock_state(
		_all_card_ids, Callable(self, "_get_card_tier"), _game_config.initial_card_unlock_count
	)
	current_run = 1
	reset_run()

func save_cycle_state() -> void:
	_cycle_mgr.save()

## Returns true when a card is placeable. Alien cards (no archetype_affinity) are blocked
## below the soul gate when an archetype has been chosen.
func can_place_card(card: FeatureCard) -> bool:
	if card == null:
		return false
	if not chosen_archetype.is_empty() and card.archetype_affinity.is_empty():
		return soul >= _game_config.alien_card_soul_gate
	return true

func set_archetype(archetype: String) -> void:
	chosen_archetype = archetype
	if _event_bus != null:
		_event_bus.archetype_chosen.emit(archetype)

func get_chosen_archetype() -> String:
	return chosen_archetype

## Tier availability is gated by current run number in the three-run cycle.
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

	# Archetype mismatch applied after base stats.
	_apply_archetype_mismatch(placed_card)

	soul = maxi(soul, 0)
	spend_day("add_feature")
	if _event_bus != null:
		_event_bus.feature_added.emit(placed_card)

func fix_bugs() -> void:
	if runway_days <= 0:
		return
	instability = max(instability - _game_config.fix_bugs_instability_reduction, 0)
	ambition = max(ambition - _game_config.fix_bugs_ambition_penalty, 0)
	soul = max(soul - _game_config.fix_bugs_soul_cost, 0)
	spend_day("fix_bugs")

func do_dev_log() -> void:
	if runway_days <= 0:
		return
	soul += _game_config.dev_log_soul_gain
	spend_day("dev_log")

func spend_day(reason: String) -> void:
	runway_days = max(runway_days - 1, 0)
	if _event_bus != null:
		_event_bus.day_spent.emit(DaySpentPayload.build(reason, runway_days))
	var popup_offered: bool = _maybe_offer_dilemma()
	if not popup_offered:
		popup_offered = _maybe_offer_draft()
	if runway_days == 0:
		if _event_bus != null:
			_event_bus.runway_depleted.emit(RunwayDepletedPayload.build(runway_days))
	_emit_state()

func ship_it() -> Dictionary:
	var completed_run: int = current_run
	var features_shipped: int = feature_board.size()

	var ship_window: Dictionary = ScoreCalculator.compute_ship_window(_game_config, runway_days, instability)
	var dg_eligible: bool = EndingResolver.is_defining_game_eligible(
		_game_config, ambition, instability, soul, chosen_archetype, current_run
	)
	var review_score: float = ScoreCalculator.calculate_final_score(
		_game_config, ambition, instability, soul, features_shipped, ship_window, dg_eligible
	)
	var jank_status: String = ScoreCalculator.compute_jank_status(_game_config, instability, review_score)
	var reviews: Array[Dictionary] = []
	if _review_generator != null:
		reviews = _review_generator.generate_reviews(
			review_score, instability, soul, features_shipped, feature_board,
			"", String(ship_window.get("label", ""))
		)

	# Post-ship jank combination detection.
	var jank_match: Dictionary = JankResolver.find_combination(feature_board, chosen_archetype, _jank_combinations)
	var has_jank_combination: bool = not jank_match.is_empty()

	var ending: String = EndingResolver.resolve_ending_description(
		_game_config, ambition, instability, soul, chosen_archetype, has_jank_combination
	)
	# Nothing shipped = unrateable. Override all outcomes regardless of stats.
	if features_shipped == 0:
		review_score = 0.1
		jank_status = "broken"
		ending = EndingResolver.description_for_label("Shipped Something")

	# Unlock cards for next run in this cycle.
	var unlocked: PackedStringArray = _cycle_mgr.get_unlocked_card_ids()
	var unlock_result: Dictionary = CardUnlockResolver.resolve_unlock(
		_all_card_ids, unlocked, ending, current_run,
		_card_metadata_cache, _rng, Callable(self, "_load_card_by_id"),
		_game_config, ambition, instability, soul, chosen_archetype
	)
	# Enrich with display name so UI never renders raw file IDs.
	var _unlocked_card_id: String = String(unlock_result.get("card_id", ""))
	if not _unlocked_card_id.is_empty():
		var _unlocked_card: FeatureCard = _load_card_by_id(_unlocked_card_id)
		unlock_result["card_name"] = _unlocked_card.feature_name if _unlocked_card != null else _unlocked_card_id.replace("_", " ").capitalize()
	var _bonus_card_id: String = String(unlock_result.get("bonus_card_id", ""))
	if not _bonus_card_id.is_empty():
		var _bonus_card: FeatureCard = _load_card_by_id(_bonus_card_id)
		unlock_result["bonus_card_name"] = _bonus_card.feature_name if _bonus_card != null else _bonus_card_id.replace("_", " ").capitalize()
	var new_unlocked: PackedStringArray = PackedStringArray(unlock_result.get("new_unlocked_ids", unlocked))

	# Record jank card from combination discovery into cycle state.
	var jank_card_id: String = String(jank_match.get("jank_card_id", ""))
	if not jank_card_id.is_empty():
		if not new_unlocked.has(jank_card_id):
			new_unlocked.append(jank_card_id)
		_cycle_mgr.add_jank_card(jank_card_id)

	var cycle_summary: Dictionary = {
		"run": completed_run,
		"ending": ending,
		"ambition": ambition,
		"instability": instability,
		"soul": soul,
		"archetype": chosen_archetype,
		"features_shipped": features_shipped,
		"jank_combination": jank_match.duplicate(true),
		"ship_window": ship_window.duplicate(true),
		"card_unlock": unlock_result.duplicate(true),
	}

	# Advance cycle state — saves immediately to disk.
	_last_completed_run = _cycle_mgr.complete_run(ending, new_unlocked, cycle_summary)
	current_run = _cycle_mgr.get_current_run()

	var result: ShipResult = ShipResult.new()
	result.review_score = review_score
	result.ending = ending
	result.jank_status = jank_status
	result.ship_window = ship_window
	result.card_unlock = unlock_result
	result.features_shipped = features_shipped
	result.reviews = reviews
	result.jank_combination = jank_match
	result.unlock_defining_game = EndingResolver.normalize_ending_name(ending) == "defining game"
	result.completed_run = completed_run

	if _event_bus != null:
		_event_bus.reviews_generated.emit(ReviewsGeneratedPayload.from_dictionary(result.to_dictionary()))
	return result.to_dictionary()

func apply_dilemma_choice(choice_index: int) -> void:
	if _pending_dilemma.is_empty():
		return
	var choices: Array = _pending_dilemma.get("choices", [])
	if choices.is_empty():
		_pending_dilemma.clear()
		return
	var selected: Dictionary = choices[clampi(choice_index, 0, choices.size() - 1)]
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
	var selected: Dictionary = picks[clampi(pick_index, 0, picks.size() - 1)]
	_apply_threshold_effects(selected.get("effects", {}))
	_emit_threshold_event(
		"draft_pick",
		"Draft pick accepted: %s" % String(selected.get("title", "Unknown pitch")),
		selected.get("effects", {})
	)
	_pending_draft_offer.clear()
	_emit_state()

func calculate_predicted_score() -> float:
	var ship_window: Dictionary = ScoreCalculator.compute_ship_window(_game_config, runway_days, instability)
	return ScoreCalculator.calculate_final_score(
		_game_config, ambition, instability, soul, feature_board.size(), ship_window
	)

func get_unlocked_card_ids() -> PackedStringArray:
	return _cycle_mgr.get_unlocked_card_ids()

func get_all_card_ids() -> PackedStringArray:
	return _all_card_ids.duplicate()

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
	if card == null or chosen_archetype.is_empty():
		return 0
	var count: int = card.archetype_affinity.size()
	if count >= 3:
		return 0
	if count > 0 and card.archetype_affinity.has(chosen_archetype):
		return 0
	match count:
		0: return 3
		1: return 2
		2: return 1
	return 0

func _apply_archetype_mismatch(card: FeatureCard) -> void:
	if chosen_archetype.is_empty():
		return
	var count: int = card.archetype_affinity.size()
	# Universal cards (cover all 3 archetypes) never clash.
	if count >= 3:
		return
	# On-archetype card — no penalty.
	if count > 0 and card.archetype_affinity.has(chosen_archetype):
		return
	var genre_label: String = chosen_archetype.capitalize().replace("_", "-")
	if count == 0:
		# Alien card — should be blocked by can_place_card(), but guard defensively.
		if soul < _game_config.alien_card_soul_gate:
			return
		instability += _game_config.alien_card_instability_bonus
		ambition += _game_config.alien_card_ambition_bonus
		soul = max(soul - _game_config.alien_card_soul_penalty, 0)
		_emit_threshold_event(
			"archetype_alien",
			"%s in a %s — this card belongs to another universe entirely. +%d Instability, +%d Ambition, -%d Soul" % [
				card.feature_name, genre_label,
				_game_config.alien_card_instability_bonus,
				_game_config.alien_card_ambition_bonus,
				_game_config.alien_card_soul_penalty,
			],
			{"instability": _game_config.alien_card_instability_bonus,
			 "ambition": _game_config.alien_card_ambition_bonus,
			 "soul": -_game_config.alien_card_soul_penalty},
			"warning"
		)
		return
	if count == 2:
		# Genre stretch — adjacent genre, small dissonance.
		instability += _game_config.genre_stretch_instability_bonus
		_emit_threshold_event(
			"archetype_genre_stretch",
			"%s in a %s — familiar territory, slightly off-brief. +%d Instability" % [
				card.feature_name, genre_label,
				_game_config.genre_stretch_instability_bonus,
			],
			{"instability": _game_config.genre_stretch_instability_bonus},
			"info"
		)
		return
	# count == 1: wild swing — specialized card, wrong genre.
	instability += _game_config.archetype_mismatch_instability_bonus
	ambition += _game_config.archetype_mismatch_ambition_bonus
	soul = max(soul - _game_config.archetype_mismatch_soul_penalty, 0)
	_emit_threshold_event(
		"archetype_mismatch",
		"%s in a %s — the team is confused but intrigued. +%d Instability, +%d Ambition, -%d Soul" % [
			card.feature_name, genre_label,
			_game_config.archetype_mismatch_instability_bonus,
			_game_config.archetype_mismatch_ambition_bonus,
			_game_config.archetype_mismatch_soul_penalty,
		],
		{"instability": _game_config.archetype_mismatch_instability_bonus,
		 "ambition": _game_config.archetype_mismatch_ambition_bonus,
		 "soul": -_game_config.archetype_mismatch_soul_penalty},
		"warning"
	)

func _build_interaction_events(_new_card: FeatureCard) -> Array[Dictionary]:
	return []  # Interaction system removed; kept as stub to avoid build breaks.

func _load_game_config() -> void:
	_game_config = load(GAME_CONFIG_PATH) as GameConfig
	if _game_config == null:
		push_warning("GameConfig not found at %s — falling back to defaults" % GAME_CONFIG_PATH)
		_game_config = GameConfig.new()
	_try_apply_game_config_override()

func _try_apply_game_config_override() -> void:
	for path in GAME_CONFIG_OVERRIDE_PATHS:
		if not FileAccess.file_exists(path):
			continue
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		if file == null:
			push_warning("game_config_override: cannot open '%s'" % path)
			continue
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if parsed is not Dictionary:
			push_warning("game_config_override: '%s' is not a valid JSON object — skipped" % path)
			continue
		# Duplicate so we never mutate the engine-cached .tres resource.
		_game_config = _game_config.duplicate() as GameConfig
		_apply_game_config_override(parsed as Dictionary, path)
		return  # First valid file wins; user:// only checked if data/ not present.

func _apply_game_config_override(data: Dictionary, source_path: String) -> void:
	# Build a map of all script-defined exported properties.
	var prop_map: Dictionary = {}
	for prop in _game_config.get_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			prop_map[prop.name] = prop

	# Full-replacement: zero all overridable properties so any key absent from
	# the JSON is explicit 0/[] rather than inheriting a .tres value.
	for prop_name: String in prop_map:
		var t: int = int((prop_map[prop_name] as Dictionary).get("type", TYPE_NIL))
		match t:
			TYPE_INT:   _game_config.set(prop_name, 0)
			TYPE_FLOAT: _game_config.set(prop_name, 0.0)
			TYPE_ARRAY: _game_config.set(prop_name, [])

	# Apply values from JSON with safe type coercion.
	var applied: int = 0
	var unknown: PackedStringArray = PackedStringArray()
	for key: String in data:
		if key.begins_with("__"):
			continue  # __ prefix = informational comment key; skip silently.
		if not prop_map.has(key):
			unknown.append(key)
			continue
		var raw: Variant = data[key]
		var prop_type: int = int((prop_map[key] as Dictionary).get("type", TYPE_NIL))
		match prop_type:
			TYPE_INT:
				_game_config.set(key, int(raw))
				applied += 1
			TYPE_FLOAT:
				_game_config.set(key, float(raw))
				applied += 1
			TYPE_ARRAY:
				var typed: Array[int] = []
				if raw is Array:
					for v: Variant in (raw as Array):
						typed.append(int(v))
				_game_config.set(key, typed)
				applied += 1
			_:
				_game_config.set(key, raw)
				applied += 1
	print("[GameConfig] Override applied from '%s': %d/%d parameters set." % [source_path, applied, prop_map.size()])
	if not unknown.is_empty():
		push_warning("[GameConfig] Override: unrecognized keys (ignored): %s" % ", ".join(unknown))

func _load_offers() -> void:
	_offers = JsonDataLoader.load_dictionary(OFFERS_PATH, "Offers")

func _load_threshold_events() -> void:
	var parse_result: Array = JsonDataLoader.load_array(THRESHOLD_EVENTS_PATH, "Threshold events")
	var loaded_events: Array[Dictionary] = []
	for event_entry in parse_result:
		if event_entry is Dictionary:
			loaded_events.append(event_entry)
	_threshold_events = loaded_events

func _emit_state() -> void:
	_evaluate_threshold_events()
	if _event_bus != null:
		var snapshot: StateSnapshotPayload = StateSnapshotPayload.new()
		snapshot.ambition = ambition
		snapshot.instability = instability
		snapshot.runway_days = runway_days
		snapshot.soul = soul
		snapshot.features_shipped = feature_board.size()
		snapshot.current_run = current_run
		_event_bus.state_changed.emit(snapshot)

func _update_run_identity() -> void:
	pass  # Style buckets removed; identity is derived from endings only.

func _maybe_offer_dilemma() -> bool:
	var result: Dictionary = _offer_sched.maybe_offer_dilemma(
		_game_config, _offers, runway_days, soul,
		current_run,
		_cycle_mgr.get_pressure_modifier()
	)
	if result.is_empty():
		return false
	_pending_dilemma = result
	if _event_bus != null:
		_event_bus.dilemma_offered.emit(DilemmaOfferPayload.from_dictionary(_pending_dilemma))
	return true

func _maybe_offer_draft() -> bool:
	var result: Dictionary = _offer_sched.maybe_offer_draft(
		_game_config, _offers, runway_days, soul, feature_board.is_empty(),
		current_run,
		_cycle_mgr.get_pressure_modifier()
	)
	if result.is_empty():
		return false
	_pending_draft_offer = result
	if _event_bus != null:
		_event_bus.draft_offer.emit(DraftOfferPayload.from_dictionary(_pending_draft_offer))
	return true

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
		# Threshold events must never move runway days.
		if threshold_effects.has("runway_days"):
			threshold_effects.erase("runway_days")
		_apply_threshold_effects(threshold_effects)
		_emit_threshold_event(
			event_id,
			String(threshold_event.get("message", "Threshold event triggered.")),
			threshold_effects,
			String(threshold_event.get("severity", "info"))
		)

func _emit_threshold_event(
	event_id: String,
	message: String,
	effects: Variant,
	severity: String = "info",
) -> void:
	if _event_bus == null:
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
	if comparison == "lte":
		return _get_metric_value(metric_name) <= threshold_value
	return _get_metric_value(metric_name) >= threshold_value

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
	ambition += int(effects.get("ambition", 0))
	instability += int(effects.get("instability", 0))
	runway_days += int(effects.get("runway_days", 0))
	soul += int(effects.get("soul", 0))
	ambition = max(ambition, 0)
	instability = max(instability, 0)
	runway_days = max(runway_days, 0)
	soul = max(soul, 0)

func _rebuild_all_card_ids() -> void:
	_all_card_ids.clear()
	_card_metadata_cache.clear()
	_append_card_ids_from_directory(CARDS_PATH)
	_append_card_ids_from_directory(CUSTOM_CARDS_PATH)
	_append_jank_card_ids()
	_all_card_ids.sort()
	_populate_card_metadata_cache()

func _append_jank_card_ids() -> void:
	for combo in _jank_combinations:
		if combo is not Dictionary:
			continue
		var card_id: String = String((combo as Dictionary).get("jank_card_id", ""))
		if not card_id.is_empty() and not _all_card_ids.has(card_id):
			_all_card_ids.append(card_id)

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
	for card_id in _all_card_ids:
		var card: FeatureCard = _load_card_by_id(card_id)
		if card == null:
			continue
		_card_metadata_cache[card_id] = {
			"tier": String(card.tier).to_lower(),
			"unlock_weight": float(card.unlock_weight),
		}

func _get_card_tier(card_id: String) -> String:
	if _card_metadata_cache.has(card_id):
		return String(_card_metadata_cache[card_id].get("tier", "common"))
	return "common"

func _load_card_by_id(card_id: String) -> FeatureCard:
	var card_path: String = "%s/%s.tres" % [CARDS_PATH, card_id]
	if ResourceLoader.exists(card_path):
		var card: FeatureCard = load(card_path) as FeatureCard
		if card != null:
			return card
	card_path = "%s/%s.tres" % [CUSTOM_CARDS_PATH, card_id]
	if ResourceLoader.exists(card_path):
		var card: FeatureCard = load(card_path) as FeatureCard
		if card != null:
			return card
	return _build_virtual_jank_card(card_id)

func _index_jank_combinations() -> void:
	_jank_combo_index.clear()
	for combo in _jank_combinations:
		if combo is not Dictionary:
			continue
		var combo_dict: Dictionary = combo as Dictionary
		var card_id: String = String(combo_dict.get("jank_card_id", ""))
		if not card_id.is_empty():
			_jank_combo_index[card_id] = combo_dict.duplicate(true)

func _build_virtual_jank_card(card_id: String) -> FeatureCard:
	if not _jank_combo_index.has(card_id):
		return null
	var combo: Dictionary = _jank_combo_index.get(card_id, {})
	var archetype: String = String(combo.get("archetype", "")).to_lower()
	var card: FeatureCard = FeatureCard.new()
	card.resource_name = card_id
	card.feature_name = String(combo.get("name", card_id.replace("_", " ").capitalize()))
	card.tier = "jank"
	card.unlock_weight = 2.5
	match archetype:
		"rpg":
			card.ambition_value = 5
			card.instability_value = 4
		"shooter":
			card.ambition_value = 4
			card.instability_value = 6
		_:
			card.ambition_value = 5
			card.instability_value = 5
	var tags: PackedStringArray = PackedStringArray(["jank", "legacy"])
	if not archetype.is_empty():
		tags.append(archetype)
		card.archetype_affinity = PackedStringArray([archetype])
	card.tags = tags
	card.interactions = {}
	card.interaction_flavor = {}
	return card
