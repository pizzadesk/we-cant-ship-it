extends RefCounted
class_name ShipResult

# Typed payload for all outcomes produced by ship_it().
# Replaces the raw Dictionary returned from that function so callers get
# compile-time field names instead of string key lookups.

var review_score: float = 0.0
var ending_id: String = ""
var ending: String = ""
var jank_status: String = ""
var ship_window: Dictionary = {}
var card_unlock: Dictionary = {}
var features_shipped: int = 0
var reviews: Array[Dictionary] = []
var jank_combination: Dictionary = {}
var unlock_defining_game: bool = false
var completed_run: int = 0

func to_dictionary() -> Dictionary:
	return {
		"review_score": review_score,
		"ending_id": ending_id,
		"ending": ending,
		"jank_status": jank_status,
		"ship_window": ship_window,
		"card_unlock": card_unlock,
		"features_shipped": features_shipped,
		"reviews": reviews,
		"jank_combination": jank_combination,
		"unlock_defining_game": unlock_defining_game,
		"completed_run": completed_run,
	}
