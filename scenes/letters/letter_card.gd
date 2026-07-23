extends Panel
## A card in the bottom row of the Letters game, showing a single letter.
## Its outline can be tinted (green for a correct match, red for a wrong one).

const NEUTRAL := Color(0.2, 0.15, 0.1)
const CORRECT := Color(0.2, 0.7, 0.25)
const WRONG := Color(0.85, 0.2, 0.2)

var letter: String = "":
	set(value):
		letter = value
		if is_node_ready():
			_label.text = value

@onready var _label: Label = %Letter

var _style: StyleBoxFlat


func _ready() -> void:
	# Duplicate the style so tinting this card doesn't affect the others.
	_style = (get_theme_stylebox("panel") as StyleBoxFlat).duplicate()
	add_theme_stylebox_override("panel", _style)
	_label.text = letter


func set_outline(color: Color) -> void:
	_style.border_color = color


func reset_outline() -> void:
	_style.border_color = NEUTRAL
