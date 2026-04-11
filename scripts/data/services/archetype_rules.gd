extends RefCounted
class_name ArchetypeRules

static func get_goldilocks_window_for_archetype(config: GameConfig, archetype: String) -> Array[int]:
	if config == null:
		return [0, 100]
	match archetype.to_lower().replace(" ", "_").replace("-", "_"):
		"rpg":
			return [config.goldilocks_instability_min_rpg, config.goldilocks_instability_max_rpg]
		"shooter":
			return [config.goldilocks_instability_min_shooter, config.goldilocks_instability_max_shooter]
		_:
			return [config.goldilocks_instability_min_action_adventure, config.goldilocks_instability_max_action_adventure]

static func is_defining_game_eligible(
	config: GameConfig,
	ambition: int,
	instability: int,
	soul: int,
	archetype: String,
	run: int,
) -> bool:
	if config == null or run < 2:
		return false
	var window: Array[int] = get_goldilocks_window_for_archetype(config, archetype)
	return ambition >= config.goldilocks_ambition_min \
		and instability >= window[0] and instability <= window[1] \
		and soul >= config.goldilocks_soul_min

func can_place_card(card: FeatureCard, chosen_archetype: String, soul: int, config: GameConfig) -> bool:
	if card == null:
		return false
	if not chosen_archetype.is_empty() and card.archetype_affinity.is_empty():
		return config != null and soul >= config.alien_card_soul_gate
	return true

func get_mismatch_level(card: FeatureCard, chosen_archetype: String) -> int:
	if card == null or chosen_archetype.is_empty():
		return 0
	var count: int = card.archetype_affinity.size()
	if count >= 3:
		return 0
	if count > 0 and card.archetype_affinity.has(chosen_archetype):
		return 0
	match count:
		0:
			return 3
		1:
			return 2
		2:
			return 1
	return 0

func build_mismatch_result(
	card: FeatureCard,
	chosen_archetype: String,
	soul: int,
	config: GameConfig,
) -> Dictionary:
	if card == null or config == null or chosen_archetype.is_empty():
		return {}
	var count: int = card.archetype_affinity.size()
	if count >= 3:
		return {}
	if count > 0 and card.archetype_affinity.has(chosen_archetype):
		return {}
	var genre_label: String = chosen_archetype.capitalize().replace("_", "-")
	if count == 0:
		if soul < config.alien_card_soul_gate:
			return {}
		return {
			"ambition_delta": config.alien_card_ambition_bonus,
			"instability_delta": config.alien_card_instability_bonus,
			"soul_delta": -config.alien_card_soul_penalty,
			"event_id": "archetype_alien",
			"message": "%s in a %s — this card belongs to another universe entirely. +%d Instability, +%d Ambition, -%d Soul" % [
				card.feature_name,
				genre_label,
				config.alien_card_instability_bonus,
				config.alien_card_ambition_bonus,
				config.alien_card_soul_penalty,
			],
			"effects": {
				"instability": config.alien_card_instability_bonus,
				"ambition": config.alien_card_ambition_bonus,
				"soul": -config.alien_card_soul_penalty,
			},
			"severity": "warning",
		}
	if count == 2:
		return {
			"ambition_delta": 0,
			"instability_delta": config.genre_stretch_instability_bonus,
			"soul_delta": 0,
			"event_id": "archetype_genre_stretch",
			"message": "%s in a %s — familiar territory, slightly off-brief. +%d Instability" % [
				card.feature_name,
				genre_label,
				config.genre_stretch_instability_bonus,
			],
			"effects": {
				"instability": config.genre_stretch_instability_bonus,
			},
			"severity": "info",
		}
	return {
		"ambition_delta": config.archetype_mismatch_ambition_bonus,
		"instability_delta": config.archetype_mismatch_instability_bonus,
		"soul_delta": -config.archetype_mismatch_soul_penalty,
		"event_id": "archetype_mismatch",
		"message": "%s in a %s — the team is confused but intrigued. +%d Instability, +%d Ambition, -%d Soul" % [
			card.feature_name,
			genre_label,
			config.archetype_mismatch_instability_bonus,
			config.archetype_mismatch_ambition_bonus,
			config.archetype_mismatch_soul_penalty,
		],
		"effects": {
			"instability": config.archetype_mismatch_instability_bonus,
			"ambition": config.archetype_mismatch_ambition_bonus,
			"soul": -config.archetype_mismatch_soul_penalty,
		},
		"severity": "warning",
	}