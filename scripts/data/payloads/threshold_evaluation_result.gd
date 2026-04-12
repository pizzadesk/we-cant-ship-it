extends RefCounted
class_name ThresholdEvaluationResult

const RunStateDataType = preload("res://scripts/data/payloads/run_state_data.gd")

var state: RunStateDataType = null
var events: Array[ThresholdEventPayload] = []

func is_empty() -> bool:
	return state == null and events.is_empty()
