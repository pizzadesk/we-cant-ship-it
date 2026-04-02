extends Node

const INTERACTION_RULES_PATH: String = "res://data/interaction_rules.json"
const THRESHOLD_EVENTS_PATH: String = "res://data/threshold_events.json"
const OFFERS_PATH: String = "res://data/offers.json"
const CARDS_PATH: String = "res://data/cards"
const CUSTOM_CARDS_PATH: String = "res://data/custom_cards"
const GAME_CONFIG_PATH: String = "res://data/game_config.tres"
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
	_rebuild_all_card_ids()
	_cycle_mgr.ensure_initial_card_unlock_state(
		_all_card_ids, Callable(self, "_get_card_tier"), _game_config.initial_card_unlock_count
	)
	_load_interaction_rules()
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
	_style_points = {"cult_jank": 0, "prestige_collapse": 0, "community_darling": 0}
	_current_identity = "Unformed"
	chosen_archetype = ""
	current_run = _cycle_mgr.get_current_run()
	_offer_sched.reset()
	_publisher_trust_mode_enabled_run = _cycle_mgr.is_publisher_trust_mode_enabled()
	if _publisher_trust_mode_enabled_run:
		_publisher_trust_run = _cycle_mgr.get_publisher_trust()
	else:
		_publisher_trust_run = 0
	_emit_state()

func get_game_config() -> GameConfig:
	return _game_config

func get_dominant_style_bucket() -> String:
	return _get_dominant_style_bucket()

func get_cycle_state() -> Dictionary:
	return _cycle_mgr.get_cycle_state()

func get_last_completed_run() -> int:
	return _last_completed_run

func get_run_identity() -> String:
	return _current_identity

func get_style_points() -> Dictionary:
	return _style_points.duplicate(true)

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

func is_publisher_trust_mode_enabled() -> bool:
	return _cycle_mgr.is_publisher_trust_mode_enabled()

func set_publisher_trust_mode_enabled(enabled: bool) -> void:
	_cycle_mgr.set_publisher_trust_mode_enabled(enabled)

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

## Tier availability is gated by current run number in the three-run cycle.
func is_tier_available(tier: String) -> bool:
	match tier.to_lower():
		"common":
			return true
		"uncommon":
			return current_run >= 2
		"rare":
			return current_run >= 3
		_:
			return true

## Returns interaction heat level for pre-placement hint display.
## 0 = no interaction, 1 = low (delta 1-4), 2 = medium (5-9), 3 = high (10+).
func get_interaction_heat(card: FeatureCard, board: Array[FeatureCard]) -> int:
	if card == null:
		return 0
	var total_delta: int = 0
	for existing in board:
		if existing == null:
			continue
		for new_tag in card.tags:
			for existing_tag in existing.tags:
				var rule: Dictionary = _get_rule(String(new_tag), String(existing_tag))
				if _is_rule_blocked_by_soul(rule):
					continue
				if String(new_tag) == String(existing_tag):
					total_delta += 2
				total_delta += abs(int(rule.get("instability_delta", 0)))
				total_delta += abs(int(rule.get("soul_delta", 0)))
	if total_delta == 0:
		return 0
	if total_delta < 5:
		return 1
	if total_delta < 10:
		return 2
	return 3

