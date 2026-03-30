extends RefCounted
class_name ShipResult

# Typed payload for all outcomes produced by ship_it().
# Replaces the raw Dictionary returned from that function so callers get
# compile-time field names instead of string key lookups.

var review_score: float = 0.0
var ending: String = ""
var jank_status: String = ""
var ship_window: Dictionary = {}
var publisher_meeting_quality: float = 0.0
var publisher_trust: int = 0
var card_unlock: Dictionary = {}
var features_shipped: int = 0
var reviews: Array[Dictionary] = []
var mechanics_highlights: Array[String] = []
var run_identity: String = ""
var unlock_defining_game: bool = false
var meta_progress: Dictionary = {}

func to_dictionary() -> Dictionary:
	return {
		"review_score": review_score,
		"ending": ending,
		"jank_status": jank_status,
		"ship_window": ship_window,
		"publisher_meeting_quality": publisher_meeting_quality,
		"publisher_trust": publisher_trust,
		"card_unlock": card_unlock,
		"features_shipped": features_shipped,
		"reviews": reviews,
		"mechanics_highlights": mechanics_highlights,
		"run_identity": run_identity,
		"unlock_defining_game": unlock_defining_game,
		"meta_progress": meta_progress,
	}
