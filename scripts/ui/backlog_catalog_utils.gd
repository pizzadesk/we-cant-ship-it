const ON_ARCHETYPE_OFFER_WEIGHT: float = 12.0
const UNIVERSAL_OFFER_WEIGHT: float = 9.0
const GENRE_STRETCH_OFFER_WEIGHT: float = 4.0
const WILD_SWING_OFFER_WEIGHT: float = 1.5
const ALIEN_OFFER_WEIGHT: float = 0.5
const PROSPECT_TARGET_OFFER_WEIGHT_MULTIPLIER: float = 3.0
const RECENT_DAY_REPEAT_WEIGHT: float = 0.08
const TWO_DAY_REPEAT_WEIGHT: float = 0.4
const THREE_DAY_REPEAT_WEIGHT: float = 0.7
const SAME_DAY_TIER_WEIGHT: float = 0.82
const SAME_DAY_TAG_WEIGHT: float = 0.9
const NOVEL_TAG_BONUS_WEIGHT: float = 1.12
const STABILITY_RECOVERY_WEIGHT: float = 1.15
const STABILITY_DANGER_WEIGHT: float = 0.72

static func ensure_template_cards_loaded(
	template_cards: Array[Resource],
	templates_loaded: bool,
	cards_path: String,
	custom_cards_path: String,
	append_log: Callable
) -> TemplateCardsLoadResult:
	var result: TemplateCardsLoadResult = TemplateCardsLoadResult.new()
	if templates_loaded and not template_cards.is_empty():
		result.template_cards = template_cards
		result.templates_loaded = templates_loaded
		return result

	var next_template_cards: Array[Resource] = []
	next_template_cards = _load_cards_from_directory(next_template_cards, cards_path, false, append_log)
	next_template_cards = _load_cards_from_directory(next_template_cards, custom_cards_path, true, append_log)

	result.template_cards = next_template_cards
	result.templates_loaded = not next_template_cards.is_empty()
	return result

