extends RefCounted
class_name DailyOfferResult

var backlog_cards: Array[Resource] = []
var last_offer_runway_day: int = -1
var unchanged: bool = false
var offered_paths: PackedStringArray = PackedStringArray()
var pool_reset: bool = false
