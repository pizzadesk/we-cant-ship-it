extends Node

const EndingResolver = preload("res://scripts/data/ending_resolver.gd")

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

func generate_reviews(critic_score: float, instability: int, soul: int, features_shipped: int, shipped_cards: Array[FeatureCard] = [], ship_window_label: String = "", ending_id: String = "") -> Array[Dictionary]:
	if features_shipped <= 0:
		return _generate_unrateable_reviews()
	var normalized_ending: String = EndingResolver.normalize_ending_id(ending_id)
	var context: Dictionary = _extract_shipped_context(shipped_cards)
	var reviews: Array[Dictionary] = []
	reviews.append(_generate_ign_review(critic_score, instability, soul, context, normalized_ending, ship_window_label))
	reviews.append(_generate_forum_review(critic_score, soul, instability, context, normalized_ending, ship_window_label))
	reviews.append(_generate_steam_review(critic_score, features_shipped, soul, instability, context, normalized_ending, ship_window_label))
	reviews.append(_generate_indie_blog_review(critic_score, soul, instability, ship_window_label, context, normalized_ending))
	return reviews

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

func _generate_ign_review(critic_score: float, instability: int, soul: int, context: Dictionary = {}, ending: String = "", ship_window_label: String = "") -> Dictionary:
	var archetype: Dictionary = _get_archetype("ign")
	var ratio: float = float(soul) / float(instability + 1)
	var displayed_score: float = clampf(
		critic_score + _ending_score_bias(ending, "ign") + _ratio_score_bias(ratio, "ign"),
		1.0,
		10.0
	)
	var bug_callout: String
	if ratio >= 1.0:
		bug_callout = "bugs that become accidental features"
	elif ratio < 0.4:
		bug_callout = "bugs that undermine what could have been"
	else:
		bug_callout = "rough edges that won't leave the mind"
	var opener: String = _pick_weighted_text(archetype.get("openers", []), "Promising ambition")
	var closer: String = _pick_weighted_text(archetype.get("closers", []), "You can feel the rough edges in every quest.")
	var release_frame: String = _build_release_frame(ending, ship_window_label)
	var callout: String = _pick_contextual_callout(archetype, context)
	return {
		"author": String(archetype.get("author", "IGN-ish")),
		"score": "%.1f/10" % displayed_score,
		"text": _compose_sentences([
			opener,
			"%s, %s" % [release_frame, bug_callout],
			callout,
			closer,
		])
	}

func _generate_forum_review(critic_score: float, soul: int, instability: int, context: Dictionary = {}, ending: String = "", ship_window_label: String = "") -> Dictionary:
	var archetype: Dictionary = _get_archetype("fan_forum")
	var ratio: float = float(soul) / float(instability + 1)
	var score_value: int = clampi(
		int(round((critic_score * 10.0) + _ending_score_bias(ending, "forum") + _ratio_forum_bonus(ratio))),
		18,
		100
	)
	if ratio >= 1.0:
		score_value = min(score_value + 6, 100)
	elif ratio >= 0.4:
		score_value = min(score_value + 2, 100)
	var opener: String = _pick_weighted_text(archetype.get("openers", []), "Thread title: Horse bug hall of fame")
	var closer: String = _pick_weighted_text(archetype.get("closers", []), "Never patch the sideways gallop glitch.")
	var callout: String = _pick_contextual_callout(archetype, context)
	return {
		"author": String(archetype.get("author", "Obsessive Forum User")),
		"score": "%d/100" % score_value,
		"text": _compose_sentences([
			opener,
			_build_forum_release_frame(ending, ship_window_label),
			callout,
			closer,
		])
	}

func _generate_steam_review(critic_score: float, features_shipped: int, soul: int, instability: int, context: Dictionary = {}, ending: String = "", ship_window_label: String = "") -> Dictionary:
	var archetype: Dictionary = _get_archetype("steam")
	var ratio: float = float(soul) / float(instability + 1)
	var played_hours: int = max(features_shipped * 120, 240)
	var callout: String = _pick_contextual_callout(archetype, context)
	var body: String
	if not callout.is_empty() and _rng.randi_range(0, 1) == 0:
		body = callout
	else:
		body = _pick_weighted_text(archetype.get("entries", []), "yes")
	var ratio_note: String = ""
	if ratio >= 1.0:
		ratio_note = "jank is plot"
	elif ratio < 0.4:
		ratio_note = "took 200hrs to figure out if this was intentional. still unclear"
	var recommendation: String = "Recommended" if _steam_recommends(critic_score, ratio, ending) else "Not Recommended"
	return {
		"author": String(archetype.get("author", "Steam User")),
		"score": recommendation,
		"text": "%s (%d hours played)" % [
			_compose_sentences([
				body,
				ratio_note,
				_build_steam_release_frame(ending, ship_window_label),
			]),
			played_hours,
		]
	}

