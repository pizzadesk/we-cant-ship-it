extends Node

const REVIEW_POOLS_PATH: String = "res://data/review_pools.json"
const INTERACTION_RULES_PATH: String = "res://data/interaction_rules.json"

var _pools: Dictionary = {}
var _interaction_rules: Dictionary = {}
var _rules_by_pair: Dictionary = {}
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	_load_pools()
	_load_interaction_rules()

func generate_reviews(critic_score: float, instability: int, soul: int, features_shipped: int, shipped_cards: Array[FeatureCard] = [], run_identity: String = "", ship_window_label: String = "") -> Array[Dictionary]:
	var context: Dictionary = _extract_shipped_context(shipped_cards)
	var reviews: Array[Dictionary] = []
	reviews.append(_generate_ign_review(critic_score, instability, soul, context))
	reviews.append(_generate_forum_review(soul, instability, context))
	reviews.append(_generate_steam_review(features_shipped, soul, instability, context))
	reviews.append(_generate_indie_blog_review(critic_score, soul, instability, run_identity, ship_window_label, context))
	return reviews

func generate_mechanics_highlights(shipped_cards: Array[FeatureCard]) -> Array[String]:
	var highlights: Array[String] = []
	var seen_highlights: Dictionary = {}
	if shipped_cards.is_empty():
		return highlights

	if _rules_by_pair.is_empty():
		return highlights

	for i in range(shipped_cards.size()):
		if shipped_cards[i] is not FeatureCard:
			continue
		var card_a: FeatureCard = shipped_cards[i] as FeatureCard
		for j in range(i + 1, shipped_cards.size()):
			if shipped_cards[j] is not FeatureCard:
				continue
			var card_b: FeatureCard = shipped_cards[j] as FeatureCard

			for tag_a in card_a.tags:
				for tag_b in card_b.tags:
					var rule: Dictionary = _get_rule_for_pair(String(tag_a), String(tag_b))
					if rule.is_empty():
						continue
					var flavors: Array = rule.get("flavors", [])
					if flavors.is_empty():
						continue
					var flavor: String = String(flavors[_rng.randi_range(0, flavors.size() - 1)])
					flavor = flavor.replace("{tag_a}", String(tag_a))
					flavor = flavor.replace("{tag_b}", String(tag_b))
					flavor = flavor.replace("{new_feature}", card_a.feature_name)
					flavor = flavor.replace("{existing_feature}", card_b.feature_name)
					if seen_highlights.has(flavor):
						continue
					seen_highlights[flavor] = true
					highlights.append(flavor)

	return highlights

func _load_pools() -> void:
	_pools = _load_json_file(REVIEW_POOLS_PATH, "Review pools")

func _load_interaction_rules() -> void:
	_interaction_rules = _load_json_file(INTERACTION_RULES_PATH, "Interaction rules")
	_index_interaction_rules()

func _index_interaction_rules() -> void:
	_rules_by_pair.clear()
	var rules: Array = _interaction_rules.get("rules", [])
	for rule in rules:
		if rule is not Dictionary:
			continue
		var tags: Array = rule.get("tags", [])
		if tags.size() != 2:
			continue
		var tag_a: String = String(tags[0])
		var tag_b: String = String(tags[1])
		_rules_by_pair["%s|%s" % [tag_a, tag_b]] = rule
		_rules_by_pair["%s|%s" % [tag_b, tag_a]] = rule

func _get_rule_for_pair(tag_a: String, tag_b: String) -> Dictionary:
	return _rules_by_pair.get("%s|%s" % [tag_a, tag_b], {})

func _load_json_file(path: String, file_label: String) -> Dictionary:
	return JsonDataLoader.load_dictionary(path, file_label)

