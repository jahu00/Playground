extends Node
## Autoload providing simple localization for the Playground games.
##
## Holds the active language, detects the system language on startup (falling
## back to English), and exposes UI strings plus per-image display names. The
## letter game derives its matching letters from these names, so translating a
## name also changes the letter the player must match.

signal language_changed(language: String)

const SUPPORTED := ["en", "pl"]
const FALLBACK := "en"

## Emoji shown next to each language option (used on the game select screen).
const FLAGS := {
	"en": "🇬🇧",
	"pl": "🇵🇱",
}

## Human-readable language names, in their own language.
const LANGUAGE_NAMES := {
	"en": "English",
	"pl": "Polski",
}

## UI strings keyed by a stable identifier, per language.
const UI := {
	"en": {
		"select_game": "Select a Game",
		"back": "Back",
		"difficulty": "Difficulty",
		"language": "Language",
		"memory": "Memory",
		"letters": "Letters",
		"choose_set": "Choose an image set to start",
		"letters_hint": "Drag each picture onto its matching letter",
		"win": "You matched them all!",
		"fruit": "Fruits",
		"vegetables": "Vegetables",
		"animals": "Animals",
	},
	"pl": {
		"select_game": "Wybierz grę",
		"back": "Wstecz",
		"difficulty": "Trudność",
		"language": "Język",
		"memory": "Memory",
		"letters": "Literki",
		"choose_set": "Wybierz zestaw, aby zacząć",
		"letters_hint": "Przeciągnij obrazek na pasującą literę",
		"win": "Brawo, wszystko dopasowane!",
		"fruit": "Owoce",
		"vegetables": "Warzywa",
		"animals": "Zwierzęta",
	},
}

## Display names per image, keyed by the image file name (without extension).
## Each entry maps a language code to the localized name. The first letter of
## the name is used as the card letter in the letter game.
const IMAGE_NAMES := {
	# Animals
	"cat": {"en": "Cat", "pl": "Kot"},
	"cow": {"en": "Cow", "pl": "Krowa"},
	"dog": {"en": "Dog", "pl": "Pies"},
	"elephant": {"en": "Elephant", "pl": "Słoń"},
	"fish": {"en": "Fish", "pl": "Ryba"},
	"giraffe": {"en": "Giraffe", "pl": "Żyrafa"},
	"lion": {"en": "Lion", "pl": "Lew"},
	"mouse": {"en": "Mouse", "pl": "Mysz"},
	"parrot": {"en": "Parrot", "pl": "Papuga"},
	"penguin": {"en": "Penguin", "pl": "Pingwin"},
	"pig": {"en": "Pig", "pl": "Świnia"},
	"zebra": {"en": "Zebra", "pl": "Zebra"},
	# Fruit
	"apple": {"en": "Apple", "pl": "Jabłko"},
	"banana": {"en": "Banana", "pl": "Banan"},
	"lemon": {"en": "Lemon", "pl": "Cytryna"},
	"melon": {"en": "Melon", "pl": "Melon"},
	"peach": {"en": "Peach", "pl": "Brzoskwinia"},
	"pear": {"en": "Pear", "pl": "Gruszka"},
	"pineapple": {"en": "Pineapple", "pl": "Ananas"},
	"strawberry": {"en": "Strawberry", "pl": "Truskawka"},
	"watermelon": {"en": "Watermelon", "pl": "Arbuz"},
	# Vegetables
	"broccoli": {"en": "Broccoli", "pl": "Brokuł"},
	"carrot": {"en": "Carrot", "pl": "Marchew"},
	"cauliflower": {"en": "Cauliflower", "pl": "Kalafior"},
	"cucumber": {"en": "Cucumber", "pl": "Ogórek"},
	"eggplant": {"en": "Eggplant", "pl": "Bakłażan"},
	"leek": {"en": "Leek", "pl": "Por"},
	"mushroom": {"en": "Mushroom", "pl": "Grzyb"},
	"potato": {"en": "Potato", "pl": "Ziemniak"},
}

var language: String = FALLBACK


func _ready() -> void:
	_detect_system_language()


## Pick the system language when it's supported, otherwise fall back to English.
func _detect_system_language() -> void:
	var sys := OS.get_locale_language()
	language = sys if sys in SUPPORTED else FALLBACK


func set_language(lang: String) -> void:
	if lang not in SUPPORTED or lang == language:
		return
	language = lang
	language_changed.emit(lang)


## Return a UI string for `key`, falling back to English then to the raw key.
func t(key: String) -> String:
	var table: Dictionary = UI.get(language, UI[FALLBACK])
	if table.has(key):
		return table[key]
	return UI[FALLBACK].get(key, key)


## Localized display name for an image key (file name without extension).
func image_name(key: String) -> String:
	var entry: Dictionary = IMAGE_NAMES.get(key, {})
	if entry.has(language):
		return entry[language]
	return entry.get(FALLBACK, key.capitalize())


## Uppercase first letter of an image's localized name, used as its card letter.
func first_letter(key: String) -> String:
	var name := image_name(key)
	return name.substr(0, 1).to_upper() if not name.is_empty() else "?"