static func rebuild_daily_offer(
	template_cards: Array[Resource],
	game_state: Node,
	last_offer_runway_day: int,
	initial_runway_days: int,
	daily_visible_cards: int,
	ui_rng: RandomNumberGenerator,
	is_template_unlocked_cb: Callable,
	already_offered_paths: PackedStringArray = PackedStringArray(),
	recent_offer_days: Array = []
) -> DailyOfferResult:
	var result: DailyOfferResult = DailyOfferResult.new()
	if template_cards.is_empty():
		result.last_offer_runway_day = last_offer_runway_day
		return result

	var runway_today: int = initial_runway_days
	if game_state != null:
		runway_today = int(game_state.runway_days)

	if runway_today == last_offer_runway_day:
		result.last_offer_runway_day = last_offer_runway_day
		result.unchanged = true
		return result

	var available_templates: Array[Resource] = []
	var chosen_archetype: String = ""
	var prospect_targets: PackedStringArray = PackedStringArray()
	var recent_paths: Array[PackedStringArray] = _sanitize_recent_offer_days(recent_offer_days)
	var prior_day_paths: PackedStringArray = PackedStringArray()
	if game_state != null and game_state.has_method("get_chosen_archetype"):
		chosen_archetype = String(game_state.get_chosen_archetype())
	if game_state != null and game_state.has_method("get_active_prospect_offer_targets"):
		prospect_targets = PackedStringArray(game_state.get_active_prospect_offer_targets())
	if not recent_paths.is_empty():
		prior_day_paths = recent_paths[recent_paths.size() - 1]

	# Build the eligible pool, respecting unlock and run-tier rules.
	# Archetype commitment is enforced by weighted offers rather than hard filtering,
	# so off-genre cards still appear occasionally and trigger mismatch friction.
	var eligible_templates: Array[Resource] = []
	for template in template_cards:
		if not is_template_unlocked_cb.call(template):
			continue
		if template is FeatureCard and game_state != null and game_state.has_method("is_tier_available"):
			var feature: FeatureCard = template as FeatureCard
			if not bool(game_state.is_tier_available(feature.tier)):
				continue
			eligible_templates.append(template)

	# Apply day-scoped discard filter. Wrap when fewer than daily_visible_cards
	# remain — guarantees a full offer every day.
	if not already_offered_paths.is_empty():
		for template in eligible_templates:
			var is_prospect_target: bool = _is_prospect_target_template(template, prospect_targets)
			if not already_offered_paths.has(template.resource_path) or (is_prospect_target and not prior_day_paths.has(template.resource_path)):
				available_templates.append(template)
		if available_templates.size() < daily_visible_cards:
			# Pool nearly or fully exhausted — wrap to the full eligible pool.
			available_templates = eligible_templates.duplicate()
			result.pool_reset = true
	else:
		available_templates = eligible_templates.duplicate()

	var immediate_repeat_filtered: Array[Resource] = []
	for template in available_templates:
		if not prior_day_paths.has(template.resource_path):
			immediate_repeat_filtered.append(template)
	if immediate_repeat_filtered.size() >= daily_visible_cards:
		available_templates = immediate_repeat_filtered

	var backlog_cards: Array[Resource] = []
	var selected_cards: Array[FeatureCard] = []
	var offer_context: Dictionary = {}
	if game_state != null and game_state.has_method("get_daily_offer_context"):
		offer_context = game_state.get_daily_offer_context()
	if runway_today <= 0 or available_templates.is_empty():
		result.backlog_cards = backlog_cards
		result.last_offer_runway_day = runway_today
		return result

	# Hard guarantee: if a prospect is active, reserve one slot for a prospect target.
	var visible_count: int = mini(daily_visible_cards, available_templates.size())
	var prospect_target_templates: Array[Resource] = []
	var filtered_templates: Array[Resource] = []
	for template in available_templates:
		if _is_prospect_target_template(template, prospect_targets):
			prospect_target_templates.append(template)
		else:
			filtered_templates.append(template)

	for _pick in range(visible_count - 1):
		if filtered_templates.is_empty():
			break
		var pick_index: int = _pick_weighted_template_index(
				filtered_templates,
				chosen_archetype,
				ui_rng,
				prospect_targets,
				recent_paths,
				selected_cards,
				offer_context
		)
		if pick_index < 0:
			break
		var template: Resource = filtered_templates[pick_index]
		filtered_templates.remove_at(pick_index)
		_commit_card_variant(template, backlog_cards, selected_cards, result)

	if not prospect_target_templates.is_empty():
		var idx: int = ui_rng.randi_range(0, prospect_target_templates.size() - 1)
		_commit_card_variant(prospect_target_templates[idx], backlog_cards, selected_cards, result)
	elif not filtered_templates.is_empty() and backlog_cards.size() < visible_count:
		var pick_index: int = _pick_weighted_template_index(
				filtered_templates,
				chosen_archetype,
				ui_rng,
				prospect_targets,
				recent_paths,
				selected_cards,
				offer_context
		)
		if pick_index >= 0:
			_commit_card_variant(filtered_templates[pick_index], backlog_cards, selected_cards, result)

	assert(backlog_cards.size() <= visible_count, "backlog overflow")

	result.backlog_cards = backlog_cards
	result.last_offer_runway_day = runway_today
	return result

static func is_template_unlocked(template: Resource, custom_cards_path: String, game_state: Node, card_id_from_resource_cb: Callable) -> bool:
	if template != null and template.resource_path.begins_with("%s/" % custom_cards_path):
		return true
	if game_state == null or not game_state.has_method("is_card_unlocked"):
		return true
	var card_id: String = String(card_id_from_resource_cb.call(template))
	if card_id.is_empty():
		return true
	return bool(game_state.is_card_unlocked(card_id))

static func card_id_from_resource(card: Resource) -> String:
	if card == null:
		return ""
	if card.resource_path.is_empty():
		return card.resource_name
	var file_name: String = card.resource_path.get_file()
	if file_name.ends_with(".tres"):
		return file_name.trim_suffix(".tres")
	if file_name.ends_with(".res"):
		return file_name.trim_suffix(".res")
	if file_name.ends_with(".tres.remap"):
		return file_name.trim_suffix(".tres.remap")
	if file_name.ends_with(".res.remap"):
		return file_name.trim_suffix(".res.remap")
	return ""

