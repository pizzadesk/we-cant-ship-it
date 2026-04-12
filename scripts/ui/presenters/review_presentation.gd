const ReviewMarkupUtils = preload("res://scripts/ui/review_markup_utils.gd")
const _S = preload("res://scripts/ui/ui_strings.gd")

static func build_review_fallout_text(results: Dictionary) -> String:
	var review_lines: PackedStringArray = []
	review_lines.append(_S.get_string("popups", "review_roulette_header") + "\n")
	var ending: String = String(results.get("ending", "Shipped Something"))
	var review_score: float = float(results.get("review_score", 0.0))
	review_lines.append(_build_review_intro(ending, review_score))
	review_lines.append("")

	var reviews: Array = results.get("reviews", [])
	for review in reviews:
		if review is Dictionary:
			var author: String = ReviewMarkupUtils.normalize_review_markup(String(review.get("author", "Reviewer")))
			var score: String = ReviewMarkupUtils.normalize_review_markup(String(review.get("score", "?")))
			var body: String = ReviewMarkupUtils.normalize_review_markup(String(review.get("text", "")))
			review_lines.append("[b]%s[/b] [%s]" % [author, score])
			review_lines.append(body)
			review_lines.append("")
	return "\n".join(review_lines)

static func build_review_roulette_text(results: Dictionary) -> String:
	return build_review_fallout_text(results)

static func _build_review_intro(ending: String, review_score: float) -> String:
	var intro_key: String = "roulette_intro_" + _ending_key(ending)
	if _S.has_key("popups", intro_key):
		return _S.get_string("popups", intro_key)
	if review_score >= 7.0:
		return _S.get_string("popups", "roulette_intro_high_score")
	if review_score <= 3.0:
		return _S.get_string("popups", "roulette_intro_low_score")
	return _S.get_string("popups", "roulette_intro_default")

static func _ending_key(ending: String) -> String:
	return _extract_ending_name(ending).to_lower().replace(" ", "_")

static func _extract_ending_name(ending: String) -> String:
	if ending.contains(":"):
		return String(ending.split(":", false, 1)[0]).strip_edges()
	return ending.strip_edges()
