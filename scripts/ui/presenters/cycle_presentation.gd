const _S = preload("res://scripts/ui/ui_strings.gd")

static func build_cycle_legacy_text(cycle_state: Dictionary) -> String:
	var lines: PackedStringArray = PackedStringArray()
	var rule: String = "[color=#1a3d1a]" + "\u2500".repeat(42) + "[/color]"

	lines.append(_S.get_string("popups", "cycle_legacy_arc_header") + "\n")

	var ending_colors: Dictionary = {
		"defining game": "66dd66",
		"legendary jank": "ff8c42",
		"surprise hit": "66cccc",
		"prestige collapse": "cc5de8",
		"shipped something": "6db06d",
	}

	var any_defining: bool = false
	var first_run: bool = true
	for run_num in [1, 2, 3, 4]:
		if not first_run:
			lines.append(rule)
		first_run = false
		var ending: String = String(cycle_state.get("run_%d_ending" % run_num, ""))
		var raw_summary: Variant = cycle_state.get("run_%d_summary" % run_num, {})
		var summary: Dictionary = raw_summary if raw_summary is Dictionary else {}
		var label: String = _S.get_string("popups", "cycle_legacy_run_header") % run_num
		var normalized: String = String(summary.get("ending_id", EndingResolver.normalize_ending_id(ending)))
		var color: String = String(ending_colors.get(normalized, "ffffff"))
		var ending_display: String = _extract_ending_label(ending)
		lines.append("%s  [color=#%s]%s[/color]" % [label, color, ending_display if not ending_display.is_empty() else "—"])
		var raw_jank_combination: Variant = summary.get("jank_combination", {})
		var jank_combination: Dictionary = raw_jank_combination if raw_jank_combination is Dictionary else {}
		if not jank_combination.is_empty():
			lines.append("  Jank discovered: [color=#ff922b]%s[/color]" % String(jank_combination.get("name", "Unknown Jank")))
			lines.append("  %s" % String(jank_combination.get("description", "")))
		var raw_unfulfilled: Variant = summary.get("unfulfilled_prospect", {})
		var unfulfilled: Dictionary = raw_unfulfilled if raw_unfulfilled is Dictionary else {}
		var unfulfilled_name: String = String(unfulfilled.get("name", ""))
		if not unfulfilled_name.is_empty() and jank_combination.is_empty():
			lines.append("  [color=#3a6a3a]Almost locked: %s[/color]" % unfulfilled_name)
		if normalized == EndingResolver.DEFINING_GAME_ID:
			any_defining = true
		lines.append("")

	if any_defining:
		lines.append(_S.get_string("popups", "cycle_legacy_goldilocks_reached"))
	else:
		lines.append(_S.get_string("popups", "cycle_legacy_goldilocks_missed"))
		lines.append(_S.get_string("popups", "cycle_legacy_reset_note"))

	return "\n".join(lines)

static func build_gap_visualizer_text(_results: Dictionary, ambition: int, instability: int, soul: int, archetype: String, config: GameConfig, completed_run: int) -> String:
	if config == null:
		return ""
	return _build_goldilocks_gap_section(ambition, instability, soul, archetype, config, completed_run)

static func build_previously_on_text(run_summary: Dictionary, current_run: int, config: GameConfig) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("[b]RUN %d OF 4[/b]" % current_run)
	if current_run == 2:
		lines.append("[color=#558855]The five-day tutorial sprint is over. The studio found its voice. Now it has to ship on purpose.[/color]")
	else:
		lines.append("[color=#558855]A new sprint begins.[/color]")
	lines.append("")
	if run_summary.is_empty():
		lines.append("[i]The studio remembers the bruises, not the details.[/i]")
		return "\n".join(lines)

	var ending: String = String(run_summary.get("ending", ""))
	var ending_id: String = String(run_summary.get("ending_id", EndingResolver.normalize_ending_id(ending)))
	if not ending.is_empty():
		var last_time_color: String = "66cccc" if ending_id != EndingResolver.PRESTIGE_COLLAPSE_ID else "cc5de8"
		lines.append("Last time: [color=#%s]%s[/color]" % [last_time_color, _extract_ending_label(ending)])
		lines.append("")

	if config != null:
		lines.append(_build_goldilocks_gap_section(
			int(run_summary.get("ambition", 0)),
			int(run_summary.get("instability", 0)),
			int(run_summary.get("soul", 0)),
			String(run_summary.get("archetype", "")),
			config,
			int(run_summary.get("run", maxi(1, current_run - 1)))
		))

	var raw_jank_combination: Variant = run_summary.get("jank_combination", {})
	var jank_combination: Dictionary = raw_jank_combination if raw_jank_combination is Dictionary else {}
	if not jank_combination.is_empty():
		lines.append("")
		lines.append("[b]Discovered jank[/b]")
		var src_a: String = String(jank_combination.get("card_a", ""))
		var src_b: String = String(jank_combination.get("card_b", ""))
		if not src_a.is_empty() and not src_b.is_empty():
			lines.append("%s + %s" % [src_a, src_b])
		lines.append("[color=#ff922b]\u2192 %s[/color]" % String(jank_combination.get("name", "Unknown Combo")))
		lines.append(String(jank_combination.get("description", "")))

	return "\n".join(lines)

