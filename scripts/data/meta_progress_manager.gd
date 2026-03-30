extends RefCounted
class_name MetaProgressManager

## Owns the meta persistence dictionary, save/load, save-migration,
## studio tier computation, milestone tracking, and reputation accounting.
## Instantiated by AppState as an internal collaborator — NOT an autoload.

const META_SAVE_PATH: String = "user://meta_progress.json"

var _meta: Dictionary = {
	"runs_played": 0,
	"best_review_score": 0.0,
	"last_release_score": 0.0,
	"studio_tier": 1,
	"reputation_total": 0,
	"runs_since_milestone": 0,
	"milestone_history": [],
	"defining_game_unlocked": false,
	"unlocked_card_ids": PackedStringArray(),
	"publisher_trust_mode_enabled": false,
	"publisher_profile_trust": 0,
	"active_legacy": {},
	"pending_legacy": {},
}

# --- Public read accessors ---

func get_meta_dict() -> Dictionary:
	return _meta.duplicate(true)

func get_value(key: String, default: Variant = null) -> Variant:
	return _meta.get(key, default)

func set_value(key: String, value: Variant) -> void:
	_meta[key] = value

func get_unlocked_card_ids() -> PackedStringArray:
	return PackedStringArray(_meta.get("unlocked_card_ids", PackedStringArray()))

func is_publisher_trust_mode_enabled() -> bool:
	return bool(_meta.get("publisher_trust_mode_enabled", false))

func set_publisher_trust_mode_enabled(enabled: bool) -> void:
	_meta["publisher_trust_mode_enabled"] = enabled
	save()

func get_active_legacy() -> Dictionary:
	var d: Variant = _meta.get("active_legacy", {})
	return d if d is Dictionary else {}

func get_pending_legacy() -> Dictionary:
	var d: Variant = _meta.get("pending_legacy", {})
	return d if d is Dictionary else {}

func resolve_legacy_displacement(keep_current: bool) -> void:
	if keep_current:
		_meta["pending_legacy"] = {}
	else:
		_meta["active_legacy"] = _meta.get("pending_legacy", {})
		_meta["pending_legacy"] = {}
	save()

# --- Studio tier ---

func compute_studio_tier(config: GameConfig) -> int:
	var reputation_total: int = int(_meta.get("reputation_total", 0))
	var defining_unlocked: bool = bool(_meta.get("defining_game_unlocked", false))
	if defining_unlocked and reputation_total >= config.studio_tier_4_reputation_min:
		return 4
	if reputation_total >= config.studio_tier_3_reputation_min:
		return 3
	if reputation_total >= config.studio_tier_2_reputation_min:
		return 2
	return 1

# --- Reputation ---

static func reputation_for_ending(config: GameConfig, ending: String) -> int:
	var normalized: String = EndingResolver.normalize_ending_name(ending)
	match normalized:
		"defining game":
			return config.reputation_defining_game
		"legendary jank":
			return config.reputation_legendary_jank
		"surprise hit":
			return config.reputation_surprise_hit
		"cult classic":
			return config.reputation_cult_classic
		"rough diamond":
			return config.reputation_rough_diamond
		"prestige collapse":
			return config.reputation_prestige_collapse
		"cult disaster":
			return config.reputation_cult_disaster
		"financial catastrophe":
			return config.reputation_financial_catastrophe
		_:
			return 0

# --- Progress update + milestone ---

## Returns a MilestonePayload dictionary if a milestone was triggered, else empty.
func update_progress(config: GameConfig, review_score: float, ending: String) -> Dictionary:
	_meta["runs_played"] = int(_meta.get("runs_played", 0)) + 1
	_meta["last_release_score"] = review_score
	_meta["best_review_score"] = max(float(_meta.get("best_review_score", 0.0)), review_score)
	_meta["reputation_total"] = int(_meta.get("reputation_total", 0)) + reputation_for_ending(config, ending)
	_meta["runs_since_milestone"] = int(_meta.get("runs_since_milestone", 0)) + 1
	return _maybe_record_milestone(config, ending)

