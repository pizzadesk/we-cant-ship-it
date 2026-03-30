extends RefCounted
class_name JsonDataLoader

static func load_dictionary(path: String, file_label: String) -> Dictionary:
	var parsed: Variant = _load_json(path, file_label)
	if parsed is Dictionary:
		return parsed
	if parsed != null:
		push_warning("%s JSON is not a dictionary" % file_label)
	return {}

static func load_array(path: String, file_label: String) -> Array:
	var parsed: Variant = _load_json(path, file_label)
	if parsed is Array:
		return parsed
	if parsed != null:
		push_warning("%s JSON is not an array" % file_label)
	return []

static func _load_json(path: String, file_label: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_warning("Missing %s at %s" % [file_label, path])
		return null

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Unable to open %s at %s" % [file_label, path])
		return null

	return JSON.parse_string(file.get_as_text())
