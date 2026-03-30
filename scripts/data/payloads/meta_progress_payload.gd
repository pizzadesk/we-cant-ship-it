extends RefCounted
class_name MetaProgressPayload

var runs_played: int = 0
var best_review_score: float = 0.0
var last_release_score: float = 0.0
var studio_tier: int = 1
var reputation_total: int = 0
var runs_since_milestone: int = 0

static func from_dictionary(event_data: Dictionary) -> MetaProgressPayload:
	var payload: MetaProgressPayload = MetaProgressPayload.new()
	payload.runs_played = int(event_data.get("runs_played", 0))
	payload.best_review_score = float(event_data.get("best_review_score", 0.0))
	payload.last_release_score = float(event_data.get("last_release_score", 0.0))
	payload.studio_tier = int(event_data.get("studio_tier", 1))
	payload.reputation_total = int(event_data.get("reputation_total", 0))
	payload.runs_since_milestone = int(event_data.get("runs_since_milestone", 0))
	return payload

func to_dictionary() -> Dictionary:
	return {
		"runs_played": runs_played,
		"best_review_score": best_review_score,
		"last_release_score": last_release_score,
		"studio_tier": studio_tier,
		"reputation_total": reputation_total,
		"runs_since_milestone": runs_since_milestone,
	}
