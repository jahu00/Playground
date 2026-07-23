@tool
extends VBoxContainer
## Reusable difficulty picker. Shows N options (1..levels stars) and tracks
## the selected difficulty. Emits `difficulty_changed` when the choice changes.

signal difficulty_changed(difficulty: int)

const DifficultyOption := preload("res://scenes/difficulty_option.tscn")

## Number of difficulty levels to offer.
@export var levels: int = 3:
	set(value):
		levels = maxi(1, value)
		_rebuild()

## Currently selected difficulty (1-based).
var selected_difficulty: int = 1

@onready var _options: HBoxContainer = %Options

var _button_group: ButtonGroup


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_node_ready():
		return
	for child in _options.get_children():
		child.queue_free()

	_button_group = ButtonGroup.new()
	for level in range(1, levels + 1):
		var option := DifficultyOption.instantiate()
		option.stars = level
		option.button_group = _button_group
		if level == selected_difficulty:
			option.button_pressed = true
		option.pressed.connect(_on_option_pressed.bind(level))
		_options.add_child(option)


func _on_option_pressed(level: int) -> void:
	selected_difficulty = level
	difficulty_changed.emit(level)
