extends RefCounted
class_name StateSnapshotPayload

var ambition: int = 0
var instability: int = 0
var runway_days: int = 0
var soul: int = 0
var features_shipped: int = 0
var current_run: int = 1

static func from_dictionary(snapshot: Dictionary) -> StateSnapshotPayload:
	var payload: StateSnapshotPayload = StateSnapshotPayload.new()
	payload.ambition = int(snapshot.get("ambition", 0))
	payload.instability = int(snapshot.get("instability", 0))
	payload.runway_days = int(snapshot.get("runway_days", 0))
	payload.soul = int(snapshot.get("soul", 0))
	payload.features_shipped = int(snapshot.get("features_shipped", 0))
	payload.current_run = int(snapshot.get("current_run", 1))
	return payload

func to_dictionary() -> Dictionary:
	return {
		"ambition": ambition,
		"instability": instability,
		"runway_days": runway_days,
		"soul": soul,
		"features_shipped": features_shipped,
		"current_run": current_run,
	}
