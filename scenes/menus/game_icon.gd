@tool
extends Button
## A reusable icon tile for a single minigame.
##
## Shows a color-modulated background (icon-background.png) behind the game's
## icon, framed by a border. Emits `selected` when clicked/activated.

signal selected

## The game's icon, drawn on top of the background.
@export var game_texture: Texture2D:
	set(value):
		game_texture = value
		_update()

## Color applied to the background image, letting each game have its own tint.
@export var background_color: Color = Color.WHITE:
	set(value):
		background_color = value
		_update()

@onready var _background: TextureRect = %Background
@onready var _icon: TextureRect = %Icon


func _ready() -> void:
	_update()
	if not Engine.is_editor_hint():
		pressed.connect(func() -> void: selected.emit())


func _update() -> void:
	if not is_node_ready():
		return
	_background.self_modulate = background_color
	_icon.texture = game_texture
