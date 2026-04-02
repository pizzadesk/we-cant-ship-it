extends RefCounted
class_name OfferScheduler

## Manages dilemma, draft, and publisher-meeting offer scheduling.
## Owns per-run scheduling state (cooldowns, offered-day tracking).
## Instantiated by AppState each run — NOT an autoload.

var _last_draft_day_offered: int = -1
var _last_publisher_meeting_day_offered: int = -1
var _dilemma_days_offered: Dictionary = {}
var _publisher_meeting_days_offered: Dictionary = {}
var _popup_offered_on_runway_day: int = -1
var _pending_dilemma: Dictionary = {}
var _pending_draft_offer: Dictionary = {}
var _pending_publisher_meeting: Dictionary = {}
var _meeting_quality_samples: Array[float] = []

var _rng: RandomNumberGenerator

func _init(rng: RandomNumberGenerator) -> void:
	_rng = rng

func reset() -> void:
	_last_draft_day_offered = -1
	_last_publisher_meeting_day_offered = -1
	_dilemma_days_offered.clear()
	_publisher_meeting_days_offered.clear()
	_pending_dilemma.clear()
	_pending_draft_offer.clear()
	_pending_publisher_meeting.clear()
	_meeting_quality_samples.clear()
	_popup_offered_on_runway_day = -1

# --- Getters for pending state (AppState reads these) ---

func get_pending_dilemma() -> Dictionary:
	return _pending_dilemma

func get_pending_draft_offer() -> Dictionary:
	return _pending_draft_offer

func get_pending_publisher_meeting() -> Dictionary:
	return _pending_publisher_meeting

func get_popup_offered_on_runway_day() -> int:
	return _popup_offered_on_runway_day

func clear_pending_dilemma() -> void:
	_pending_dilemma.clear()

func clear_pending_draft_offer() -> void:
	_pending_draft_offer.clear()

func clear_pending_publisher_meeting() -> void:
	_pending_publisher_meeting.clear()

# --- Meeting quality ---

func record_meeting_quality(quality: float) -> void:
	_meeting_quality_samples.append(quality)

func average_meeting_quality() -> float:
	if _meeting_quality_samples.is_empty():
		return 0.50
	var total: float = 0.0
	for q in _meeting_quality_samples:
		total += float(q)
	return clampf(total / float(_meeting_quality_samples.size()), 0.0, 1.0)

# --- Dilemma scheduling ---

func maybe_offer_dilemma(
	config: GameConfig,
	offers: Dictionary,
	runway_days: int,
	_soul: int,
	publisher_trust_mode_enabled: bool,
	publisher_trust: int,
	pressure_modifier: float,
) -> Dictionary:
	if runway_days <= 0:
		return {}
	if _popup_offered_on_runway_day == runway_days:
		return {}
	var effective_interval: int = maxi(1, int(float(config.dilemma_offer_interval) / pressure_modifier))
	if not (runway_days % effective_interval == 0):
		return {}
	if _dilemma_days_offered.get(runway_days, false):
		return {}

	var dilemmas: Array = offers.get("dilemmas", [])
	if dilemmas.is_empty():
		push_warning("No dilemmas loaded from offers.json — skipping dilemma offer")
		return {}

	_pending_dilemma = _pick_weighted_dilemma(dilemmas, offers, publisher_trust_mode_enabled, publisher_trust, pressure_modifier)
	if _pending_dilemma.is_empty():
		return {}
	_pending_dilemma["runway_day"] = runway_days
	_dilemma_days_offered[runway_days] = true
	_popup_offered_on_runway_day = runway_days
	return _pending_dilemma

