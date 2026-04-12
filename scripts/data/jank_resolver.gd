extends RefCounted
class_name JankResolver

## Post-ship combinatorial jank detection.
## Formula: Card A + Card B + Archetype = Jank Card
##
## Evaluates the shipped board against jank_combinations.json and returns
## the first matching combination, if any.
##
## Usage (called from AppState.ship_it):
##   var result = JankResolver.find_combination(feature_board, chosen_archetype, combinations)

const JANK_COMBINATIONS_PATH: String = "res://data/jank_combinations.json"

## Loads combination rules from disk. Call once and cache the result.
static func load_combinations() -> Array:
	var data: Variant = JSON.parse_string(_read_file(JANK_COMBINATIONS_PATH))
	if data is Array:
		return data as Array
	if data is Dictionary:
		var d: Dictionary = data as Dictionary
		if d.has("combinations") and d["combinations"] is Array:
			return d["combinations"] as Array
	push_warning("JankResolver: could not load jank_combinations.json")
	return []

## Evaluates the board against loaded combination rules.
## Returns a Dictionary with match info, or {} if no match.
##   { "jank_card_id", "name", "description", "archetype", "card_a", "card_b" }
static func find_combination(
	board: Array[FeatureCard],
	archetype: String,
	combinations: Array,
) -> Dictionary:
	var board_ids: PackedStringArray = _collect_board_ids(board)
	var arch_key: String = _normalize_id(archetype)

	for raw in combinations:
		if raw is not Dictionary:
			continue
		var combo: Dictionary = raw as Dictionary
		if not _matches_archetype(combo, arch_key):
			continue
		var card_a: String = _normalize_id(String(combo.get("card_a", "")))
		var card_b: String = _normalize_id(String(combo.get("card_b", "")))
		if card_a.is_empty() or card_b.is_empty():
			continue
		if board_ids.has(card_a) and board_ids.has(card_b):
			return combo.duplicate(true)

	return {}

static func find_prospect(
	board: Array[FeatureCard],
	archetype: String,
	latest_card: FeatureCard,
	combinations: Array,
) -> Dictionary:
	if latest_card == null:
		return {}
	var board_ids: PackedStringArray = _collect_board_ids(board)
	var latest_id: String = _normalize_id(latest_card.feature_name)
	var arch_key: String = _normalize_id(archetype)

	for raw in combinations:
		if raw is not Dictionary:
			continue
		var combo: Dictionary = raw as Dictionary
		if not _matches_archetype(combo, arch_key):
			continue
		var card_a: String = _normalize_id(String(combo.get("card_a", "")))
		var card_b: String = _normalize_id(String(combo.get("card_b", "")))
		if card_a.is_empty() or card_b.is_empty():
			continue
		if latest_id != card_a and latest_id != card_b:
			continue
		var has_a: bool = board_ids.has(card_a)
		var has_b: bool = board_ids.has(card_b)
		if has_a == has_b:
			continue
		return combo.duplicate(true)

	return {}

static func _collect_board_ids(board: Array[FeatureCard]) -> PackedStringArray:
	var board_ids: PackedStringArray = PackedStringArray()
	for card in board:
		if card is FeatureCard:
			board_ids.append(_normalize_id(String((card as FeatureCard).feature_name)))
	return board_ids

static func _matches_archetype(combo: Dictionary, arch_key: String) -> bool:
	var required_arch: String = _normalize_id(String(combo.get("archetype", "")))
	return required_arch.is_empty() or required_arch == arch_key

static func _normalize_id(raw: String) -> String:
	return raw.to_lower().strip_edges().replace(" ", "_").replace("-", "_")

static func _read_file(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	return f.get_as_text()
