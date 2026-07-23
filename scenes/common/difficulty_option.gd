@tool
extends Button
## A single difficulty choice, shown as 1..N star icons.
## Meant to be used inside a DifficultySelector (toggle + ButtonGroup are set
## by the selector). Kept generic so other games can reuse it.

const STAR_TEXTURE := preload("res://assets/star.png")

## How many stars this option displays.
@export var stars: int = 1:
	set(value):
		stars = maxi(1, value)
		_rebuild()

@onready var _stars: HBoxContainer = %Stars


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_node_ready():
		return
	# Pull stars closer together as their count grows so they stay within the
	# option's width. Negative separation lets them slightly overlap.
	_stars.add_theme_constant_override("separation", -10 if stars >= 4 else 6)
	for child in _stars.get_children():
		child.queue_free()
	for _i in stars:
		var star := TextureRect.new()
		star.texture = STAR_TEXTURE
		star.custom_minimum_size = Vector2(40, 40)
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_stars.add_child(star)
