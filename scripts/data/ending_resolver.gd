extends RefCounted
class_name EndingResolver

const _S = preload("res://scripts/ui/ui_strings.gd")

## Returns the full description string for a known ending label (e.g. "Prestige Collapse").
static func description_for_label(label: String) -> String:
	var key: String = "ending_desc_" + label.to_lower().replace(" ", "_")
	var desc: String = _S.get_string("popups", key)
	if desc.is_empty():
		return _S.get_string("popups", "ending_desc_shipped_something")
	return desc

static func resolve_ending_description(config: GameConfig, ambition: int, instability: int, soul: int, archetype: String, has_jank_combination: bool) -> String:
	var label: String = resolve_ending_label(config, ambition, instability, soul, archetype, has_jank_combination)
	return description_for_label(label)

## Five endings in priority order:
## 1. Defining Game  — conditions met (ambition, per-archetype instability window, soul)
## 2. Legendary Jank — instability ≥ 55 AND a jank combination was found on the board
## 3. Surprise Hit   — soul ≥ 8, ambition in 15–24 (Goldilocks not met)
## 4. Prestige Collapse — ambition ≥ 25, soul ≤ 4
## 5. Shipped... something — everything else
static func resolve_ending_label(config: GameConfig, ambition: int, instability: int, soul: int, archetype: String, has_jank_combination: bool) -> String:
	if config == null:
		return "Shipped... something"

	var window: Array[int] = _get_goldilocks_window(config, archetype)
	var active_run: int = 1
	if AppState != null:
		active_run = int(AppState.current_run)

	# Priority 1: Defining Game conditions
	if active_run >= 2 and ambition >= config.goldilocks_ambition_min and instability >= window[0] and instability <= window[1] and soul >= config.goldilocks_soul_min:
		return "Defining Game. Congratulations!"  # (full description is in the popup, this is just the label)

	# Priority 2: Legendary Jank
	if instability >= config.legendary_jank_instability_min and has_jank_combination:
		return "Legendary Jank"

	# Priority 3: Surprise Hit
	if soul >= config.surprise_hit_soul_min and ambition >= config.surprise_hit_ambition_min and ambition <= config.surprise_hit_ambition_max:
		return "Surprise Hit"

	# Priority 4: Prestige Collapse
	if ambition >= config.prestige_collapse_ambition_min and soul <= config.prestige_collapse_soul_max:
		return "Prestige Collapse"

	# Priority 5: fallback
	return "Shipped... something"

## Returns [instability_min, instability_max] for the Goldilocks window of the given archetype.
## Falls back to Action-Adventure window for unknown archetypes.
static func _get_goldilocks_window(config: GameConfig, archetype: String) -> Array[int]:
	match archetype.to_lower().replace(" ", "_").replace("-", "_"):
		"rpg":
			return [config.goldilocks_instability_min_rpg, config.goldilocks_instability_max_rpg]
		"shooter":
			return [config.goldilocks_instability_min_shooter, config.goldilocks_instability_max_shooter]
		_:
			return [config.goldilocks_instability_min_action_adventure, config.goldilocks_instability_max_action_adventure]

## Returns [min, max] instability window for an archetype key.
## Used by the gap visualizer to show the target range.
static func get_goldilocks_window_for_archetype(config: GameConfig, archetype: String) -> Array[int]:
	return _get_goldilocks_window(config, archetype)

## Returns true if Defining Game conditions are all met right now.
## Used pre-ship to decide whether to suppress timing penalties.
static func is_defining_game_eligible(config: GameConfig, ambition: int, instability: int, soul: int, archetype: String, run: int) -> bool:
	if config == null or run < 2:
		return false
	var window: Array[int] = _get_goldilocks_window(config, archetype)
	return ambition >= config.goldilocks_ambition_min \
		and instability >= window[0] and instability <= window[1] \
		and soul >= config.goldilocks_soul_min

static func normalize_ending_name(ending: String) -> String:
	if ending.contains(":"):
		return String(ending.split(":", false, 1)[0]).strip_edges().to_lower()
	return ending.strip_edges().to_lower()
