class_name LegacyUtils

@warning_ignore("shadowed_global_identifier")
const LegacyRecord = preload("res://scripts/data/legacy_record.gd")

# Static utility: all legacy determination, name generation, tier computation,
# and studio briefing text. No state; no side effects.

const LEGACY_PHRASES_PATH: String = "res://data/legacy_phrases.json"
# Cult Disaster soul threshold moved to GameConfig.legacy_cult_disaster_soul_min (default 40)

# --------------------------------------------------------------------------
# Type determination
# --------------------------------------------------------------------------

# Returns the legacy type string from ship metrics.
# Order matters: cult_disaster and celebrated are checked first so they are
# not shadowed by the looser disaster / regretted checks below them.
static func determine_legacy_type(
	review_score: float,
	soul: int,
	instability: int,
	ambition: int,
	_run_identity: String,
	config: GameConfig = null
) -> String:
	# Default to GameConfig if not provided (for centralized tuning)
	if config == null:
		config = AppState.get_game_config()
	
	# Cult Disaster: broken AND soulful. The studio failed and somehow mattered.
	if instability >= 75 and soul >= config.legacy_cult_disaster_soul_min and review_score < 5.0:
		return "cult_disaster"

	# Celebrated: high score, high soul — the Goldilocks run.
	if review_score >= 7.5 and soul >= 50:
		return "celebrated"

	# Sellout: good score, tiny ambition — technically a win, emotionally hollow.
	if review_score >= 6.5 and ambition < 20:
		return "sellout"

	# Regretted: decent score, low soul — shipped clean, meant nothing.
	if review_score >= 6.0 and soul < 25:
		return "regretted"

	# Notorious: high chaos, still pulled through.
	if instability >= 70 and review_score >= 6.0:
		return "notorious"

	# Financial Catastrophe: plain failure.
	if review_score < 4.0:
		return "disaster"

	# Fallback for mid-range runs that don't qualify for anything distinctive.
	return "regretted"

# --------------------------------------------------------------------------
# Tier calculation
# --------------------------------------------------------------------------

# Computes the new legacy tier after a run.
# - Tier ratchets up based on total runs and milestone scores.
# - Financial Catastrophe (review_score < 4.0) drops tier by 1, floor 1.
# - Tier is never computed below 1 or above 3.
static func compute_tier(current_tier: int, runs_played: int, best_score_ever: float, this_run_score: float) -> int:
	var tier: int = current_tier

	# Upward progression: milestone thresholds.
	if runs_played >= 6 and best_score_ever >= 8.0:
		tier = max(tier, 3)
	elif runs_played >= 3 and best_score_ever >= 6.5:
		tier = max(tier, 2)
	elif runs_played >= 1:
		tier = max(tier, 1)

	# Downward pressure: catastrophic runs knock one tier back. Floor is always 1.
	if this_run_score < 4.0 and tier > 1:
		tier -= 1

	return clampi(tier, 1, 3)

# --------------------------------------------------------------------------
# Name generation
# --------------------------------------------------------------------------

static func generate_legacy_name(legacy_type: String, rng: RandomNumberGenerator) -> String:
	var phrases: Dictionary = _load_phrases()
	var templates: Dictionary = phrases.get("templates", {})
	var pool: Array = templates.get(legacy_type, [])
	if pool.is_empty():
		return "games that shipped"
	return String(pool[rng.randi_range(0, pool.size() - 1)])

static func generate_era_label(runs_played: int, rng: RandomNumberGenerator) -> String:
	var phrases: Dictionary = _load_phrases()
	var eras: Array = phrases.get("eras", [])
	if eras.is_empty():
		return "An Undefined Era"
	# Era advances roughly every two runs, with a touch of randomness.
	@warning_ignore("integer_division")
	var era_index: int = clampi((runs_played - 1) / 2 + rng.randi_range(0, 1), 0, eras.size() - 1)
	return String(eras[era_index])

static func _load_phrases() -> Dictionary:
	if not FileAccess.file_exists(LEGACY_PHRASES_PATH):
		push_warning("LegacyUtils: missing %s" % LEGACY_PHRASES_PATH)
		return {}
	var file: FileAccess = FileAccess.open(LEGACY_PHRASES_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

# --------------------------------------------------------------------------
# Briefing text (BBCode for RichTextLabel)
# --------------------------------------------------------------------------

static func build_briefing_text(active: LegacyRecord, pending: LegacyRecord, meta_progress: Dictionary) -> String:
	var lines: PackedStringArray = PackedStringArray()
	var legacy_tier: int = int(meta_progress.get("studio_tier", 1))
	var last_release_score: float = float(meta_progress.get("last_release_score", 0.0))
	var runs_played: int = int(meta_progress.get("runs_played", 0))
	var reputation_total: int = int(meta_progress.get("reputation_total", 0))

	lines.append("[b]Studio Briefing[/b]")
	lines.append("[color=#aaaaaa]Tier %d Studio[/color]" % legacy_tier)
	lines.append("[color=#bbbbbb]Runs Played: %d  ·  Reputation: %d  ·  Last Release Score: %.1f[/color]\n" % [
		runs_played,
		reputation_total,
		last_release_score,
	])

	if active != null and not active.is_empty():
		lines.append("[b]Known for:[/b] [i]%s[/i]" % active.name)
		lines.append("[color=#888888]%s  ·  %s  ·  Score: %.1f[/color]\n" % [
			active.era_label, _type_label(active.type), active.review_score
		])
	else:
		lines.append("[color=#888888]No active legacy selected yet.[/color]\n")

	if pending != null and not pending.is_empty():
		if active == null or active.is_empty():
			lines.append("This run leaves its mark:")
		else:
			lines.append("This run offers a new legacy:")
		lines.append("[b]%s[/b]" % pending.name)
		lines.append("[color=#888888]%s  ·  %s  ·  Score: %.1f[/color]" % [
			pending.era_label, _type_label(pending.type), pending.review_score
		])
	else:
		lines.append("[color=#888888]No pending legacy change for this cycle.[/color]")

	return "\n".join(lines)

static func _type_label(legacy_type: String) -> String:
	match legacy_type:
		"celebrated":    return "Celebrated"
		"notorious":     return "Notorious"
		"regretted":     return "Regretted"
		"disaster":      return "Disaster"
		"sellout":       return "Sellout"
		"cult_disaster": return "Cult Disaster"
		_:               return legacy_type.capitalize()