func add_feature_card(card: Resource) -> void:
	if card == null or runway_days <= 0:
		return
	if card is not FeatureCard:
		return
	var placed_card: FeatureCard = card as FeatureCard

	if not can_place_card(placed_card):
		push_warning("add_feature_card: placement blocked by soul gate for alien card")
		return

	var interaction_events: Array[Dictionary] = _build_interaction_events(placed_card)
	feature_board.append(placed_card)
	ambition += placed_card.ambition_value
	instability += placed_card.instability_value

	# Style points: prestige accumulates only when ambition outpaces soul.
	if placed_card.ambition_value > soul:
		_style_points["prestige_collapse"] += max(placed_card.ambition_value, 0)
	else:
		_style_points["community_darling"] += 1

	_style_points["cult_jank"] += max(placed_card.instability_value, 0)

	# Community darling bonus for narrative/character/world/lore/quest tags.
	var darling_tags: PackedStringArray = PackedStringArray(["lore", "quest", "narrative", "character", "world"])
	for tag in darling_tags:
		if placed_card.tags.has(tag):
			_style_points["community_darling"] += 3
			break

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

	# Archetype mismatch resolved after interaction events.
	_apply_archetype_mismatch(placed_card)

	soul = clampi(soul, 0, _game_config.soul_max)
	_update_run_identity()
	spend_day("add_feature")
	if _event_bus != null:
		_event_bus.feature_added.emit(placed_card)
	# Note: spend_day() already calls _emit_state(); a second call here would
	# double-fire threshold evaluation and send redundant state_changed events.

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
	soul = mini(soul + _game_config.dev_log_soul_gain, _game_config.soul_max)
	_style_points["community_darling"] += 4
	spend_day("dev_log")

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

	var ship_window: Dictionary = ScoreCalculator.compute_ship_window(_game_config, runway_days, instability)
	var review_score: float = ScoreCalculator.calculate_final_score(
		_game_config, ambition, instability, soul, features_shipped, ship_window
	)
	var jank_status: String = ScoreCalculator.compute_jank_status(_game_config, instability, review_score)
	var meeting_quality: float = _offer_sched.average_meeting_quality()
	var ship_window_quality: float = ScoreCalculator.ship_window_quality(String(ship_window.get("label", "")))
	var reviews: Array[Dictionary] = []
	var mechanics_highlights: Array[String] = []
	if _review_generator != null:
		reviews = _review_generator.generate_reviews(
			review_score, instability, soul, features_shipped, feature_board,
			_current_identity, String(ship_window.get("label", ""))
		)
		mechanics_highlights = _review_generator.generate_mechanics_highlights(feature_board)

	var ending: String = EndingResolver.resolve_ending_description(
		_game_config, ambition, instability, soul, review_score, _get_dominant_style_bucket()
	)
	# Nothing shipped = unrateable. Override all outcomes regardless of stats.
	if features_shipped == 0:
		review_score = 0.1
		jank_status = "broken"
		ending = _S.get_string("popups", "ending_desc_financial_catastrophe")

	# Unlock cards for next run in this cycle.
	var unlocked: PackedStringArray = _cycle_mgr.get_unlocked_card_ids()
	var unlock_result: Dictionary = CardUnlockResolver.resolve_unlock(
		_all_card_ids, unlocked, ending, jank_status,
		meeting_quality, ship_window_quality,
		_card_metadata_cache, _rng, Callable(self, "_load_card_by_id")
	)
	# Enrich with display name so UI never renders raw file IDs.
	var _unlocked_card_id: String = String(unlock_result.get("card_id", ""))
	if not _unlocked_card_id.is_empty():
		var _unlocked_card: FeatureCard = _load_card_by_id(_unlocked_card_id)
		unlock_result["card_name"] = _unlocked_card.feature_name if _unlocked_card != null else _unlocked_card_id.replace("_", " ").capitalize()
	var new_unlocked: PackedStringArray = PackedStringArray(unlock_result.get("new_unlocked_ids", unlocked))

	# Advance cycle state — saves immediately to disk.
	_last_completed_run = _cycle_mgr.complete_run(ending, new_unlocked)
	current_run = _cycle_mgr.get_current_run()

	var result: ShipResult = ShipResult.new()
	result.review_score = review_score
	result.ending = ending
	result.jank_status = jank_status
	result.ship_window = ship_window
	result.publisher_meeting_quality = meeting_quality
	result.publisher_trust = _publisher_trust_run
	result.card_unlock = unlock_result
	result.features_shipped = features_shipped
	result.reviews = reviews
	result.mechanics_highlights = mechanics_highlights
	result.run_identity = _current_identity
	result.unlock_defining_game = EndingResolver.normalize_ending_name(ending) == "defining game"

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

func apply_publisher_meeting_choice(choice_index: int) -> void:
	if _pending_publisher_meeting.is_empty():
		return
	var options: Array = _pending_publisher_meeting.get("options", [])
	if options.is_empty():
		_pending_publisher_meeting.clear()
		return
	var selected: Dictionary = options[clampi(choice_index, 0, options.size() - 1)]
	_apply_threshold_effects(selected.get("effects", {}))
	_publisher_trust_run += int(_pending_publisher_meeting.get("grade_trust_delta", 0))
	_publisher_trust_run += int(selected.get("trust_delta", 0))
	_publisher_trust_run = clampi(_publisher_trust_run, -100, 100)
	if _publisher_trust_mode_enabled_run:
		_cycle_mgr.set_publisher_trust(_publisher_trust_run)
	_offer_sched.record_meeting_quality(float(_pending_publisher_meeting.get("grade_quality", 0.5)))
	_emit_threshold_event(
		"publisher_meeting_choice",
		"Publisher meeting stance chosen: %s" % String(selected.get("label", "Unknown")),
		selected.get("effects", {})
	)
	_pending_publisher_meeting.clear()
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
		_style_points["cult_jank"] += _game_config.alien_card_instability_bonus
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
		_style_points["cult_jank"] += _game_config.genre_stretch_instability_bonus
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
	_style_points["cult_jank"] += _game_config.archetype_mismatch_instability_bonus
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