static func _pick_weighted_template_index(
	templates: Array[Resource],
	chosen_archetype: String,
	ui_rng: RandomNumberGenerator,
	prospect_targets: PackedStringArray = PackedStringArray(),
	recent_offer_days: Array[PackedStringArray] = [],
	selected_cards: Array[FeatureCard] = [],
	offer_context: Dictionary = {},
) -> int:
	if templates.is_empty():
		return -1
	var total_weight: float = 0.0
	var weights: Array[float] = []
	for template in templates:
		var weight: float = 1.0
		if template is FeatureCard:
			weight = _offer_weight_for_template(
				template,
				template as FeatureCard,
				chosen_archetype,
				prospect_targets,
				recent_offer_days,
				selected_cards,
				offer_context
			)
		weights.append(weight)
		total_weight += weight
	if total_weight <= 0.0:
		return ui_rng.randi_range(0, templates.size() - 1)
	var roll: float = ui_rng.randf() * total_weight
	var running: float = 0.0
	for idx in range(weights.size()):
		running += weights[idx]
		if roll <= running:
			return idx
	return templates.size() - 1

static func _offer_weight_for_template(
	template: Resource,
	card: FeatureCard,
	chosen_archetype: String,
	prospect_targets: PackedStringArray,
	recent_offer_days: Array[PackedStringArray],
	selected_cards: Array[FeatureCard],
	offer_context: Dictionary,
) -> float:
	var weight: float = _offer_weight_for_archetype(card, chosen_archetype, prospect_targets)
	weight *= _authorial_offer_weight(card)
	weight *= _recent_offer_weight(template, prospect_targets, recent_offer_days)
	weight *= _board_state_offer_weight(card, offer_context)
	weight *= _selection_diversity_weight(card, selected_cards)
	return maxf(weight, 0.01)

static func _offer_weight_for_archetype(
	card: FeatureCard,
	chosen_archetype: String,
	prospect_targets: PackedStringArray = PackedStringArray(),
) -> float:
	if card == null or chosen_archetype.is_empty():
		var neutral_weight: float = 1.0
		if _is_prospect_target_card(card, prospect_targets):
			neutral_weight *= PROSPECT_TARGET_OFFER_WEIGHT_MULTIPLIER
		return neutral_weight
	var weight: float = 1.0
	var affinity_count: int = card.archetype_affinity.size()
	if affinity_count >= 3:
		weight = UNIVERSAL_OFFER_WEIGHT
	elif affinity_count > 0 and card.archetype_affinity.has(chosen_archetype):
		weight = ON_ARCHETYPE_OFFER_WEIGHT
	else:
		match affinity_count:
			0:
				weight = ALIEN_OFFER_WEIGHT
			1:
				weight = WILD_SWING_OFFER_WEIGHT
			2:
				weight = GENRE_STRETCH_OFFER_WEIGHT
			_:
				weight = UNIVERSAL_OFFER_WEIGHT
	if _is_prospect_target_card(card, prospect_targets):
		weight *= PROSPECT_TARGET_OFFER_WEIGHT_MULTIPLIER
	return weight

static func _authorial_offer_weight(card: FeatureCard) -> float:
	if card == null:
		return 1.0
	return clampf(sqrt(maxf(card.unlock_weight, 0.1)), 0.75, 1.4)

static func _recent_offer_weight(
	template: Resource,
	prospect_targets: PackedStringArray,
	recent_offer_days: Array[PackedStringArray],
) -> float:
	if template == null or template.resource_path.is_empty() or recent_offer_days.is_empty():
		return 1.0
	var is_prospect_target: bool = _is_prospect_target_template(template, prospect_targets)
	var multiplier: float = 1.0
	var history_size: int = recent_offer_days.size()
	for idx in range(history_size):
		var day_paths: PackedStringArray = recent_offer_days[history_size - 1 - idx]
		if not day_paths.has(template.resource_path):
			continue
		match idx:
			0:
				multiplier *= RECENT_DAY_REPEAT_WEIGHT if not is_prospect_target else 0.35
			1:
				multiplier *= TWO_DAY_REPEAT_WEIGHT
			2:
				multiplier *= THREE_DAY_REPEAT_WEIGHT
			_:
				multiplier *= 0.85
	return multiplier

