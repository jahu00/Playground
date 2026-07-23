extends Control
## A draggable picture card for the Letters game (top row). The player drags it
## onto a drop slot; the game controller checks whether its letter matches.
## Its outline tints green (correct) or red (wrong).

const NEUTRAL := Color(0.2, 0.15, 0.1)
const CORRECT := Color(0.2, 0.7, 0.25)
const WRONG := Color(0.85, 0.2, 0.2)

## File-name key of the image (without extension), e.g. "apple".
var image_key: String = ""
## Uppercase first letter of the image's localized name.
var letter: String = ""

var _texture: Texture2D
var _matched: bool = false

@onready var _panel: Panel = %Panel
@onready var _image: TextureRect = %Image

var _style: StyleBoxFlat


func setup(key: String, tex: Texture2D, card_letter: String) -> void:
	image_key = key
	_texture = tex
	letter = card_letter
	if is_node_ready():
		_image.texture = tex


func _ready() -> void:
	_image.texture = _texture
	_style = (_panel.get_theme_stylebox("panel") as StyleBoxFlat).duplicate()
	_panel.add_theme_stylebox_override("panel", _style)


func is_matched() -> bool:
	return _matched


func set_matched() -> void:
	_matched = true
	mouse_default_cursor_shape = Control.CURSOR_ARROW


func set_outline(color: Color) -> void:
	_style.border_color = color


func reset_outline() -> void:
	_style.border_color = NEUTRAL


## Reparent into `parent` and stretch to fill it.
func place_in(parent: Control) -> void:
	var current := get_parent()
	if current == parent:
		return
	if current != null:
		current.remove_child(self)
	parent.add_child(self)
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0


func _get_drag_data(_at_position: Vector2) -> Variant:
	if _matched:
		return null
	var preview := TextureRect.new()
	preview.texture = _texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.custom_minimum_size = size
	preview.size = size
	preview.modulate = Color(1, 1, 1, 0.85)
	var holder := Control.new()
	holder.add_child(preview)
	preview.position = -size * 0.5
	set_drag_preview(holder)
	return {"card": self}