func _build_interaction_events(new_card: FeatureCard) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	for existing_card in feature_board:
		if existing_card == null:
			continue
		for new_tag in new_card.tags:
			for existing_tag in existing_card.tags:
				var maybe_event: Dictionary = _create_event_for_tag_pair(
					new_card, existing_card, String(new_tag), String(existing_tag)
				)
				if not maybe_event.is_empty():
					events.append(maybe_event)
	return events

func _create_event_for_tag_pair(
	new_card: FeatureCard,
	existing_card: FeatureCard,
	new_tag: String,
	existing_tag: String,
) -> Dictionary:
	var has_overlap: bool = new_tag == existing_tag
	var rule: Dictionary = _get_rule(new_tag, existing_tag)
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
		"flavor": flavor,
	}

func _pick_interaction_flavor(
	rule: Dictionary,
	new_card: FeatureCard,
	existing_card: FeatureCard,
	new_tag: String,
	existing_tag: String,
) -> String:
	if new_tag == existing_tag:
		var new_flavor: String = new_card.get_interaction_flavor_for_tag(new_tag)
		if not new_flavor.is_empty():
			return new_flavor
		var existing_flavor: String = existing_card.get_interaction_flavor_for_tag(existing_tag)
		if not existing_flavor.is_empty():
			return existing_flavor
	var flavors: Array = rule.get("flavors", [])
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

func _load_interaction_rules() -> void:
	var interaction_data: Dictionary = JsonDataLoader.load_dictionary(INTERACTION_RULES_PATH, "Interaction rules")
	var rules: Variant = interaction_data.get("rules", [])
	if rules is not Array:
		return
	for rule_entry in rules:
		if rule_entry is Dictionary:
			var tags: Variant = rule_entry.get("tags", [])
			if tags is Array and (tags as Array).size() == 2:
				var key: String = "%s|%s" % [String((tags as Array)[0]), String((tags as Array)[1])]
				_interaction_rules[key] = rule_entry

func _load_threshold_events() -> void:
	var parse_result: Array = JsonDataLoader.load_array(THRESHOLD_EVENTS_PATH, "Threshold events")
	var loaded_events: Array[Dictionary] = []
	for event_entry in parse_result:
		if event_entry is Dictionary:
			loaded_events.append(event_entry)
	_threshold_events = loaded_events

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
		snapshot.current_run = current_run
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
		if _event_bus != null:
			var payload: RunIdentityPayload = RunIdentityPayload.new()
			payload.identity = _current_identity
			payload.style_points = _style_points.duplicate(true)
			_event_bus.run_identity_changed.emit(payload)

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

func _maybe_offer_dilemma() -> bool:
	var result: Dictionary = _offer_sched.maybe_offer_dilemma(
		_game_config, _offers, runway_days, soul,
		_publisher_trust_mode_enabled_run, _publisher_trust_run,
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
		_cycle_mgr.get_pressure_modifier()
	)
	if result.is_empty():
		return false
	_pending_draft_offer = result
	if _event_bus != null:
		_event_bus.draft_offer.emit(DraftOfferPayload.from_dictionary(_pending_draft_offer))
	return true

func _maybe_offer_publisher_meeting() -> bool:
	var result: Dictionary = _offer_sched.maybe_offer_publisher_meeting(
		_game_config, runway_days, instability, soul, feature_board.size(),
		_publisher_trust_mode_enabled_run, _publisher_trust_run,
		_cycle_mgr.get_pressure_modifier()
	)
	if result.is_empty():
		return false
	_pending_publisher_meeting = result
	if _event_bus != null:
		_event_bus.publisher_meeting_offered.emit(
			PublisherMeetingOfferPayload.from_dictionary(_pending_publisher_meeting)
		)
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
	var ambition_delta: int = int(effects.get("ambition", 0))
	var instability_delta: int = int(effects.get("instability", 0))
	var soul_delta: int = int(effects.get("soul", 0))
	ambition += ambition_delta
	instability += instability_delta
	runway_days += int(effects.get("runway_days", 0))
	soul += soul_delta
	# Mirror the card-placement rule: ambition that outpaces current soul → prestige pressure.
	if ambition_delta > 0:
		if ambition_delta > soul:
			_style_points["prestige_collapse"] += ambition_delta
		else:
			_style_points["community_darling"] += 1
	if instability_delta > 0:
		_style_points["cult_jank"] += instability_delta
	if soul_delta > 0:
		_style_points["community_darling"] += soul_delta
	ambition = max(ambition, 0)
	instability = max(instability, 0)
	runway_days = max(runway_days, 0)
	soul = clampi(soul, 0, _game_config.soul_max)

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
	var card: FeatureCard = load(card_path) as FeatureCard
	if card == null:
		card_path = "%s/%s.tres" % [CUSTOM_CARDS_PATH, card_id]
		card = load(card_path) as FeatureCard
	return card
