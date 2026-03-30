extends RefCounted
class_name InteractionEventPayload

var flavor: String = "Unexpected interaction happened."
var instability_delta: int = 0
var soul_delta: int = 0

static func from_dictionary(event_data: Dictionary) -> InteractionEventPayload:
	var payload: InteractionEventPayload = InteractionEventPayload.new()
	payload.flavor = String(event_data.get("flavor", "Unexpected interaction happened."))
	payload.instability_delta = int(event_data.get("instability_delta", 0))
	payload.soul_delta = int(event_data.get("soul_delta", 0))
	return payload

func to_dictionary() -> Dictionary:
	return {
		"flavor": flavor,
		"instability_delta": instability_delta,
		"soul_delta": soul_delta,
	}