## Returns a MilestonePayload dictionary if a milestone was just triggered, else empty.
func _maybe_record_milestone(config: GameConfig, ending: String) -> Dictionary:
	var runs_since: int = int(_meta.get("runs_since_milestone", 0))
	if runs_since < config.milestone_interval_runs:
		return {}
	_meta["studio_tier"] = compute_studio_tier(config)
	var history: Array = _meta.get("milestone_history", [])
	var entry: Dictionary = {
		"run": int(_meta.get("runs_played", 0)),
		"ending": EndingResolver.normalize_ending_name(ending),
		"studio_tier": int(_meta.get("studio_tier", 1)),
		"reputation_total": int(_meta.get("reputation_total", 0)),
	}
	history.append(entry)
	_meta["milestone_history"] = history
	_meta["runs_since_milestone"] = 0
	return {
		"runs_played": int(_meta.get("runs_played", 0)),
		"studio_tier": int(_meta.get("studio_tier", 1)),
		"reputation_total": int(_meta.get("reputation_total", 0)),
		"ending": EndingResolver.normalize_ending_name(ending),
		"milestone_index": history.size(),
	}

# --- Persistence ---

func load_from_disk() -> void:
	if not FileAccess.file_exists(META_SAVE_PATH):
		return
	var file: FileAccess = FileAccess.open(META_SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		for key in parsed.keys():
			_meta[key] = parsed[key]
		_run_save_migrations()

func save() -> void:
	var file: FileAccess = FileAccess.open(META_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(_meta, "\t"))

func _run_save_migrations() -> void:
	if _meta.get("unlocked_card_ids", null) is Array:
		_meta["unlocked_card_ids"] = PackedStringArray(_meta.get("unlocked_card_ids", []))
	if _meta.get("milestone_history", null) is not Array:
		_meta["milestone_history"] = []
	# gothic_mode_unlocked → defining_game_unlocked
	if _meta.has("gothic_mode_unlocked"):
		if bool(_meta.get("gothic_mode_unlocked", false)):
			_meta["defining_game_unlocked"] = true
		_meta.erase("gothic_mode_unlocked")
	# unlock_tier/legacy_tier → studio reputation model
	if _meta.has("legacy_tier") and not _meta.has("studio_tier"):
		_meta["studio_tier"] = int(_meta.get("legacy_tier", 1))
	if _meta.has("unlock_tier"):
		_meta.erase("unlock_tier")
	if _meta.has("legacy_tier"):
		_meta.erase("legacy_tier")
	if not _meta.has("studio_tier"):
		_meta["studio_tier"] = 1
	if not _meta.has("reputation_total"):
		_meta["reputation_total"] = 0
	if not _meta.has("last_release_score"):
		_meta["last_release_score"] = 0.0
	if not _meta.has("runs_played"):
		_meta["runs_played"] = 0
	if not _meta.has("runs_since_milestone"):
		_meta["runs_since_milestone"] = 0
	if not _meta.has("publisher_trust_mode_enabled"):
		_meta["publisher_trust_mode_enabled"] = false

# --- Card unlock state ---

func ensure_card_unlock_state(config: GameConfig, all_card_ids: PackedStringArray, get_card_tier: Callable) -> void:
	var unlocked: PackedStringArray = PackedStringArray(_meta.get("unlocked_card_ids", PackedStringArray()))
	if unlocked.is_empty():
		var common_ids: PackedStringArray = PackedStringArray()
		for card_id in all_card_ids:
			if get_card_tier.call(card_id) == "common":
				common_ids.append(card_id)
		var seed_count: int = mini(config.initial_card_unlock_count, common_ids.size())
		for idx in range(seed_count):
			unlocked.append(common_ids[idx])
		_meta["unlocked_card_ids"] = unlocked
		save()
		return

	var filtered: PackedStringArray = PackedStringArray()
	for card_id in unlocked:
		if all_card_ids.has(card_id) and not filtered.has(card_id):
			filtered.append(card_id)
	if filtered.size() < config.initial_card_unlock_count:
		for card_id in all_card_ids:
			if filtered.size() >= config.initial_card_unlock_count:
				break
			if filtered.has(card_id):
				continue
			if get_card_tier.call(card_id) == "common":
				filtered.append(card_id)
	_meta["unlocked_card_ids"] = filtered

func is_card_unlocked(card_id: String) -> bool:
	if card_id.is_empty():
		return false
	return get_unlocked_card_ids().has(card_id)
