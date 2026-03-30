extends RefCounted
class_name RunwayDepletedPayload

var runway_days: int = 0

static func build(runway_remaining: int) -> RunwayDepletedPayload:
	var payload: RunwayDepletedPayload = RunwayDepletedPayload.new()
	payload.runway_days = runway_remaining
	return payload

func to_dictionary() -> Dictionary:
	return {
		"runway_days": runway_days,
	}
