extends Control
## Reusable full-screen overlay that dims the screen and shows a splash image
## (e.g. win / lose). Clicking anywhere dismisses it and emits `dismissed`.
## Meant to be instantiated on top of any game scene.

signal dismissed

const FADE_IN := 0.3

## Splash image shown centered over the dimmed background.
@export var splash_texture: Texture2D:
	set(value):
		splash_texture = value
		if is_node_ready():
			_splash.texture = value

@onready var _splash: TextureRect = %Splash


func _ready() -> void:
	_splash.texture = splash_texture
	# Fade the whole overlay in.
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, FADE_IN)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_dismiss()
	elif event is InputEventScreenTouch and event.pressed:
		_dismiss()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_pressed():
		_dismiss()


func _dismiss() -> void:
	# Guard against double-dismiss from rapid input.
	set_process_input(false)
	dismissed.emit()