static func _board_state_offer_weight(card: FeatureCard, offer_context: Dictionary) -> float:
	if card == null or offer_context.is_empty():
		return 1.0
	var current_instability: int = int(offer_context.get("instability", 0))
	var current_soul: int = int(offer_context.get("soul", 0))
	var board_size: int = int(offer_context.get("board_size", 0))
	var board_tags: PackedStringArray = PackedStringArray(offer_context.get("board_tags", PackedStringArray()))
	var weight: float = 1.0
	if current_instability <= 12 and board_size >= 1:
		if card.instability_value >= 4 and card.instability_value <= 7:
			weight *= 1.15
		elif card.instability_value <= 2:
			weight *= 0.92
	elif current_instability >= 45 or current_soul <= 4:
		if card.instability_value >= 8:
			weight *= STABILITY_DANGER_WEIGHT
		elif card.instability_value <= 3:
			weight *= STABILITY_RECOVERY_WEIGHT
	else:
		if card.instability_value >= 8:
			weight *= 0.94
	if not board_tags.is_empty() and _has_no_shared_tags(card, board_tags):
		weight *= NOVEL_TAG_BONUS_WEIGHT
	return weight

static func _selection_diversity_weight(
	card: FeatureCard,
	selected_cards: Array[FeatureCard],
) -> float:
	if card == null or selected_cards.is_empty():
		return 1.0
	var weight: float = 1.0
	var shared_tag_hits: int = 0
	var same_tier_hits: int = 0
	for selected_card in selected_cards:
		if selected_card == null:
			continue
		if String(selected_card.tier).to_lower() == String(card.tier).to_lower():
			same_tier_hits += 1
		if _cards_share_any_tag(card, selected_card):
			shared_tag_hits += 1
	if same_tier_hits > 0:
		weight *= pow(SAME_DAY_TIER_WEIGHT, same_tier_hits)
	if shared_tag_hits > 0:
		weight *= pow(SAME_DAY_TAG_WEIGHT, shared_tag_hits)
	return weight

static func _cards_share_any_tag(card_a: FeatureCard, card_b: FeatureCard) -> bool:
	if card_a == null or card_b == null:
		return false
	for tag in card_a.tags:
		if card_b.tags.has(tag):
			return true
	return false

static func _has_no_shared_tags(card: FeatureCard, board_tags: PackedStringArray) -> bool:
	if card == null or board_tags.is_empty():
		return false
	for tag in card.tags:
		if board_tags.has(tag):
			return false
	return true

static func _sanitize_recent_offer_days(recent_offer_days: Array) -> Array[PackedStringArray]:
	var sanitized: Array[PackedStringArray] = []
	for entry in recent_offer_days:
		if entry is PackedStringArray:
			sanitized.append(entry)
	return sanitized

static func _is_prospect_target_template(template: Resource, prospect_targets: PackedStringArray) -> bool:
	if template is not FeatureCard:
		return false
	return _is_prospect_target_card(template as FeatureCard, prospect_targets)

static func _is_prospect_target_card(card: FeatureCard, prospect_targets: PackedStringArray) -> bool:
	if card == null or prospect_targets.is_empty():
		return false
	return prospect_targets.has(_normalize_feature_name(card.feature_name))

static func _normalize_feature_name(raw: String) -> String:
	return raw.to_lower().strip_edges().replace(" ", "_").replace("-", "_")

static func _commit_card_variant(
	template: Resource,
	backlog_cards: Array[Resource],
	selected_cards: Array[FeatureCard],
	result: DailyOfferResult,
) -> void:
	var variant: FeatureCard = template.duplicate(false) as FeatureCard
	if variant == null:
		return
	backlog_cards.append(variant)
	selected_cards.append(variant)
	if not template.resource_path.is_empty():
		result.offered_paths.append(template.resource_path)