func _generate_indie_blog_review(critic_score: float, soul: int, instability: int, ship_window_label: String, context: Dictionary = {}, ending: String = "") -> Dictionary:
	var archetype: Dictionary = _get_archetype("indie_blog")
	var ratio: float = float(soul) / float(instability + 1)
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
	var callout: String = _pick_contextual_callout(archetype, context)
	var release_frame: String = _build_release_frame(ending, ship_window_label)
	return {
		"author": String(archetype.get("author", "Indie Orbit")),
		"score": "%.1f/10" % clampf(critic_score + score_offset + _ending_score_bias(ending, "blog"), 1.0, 10.0),
		"text": _compose_sentences([
			opener,
			release_frame,
			_build_indie_tone_line(tone),
			callout,
			closer,
		])
	}

func _generate_unrateable_reviews() -> Array[Dictionary]:
	return [
		{
			"author": "MegaScore Weekly",
			"score": "1.0/10",
			"text": "There is no shipped game here, only an intention. Critics can review ambition; they cannot review an empty build."
		},
		{
			"author": "HorseQuestFanForum user #8841",
			"score": "18/100",
			"text": "Thread title: where is the game. We respect the bit, but you do need to ship at least one thing."
		},
		{
			"author": "steam_user_2000h",
			"score": "Not Recommended",
			"text": "booted to title. that was the whole experience. (240 hours played)"
		},
		{
			"author": "Indie Orbit",
			"score": "1.2/10",
			"text": "A non-release framed as a release. The studio's sincerity is not in doubt; the shipped work is."
		}
	]

func _get_archetype(key: String) -> Dictionary:
	var archetypes: Dictionary = _pools.get("archetypes", {})
	return archetypes.get(key, {})

func _build_release_frame(ending: String, ship_window_label: String) -> String:
	var ending_phrase: String
	match ending:
		EndingResolver.DEFINING_GAME_ID:
			ending_phrase = "Against the odds, the studio shipped something singular"
		EndingResolver.LEGENDARY_JANK_ID:
			ending_phrase = "The release is half-broken and instantly memorable"
		EndingResolver.SURPRISE_HIT_ID:
			ending_phrase = "The smaller swing landed with real affection"
		EndingResolver.PRESTIGE_COLLAPSE_ID:
			ending_phrase = "The scale is obvious, but the heart never fully arrives"
		_:
			ending_phrase = "The studio shipped something that survives contact with the public"
	var window_phrase: String = ""
	match ship_window_label:
		"Sweet Spot":
			window_phrase = "; it hit the sweet spot and people could feel the controlled chaos"
		"Too Early":
			window_phrase = "; it arrived too early, before the rough edges could become culture"
		"Last-Minute Panic":
			window_phrase = "; it shipped in full panic mode, and the seams show"
		_:
			window_phrase = ""
	return ending_phrase + window_phrase

func _build_forum_release_frame(ending: String, ship_window_label: String) -> String:
	var ending_phrase: String
	match ending:
		EndingResolver.DEFINING_GAME_ID:
			ending_phrase = "they actually shipped something singular"
		EndingResolver.LEGENDARY_JANK_ID:
			ending_phrase = "they shipped a glorious wreck"
		EndingResolver.SURPRISE_HIT_ID:
			ending_phrase = "they aimed smaller and still landed it"
		EndingResolver.PRESTIGE_COLLAPSE_ID:
			ending_phrase = "they overscoped it and forgot the pulse"
		_:
			ending_phrase = "they shipped it and now everyone has opinions"
	var window_phrase: String = ""
	match ship_window_label:
		"Sweet Spot":
			window_phrase = "; chaos level was exactly correct"
		"Too Early":
			window_phrase = "; definitely shipped too early"
		"Last-Minute Panic":
			window_phrase = "; panic build energy off the charts"
		_:
			window_phrase = ""
	return ending_phrase + window_phrase

