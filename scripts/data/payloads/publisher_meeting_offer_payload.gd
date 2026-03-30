extends RefCounted
class_name PublisherMeetingOfferPayload

var title: String = "Publisher Meeting"
var summary: String = "Publisher requests a status report."
var topic: String = "Scope"
var grade: String = "Promising"
var options: Array[Dictionary] = []

static func from_dictionary(event_data: Dictionary) -> PublisherMeetingOfferPayload:
	var payload: PublisherMeetingOfferPayload = PublisherMeetingOfferPayload.new()
	payload.title = String(event_data.get("title", "Publisher Meeting"))
	payload.summary = String(event_data.get("summary", "Publisher requests a status report."))
	payload.topic = String(event_data.get("topic", "Scope"))
	payload.grade = String(event_data.get("grade", "Promising"))

	var raw_options: Variant = event_data.get("options", [])
	if raw_options is Array:
		for option in raw_options:
			if option is Dictionary:
				payload.options.append((option as Dictionary).duplicate(true))
	return payload

func to_dictionary() -> Dictionary:
	return {
		"title": title,
		"summary": summary,
		"topic": topic,
		"grade": grade,
		"options": options.duplicate(true),
	}
