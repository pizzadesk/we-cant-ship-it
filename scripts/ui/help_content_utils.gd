const _S = preload("res://scripts/ui/ui_strings.gd")

static func build_help_text() -> String:
	var lines: Array = _S.get_array("help", "body")
	if lines.is_empty():
		return "[b]Help content not found.[/b]"
	return "\n".join(lines)
