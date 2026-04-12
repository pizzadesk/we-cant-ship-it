extends RefCounted
class_name ChoiceResolution

const RunStateDataType = preload("res://scripts/data/payloads/run_state_data.gd")

var state: RunStateDataType = null
var threshold_event: ThresholdEventPayload = null

func is_empty() -> bool:
	return state == null and threshold_event == null
