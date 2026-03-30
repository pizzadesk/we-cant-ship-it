extends RefCounted
class_name MilestonePayload

var runs_played: int = 0
var studio_tier: int = 1
var reputation_total: int = 0
var ending: String = ""
var milestone_index: int = 0

static func from_dictionary(data: Dictionary) -> MilestonePayload:
	var payload: MilestonePayload = MilestonePayload.new()
	payload.runs_played = int(data.get("runs_played", 0))
	payload.studio_tier = int(data.get("studio_tier", 1))
	payload.reputation_total = int(data.get("reputation_total", 0))
	payload.ending = String(data.get("ending", ""))
	payload.milestone_index = int(data.get("milestone_index", 0))
	return payload

func to_dictionary() -> Dictionary:
	return {
		"runs_played": runs_played,
		"studio_tier": studio_tier,
		"reputation_total": reputation_total,
		"ending": ending,
		"milestone_index": milestone_index,
	}
