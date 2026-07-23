extends Control
## Grid view for choosing a minigame to play. Also lets the player switch
## language via emoji-flag buttons.

const GameIcon := preload("res://scenes/menus/game_icon.tscn")

## Each entry describes a game tile shown in the grid.
## `name_key` is a localization key; `scene` is left empty for games that
## aren't implemented yet.
const GAMES: Array[Dictionary] = [
	{
		"name_key": "memory",
		"icon": "res://assets/games/memory.png",
		"background_color": Color(0.4, 0.7, 1.0),
		"scene": "res://scenes/memory/memory_setup.tscn",
	},
	{
		"name_key": "letters",
		"icon": "res://assets/games/letters.png",
		"background_color": Color(0.9, 0.6, 1.0),
		"scene": "res://scenes/letters/letters_setup.tscn",
	},
]

@onready var _grid: GridContainer = %Grid
@onready var _title: Label = %Title
@onready var _back_button: Button = %BackButton
@onready var _languages: HBoxContainer = %Languages

var _tile_labels: Array[Label] = []
var _lang_buttons: Array[Button] = []

## Green outline shown on the currently selected language button.
var _selected_lang_style: StyleBoxFlat = _make_selected_style()


static func _make_selected_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	# Keep the button's darker pressed background, add a green outline on top.
	style.bg_color = Color(0, 0, 0, 0.35)
	style.set_border_width_all(4)
	style.border_color = Color(0.2, 0.7, 0.25)
	style.set_corner_radius_all(8)
	return style


func _ready() -> void:
	_populate_grid()
	_populate_languages()
	_apply_language()
	Localization.language_changed.connect(_on_language_changed)


func _populate_grid() -> void:
	for game in GAMES:
		_grid.add_child(_make_tile(game))
	# Focus the first tile so the grid is keyboard/controller navigable.
	if _grid.get_child_count() > 0:
		_grid.get_child(0).grab_focus()


func _make_tile(game: Dictionary) -> Control:
	var tile := VBoxContainer.new()
	tile.alignment = BoxContainer.ALIGNMENT_CENTER

	var icon := GameIcon.instantiate()
	icon.game_texture = load(game["icon"])
	icon.background_color = game.get("background_color", Color.WHITE)
	icon.selected.connect(_on_game_pressed.bind(game))
	tile.add_child(icon)

	var label := Label.new()
	label.text = Localization.t(game["name_key"])
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tile.add_child(label)
	_tile_labels.append(label)

	return tile


## One button per supported language, labeled with its flag emoji.
func _populate_languages() -> void:
	for lang in Localization.SUPPORTED:
		var button := Button.new()
		button.text = Localization.FLAGS.get(lang, lang)
		button.tooltip_text = Localization.LANGUAGE_NAMES.get(lang, lang)
		button.add_theme_font_size_override("font_size", 32)
		button.toggle_mode = true
		button.pressed.connect(_on_language_button.bind(lang))
		_languages.add_child(button)
		_lang_buttons.append(button)
	_update_language_buttons()


func _on_language_button(lang: String) -> void:
	Localization.set_language(lang)


func _on_language_changed(_lang: String) -> void:
	_apply_language()


func _apply_language() -> void:
	_title.text = Localization.t("select_game")
	_back_button.text = Localization.t("back")
	for i in _tile_labels.size():
		_tile_labels[i].text = Localization.t(GAMES[i]["name_key"])
	_update_language_buttons()


func _update_language_buttons() -> void:
	for i in _lang_buttons.size():
		var is_selected: bool = Localization.SUPPORTED[i] == Localization.language
		var button := _lang_buttons[i]
		button.button_pressed = is_selected
		# Give the selected language a green outline in every button state.
		if is_selected:
			button.add_theme_stylebox_override("normal", _selected_lang_style)
			button.add_theme_stylebox_override("hover", _selected_lang_style)
			button.add_theme_stylebox_override("pressed", _selected_lang_style)
		else:
			button.remove_theme_stylebox_override("normal")
			button.remove_theme_stylebox_override("hover")
			button.remove_theme_stylebox_override("pressed")


func _on_game_pressed(game: Dictionary) -> void:
	var scene_path: String = game["scene"]
	if scene_path.is_empty():
		# TODO: Build the actual game scene, then set its path in GAMES.
		print("%s is not implemented yet" % Localization.t(game["name_key"]))
		return
	get_tree().change_scene_to_file(scene_path)


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/title_screen.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()