func _pick_weighted_dilemma(
	dilemmas: Array,
	offers: Dictionary,
	publisher_trust_mode_enabled: bool,
	publisher_trust: int,
	_pressure_modifier: float,
) -> Dictionary:
	var weighted_entries: Array[Dictionary] = []
	var total_weight: float = 0.0
	for raw_dilemma in dilemmas:
		if raw_dilemma is not Dictionary:
			continue
		var dilemma: Dictionary = raw_dilemma as Dictionary
		var category: String = String(dilemma.get("category", "default"))
		var weight: float = _get_dilemma_category_weight(category, offers, publisher_trust_mode_enabled, publisher_trust)
		if weight <= 0.0:
			continue
		total_weight += weight
		weighted_entries.append({"weight": weight, "dilemma": dilemma})

	if weighted_entries.is_empty():
		for raw_d in dilemmas:
			if raw_d is Dictionary:
				return (raw_d as Dictionary).duplicate(true)
		return {}

	var roll: float = _rng.randf() * total_weight
	var cursor: float = 0.0
	for entry in weighted_entries:
		cursor += float(entry.get("weight", 0.0))
		if roll <= cursor:
			return (entry.get("dilemma", {}) as Dictionary).duplicate(true)
	return (weighted_entries[weighted_entries.size() - 1].get("dilemma", {}) as Dictionary).duplicate(true)

func _get_dilemma_category_weight(
	category: String,
	offers: Dictionary,
	publisher_trust_mode_enabled: bool,
	publisher_trust: int,
) -> float:
	var all_weights: Variant = offers.get("dilemma_category_weights", {})
	if all_weights is not Dictionary:
		return 1.0

	var profile: String = "default"
	if publisher_trust_mode_enabled:
		if publisher_trust >= 20:
			profile = "high_trust"
		elif publisher_trust <= -20:
			profile = "low_trust"

	var profile_weights: Variant = (all_weights as Dictionary).get(profile, {})
	if profile_weights is not Dictionary:
		return 1.0

	if (profile_weights as Dictionary).has(category):
		return maxf(float((profile_weights as Dictionary).get(category, 1.0)), 0.0)
	if (profile_weights as Dictionary).has("default"):
		return maxf(float((profile_weights as Dictionary).get("default", 1.0)), 0.0)
	return 1.0

# --- Draft scheduling ---

func maybe_offer_draft(
	config: GameConfig,
	offers: Dictionary,
	runway_days: int,
	soul: int,
	feature_board_empty: bool,
	pressure_modifier: float,
) -> Dictionary:
	if runway_days <= 0:
		return {}
	if feature_board_empty:
		return {}
	if _popup_offered_on_runway_day == runway_days:
		return {}
	var effective_interval: int = maxi(1, int(float(config.draft_offer_interval) / pressure_modifier))
	if runway_days % effective_interval != 0:
		return {}
	if _last_draft_day_offered == runway_days:
		return {}

	_last_draft_day_offered = runway_days
	var draft_picks: Array = Array((offers.get("draft_picks", {}) as Dictionary).get("base", []))
	var soul_gated: Array = Array((offers.get("draft_picks", {}) as Dictionary).get("soul_gated", []))
	for sg_pick: Variant in soul_gated:
		if int((sg_pick as Dictionary).get("soul_required", 0)) <= soul:
			draft_picks.append(sg_pick)
	_pending_draft_offer = {
		"title": "Feature Pitch Draft",
		"description": "Pick one producer pitch to shape the next stretch.",
		"picks": draft_picks,
	}
	_popup_offered_on_runway_day = runway_days
	return _pending_draft_offer

# --- Publisher meeting scheduling ---

