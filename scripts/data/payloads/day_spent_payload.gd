extends RefCounted
class_name DaySpentPayload

var reason: String = ""
var runway_days: int = 0

static func build(spend_reason: String, runway_remaining: int) -> DaySpentPayload:
	var payload: DaySpentPayload = DaySpentPayload.new()
	payload.reason = spend_reason
	payload.runway_days = runway_remaining
	return payload

func to_dictionary() -> Dictionary:
	return {
		"reason": reason,
		"runway_days": runway_days,
	}
