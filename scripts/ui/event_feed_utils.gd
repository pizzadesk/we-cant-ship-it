static func push_event_message(lines: PackedStringArray, message: String, max_lines: int, max_line_len: int = 132) -> PackedStringArray:
	var updated: PackedStringArray = PackedStringArray(lines)
	var normalized: String = message.strip_edges().replace("\n", " ")
	if normalized.is_empty():
		return updated
	if normalized.length() > max_line_len:
		normalized = "%s..." % normalized.substr(0, max_line_len - 3)
	updated.append(normalized)
	while updated.size() > max_lines:
		updated.remove_at(0)
	return updated

static func build_feed_text(lines: PackedStringArray) -> String:
	var rendered: PackedStringArray = PackedStringArray()
	for entry in lines:
		rendered.append("* %s" % entry)
	return "\n".join(rendered)