func _build_steam_release_frame(ending: String, ship_window_label: String) -> String:
	var ending_phrase: String
	match ending:
		EndingResolver.DEFINING_GAME_ID:
			ending_phrase = "somehow they shipped something singular"
		EndingResolver.LEGENDARY_JANK_ID:
			ending_phrase = "half broken. unforgettable"
		EndingResolver.SURPRISE_HIT_ID:
			ending_phrase = "small swing. landed"
		EndingResolver.PRESTIGE_COLLAPSE_ID:
			ending_phrase = "big budget feelings. no pulse"
		_:
			ending_phrase = "it shipped. people are arguing"
	var window_phrase: String = ""
	match ship_window_label:
		"Sweet Spot":
			window_phrase = " hit the sweet spot too"
		"Too Early":
			window_phrase = " shipped too early though"
		"Last-Minute Panic":
			window_phrase = " panic build for sure"
		_:
			window_phrase = ""
	return ending_phrase + window_phrase

func _build_indie_tone_line(tone: String) -> String:
	match tone:
		"sincere":
			return "It feels sincere in the places that matter."
		"hollow":
			return "It feels hollow in a way the bug count cannot hide."
		_:
			return "It feels chaotic, but never anonymous."

func _ending_score_bias(ending: String, outlet: String) -> float:
	match outlet:
		"ign":
			match ending:
				EndingResolver.DEFINING_GAME_ID: return 0.4
				EndingResolver.LEGENDARY_JANK_ID: return 0.2
				EndingResolver.SURPRISE_HIT_ID: return 0.3
				EndingResolver.PRESTIGE_COLLAPSE_ID: return -0.5
				_: return -0.2
		"forum":
			match ending:
				EndingResolver.DEFINING_GAME_ID: return 12.0
				EndingResolver.LEGENDARY_JANK_ID: return 16.0
				EndingResolver.SURPRISE_HIT_ID: return 10.0
				EndingResolver.PRESTIGE_COLLAPSE_ID: return -10.0
				_: return -4.0
		"blog":
			match ending:
				EndingResolver.DEFINING_GAME_ID: return 0.5
				EndingResolver.LEGENDARY_JANK_ID: return 0.3
				EndingResolver.SURPRISE_HIT_ID: return 0.4
				EndingResolver.PRESTIGE_COLLAPSE_ID: return -0.4
				_: return -0.1
		_:
			return 0.0

func _ratio_score_bias(ratio: float, outlet: String) -> float:
	if outlet != "ign":
		return 0.0
	if ratio >= 1.0:
		return 0.2
	if ratio < 0.4:
		return -0.4
	return 0.0

func _ratio_forum_bonus(ratio: float) -> float:
	if ratio >= 1.0:
		return 8.0
	if ratio >= 0.4:
		return 3.0
	return -6.0

func _steam_recommends(critic_score: float, ratio: float, ending: String) -> bool:
	if ending == EndingResolver.PRESTIGE_COLLAPSE_ID:
		return false
	if ending == EndingResolver.DEFINING_GAME_ID or ending == EndingResolver.LEGENDARY_JANK_ID:
		return true
	if critic_score >= 5.6:
		return true
	if ratio >= 1.0 and critic_score >= 4.8:
		return true
	return false

# Builds a lookup of which tags are present in shipped cards and which feature names carry each tag.
func _extract_shipped_context(shipped_cards: Array[FeatureCard]) -> Dictionary:
	var tags_present: Array = []
	var names_by_tag: Dictionary = {}
	var matched_flavors: Array[String] = []
	var seen_flavors: Dictionary = {}
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
					if seen_flavors.has(flavor):
						continue
					seen_flavors[flavor] = true
					matched_flavors.append(flavor)

	return {
		"tags": tags_present,
		"names_by_tag": names_by_tag,
		"matched_flavors": matched_flavors,
	}

# Picks a tag_callout sentence from the archetype that matches the shipped card set.
# Shuffles tag order for variety; substitutes {feature_name} with a random matching card name.
func _pick_contextual_callout(archetype: Dictionary, context: Dictionary) -> String:
	var tag_callouts: Dictionary = archetype.get("tag_callouts", {})
	if context.is_empty():
		return ""
	var matched_flavors: Array = context.get("matched_flavors", [])
	if not matched_flavors.is_empty():
		return String(matched_flavors[_rng.randi_range(0, matched_flavors.size() - 1)])
	if tag_callouts.is_empty():
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

func _compose_sentences(parts: Array) -> String:
	var rendered: PackedStringArray = PackedStringArray()
	for part in parts:
		var text: String = String(part).strip_edges()
		if text.is_empty():
			continue
		if not _ends_with_sentence_punctuation(text):
			text += "."
		rendered.append(text)
	return " ".join(rendered)

func _ends_with_sentence_punctuation(text: String) -> bool:
	return text.ends_with(".") or text.ends_with("!") or text.ends_with("?")
