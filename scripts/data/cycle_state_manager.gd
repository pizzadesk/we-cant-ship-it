extends RefCounted
class_name CycleStateManager

## Owns the three-run cycle state, save/load, and card unlock tracking within a cycle.
## Replaces MetaProgressManager — scoped to a fixed three-run arc, not infinite runs.
## Instantiated by AppState as an internal collaborator — NOT an autoload.

const CYCLE_SAVE_PATH: String = "user://cycle_state.json"

var _cycle: Dictionary = {
	"current_run": 1,
	"run_1_ending": "",
	"run_2_ending": "",
	"run_3_ending": "",
	"run_1_summary": {},
	"run_2_summary": {},
	"run_3_summary": {},
	"pressure_modifier": 1.0,
	"unlocked_card_ids": [],
	"jank_card_ids": [],
	"cycle_complete": false,
}

# --- Read accessors ---

func get_current_run() -> int:
	return int(_cycle.get("current_run", 1))

func get_run_ending(run_number: int) -> String:
	return String(_cycle.get("run_%d_ending" % run_number, ""))

func get_run_summary(run_number: int) -> Dictionary:
	var raw: Variant = _cycle.get("run_%d_summary" % run_number, {})
	if raw is Dictionary:
		return (raw as Dictionary).duplicate(true)
	return {}

## Returns the pressure factor for the current run.
## Run 1 → 1.0, Run 2 → 1.3, Run 3 → 1.6.
func get_pressure_modifier() -> float:
	return 1.0 + (0.3 * float(get_current_run() - 1))

func is_cycle_complete() -> bool:
	return bool(_cycle.get("cycle_complete", false))

func get_unlocked_card_ids() -> PackedStringArray:
	return PackedStringArray(_cycle.get("unlocked_card_ids", []))

func get_jank_card_ids() -> PackedStringArray:
	return PackedStringArray(_cycle.get("jank_card_ids", []))

func add_jank_card(jank_card_id: String) -> void:
	if jank_card_id.is_empty():
		return
	var existing: PackedStringArray = get_jank_card_ids()
	if not existing.has(jank_card_id):
		existing.append(jank_card_id)
		_cycle["jank_card_ids"] = Array(existing)
		save()

func get_cycle_state() -> Dictionary:
	return _cycle.duplicate(true)

# --- Run completion ---

## Records the ending, summary, and unlocked cards for the completed run, then advances current_run.
## Returns the run number that was just completed (1, 2, or 3).
## Saves immediately — cycle state is always consistent regardless of when the player quits.
func complete_run(ending: String, unlocked_ids: PackedStringArray, summary: Dictionary = {}) -> int:
	var completed_run: int = get_current_run()
	_cycle["run_%d_ending" % completed_run] = ending
	_cycle["run_%d_summary" % completed_run] = summary.duplicate(true)
	_cycle["unlocked_card_ids"] = Array(unlocked_ids)
	if completed_run >= 3:
		_cycle["cycle_complete"] = true
	else:
		_cycle["current_run"] = completed_run + 1
		_cycle["pressure_modifier"] = get_pressure_modifier()
	save()
	return completed_run

## Reset the cycle entirely — wipes all run history and starts fresh from run 1.
func reset_cycle() -> void:
	_cycle = {
		"current_run": 1,
		"run_1_ending": "",
		"run_2_ending": "",
		"run_3_ending": "",
		"run_1_summary": {},
		"run_2_summary": {},
		"run_3_summary": {},
		"pressure_modifier": 1.0,
		"unlocked_card_ids": [],
		"jank_card_ids": [],
		"cycle_complete": false,
	}
	save()

# --- Card unlock state ---

## Seeds unlocked_card_ids with common cards if empty; filters invalid ids if populated.
func ensure_initial_card_unlock_state(
	all_card_ids: PackedStringArray,
	get_card_tier: Callable,
	initial_count: int,
) -> void:
	var unlocked: PackedStringArray = get_unlocked_card_ids()
	if not unlocked.is_empty():
		var filtered: PackedStringArray = PackedStringArray()
		for card_id in unlocked:
			if all_card_ids.has(card_id) and not filtered.has(card_id):
				filtered.append(card_id)
		_cycle["unlocked_card_ids"] = Array(filtered)
		return

	var common_ids: PackedStringArray = PackedStringArray()
	for card_id in all_card_ids:
		if get_card_tier.call(card_id) == "common":
			common_ids.append(card_id)
	var seed_count: int = mini(initial_count, common_ids.size())
	var seeded: Array = []
	for idx in range(seed_count):
		seeded.append(common_ids[idx])
	_cycle["unlocked_card_ids"] = seeded
	save()

func set_unlocked_card_ids(ids: PackedStringArray) -> void:
	_cycle["unlocked_card_ids"] = Array(ids)

# --- Persistence ---

func load_from_disk() -> void:
	if not FileAccess.file_exists(CYCLE_SAVE_PATH):
		return
	var file: FileAccess = FileAccess.open(CYCLE_SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		for key in (parsed as Dictionary).keys():
			_cycle[key] = (parsed as Dictionary)[key]

func save() -> void:
	var file: FileAccess = FileAccess.open(CYCLE_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("CycleStateManager: could not open %s for writing" % CYCLE_SAVE_PATH)
		return
	file.store_string(JSON.stringify(_cycle, "\t"))
