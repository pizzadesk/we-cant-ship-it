extends RefCounted
class_name AppContentRepository

const CARDS_PATH: String = "res://data/cards"
const CUSTOM_CARDS_PATH: String = "res://data/custom_cards"
const GAME_CONFIG_PATH: String = "res://data/game_config.tres"
const JANK_COMBINATIONS_PATH: String = "res://data/jank_combinations.json"
const OFFERS_PATH: String = "res://data/offers.json"
const THRESHOLD_EVENTS_PATH: String = "res://data/threshold_events.json"

var _game_config_override_paths: Array[String] = [
	"res://data/game_config_override.json",
	"user://game_config_override.json",
]

var _game_config: GameConfig = null
var _offers: Dictionary = {}
var _threshold_events: Array[Dictionary] = []
var _jank_combinations: Array = []
var _jank_combo_index: Dictionary = {}
var _all_card_ids: PackedStringArray = PackedStringArray()
var _card_metadata_cache: Dictionary = {}

func initialize() -> void:
	_load_game_config()
	_jank_combinations = JankResolver.load_combinations()
	_index_jank_combinations()
	_rebuild_all_card_ids()
	_load_threshold_events()
	_load_offers()

func get_game_config() -> GameConfig:
	return _game_config

func get_offers() -> Dictionary:
	return _offers

func get_threshold_events() -> Array[Dictionary]:
	return _threshold_events.duplicate(true)

func get_jank_combinations() -> Array:
	return _jank_combinations

func get_all_card_ids() -> PackedStringArray:
	return _all_card_ids.duplicate()

func get_card_metadata_cache() -> Dictionary:
	return _card_metadata_cache

func get_dynamic_card_templates() -> Array[Resource]:
	var templates: Array[Resource] = []
	for card_id in _jank_combo_index.keys():
		var card: FeatureCard = build_virtual_jank_card(String(card_id))
		if card != null:
			templates.append(card)
	return templates

func get_card_tier(card_id: String) -> String:
	if _card_metadata_cache.has(card_id):
		return String(_card_metadata_cache[card_id].get("tier", "common"))
	return "common"

func load_card_by_id(card_id: String) -> FeatureCard:
	var card_path: String = "%s/%s.tres" % [CARDS_PATH, card_id]
	if ResourceLoader.exists(card_path):
		var card: FeatureCard = load(card_path) as FeatureCard
		if card != null:
			return card
	card_path = "%s/%s.tres" % [CUSTOM_CARDS_PATH, card_id]
	if ResourceLoader.exists(card_path):
		var custom_card: FeatureCard = load(card_path) as FeatureCard
		if custom_card != null:
			return custom_card
	return build_virtual_jank_card(card_id)

func build_virtual_jank_card(card_id: String) -> FeatureCard:
	if not _jank_combo_index.has(card_id):
		return null
	var combo: Dictionary = _jank_combo_index.get(card_id, {})
	var archetype: String = String(combo.get("archetype", "")).to_lower()
	var card: FeatureCard = FeatureCard.new()
	card.resource_name = card_id
	card.feature_name = String(combo.get("name", card_id.replace("_", " ").capitalize()))
	card.tier = "jank"
	card.unlock_weight = 2.5
	match archetype:
		"rpg":
			card.ambition_value = 5
			card.instability_value = 4
		"shooter":
			card.ambition_value = 4
			card.instability_value = 6
		_:
			card.ambition_value = 5
			card.instability_value = 5
	var tags: PackedStringArray = PackedStringArray(["jank", "legacy"])
	if not archetype.is_empty():
		tags.append(archetype)
		card.archetype_affinity = PackedStringArray([archetype])
	card.tags = tags
	card.interactions = {}
	card.interaction_flavor = {}
	return card

func _load_game_config() -> void:
	_game_config = load(GAME_CONFIG_PATH) as GameConfig
	if _game_config == null:
		push_warning("GameConfig not found at %s — falling back to defaults" % GAME_CONFIG_PATH)
		_game_config = GameConfig.new()
	_try_apply_game_config_override()

func _try_apply_game_config_override() -> void:
	for path in _game_config_override_paths:
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
		_game_config = _game_config.duplicate() as GameConfig
		_apply_game_config_override(parsed as Dictionary, path)
		return

func _apply_game_config_override(data: Dictionary, source_path: String) -> void:
	var prop_map: Dictionary = {}
	for prop in _game_config.get_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			prop_map[prop.name] = prop

	var applied: int = 0
	var unknown: PackedStringArray = PackedStringArray()
	for key: String in data:
		if key.begins_with("__"):
			continue
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
					for value: Variant in (raw as Array):
						typed.append(int(value))
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

func _load_threshold_events() -> void:
	var parse_result: Array = JsonDataLoader.load_array(THRESHOLD_EVENTS_PATH, "Threshold events")
	var loaded_events: Array[Dictionary] = []
	for event_entry in parse_result:
		if event_entry is Dictionary:
			loaded_events.append(event_entry)
	_threshold_events = loaded_events

func _rebuild_all_card_ids() -> void:
	_all_card_ids.clear()
	_card_metadata_cache.clear()
	_append_card_ids_from_directory(CARDS_PATH)
	_append_card_ids_from_directory(CUSTOM_CARDS_PATH)
	_append_jank_card_ids()
	_all_card_ids.sort()
	_populate_card_metadata_cache()

func _append_jank_card_ids() -> void:
	for combo in _jank_combinations:
		if combo is not Dictionary:
			continue
		var card_id: String = String((combo as Dictionary).get("jank_card_id", ""))
		if not card_id.is_empty() and not _all_card_ids.has(card_id):
			_all_card_ids.append(card_id)

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
		var card: FeatureCard = load_card_by_id(card_id)
		if card == null:
			continue
		_card_metadata_cache[card_id] = {
			"tier": String(card.tier).to_lower(),
			"unlock_weight": float(card.unlock_weight),
		}

func _index_jank_combinations() -> void:
	_jank_combo_index.clear()
	for combo in _jank_combinations:
		if combo is not Dictionary:
			continue
		var combo_dict: Dictionary = combo as Dictionary
		var card_id: String = String(combo_dict.get("jank_card_id", ""))
		if not card_id.is_empty():
			_jank_combo_index[card_id] = combo_dict.duplicate(true)