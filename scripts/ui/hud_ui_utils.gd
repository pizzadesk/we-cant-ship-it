const _S = preload("res://scripts/ui/ui_strings.gd")

static func update_action_tooltips(fix_bugs_button: Button, dev_log_button: Button, ship_button: Button, runway_days: int, instability: int, soul: int = 0) -> void:
	if runway_days <= 0:
		fix_bugs_button.tooltip_text = _S.get_string("tooltips", "fix_bugs_depleted")
		dev_log_button.tooltip_text = _S.get_string("tooltips", "dev_log_depleted")
	elif soul <= 6:
		# GDD: tooltip shifts at Soul ≤ 6 to signal exhaustion without explaining the trap.
		fix_bugs_button.tooltip_text = _S.get_string("tooltips", "fix_bugs_exhausted")
		dev_log_button.tooltip_text = _S.get_string("tooltips", "dev_log_active")
	else:
		fix_bugs_button.tooltip_text = _S.get_string("tooltips", "fix_bugs_active")
		dev_log_button.tooltip_text = _S.get_string("tooltips", "dev_log_active")

	if instability >= 70:
		ship_button.tooltip_text = _S.get_string("tooltips", "ship_overloaded")
	elif instability <= 25:
		ship_button.tooltip_text = _S.get_string("tooltips", "ship_underloaded")
	else:
		ship_button.tooltip_text = _S.get_string("tooltips", "ship_default")