static func refresh_backlog_list(card_list: VBoxContainer, backlog_cards: Array[Resource], card_widget_scene: PackedScene, origin: String = "backlog") -> void:
	for child in card_list.get_children():
		child.queue_free()
	var stagger_index: int = 0
	for card in backlog_cards:
		var widget: Control = card_widget_scene.instantiate() as Control
		widget.set_feature_card(card)
		if widget.has_method("set_drag_origin"):
			widget.set_drag_origin(origin)
		widget.modulate = Color(1.0, 1.0, 1.0, 0.0)
		card_list.add_child(widget)
		var t: Tween = widget.create_tween()
		t.set_ease(Tween.EASE_OUT)
		t.set_trans(Tween.TRANS_QUAD)
		t.tween_interval(stagger_index * 0.07)
		t.tween_property(widget, "modulate", Color.WHITE, 0.18)
		stagger_index += 1

static func _load_cards_from_directory(cards: Array[Resource], directory_path: String, is_custom_directory: bool, append_log: Callable) -> Array[Resource]:
	var out_cards: Array[Resource] = cards.duplicate()
	var directory: DirAccess = DirAccess.open(directory_path)
	if directory == null:
		if not is_custom_directory:
			append_log.call("No feature cards found at %s" % directory_path)
		return out_cards

	directory.list_dir_begin()
	var file_name: String = directory.get_next()
	while file_name != "":
		if not directory.current_is_dir() and _is_card_resource_file(file_name):
			if is_custom_directory and _is_custom_template_file(file_name):
				file_name = directory.get_next()
				continue

			var load_path: String = _resolve_card_resource_path(directory_path, file_name)
			if load_path.is_empty():
				file_name = directory.get_next()
				continue

			var loaded: Resource = load(load_path)
			if loaded == null:
				push_warning("Skipping card at %s: failed to load resource." % load_path)
				file_name = directory.get_next()
				continue

			if loaded is not FeatureCard:
				push_warning("Skipping card at %s: resource is not FeatureCard." % load_path)
				file_name = directory.get_next()
				continue

			var feature_card: FeatureCard = loaded as FeatureCard
			if feature_card.feature_name.strip_edges().is_empty():
				push_warning("Skipping card at %s: missing feature_name." % load_path)
				file_name = directory.get_next()
				continue

			if feature_card.tags.is_empty():
				push_warning("Skipping card at %s: card must have at least one tag." % load_path)
				file_name = directory.get_next()
				continue

			out_cards.append(feature_card)
		file_name = directory.get_next()
	directory.list_dir_end()
	return out_cards

static func _is_card_resource_file(file_name: String) -> bool:
	return file_name.ends_with(".tres") or file_name.ends_with(".res") or file_name.ends_with(".tres.remap") or file_name.ends_with(".res.remap")

static func _is_custom_template_file(file_name: String) -> bool:
	var lower_name: String = file_name.to_lower()
	return lower_name.contains("template") or lower_name.begins_with("readme") or lower_name.begins_with("tutorial")

static func _resolve_card_resource_path(directory_path: String, file_name: String) -> String:
	if file_name.ends_with(".tres.remap") or file_name.ends_with(".res.remap"):
		return "%s/%s" % [directory_path, file_name.trim_suffix(".remap")]
	if file_name.ends_with(".tres") or file_name.ends_with(".res"):
		return "%s/%s" % [directory_path, file_name]
	return ""

static func apply_prospect_highlights(
		card_list: Control,
		targets: PackedStringArray,
		jank_name: String) -> void:
	for child: Node in card_list.get_children():
		if child is not FeatureCardWidget:
			continue
		var widget: FeatureCardWidget = child as FeatureCardWidget
		if widget.feature_card is not FeatureCard:
			continue
		var fc: FeatureCard = widget.feature_card as FeatureCard
		var normalized: String = _normalize_feature_name(fc.feature_name)
		if targets.has(normalized):
			widget.apply_prospect_target_style(jank_name)
		else:
			widget.clear_prospect_target_style()