func _generate_ign_review(critic_score: float, instability: int, soul: int, context: Dictionary = {}) -> Dictionary:
	var archetype: Dictionary = _get_archetype("ign")
	# soul/instability ratio determines how IGN frames the jank
	var ratio: float = float(soul) / float(instability + 1)
	var score_min: float = float(archetype.get("score_min", 6.0))
	var score_max: float = float(archetype.get("score_max", 7.5))
	var bug_callout: String
	if ratio >= 1.0:
		# heartful jank: IGN is charmed, gives a little more ceiling
		score_max = minf(score_max + 0.5, 8.0)
		bug_callout = "bugs that become accidental features"
	elif ratio < 0.4:
		# soulless jank: IGN is disappointed, ceiling tightens
		score_max = maxf(score_max - 0.5, 6.0)
		bug_callout = "bugs that undermine what could have been"
	else:
		# volatile: ambivalent, arrested by the rough edges
		bug_callout = "rough edges that won't leave the mind"
	var clamped_score: float = clampf(critic_score, score_min, score_max)
	var opener: String = _pick_weighted_text(archetype.get("openers", []), "Promising ambition")
	var closer: String = _pick_weighted_text(archetype.get("closers", []), "You can feel the rough edges in every quest.")
	var base: String = "%s, %s." % [opener, bug_callout]
	var callout: String = _pick_contextual_callout(archetype, context)
	if not callout.is_empty():
		base += " %s" % callout
	return {
		"author": String(archetype.get("author", "IGN-ish")),
		"score": "%.1f/10" % clamped_score,
		"text": "%s %s" % [base, closer]
	}

func _generate_forum_review(soul: int, instability: int, context: Dictionary = {}) -> Dictionary:
	var archetype: Dictionary = _get_archetype("fan_forum")
	var ratio: float = float(soul) / float(instability + 1)
	var score_value: int = int(archetype.get("score", 94))
	# Forum obsessives love heartful jank most — they can tell when the studio believed in it
	if ratio >= 1.0:
		score_value = min(score_value + 3, 100)
	elif ratio >= 0.4:
		score_value = min(score_value + 1, 100)
	# soulless jank (ratio < 0.4): base score, the forum still loves it but with less conviction
	var opener: String = _pick_weighted_text(archetype.get("openers", []), "Thread title: Horse bug hall of fame")
	var closer: String = _pick_weighted_text(archetype.get("closers", []), "Never patch the sideways gallop glitch.")
	var callout: String = _pick_contextual_callout(archetype, context)
	var text: String = "%s. %s %s" % [opener, callout, closer] if not callout.is_empty() else "%s. %s" % [opener, closer]
	return {
		"author": String(archetype.get("author", "Obsessive Forum User")),
		"score": "%d/100" % score_value,
		"text": text
	}

func _generate_steam_review(features_shipped: int, soul: int, instability: int, context: Dictionary = {}) -> Dictionary:
	var archetype: Dictionary = _get_archetype("steam")
	var ratio: float = float(soul) / float(instability + 1)
	var played_hours: int = max(features_shipped * 120, 240)
	var callout: String = _pick_contextual_callout(archetype, context)
	var body: String
	if not callout.is_empty() and _rng.randi_range(0, 1) == 0:
		body = callout
	else:
		body = _pick_weighted_text(archetype.get("entries", []), "yes")
	# Append a soul-ratio flavour fragment — Steam reviewers cut to the bone
	if ratio >= 1.0:
		body = "%s. jank is plot" % body.rstrip(".")
	elif ratio < 0.4:
		body = "%s. took 200hrs to figure out if this was intentional. still unclear" % body.rstrip(".")
	# volatile ratio: no suffix — pure cryptic Steam brevity
	return {
		"author": String(archetype.get("author", "Steam User")),
		"score": "Recommended",
		"text": "%s (%d hours played)" % [body, played_hours]
	}

