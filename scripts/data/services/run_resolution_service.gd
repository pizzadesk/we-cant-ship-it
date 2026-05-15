extends RefCounted
class_name RunResolutionService

const RunResolutionOutcomeType = preload("res://scripts/data/payloads/run_resolution_outcome.gd")

var _content_repository: AppContentRepository = null
var _cycle_mgr: CycleStateManager = null
var _review_generator: Node = null
var _rng: RandomNumberGenerator = null

func setup(
	content_repository: AppContentRepository,
	cycle_mgr: CycleStateManager,
	review_generator: Node,
	rng: RandomNumberGenerator,
) -> void:
	_content_repository = content_repository
	_cycle_mgr = cycle_mgr
	_review_generator = review_generator
	_rng = rng

func calculate_predicted_score(
	ambition: int,
	instability: int,
	runway_days: int,
	soul: int,
	features_shipped: int,
) -> float:
	var config: GameConfig = _content_repository.get_game_config()
	var ship_window: Dictionary = ScoreCalculator.compute_ship_window(config, runway_days, instability)
	return ScoreCalculator.calculate_final_score(config, ambition, instability, soul, features_shipped, ship_window)

func resolve_and_commit_run(
	ambition: int,
	instability: int,
	runway_days: int,
	soul: int,
	feature_board: Array[FeatureCard],
	chosen_archetype: String,
	current_run: int,
	locked_signature_jank: Dictionary = {},
	unfulfilled_prospect: Dictionary = {},
) -> RunResolutionOutcomeType:
	var config: GameConfig = _content_repository.get_game_config()
	var completed_run: int = current_run
	var features_shipped: int = feature_board.size()

	var ship_window: Dictionary = ScoreCalculator.compute_ship_window(config, runway_days, instability)
	var dg_eligible: bool = ArchetypeRules.is_defining_game_eligible(
		config,
		ambition,
		instability,
		soul,
		chosen_archetype,
		current_run
	)
	var review_score: float = ScoreCalculator.calculate_final_score(
		config,
		ambition,
		instability,
		soul,
		features_shipped,
		ship_window,
		dg_eligible
	)
	var jank_status: String = ScoreCalculator.compute_jank_status(config, instability, review_score)
	var jank_match: Dictionary = locked_signature_jank.duplicate(true)
	if jank_match.is_empty():
		jank_match = JankResolver.find_combination(feature_board, chosen_archetype, _content_repository.get_jank_combinations())
	var has_jank_combination: bool = not jank_match.is_empty()
	var ending_id: String = EndingResolver.resolve_ending_id(
		config,
		ambition,
		instability,
		soul,
		chosen_archetype,
		has_jank_combination,
		current_run
	)
	var ending: String = EndingResolver.label_for_id(ending_id)
	if features_shipped == 0:
		review_score = 0.1
		jank_status = "broken"
		ending_id = EndingResolver.SHIPPED_SOMETHING_ID
		ending = EndingResolver.label_for_id(ending_id)

	var reviews: Array[Dictionary] = []
	if _review_generator != null:
		reviews = _review_generator.generate_reviews(
			review_score,
			instability,
			soul,
			features_shipped,
			feature_board,
			String(ship_window.get("label", "")),
			ending_id,
			jank_match
		)

	var unlocked: PackedStringArray = _cycle_mgr.get_unlocked_card_ids()
	var unlock_result: Dictionary = CardUnlockResolver.resolve_unlock(
		_content_repository.get_all_card_ids(),
		unlocked,
		ending_id,
		current_run,
		_content_repository.get_card_metadata_cache(),
		_rng,
		Callable(_content_repository, "load_card_by_id"),
		config,
		ambition,
		instability,
		soul,
		chosen_archetype
	)
	_enrich_unlock_result(unlock_result)
	var new_unlocked: PackedStringArray = PackedStringArray(unlock_result.get("new_unlocked_ids", unlocked))

	var jank_card_id: String = String(jank_match.get("jank_card_id", ""))
	if not jank_card_id.is_empty():
		if not new_unlocked.has(jank_card_id):
			new_unlocked.append(jank_card_id)
		_cycle_mgr.add_jank_card(jank_card_id)

	var cycle_summary: Dictionary = {
		"run": completed_run,
		"ending_id": ending_id,
		"ending": ending,
		"ambition": ambition,
		"instability": instability,
		"soul": soul,
		"archetype": chosen_archetype,
		"features_shipped": features_shipped,
		"jank_combination": jank_match.duplicate(true),
		"ship_window": ship_window.duplicate(true),
		"card_unlock": unlock_result.duplicate(true),
		"unfulfilled_prospect": unfulfilled_prospect.duplicate(true),
	}

	var last_completed_run: int = _cycle_mgr.complete_run(ending, new_unlocked, cycle_summary)
	var result: ShipResult = ShipResult.new()
	result.review_score = review_score
	result.ending_id = ending_id
	result.ending = ending
	result.jank_status = jank_status
	result.ship_window = ship_window
	result.card_unlock = unlock_result
	result.features_shipped = features_shipped
	result.reviews = reviews
	result.jank_combination = jank_match
	result.unlock_defining_game = ending_id == EndingResolver.DEFINING_GAME_ID
	result.completed_run = completed_run
	result.unfulfilled_prospect = unfulfilled_prospect.duplicate(true)
	var outcome: RunResolutionOutcomeType = RunResolutionOutcomeType.new()
	outcome.ship_result = result
	outcome.last_completed_run = last_completed_run
	outcome.current_run = _cycle_mgr.get_current_run()
	return outcome

func _enrich_unlock_result(unlock_result: Dictionary) -> void:
	var unlocked_card_id: String = String(unlock_result.get("card_id", ""))
	if not unlocked_card_id.is_empty():
		var unlocked_card: FeatureCard = _content_repository.load_card_by_id(unlocked_card_id)
		unlock_result["card_name"] = unlocked_card.feature_name if unlocked_card != null else unlocked_card_id.replace("_", " ").capitalize()
	var bonus_card_id: String = String(unlock_result.get("bonus_card_id", ""))
	if not bonus_card_id.is_empty():
		var bonus_card: FeatureCard = _content_repository.load_card_by_id(bonus_card_id)
		unlock_result["bonus_card_name"] = bonus_card.feature_name if bonus_card != null else bonus_card_id.replace("_", " ").capitalize()