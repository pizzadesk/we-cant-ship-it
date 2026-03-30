extends RefCounted
class_name DilemmaOfferPayload

var title: String = "Studio Dilemma"
var description: String = "A hard choice appears."
var choices: Array[Dictionary] = []

static func from_dictionary(event_data: Dictionary) -> DilemmaOfferPayload:
	var payload: DilemmaOfferPayload = DilemmaOfferPayload.new()
	payload.title = String(event_data.get("title", "Studio Dilemma"))
	payload.description = String(event_data.get("description", "A hard choice appears."))

	var raw_choices: Variant = event_data.get("choices", [])
	if raw_choices is Array:
		for choice in raw_choices:
			if choice is Dictionary:
				payload.choices.append((choice as Dictionary).duplicate(true))
	return payload

func to_dictionary() -> Dictionary:
	return {
		"title": title,
		"description": description,
		"choices": choices.duplicate(true),
	}