func _generate_indie_blog_review(critic_score: float, soul: int, instability: int, run_identity: String, ship_window_label: String, context: Dictionary = {}) -> Dictionary:
	var archetype: Dictionary = _get_archetype("indie_blog")
	var ratio: float = float(soul) / float(instability + 1)
	# Three distinct Indie Orbit personas based on soul/instability ratio:
	# sincere (>=1.0): the jank is backed by genuine creative conviction — they celebrate it
	# chaotic (0.4-1.0): volatile energy, intrigued but unsettled
	# hollow (<0.4): jank without heart — the blog is critical about emptiness
	var tone: String
	var score_offset: float
	if ratio >= 1.0:
		tone = "sincere"
		score_offset = 1.0
	elif ratio < 0.4:
		tone = "hollow"
		score_offset = -0.5
	else:
		tone = "chaotic"
		score_offset = 0.5
	var opener: String = _pick_weighted_text(archetype.get("openers", []), "A fascinating mess")
	var closer: String = _pick_weighted_text(archetype.get("closers", []), "It is hard to stop thinking about this one.")
	var identity_note: String = ""
	if not run_identity.is_empty() and run_identity != "Unformed":
		identity_note = " Build identity: %s." % run_identity
	var window_note: String = ""
	if not ship_window_label.is_empty():
		window_note = " Release window: %s." % ship_window_label
	var callout: String = _pick_contextual_callout(archetype, context)
	var callout_note: String = " %s" % callout if not callout.is_empty() else ""
	return {
		"author": String(archetype.get("author", "Indie Orbit")),
		"score": "%.1f/10" % clampf(critic_score + score_offset, 1.0, 10.0),
		"text": "%s that feels %s.%s %s%s%s" % [opener, tone, callout_note, closer, identity_note, window_note]
	}

func _get_archetype(key: String) -> Dictionary:
	var archetypes: Dictionary = _pools.get("archetypes", {})
	return archetypes.get(key, {})

# Builds a lookup of which tags are present in shipped cards and which feature names carry each tag.
func _extract_shipped_context(shipped_cards: Array[FeatureCard]) -> Dictionary:
	var tags_present: Array = []
	var names_by_tag: Dictionary = {}
	for card in shipped_cards:
		if card is not FeatureCard:
			continue
		var fc: FeatureCard = card as FeatureCard
		for raw_tag in fc.tags:
			var tag: String = String(raw_tag)
			if not tags_present.has(tag):
				tags_present.append(tag)
			if not names_by_tag.has(tag):
				names_by_tag[tag] = []
			names_by_tag[tag].append(fc.feature_name)
	return {"tags": tags_present, "names_by_tag": names_by_tag}

# Picks a tag_callout sentence from the archetype that matches the shipped card set.
# Shuffles tag order for variety; substitutes {feature_name} with a random matching card name.
func _pick_contextual_callout(archetype: Dictionary, context: Dictionary) -> String:
	var tag_callouts: Dictionary = archetype.get("tag_callouts", {})
	if tag_callouts.is_empty() or context.is_empty():
		return ""
	var tags_present: Array = context.get("tags", [])
	var names_by_tag: Dictionary = context.get("names_by_tag", {})
	var shuffled: Array = tags_present.duplicate()
	shuffled.shuffle()
	for raw_tag in shuffled:
		var tag: String = String(raw_tag)
		if not tag_callouts.has(tag):
			continue
		var text: String = _pick_weighted_text(tag_callouts[tag], "")
		if text.is_empty():
			continue
		var names: Array = names_by_tag.get(tag, [])
		if not names.is_empty():
			text = text.replace("{feature_name}", String(names[_rng.randi_range(0, names.size() - 1)]))
		return text
	return ""

func _pick_weighted_text(entries: Variant, fallback: String) -> String:
	if entries is not Array or entries.is_empty():
		return fallback

	var total_weight: int = 0
	for entry in entries:
		if entry is Dictionary:
			total_weight += int(entry.get("weight", 1))

	if total_weight <= 0:
		return fallback

	var roll: int = _rng.randi_range(1, total_weight)
	var running: int = 0
	for entry in entries:
		if entry is Dictionary:
			running += int(entry.get("weight", 1))
			if roll <= running:
				return String(entry.get("text", fallback))

	return fallback
