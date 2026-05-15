class_name HudPresentation

## Formats all HUD display values from raw state data.
## Returns a typed bundle; controller passes it to the view.

class Bundle:
	var ambition_text:  String
	var ambition_met:   bool
	var soul_text:      String
	var action_label:   String

static func build(
		ambition: int, ambition_target: int,
		_instability: int,
		soul: int, soul_target: int,
		action_readout: String) -> Bundle:
	var b := Bundle.new()
	b.ambition_text  = "%d / %d+" % [ambition, ambition_target]
	b.ambition_met   = ambition >= ambition_target
	b.soul_text      = "%d / %d+" % [soul, soul_target]
	b.action_label   = action_readout
	return b
