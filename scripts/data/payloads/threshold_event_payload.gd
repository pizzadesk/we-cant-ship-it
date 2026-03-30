extends RefCounted
class_name ThresholdEventPayload

var id: String = ""
var severity: String = "info"
var message: String = "Threshold event triggered."
var effects: Dictionary = {}

static func from_dictionary(event_data: Dictionary) -> ThresholdEventPayload:
	var payload: ThresholdEventPayload = ThresholdEventPayload.new()
	payload.id = String(event_data.get("id", ""))
	payload.severity = String(event_data.get("severity", "info"))
	payload.message = String(event_data.get("message", "Threshold event triggered."))
	var raw_effects: Variant = event_data.get("effects", {})
	if raw_effects is Dictionary:
		payload.effects = raw_effects.duplicate(true)
	else:
		payload.effects = {}
	return payload

func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"severity": severity,
		"message": message,
		"effects": effects.duplicate(true),
	}
