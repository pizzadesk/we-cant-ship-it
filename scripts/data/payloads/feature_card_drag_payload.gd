extends RefCounted
class_name FeatureCardDragPayload

const PAYLOAD_TYPE: String = "feature_card"

var card: Resource = null
var origin_zone: String = "backlog"

static func from_variant(data: Variant) -> FeatureCardDragPayload:
	var payload: FeatureCardDragPayload = FeatureCardDragPayload.new()
	if data is not Dictionary:
		return payload
	payload.card = data.get("card", null)
	payload.origin_zone = String(data.get("origin_zone", "backlog"))
	return payload

func is_valid() -> bool:
	return card != null

func to_dictionary() -> Dictionary:
	return {
		"type": PAYLOAD_TYPE,
		"card": card,
		"origin_zone": origin_zone,
	}

static func matches_variant(data: Variant) -> bool:
	return data is Dictionary and String(data.get("type", "")) == PAYLOAD_TYPE
