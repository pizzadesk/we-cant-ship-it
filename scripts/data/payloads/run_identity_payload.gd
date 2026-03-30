extends RefCounted
class_name RunIdentityPayload

var identity: String = "Unformed"
var style_points: Dictionary = {}

static func from_dictionary(event_data: Dictionary) -> RunIdentityPayload:
	var payload: RunIdentityPayload = RunIdentityPayload.new()
	payload.identity = String(event_data.get("identity", "Unformed"))
	var raw_style_points: Variant = event_data.get("style_points", {})
	if raw_style_points is Dictionary:
		payload.style_points = raw_style_points.duplicate(true)
	else:
		payload.style_points = {}
	return payload

func to_dictionary() -> Dictionary:
	return {
		"identity": identity,
		"style_points": style_points.duplicate(true),
	}
