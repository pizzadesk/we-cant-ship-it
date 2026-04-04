extends Resource
class_name FeatureCard

# Name shown to the player.
@export var feature_name: String = ""
# How much this card increases project scope.
@export var ambition_value: int = 0
# How much this card adds chaos/jank.
@export var instability_value: int = 0
# Card pool tier used by unlock and offer systems.
@export var tier: String = "common"
# Unlock weighting for post-run card rewards. Higher values bias stronger unlocks.
@export var unlock_weight: float = 1.0
# Simple keywords used for interaction matching.
@export var tags: PackedStringArray = PackedStringArray()
# Per-tag stat deltas map. Example: {"ui": {"instability": 1, "soul": -1}}
@export var interactions: Dictionary = {}
# Per-tag feed flavor strings. Example: {"ui": "UI + systems wobble into charm."}
@export var interaction_flavor: Dictionary = {}
# Short flavour description shown in the card tooltip. Optional — empty = no blurb.
@export var description: String = ""
# Which archetypes this card naturally belongs to.
# Empty = alien card (penalised by all archetype choices, soul-gated).
@export var archetype_affinity: PackedStringArray = PackedStringArray()

func get_interaction_delta(tag: String, stat_name: String) -> int:
	var raw: Variant = interactions.get(tag, {})
	if raw is Dictionary:
		return int((raw as Dictionary).get(stat_name, 0))
	return 0

func get_interaction_flavor_for_tag(tag: String) -> String:
	return String(interaction_flavor.get(tag, ""))

static func get_instability_color(instability: int) -> Color:
	if int(instability) >= 8:
		return Color(1.0, 0.56, 0.48)
	elif int(instability) >= 5:
		return Color(1.0, 0.72, 0.42)
	else:
		return Color(0.95, 0.89, 0.68)
