extends Control
## Setup screen for the Memory game: pick a difficulty, then pick an image set.
## Selecting an image set starts the game with the chosen difficulty.

const GameIcon := preload("res://scenes/game_icon.tscn")

## Available image sets. `dir` points at the folder of card images; `preview`
## is the icon shown for the set on this screen.
const IMAGE_SETS: Array[Dictionary] = [
	{
		"name": "Fruits",
		"dir": "res://assets/fruit",
		"preview": "res://assets/fruit/apple.png",
		"background_color": Color(1.0, 0.5, 0.5),
	},
	{
		"name": "Vegetables",
		"dir": "res://assets/vegetables",
		"preview": "res://assets/vegetables/carrot.png",
		"background_color": Color(0.5, 0.85, 0.5),
	},
	{
		"name": "Animals",
		"dir": "res://assets/animals",
		"preview": "res://assets/animals/cat.png",
		"background_color": Color(1.0, 0.8, 0.4),
	},
]

@onready var _difficulty: Node = %DifficultySelector
@onready var _sets_grid: HBoxContainer = %ImageSets


func _ready() -> void:
	_populate_sets()


func _populate_sets() -> void:
	for image_set in IMAGE_SETS:
		_sets_grid.add_child(_make_set_tile(image_set))


func _make_set_tile(image_set: Dictionary) -> Control:
	var tile := VBoxContainer.new()
	tile.alignment = BoxContainer.ALIGNMENT_CENTER

	var icon := GameIcon.instantiate()
	icon.game_texture = load(image_set["preview"])
	icon.background_color = image_set.get("background_color", Color.WHITE)
	icon.selected.connect(_on_set_selected.bind(image_set))
	tile.add_child(icon)

	var label := Label.new()
	label.text = image_set["name"]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tile.add_child(label)

	return tile


func _on_set_selected(image_set: Dictionary) -> void:
	MemorySettings.difficulty = _difficulty.selected_difficulty
	MemorySettings.image_dir = image_set["dir"]
	MemorySettings.set_name = image_set["name"]
	get_tree().change_scene_to_file("res://scenes/memory_game.tscn")


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game_select.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()
