class_name UiStrings

# Lazy-loading string registry for all player-facing UI text.
# Each category maps to one file under data/strings/.
# Files are loaded on first access per category and cached for the session.
# Usage: UiStrings.get_string("popups", "ship_summary_title")

const _PATHS: Dictionary = {
	"buttons":      "res://data/strings/buttons.json",
	"card_ui":      "res://data/strings/card_ui.json",
	"help":         "res://data/strings/help.json",
	"log_messages": "res://data/strings/log_messages.json",
	"popups":       "res://data/strings/popups.json",
	"publisher":    "res://data/strings/publisher.json",
	"tooltips":     "res://data/strings/tooltips.json",
}

static var _cache: Dictionary = {}

# Returns the string for a key. If the key is missing, logs a warning and returns
# `fallback` (or the key name itself when no fallback is given).
static func get_string(category: String, key: String, fallback: String = "") -> String:
	_ensure_loaded(category)
	var cat: Dictionary = _cache.get(category, {})
	var value: Variant = cat.get(key, null)
	if value == null:
		push_warning("UiStrings: missing key '%s' in category '%s'" % [key, category])
		return fallback if not fallback.is_empty() else key
	return String(value)

# Returns a nested Dictionary value. Used for publisher sub-tables (topics, grades…).
static func get_dict(category: String, key: String) -> Dictionary:
	_ensure_loaded(category)
	var cat: Dictionary = _cache.get(category, {})
	var value: Variant = cat.get(key, null)
	if value is Dictionary:
		return value
	return {}

# Returns an Array value. Used for help body lines.
static func get_array(category: String, key: String) -> Array:
	_ensure_loaded(category)
	var cat: Dictionary = _cache.get(category, {})
	var value: Variant = cat.get(key, null)
	if value is Array:
		return value
	return []

# Returns true when a key is present in a category — avoids false-positive warnings
# when using optional/derived keys (e.g. roulette_intro_<ending>).
static func has_key(category: String, key: String) -> bool:
	_ensure_loaded(category)
	return _cache.get(category, {}).has(key)

static func _ensure_loaded(category: String) -> void:
	if _cache.has(category):
		return
	var path: String = String(_PATHS.get(category, ""))
	if path.is_empty():
		push_warning("UiStrings: unknown category '%s'" % category)
		_cache[category] = {}
		return
	if not FileAccess.file_exists(path):
		push_warning("UiStrings: missing strings file at %s" % path)
		_cache[category] = {}
		return
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("UiStrings: could not open %s" % path)
		_cache[category] = {}
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	_cache[category] = parsed if parsed is Dictionary else {}
