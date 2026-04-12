extends RefCounted
class_name ThresholdEventPayload

var id: String = ""
var severity: String = "info"
var message: String = "Threshold event triggered."
var effects: Dictionary = {}

static func build(event_id: String, next_message: String, next_effects: Variant = {}, next_severity: String = "info") -> ThresholdEventPayload:
	var payload: ThresholdEventPayload = ThresholdEventPayload.new()
	payload.id = event_id
	payload.severity = next_severity
	payload.message = next_message
	if next_effects is Dictionary:
		payload.effects = (next_effects as Dictionary).duplicate(true)
	else:
		payload.effects = {}
	return payload

static func from_dictionary(event_data: Dictionary) -> ThresholdEventPayload:
	return build(
		String(event_data.get("id", "")),
		String(event_data.get("message", "Threshold event triggered.")),
		event_data.get("effects", {}),
		String(event_data.get("severity", "info"))
	)

func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"severity": severity,
		"message": message,
		"effects": effects.duplicate(true),
	}
