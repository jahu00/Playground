extends Panel
## An empty slot in the middle row of the Letters game. Accepts a dragged
## image card; the game controller decides whether the drop is a match.

signal card_dropped(slot: Panel, card: Control)

## The letter shown on the letter card directly below this slot.
var letter: String = ""
## The image card currently resting in this slot, if any.
var occupant: Control = null


func can_accept() -> bool:
	return occupant == null


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return occupant == null and data is Dictionary and data.has("card")


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	card_dropped.emit(self, data["card"])