func maybe_offer_publisher_meeting(
	config: GameConfig,
	runway_days: int,
	instability: int,
	soul: int,
	feature_board_size: int,
	publisher_trust_mode_enabled: bool,
	publisher_trust: int,
	pressure_modifier: float,
) -> Dictionary:
	if runway_days <= 0:
		return {}
	if not publisher_trust_mode_enabled:
		return {}
	if feature_board_size == 0:
		return {}
	if _popup_offered_on_runway_day == runway_days:
		return {}
	var effective_interval: int = maxi(1, int(float(config.publisher_meeting_interval) / pressure_modifier))
	if runway_days % effective_interval != 0:
		return {}
	if _last_publisher_meeting_day_offered == runway_days:
		return {}
	if _publisher_meeting_days_offered.get(runway_days, false):
		return {}

	_last_publisher_meeting_day_offered = runway_days
	_publisher_meeting_days_offered[runway_days] = true

	var grade_info: Dictionary = _grade_publisher_meeting_state(instability, soul, feature_board_size, runway_days)
	var topic: String = _pick_publisher_topic()
	var options: Array[Dictionary] = _build_publisher_meeting_options(topic, pressure_modifier, publisher_trust)
	_pending_publisher_meeting = {
		"title": "Publisher Meeting / Day %d" % runway_days,
		"topic": topic,
		"grade": String(grade_info.get("grade", "Promising")),
		"grade_quality": float(grade_info.get("quality", 0.5)),
		"grade_trust_delta": int(grade_info.get("trust_delta", 0)),
		"summary": String(grade_info.get("summary", "Status is acceptable, barely.")),
		"options": options,
		"runway_day": runway_days,
	}
	_popup_offered_on_runway_day = runway_days
	return _pending_publisher_meeting

func _grade_publisher_meeting_state(instability: int, soul: int, feature_board_size: int, runway_days: int) -> Dictionary:
	var grade: String = "Promising"
	var quality: float = 0.65
	var trust_delta: int = 5
	var summary: String = "Deck looked expensive; build looked mostly survivable."

	if instability > 75 or feature_board_size == 0:
		grade = "Disaster"
		quality = 0.1
		trust_delta = -15
		summary = "Demo crashed during the meeting. Publisher asks if this is a prank build."
	elif instability > 60 or runway_days <= 3:
		grade = "Concerning"
		quality = 0.35
		trust_delta = -8
		summary = "Milestone risks are visible. Publisher requests a credible rescue plan."
	elif instability >= 30 and instability <= 55 and soul >= 20 and feature_board_size >= 2:
		grade = "Excellent"
		quality = 1.0
		trust_delta = 10
		summary = "Bold but coherent. Publisher sees a marketable, fixable mess."

	return {
		"grade": grade,
		"quality": quality,
		"trust_delta": trust_delta,
		"summary": summary,
	}

func _pick_publisher_topic() -> String:
	var topics: PackedStringArray = PackedStringArray(["Scope", "Tech Debt", "Community", "Production"])
	return topics[_rng.randi_range(0, topics.size() - 1)]

func _build_publisher_meeting_options(topic: String, pressure_modifier: float, publisher_trust: int) -> Array[Dictionary]:
	var options: Array[Dictionary] = [
		{
			"label": "Polish Promise",
			"effects": {"instability": -4, "ambition": -1, "soul": -1},
			"trust_delta": 4,
		},
		{
			"label": "Vision First",
			"effects": {"ambition": 3, "instability": 3, "soul": 1},
			"trust_delta": 1,
		},
		{
			"label": "Community Theater",
			"effects": {"soul": 3, "runway_days": -1, "instability": 1},
			"trust_delta": 2,
		},
	]

	match topic:
		"Tech Debt":
			(options[0]["effects"] as Dictionary)["instability"] = -6
			(options[1]["effects"] as Dictionary)["instability"] = 5
		"Community":
			(options[2]["effects"] as Dictionary)["soul"] = 5
			(options[2]["effects"] as Dictionary)["instability"] = 2
		"Production":
			(options[0]["effects"] as Dictionary)["runway_days"] = 1
			(options[1]["effects"] as Dictionary)["runway_days"] = -1

	if pressure_modifier > 1.0:
		if publisher_trust < -10:
			(options[1]["effects"] as Dictionary)["instability"] = int((options[1]["effects"] as Dictionary).get("instability", 0)) + 2
		if publisher_trust > 10:
			(options[0]["effects"] as Dictionary)["runway_days"] = int((options[0]["effects"] as Dictionary).get("runway_days", 0)) + 1

	return options
