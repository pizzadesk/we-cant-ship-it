extends RefCounted
class_name CardUnlockResolver

const ArchetypeRules = preload("res://scripts/data/services/archetype_rules.gd")

## Pure card-unlock logic extracted from AppState.
## GDD rule: Run 1 completion unlocks 1–2 uncommon cards.
##            Run 2 completion unlocks 1–2 rare cards.
##            Run 3 completion can still unlock 1–2 rare cards for the final attempt.
##            Near-miss unlock logic: gap delta direction weights which specific card unlocks.
## Jank cards are handled separately in AppState.ship_it via JankResolver.

static func resolve_unlock(
	all_card_ids: PackedStringArray,
	current_unlocked: PackedStringArray,
	ending_id: String,
	current_run: int,
	card_metadata_cache: Dictionary,
	rng: RandomNumberGenerator,
	load_card_func: Callable,
	config: GameConfig,
	ambition: int,
	instability: int,
	soul: int,
	archetype: String,
) -> Dictionary:
	if current_run >= 4:
		return {}
	var locked_ids: PackedStringArray = PackedStringArray()
	for card_id in all_card_ids:
		if not current_unlocked.has(card_id):
			locked_ids.append(card_id)
	if locked_ids.is_empty():
		return {}

	# Tier preference by run number.
	var preferred_tier: String = "common"
	match current_run:
		1: preferred_tier = "uncommon"
		2: preferred_tier = "rare"
		3: preferred_tier = "rare"
		_: preferred_tier = "rare"

	var unlocked: PackedStringArray = current_unlocked.duplicate()
	var picked_ids: PackedStringArray = PackedStringArray()
	var unlock_count: int = 2 if _should_grant_bonus_unlock(config, ambition, instability, soul, archetype, ending_id) else 1
	for _slot in range(unlock_count):
		var remaining_locked: PackedStringArray = PackedStringArray()
		for card_id in all_card_ids:
			if not unlocked.has(card_id):
				remaining_locked.append(card_id)
		if remaining_locked.is_empty():
			break
		var picked_id: String = _pick_weighted_unlock(
			remaining_locked,
			card_metadata_cache,
			rng,
			preferred_tier,
			load_card_func,
			config,
			ambition,
			instability,
			soul,
			archetype,
		)
		if picked_id.is_empty():
			break
		unlocked.append(picked_id)
		picked_ids.append(picked_id)

	if picked_ids.is_empty():
		return {}

	var primary_id: String = String(picked_ids[0])
	var bonus_card_id: String = String(picked_ids[1]) if picked_ids.size() > 1 else ""

	return {
		"card_id": primary_id,
		"bonus_card_id": bonus_card_id,
		"tier": _get_tier(primary_id, card_metadata_cache),
		"remaining_locked": maxi(0, all_card_ids.size() - unlocked.size()),
		"new_unlocked_ids": unlocked,
	}

static func _get_tier(card_id: String, cache: Dictionary) -> String:
	if cache.has(card_id):
		return String(cache[card_id].get("tier", "common"))
	return "common"

static func _pick_locked_card_by_tier(
	locked_ids: PackedStringArray,
	cache: Dictionary,
	rng: RandomNumberGenerator,
	tier: String,
) -> String:
	var candidates: PackedStringArray = PackedStringArray()
	for card_id in locked_ids:
		if _get_tier(card_id, cache) == tier:
			candidates.append(card_id)
	if candidates.is_empty():
		return ""
	return String(candidates[rng.randi_range(0, candidates.size() - 1)])

static func _pick_weighted_unlock(
	locked_ids: PackedStringArray,
	cache: Dictionary,
	rng: RandomNumberGenerator,
	tier: String,
	load_card_func: Callable,
	config: GameConfig,
	ambition: int,
	instability: int,
	soul: int,
	archetype: String,
) -> String:
	var preferred_candidates: PackedStringArray = PackedStringArray()
	for card_id in locked_ids:
		if _get_tier(card_id, cache) == tier:
			preferred_candidates.append(card_id)
	var pool: PackedStringArray = preferred_candidates if not preferred_candidates.is_empty() else locked_ids
	var best_score: float = -INF
	var best_ids: PackedStringArray = PackedStringArray()
	for card_id in pool:
		var score: float = _score_unlock_candidate(card_id, cache, load_card_func, config, ambition, instability, soul, archetype)
		if score > best_score:
			best_score = score
			best_ids.clear()
			best_ids.append(card_id)
		elif is_equal_approx(score, best_score):
			best_ids.append(card_id)
	if best_ids.is_empty():
		return ""
	return String(best_ids[rng.randi_range(0, best_ids.size() - 1)])

static func _score_unlock_candidate(
	card_id: String,
	cache: Dictionary,
	load_card_func: Callable,
	config: GameConfig,
	ambition: int,
	instability: int,
	_soul: int,
	archetype: String,
) -> float:
	var score: float = float(cache.get(card_id, {}).get("unlock_weight", 1.0))
	var card: FeatureCard = load_card_func.call(card_id) as FeatureCard
	if card == null or config == null:
		return score

	if card.tier == "jank":
		score += 1.5

	if ambition < config.goldilocks_ambition_min:
		score += float(maxi(card.ambition_value, 0)) * 2.0
	else:
		score += float(maxi(0, 6 - abs(card.ambition_value - 4))) * 0.25

	var window: Array[int] = ArchetypeRules.get_goldilocks_window_for_archetype(config, archetype)
	if instability < window[0]:
		score += float(maxi(card.instability_value, 0)) * 2.0
	elif instability > window[1]:
		score += float(maxi(0, 8 - card.instability_value)) * 1.8
	else:
		score += float(maxi(0, 6 - abs(card.instability_value - 4))) * 0.35

	if not archetype.is_empty() and not card.archetype_affinity.is_empty() and card.archetype_affinity.has(archetype):
		score += 1.0
	return score

static func _should_grant_bonus_unlock(config: GameConfig, ambition: int, instability: int, soul: int, archetype: String, ending_id: String) -> bool:
	if EndingResolver.normalize_ending_id(ending_id) == EndingResolver.DEFINING_GAME_ID:
		return true
	if config == null:
		return false
	var ambition_delta: int = maxi(0, config.goldilocks_ambition_min - ambition)
	var soul_delta: int = maxi(0, config.goldilocks_soul_min - soul)
	var window: Array[int] = ArchetypeRules.get_goldilocks_window_for_archetype(config, archetype)
	var instability_delta: int = 0
	if instability < window[0]:
		instability_delta = window[0] - instability
	elif instability > window[1]:
		instability_delta = instability - window[1]
	return ambition_delta <= 6 or soul_delta <= 2 or instability_delta <= 6
