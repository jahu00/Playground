extends Control
## Title screen for the Playground minigame collection.

func _ready() -> void:
	_play_button.grab_focus()


@onready var _play_button: TextureButton = %PlayButton


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/game_select.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit()
