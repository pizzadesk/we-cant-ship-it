extends Node

# StageDirector — resolves the current visual stage from runway_days and emits
# GameEvents.stage_changed when a sprint boundary is crossed.
# Read-only: never modifies AppState.
#
# Stage boundaries are derived from the active run's initial runway.
# Standard runs use the configured 21-day pacing; the 5-day tutorial run is scaled
# down so it still progresses through the same visual arc instead of spawning in panic mode.

const STAGE_THEMES_PATH: String = "res://data/stage_themes/"
const STAGE_FILES: Array[String] = [
	"stage_1_vscode.tres",
	"stage_2_agile.tres",
	"stage_3_desk.tres",
	"stage_4_fridge.tres",
]

var _stage_themes: Array[StageTheme] = []
var _current_stage_index: int = -1  # -1 = uninitialised; no emission until first run

func _ready() -> void:
	_load_stage_themes()
	GameEvents.state_changed.connect(_on_state_changed)

# Returns the StageTheme currently in effect, or null if no run has started yet.
func get_current_theme() -> StageTheme:
	if _current_stage_index < 0 or _current_stage_index >= _stage_themes.size():
		return null
	return _stage_themes[_current_stage_index]

func _load_stage_themes() -> void:
	for file_name: String in STAGE_FILES:
		var path: String = STAGE_THEMES_PATH + file_name
		var theme: StageTheme = load(path) as StageTheme
		if theme == null:
			push_warning("StageDirector: missing StageTheme at %s — substituting empty placeholder" % path)
			_stage_themes.append(StageTheme.new())
		else:
			_stage_themes.append(theme)

func _stage_index_for_runway(runway_days: int, config: GameConfig) -> int:
	var thresholds: Array[int] = _thresholds_for_current_run(config)
	# Walk thresholds in descending order; return index of first threshold met.
	for i: int in range(thresholds.size()):
		if runway_days >= thresholds[i]:
			return i
	return thresholds.size() - 1

func _thresholds_for_current_run(config: GameConfig) -> Array[int]:
	if config == null:
		return [15, 10, 5, 0]
	var initial_runway: int = 21
	if AppState != null and AppState.has_method("get_initial_runway_days"):
		initial_runway = int(AppState.get_initial_runway_days())
	if initial_runway <= 5:
		return [5, 3, 2, 0]
	return config.stage_threshold_runways

func _on_state_changed(snapshot: StateSnapshotPayload) -> void:
	var config: GameConfig = AppState.get_game_config()
	var new_index: int = _stage_index_for_runway(snapshot.runway_days, config)
	if new_index == _current_stage_index:
		return
	_current_stage_index = new_index
	GameEvents.stage_changed.emit(get_current_theme())
