extends RefCounted
class_name ReviewsGeneratedPayload

var review_score: float = 0.0
var ending: String = ""
var mechanics_highlights: Array[String] = []
var raw_results: Dictionary = {}

static func from_dictionary(results: Dictionary) -> ReviewsGeneratedPayload:
	var payload: ReviewsGeneratedPayload = ReviewsGeneratedPayload.new()
	payload.raw_results = results.duplicate(true)
	payload.review_score = float(results.get("review_score", 0.0))
	payload.ending = String(results.get("ending", ""))

	var raw_highlights: Variant = results.get("mechanics_highlights", [])
	if raw_highlights is Array:
		for item in raw_highlights:
			payload.mechanics_highlights.append(String(item))
	return payload

func to_dictionary() -> Dictionary:
	return raw_results.duplicate(true)
