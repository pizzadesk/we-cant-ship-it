extends ScrollContainer
class_name BacklogDropZone

signal card_dropped_to_backlog(data: Dictionary)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("type", "") == "feature_card"

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(_at_position, data):
		return
	card_dropped_to_backlog.emit(data)