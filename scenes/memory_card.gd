extends Control
## A single memory card. Shows a face-down back (card art + logo) until
## revealed, then its image. Flipping animates as a rotation around the
## vertical axis; matched cards fade away.

signal flip_requested(card: Control)

## Identifies matching pairs: two cards with the same id are a match.
var pair_id: int = -1

const FLIP_TIME := 0.15
const FADE_TIME := 0.4

var _texture: Texture2D
var _face_up: bool = false
var _matched: bool = false
var _animating: bool = false

@onready var _button: TextureButton = %Button
@onready var _flipper: Control = %Flipper
@onready var _face_panel: Panel = %FacePanel
@onready var _face: TextureRect = %Face
@onready var _back: Panel = %BackPanel


func setup(id: int, texture: Texture2D) -> void:
	pair_id = id
	_texture = texture
	if is_node_ready():
		_face.texture = texture


func _ready() -> void:
	_face.texture = _texture
	_show_face(false)
	_button.pressed.connect(_on_pressed)


func _on_pressed() -> void:
	if _face_up or _matched or _animating:
		return
	flip_requested.emit(self)


func is_face_up() -> bool:
	return _face_up


func is_matched() -> bool:
	return _matched


func is_busy() -> bool:
	return _animating


## Turn the card face up, revealing its image, with a flip animation.
func reveal() -> void:
	_face_up = true
	await _flip_to(true)


## Turn the card back face down, with a flip animation.
func hide_face() -> void:
	_face_up = false
	await _flip_to(false)


## Mark the card as matched: it stays revealed briefly, then fades away.
func set_matched() -> void:
	_matched = true
	_button.disabled = true
	await _fade_out()


## Animate a half-rotation to swap sides. Scaling X to 0 and back simulates
## spinning the card around its vertical axis.
func _flip_to(face_up: bool) -> void:
	_animating = true
	_center_pivot()
	var tween := create_tween()
	tween.tween_property(_flipper, "scale:x", 0.0, FLIP_TIME)
	tween.tween_callback(func() -> void: _show_face(face_up))
	tween.tween_property(_flipper, "scale:x", 1.0, FLIP_TIME)
	await tween.finished
	_animating = false


func _fade_out() -> void:
	_animating = true
	var tween := create_tween()
	tween.tween_interval(0.2)
	tween.tween_property(_flipper, "modulate:a", 0.0, FADE_TIME)
	await tween.finished
	_flipper.visible = false
	_animating = false


func _center_pivot() -> void:
	_flipper.pivot_offset = _flipper.size * 0.5


func _show_face(face_up: bool) -> void:
	_face_panel.visible = face_up
	_back.visible = not face_up
