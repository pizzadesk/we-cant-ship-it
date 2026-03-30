const _S = preload("res://scripts/ui/ui_strings.gd")

static func progress_percent(unlocked_count: int, total_count: int) -> int:
	if total_count <= 0:
		return 0
	return int((float(unlocked_count) / float(total_count)) * 100.0)

static func build_progress_text(unlocked_count: int, total_count: int) -> String:
	if total_count <= 0:
		return _S.get_string("card_ui", "progress_calculating")
	var pct: int = progress_percent(unlocked_count, total_count)
	var text: String = _S.get_string("card_ui", "progress_format") % [unlocked_count, total_count, pct]
	if pct < 50:
		text += _S.get_string("card_ui", "progress_low_suffix")
	elif pct < 100:
		text += _S.get_string("card_ui", "progress_mid_suffix")
	return text
