extends Node
## Autoload holding the settings chosen on the memory setup screen so the
## game scene can read them after a scene change.

## Number of pairs for each difficulty level (1-based index).
const PAIRS_PER_DIFFICULTY := {
	1: 3,  # 6 cards
	2: 4,  # 8 cards
	3: 6,  # 12 cards
	4: 8,  # 16 cards
}

var difficulty: int = 1
var image_dir: String = "res://assets/fruit"
var set_name: String = "Fruits"


func pair_count() -> int:
	return PAIRS_PER_DIFFICULTY.get(difficulty, 3)