static func _extract_ending_label(ending: String) -> String:
	if ending.contains(":"):
		return String(ending.split(":", false, 1)[0]).strip_edges()
	return ending.strip_edges()

static func _build_goldilocks_gap_section(ambition: int, instability: int, soul: int, archetype: String, cfg: GameConfig, current_run: int) -> String:
	const BAR_LEN: int = 14
	var lines: PackedStringArray = PackedStringArray()
	lines.append("[b]GAP VISUALIZER[/b]  [color=#3a6a3a]Run %d[/color]" % current_run)

	var gate_line: String
	if current_run <= 1:
		gate_line = "[color=#558855]DEFINING GAME: LOCKED \u2014 this run was about learning the shape of the chaos.[/color]"
	else:
		var gw: Array[int] = ArchetypeRules.get_goldilocks_window_for_archetype(cfg, archetype)
		var ambition_ok: bool = ambition >= cfg.goldilocks_ambition_min
		var inst_ok: bool = instability >= gw[0] and instability <= gw[1]
		var soul_ok: bool = soul >= cfg.goldilocks_soul_min
		if ambition_ok and inst_ok and soul_ok:
			gate_line = "[color=#66dd66][b]\u2713 DEFINING GAME: ACHIEVED![/b][/color]"
		else:
			gate_line = "[color=#ffd43b]DEFINING GAME: NOT QUITE THERE YET[/color]"
	lines.append(gate_line)
	lines.append("")

	var amb_ratio: float = clampf(float(ambition) / float(cfg.goldilocks_ambition_min), 0.0, 1.0)
	var amb_bar_color: String
	var amb_label: String
	if ambition >= cfg.goldilocks_ambition_min:
		amb_bar_color = "66dd66"
		amb_label = "[color=#66dd66]\u2713[/color]"
	elif amb_ratio >= 0.80:
		amb_bar_color = "ffd43b"
		amb_label = "[color=#ffd43b]close[/color]"
	else:
		amb_bar_color = "ff922b"
		amb_label = "[color=#ff922b]needs more[/color]"
	lines.append("AMBITION    %s  %s" % [_gap_bar_colored(amb_ratio, BAR_LEN, amb_bar_color), amb_label])

	var window: Array[int] = ArchetypeRules.get_goldilocks_window_for_archetype(cfg, archetype)
	var inst_ratio: float
	var inst_bar_color: String
	var inst_label: String
	if instability < window[0]:
		inst_ratio = clampf(float(instability) / float(window[0]), 0.0, 1.0)
		if inst_ratio >= 0.70:
			inst_bar_color = "ffd43b"
			inst_label = "[color=#ffd43b]close[/color]"
		else:
			inst_bar_color = "ff922b"
			inst_label = "[color=#ff922b]too low[/color]"
	elif instability > window[1]:
		inst_ratio = 1.0
		inst_bar_color = "ff6b6b"
		inst_label = "[color=#ff6b6b]too high[/color]"
	else:
		inst_ratio = 1.0
		inst_bar_color = "66dd66"
		inst_label = "[color=#66dd66]\u2713[/color]"
	lines.append("INSTABILITY %s  %s" % [_gap_bar_colored(inst_ratio, BAR_LEN, inst_bar_color), inst_label])

	var soul_ratio: float = clampf(float(soul) / float(cfg.goldilocks_soul_min), 0.0, 1.0)
	var soul_bar_color: String
	var soul_label: String
	if soul >= cfg.goldilocks_soul_min:
		soul_bar_color = "66dd66"
		soul_label = "[color=#66dd66]\u2713[/color]"
	elif soul_ratio >= 0.80:
		soul_bar_color = "ffd43b"
		soul_label = "[color=#ffd43b]close[/color]"
	else:
		soul_bar_color = "ff922b"
		soul_label = "[color=#ff922b]needs more[/color]"
	lines.append("SOUL        %s  %s" % [_gap_bar_colored(soul_ratio, BAR_LEN, soul_bar_color), soul_label])
	return "\n".join(lines)

static func _gap_bar_colored(ratio: float, length: int, bar_color: String) -> String:
	var filled: int = clampi(int(round(ratio * float(length))), 0, length)
	var empty: int = length - filled
	var result: String = ""
	if filled > 0:
		result += "[color=#%s]%s[/color]" % [bar_color, "\u2588".repeat(filled)]
	if empty > 0:
		result += "[color=#1a3d1a]%s[/color]" % "\u2591".repeat(empty)
	return result
