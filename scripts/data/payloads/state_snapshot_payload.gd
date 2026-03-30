extends RefCounted
class_name StateSnapshotPayload

var ambition: int = 0
var instability: int = 0
var runway_days: int = 0
var soul: int = 0
var features_shipped: int = 0
var run_identity: String = "Unformed"
var meta_studio_tier: int = 1
# Style pressure accumulators — three competing identities; whichever leads sets run_identity.
var style_points: Dictionary = {}

static func from_dictionary(snapshot: Dictionary) -> StateSnapshotPayload:
	var payload: StateSnapshotPayload = StateSnapshotPayload.new()
	payload.ambition = int(snapshot.get("ambition", 0))
	payload.instability = int(snapshot.get("instability", 0))
	payload.runway_days = int(snapshot.get("runway_days", 0))
	payload.soul = int(snapshot.get("soul", 0))
	payload.features_shipped = int(snapshot.get("features_shipped", 0))
	payload.run_identity = String(snapshot.get("run_identity", "Unformed"))
	payload.meta_studio_tier = int(snapshot.get("meta_studio_tier", 1))
	var sp: Variant = snapshot.get("style_points", {})
	payload.style_points = sp if sp is Dictionary else {}
	return payload

func to_dictionary() -> Dictionary:
	return {
		"ambition": ambition,
		"instability": instability,
		"runway_days": runway_days,
		"soul": soul,
		"features_shipped": features_shipped,
		"run_identity": run_identity,
		"meta_studio_tier": meta_studio_tier,
		"style_points": style_points,
	}
