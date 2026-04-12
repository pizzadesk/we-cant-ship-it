extends RefCounted
class_name DraftOfferPayload

var title: String = "Feature Pitch Draft"
var description: String = "Pick one option."
var picks: Array[Dictionary] = []

static func from_dictionary(event_data: Dictionary) -> DraftOfferPayload:
	var payload: DraftOfferPayload = DraftOfferPayload.new()
	payload.title = String(event_data.get("title", "Feature Pitch Draft"))
	payload.description = String(event_data.get("description", "Pick one option."))

	var raw_picks: Variant = event_data.get("picks", [])
	if raw_picks is Array:
		for pick in raw_picks:
			if pick is Dictionary:
				payload.picks.append((pick as Dictionary).duplicate(true))
	return payload
