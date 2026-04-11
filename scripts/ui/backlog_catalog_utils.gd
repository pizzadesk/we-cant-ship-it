const ON_ARCHETYPE_OFFER_WEIGHT: float = 12.0
const UNIVERSAL_OFFER_WEIGHT: float = 10.0
const GENRE_STRETCH_OFFER_WEIGHT: float = 3.0
const WILD_SWING_OFFER_WEIGHT: float = 1.0
const ALIEN_OFFER_WEIGHT: float = 0.35

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
	already_offered_paths: PackedStringArray = PackedStringArray()
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
	if game_state != null and game_state.has_method("get_chosen_archetype"):
		chosen_archetype = String(game_state.get_chosen_archetype())

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
			if not already_offered_paths.has(template.resource_path):
				available_templates.append(template)
		if available_templates.size() < daily_visible_cards:
			# Pool nearly or fully exhausted — wrap to the full eligible pool.
			available_templates = eligible_templates.duplicate()
			result.pool_reset = true
	else:
		available_templates = eligible_templates.duplicate()

	var backlog_cards: Array[Resource] = []
	if runway_today <= 0 or available_templates.is_empty():
		result.backlog_cards = backlog_cards
		result.last_offer_runway_day = runway_today
		return result

	var visible_count: int = mini(daily_visible_cards, available_templates.size())
	for _pick in range(visible_count):
		var pick_index: int = _pick_weighted_template_index(available_templates, chosen_archetype, ui_rng)
		if pick_index < 0:
			break
		var template: Resource = available_templates[pick_index]
		available_templates.remove_at(pick_index)

		var variant: FeatureCard = template.duplicate(false) as FeatureCard
		if variant == null:
			continue
		backlog_cards.append(variant)
		if not template.resource_path.is_empty():
			result.offered_paths.append(template.resource_path)

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

static func _pick_weighted_template_index(templates: Array[Resource], chosen_archetype: String, ui_rng: RandomNumberGenerator) -> int:
	if templates.is_empty():
		return -1
	var total_weight: float = 0.0
	var weights: Array[float] = []
	for template in templates:
		var weight: float = 1.0
		if template is FeatureCard:
			weight = _offer_weight_for_archetype(template as FeatureCard, chosen_archetype)
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

static func _offer_weight_for_archetype(card: FeatureCard, chosen_archetype: String) -> float:
	if card == null or chosen_archetype.is_empty():
		return 1.0
	var affinity_count: int = card.archetype_affinity.size()
	if affinity_count >= 3:
		return UNIVERSAL_OFFER_WEIGHT
	if affinity_count > 0 and card.archetype_affinity.has(chosen_archetype):
		return ON_ARCHETYPE_OFFER_WEIGHT
	match affinity_count:
		0:
			return ALIEN_OFFER_WEIGHT
		1:
			return WILD_SWING_OFFER_WEIGHT
		2:
			return GENRE_STRETCH_OFFER_WEIGHT
		_:
			return UNIVERSAL_OFFER_WEIGHT

static func refresh_backlog_list(card_list: VBoxContainer, backlog_cards: Array[Resource], card_widget_scene: PackedScene, origin: String = "backlog") -> void:
	for child in card_list.get_children():
		child.queue_free()
	for card in backlog_cards:
		var widget: Control = card_widget_scene.instantiate() as Control
		widget.set_feature_card(card)
		if widget.has_method("set_drag_origin"):
			widget.set_drag_origin(origin)
		card_list.add_child(widget)

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
