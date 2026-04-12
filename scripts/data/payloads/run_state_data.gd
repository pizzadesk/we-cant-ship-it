extends RefCounted
class_name RunStateData

var ambition: int = 0
var instability: int = 0
var runway_days: int = 0
var soul: int = 0

static func from_values(next_ambition: int, next_instability: int, next_runway_days: int, next_soul: int) -> RunStateData:
	var state: RunStateData = RunStateData.new()
	state.ambition = next_ambition
	state.instability = next_instability
	state.runway_days = next_runway_days
	state.soul = next_soul
	return state

static func from_dictionary(data: Dictionary) -> RunStateData:
	return from_values(
		int(data.get("ambition", 0)),
		int(data.get("instability", 0)),
		int(data.get("runway_days", 0)),
		int(data.get("soul", 0))
	)

func duplicate_state() -> RunStateData:
	return RunStateData.from_values(ambition, instability, runway_days, soul)

func apply_effects(effects: Variant) -> RunStateData:
	var next_state: RunStateData = duplicate_state()
	if effects is not Dictionary:
		return next_state
	var effect_map: Dictionary = effects as Dictionary
	next_state.ambition = max(next_state.ambition + int(effect_map.get("ambition", 0)), 0)
	next_state.instability = max(next_state.instability + int(effect_map.get("instability", 0)), 0)
	next_state.runway_days = max(next_state.runway_days + int(effect_map.get("runway_days", 0)), 0)
	next_state.soul = max(next_state.soul + int(effect_map.get("soul", 0)), 0)
	return next_state

func get_metric(metric_name: String) -> int:
	match metric_name:
		"ambition":
			return ambition
		"instability":
			return instability
		"runway_days":
			return runway_days
		"soul":
			return soul
		_:
			return 0

func to_dictionary() -> Dictionary:
	return {
		"ambition": ambition,
		"instability": instability,
		"runway_days": runway_days,
		"soul": soul,
	}
