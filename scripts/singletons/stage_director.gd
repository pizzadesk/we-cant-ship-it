extends Node

# StageDirector — resolves the current visual stage from runway_days and emits
# GameEvents.stage_changed when a sprint boundary is crossed.
# Read-only: never modifies AppState.
#
# Stage boundaries (runway days remaining → sprint day interpretation):
#   Stage 0  VSCode  runway 15–21  (sprint days  1–7)   clean dark IDE aesthetic
#   Stage 1  Agile   runway 10–14  (sprint days  8–12)  warming, post-it drift begins
#   Stage 2  Desk    runway  5–9   (sprint days 13–17)  physical desk: corkboard, index cards
#   Stage 3  Fridge  runway  0–4   (sprint days 18–21)  deadline: post-its, magnets, marker font

const STAGE_THEMES_PATH: String = "res://data/stage_themes/"
const STAGE_FILES: Array[String] = [
	"stage_1_vscode.tres",
	"stage_2_agile.tres",
	"stage_3_desk.tres",
	"stage_4_fridge.tres",
]

# Minimum runway_days required to be in each stage (checked in order; first match wins).
const STAGE_MIN_RUNWAY: Array[int] = [15, 10, 5, 0]

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
	# Load thresholds from GameConfig for centralized tuning
	var thresholds: Array[int] = config.stage_threshold_runways
	# Walk thresholds in descending order; return index of first threshold met.
	for i: int in range(thresholds.size()):
		if runway_days >= thresholds[i]:
			return i
	return thresholds.size() - 1

func _on_state_changed(snapshot: StateSnapshotPayload) -> void:
	var config: GameConfig = AppState.get_game_config()
	var new_index: int = _stage_index_for_runway(snapshot.runway_days, config)
	if new_index == _current_stage_index:
		return
	_current_stage_index = new_index
	GameEvents.stage_changed.emit(get_current_theme())
