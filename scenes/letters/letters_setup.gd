extends Control
## Setup screen for the Letters game: pick a difficulty (4/5/6 images), then
## pick an image set. Selecting a set starts the game.

const GameIcon := preload("res://scenes/menus/game_icon.tscn")

## Available image sets. `dir` points at the folder of images; `set_key` is the
## localization key for the set name; `preview` is the icon shown here.
const IMAGE_SETS: Array[Dictionary] = [
	{
		"set_key": "fruit",
		"dir": "res://assets/fruit",
		"preview": "res://assets/fruit/apple.png",
		"background_color": Color(1.0, 0.5, 0.5),
	},
	{
		"set_key": "vegetables",
		"dir": "res://assets/vegetables",
		"preview": "res://assets/vegetables/carrot.png",
		"background_color": Color(0.5, 0.85, 0.5),
	},
	{
		"set_key": "animals",
		"dir": "res://assets/animals",
		"preview": "res://assets/animals/cat.png",
		"background_color": Color(1.0, 0.8, 0.4),
	},
]

@onready var _title: Label = %Title
@onready var _difficulty: Node = %DifficultySelector
@onready var _sets_label: Label = %SetsLabel
@onready var _sets_grid: HBoxContainer = %ImageSets
@onready var _back_button: Button = %BackButton

var _set_labels: Array[Label] = []


func _ready() -> void:
	_populate_sets()
	_apply_language()


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
	label.text = Localization.t(image_set["set_key"])
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tile.add_child(label)
	_set_labels.append(label)

	return tile


func _apply_language() -> void:
	_title.text = Localization.t("letters")
	var diff_label := _difficulty.get_node_or_null("Label") as Label
	if diff_label != null:
		diff_label.text = Localization.t("difficulty")
	_sets_label.text = Localization.t("choose_set")
	_back_button.text = Localization.t("back")
	for i in _set_labels.size():
		_set_labels[i].text = Localization.t(IMAGE_SETS[i]["set_key"])


func _on_set_selected(image_set: Dictionary) -> void:
	LettersSettings.difficulty = _difficulty.selected_difficulty
	LettersSettings.image_dir = image_set["dir"]
	LettersSettings.set_key = image_set["set_key"]
	get_tree().change_scene_to_file("res://scenes/letters/letters_game.tscn")


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/game_select.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()
