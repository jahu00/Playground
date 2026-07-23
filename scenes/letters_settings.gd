extends Node
## Autoload holding the settings chosen on the letters setup screen so the
## game scene can read them after a scene change.

## Number of image/letter pairs for each difficulty level (1-based index).
const IMAGES_PER_DIFFICULTY := {
	1: 4,
	2: 5,
	3: 6,
}

var difficulty: int = 1
var image_dir: String = "res://assets/fruit"
## Localization key for the image set's name (see Localization.UI).
var set_key: String = "fruit"


func image_count() -> int:
	return IMAGES_PER_DIFFICULTY.get(difficulty, 4)
