extends RefCounted
class_name CardUnlockResolver

## Pure card-unlock logic extracted from AppState.
## Determines which card(s) to unlock after a run based on ending,
## jank status, meeting quality, and ship window quality.

static func resolve_unlock(
	all_card_ids: PackedStringArray,
	current_unlocked: PackedStringArray,
	ending: String,
	jank_status: String,
	meeting_quality: float,
	ship_window_quality: float,
	card_metadata_cache: Dictionary,
	rng: RandomNumberGenerator,
	load_card_func: Callable,
) -> Dictionary:
	var locked_ids: PackedStringArray = PackedStringArray()
	for card_id in all_card_ids:
		if not current_unlocked.has(card_id):
			locked_ids.append(card_id)
	if locked_ids.is_empty():
		return {}

	var jank_quality: float = _jank_quality_for_status(jank_status)
	var unlock_quality: float = clampf(
		(0.55 * jank_quality) + (0.30 * meeting_quality) + (0.15 * ship_window_quality),
		0.0, 1.0
	)
	var target_weight: float = lerpf(1.0, 5.0, unlock_quality)

	var picked_id: String = locked_ids[0]
	var best_distance: float = INF
	for card_id in locked_ids:
		var weight: float = _get_unlock_weight(card_id, card_metadata_cache)
		var distance: float = absf(weight - target_weight) + rng.randf_range(0.0, 0.18)
		if distance < best_distance:
			best_distance = distance
			picked_id = card_id

	var unlocked: PackedStringArray = current_unlocked.duplicate()
	unlocked.append(picked_id)

	var normalized_ending: String = EndingResolver.normalize_ending_name(ending)
	var bonus_card_id: String = ""
	if normalized_ending == "defining game":
		bonus_card_id = _pick_locked_legendary_jank_card(all_card_ids, unlocked, card_metadata_cache, rng, load_card_func)
	elif normalized_ending == "cult disaster" or normalized_ending == "financial catastrophe":
		bonus_card_id = _pick_locked_card_by_tier(all_card_ids, unlocked, "common", card_metadata_cache, rng)
	if not bonus_card_id.is_empty() and not unlocked.has(bonus_card_id):
		unlocked.append(bonus_card_id)

	return {
		"card_id": picked_id,
		"bonus_card_id": bonus_card_id,
		"unlock_quality": unlock_quality,
		"unlock_weight": _get_unlock_weight(picked_id, card_metadata_cache),
		"tier": _get_tier(picked_id, card_metadata_cache),
		"status": jank_status,
		"remaining_locked": maxi(0, all_card_ids.size() - unlocked.size()),
		"new_unlocked_ids": unlocked,
	}

static func _jank_quality_for_status(jank_status: String) -> float:
	match jank_status:
		"polished", "broken":
			return 0.20
		"sweet_spot":
			return 0.95
		"volatile":
			return 0.55
		_:
			return 0.55

static func _get_unlock_weight(card_id: String, cache: Dictionary) -> float:
	if cache.has(card_id):
		return float(cache[card_id].get("unlock_weight", 1.0))
	return 1.0

static func _get_tier(card_id: String, cache: Dictionary) -> String:
	if cache.has(card_id):
		return String(cache[card_id].get("tier", "common"))
	return "common"

static func _pick_locked_card_by_tier(
	all_card_ids: PackedStringArray,
	current_unlocked: PackedStringArray,
	tier: String,
	cache: Dictionary,
	rng: RandomNumberGenerator,
) -> String:
	var candidates: PackedStringArray = PackedStringArray()
	for card_id in all_card_ids:
		if current_unlocked.has(card_id):
			continue
		if _get_tier(card_id, cache) == tier:
			candidates.append(card_id)
	if candidates.is_empty():
		return ""
	return String(candidates[rng.randi_range(0, candidates.size() - 1)])

static func _pick_locked_legendary_jank_card(
	all_card_ids: PackedStringArray,
	current_unlocked: PackedStringArray,
	cache: Dictionary,
	rng: RandomNumberGenerator,
	load_card_func: Callable,
) -> String:
	var candidates: PackedStringArray = PackedStringArray()
	var highest_instability: int = -1
	for card_id in all_card_ids:
		if current_unlocked.has(card_id):
			continue
		if _get_tier(card_id, cache) != "rare":
			continue
		var card: FeatureCard = load_card_func.call(card_id) as FeatureCard
		if card == null:
			continue
		if card.instability_value > highest_instability:
			highest_instability = card.instability_value
			candidates.clear()
			candidates.append(card_id)
		elif card.instability_value == highest_instability:
			candidates.append(card_id)

	if candidates.is_empty():
		return _pick_locked_card_by_tier(all_card_ids, current_unlocked, "rare", cache, rng)
	return String(candidates[rng.randi_range(0, candidates.size() - 1)])
