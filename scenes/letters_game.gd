extends Control
## The Letters game. Three rows: draggable picture cards (top), empty drop
## slots (middle, separated by a gap), and letter cards (bottom). The player
## drags each picture onto the slot above its matching letter. Correct matches
## outline green; wrong ones flash red and bounce back. Match them all to win;
## clicking the win splash starts a fresh round with new random images.

const ImageCard := preload("res://scenes/image_card.tscn")
const LetterCard := preload("res://scenes/letter_card.tscn")
const DropSlot := preload("res://scenes/drop_slot.tscn")
const SplashOverlay := preload("res://scenes/splash_overlay.tscn")
const WIN_SPLASH := preload("res://assets/win-splash.png")

const CARD_SEPARATION := 24.0
const ROW_GAP := 60.0            # extra gap between the picture row and slots
const PLAY_AREA_TOP := 90.0
const PLAY_AREA_BOTTOM := 80.0
const PLAY_AREA_SIDE := 40.0
const MAX_CARD_SIZE := 180.0
const WRONG_FLASH_TIME := 0.7

const CORRECT_COLOR := Color(0.2, 0.7, 0.25)
const WRONG_COLOR := Color(0.85, 0.2, 0.2)

@onready var _status: Label = %Status
@onready var _images_row: HBoxContainer = %ImagesRow
@onready var _slots_row: HBoxContainer = %SlotsRow
@onready var _letters_row: HBoxContainer = %LettersRow
@onready var _board: VBoxContainer = %Board
@onready var _back_button: Button = %BackButton

var _image_cards: Array = []
var _slots: Array = []
var _total: int = 0
var _matched: int = 0
var _card_size: float = 120.0


func _ready() -> void:
	_back_button.text = Localization.t("back")
	_new_round()
	get_viewport().size_changed.connect(_resize)


## Clear the board and deal a fresh set of random images and letters.
func _new_round() -> void:
	_matched = 0
	for row in [_images_row, _slots_row, _letters_row]:
		for child in row.get_children():
			child.queue_free()
	_image_cards.clear()
	_slots.clear()

	var picks := _pick_images(LettersSettings.image_count())
	_total = picks.size()

	# Bottom row + slots share one order, sorted alphabetically by letter; the
	# top picture row is shuffled independently.
	var slot_order := picks.duplicate()
	slot_order.sort_custom(func(a, b): return a["letter"] < b["letter"])
	for entry in slot_order:
		var slot := DropSlot.instantiate()
		slot.letter = entry["letter"]
		slot.card_dropped.connect(_on_card_dropped)
		_slots_row.add_child(slot)
		_slots.append(slot)

		var letter_card := LetterCard.instantiate()
		_letters_row.add_child(letter_card)
		letter_card.letter = entry["letter"]

	var image_order := picks.duplicate()
	image_order.shuffle()
	for entry in image_order:
		var holder := Control.new()
		_images_row.add_child(holder)
		var card := ImageCard.instantiate()
		holder.add_child(card)
		card.setup(entry["key"], entry["texture"], entry["letter"])
		card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_image_cards.append(card)

	_resize()
	_update_status()


## Choose `count` images from the set whose localized names start with distinct
## letters, so every letter card has exactly one matching picture.
func _pick_images(count: int) -> Array:
	var available := _load_images(LettersSettings.image_dir)
	available.shuffle()
	var picks: Array = []
	var used_letters := {}
	for entry in available:
		var letter: String = Localization.first_letter(entry["key"])
		if used_letters.has(letter):
			continue
		used_letters[letter] = true
		entry["letter"] = letter
		picks.append(entry)
		if picks.size() == count:
			break
	return picks


## Load every PNG in `dir` as {key, texture}. `key` is the file name without
## extension, used for localized names.
func _load_images(dir_path: String) -> Array:
	var images: Array = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_error("Letters: could not open image dir %s" % dir_path)
		return images
	for file_name in dir.get_files():
		var name := file_name.trim_suffix(".import")
		if name.get_extension().to_lower() != "png":
			continue
		var path := dir_path.path_join(name)
		var tex := load(path)
		if tex is Texture2D:
			images.append({"key": name.get_basename(), "texture": tex})
	return images


func _on_card_dropped(slot: Panel, card: Control) -> void:
	if not slot.can_accept() or card.is_matched():
		return

	if card.letter == slot.letter:
		# Correct: settle the card into the slot and lock it in.
		card.place_in(slot)
		slot.occupant = card
		card.set_outline(CORRECT_COLOR)
		_tint_letter_below(slot, CORRECT_COLOR)
		card.set_matched()
		_matched += 1
		_update_status()
		if _matched == _total:
			_on_win()
	else:
		# Wrong: flash both red, then clear.
		card.set_outline(WRONG_COLOR)
		_tint_letter_below(slot, WRONG_COLOR)
		await get_tree().create_timer(WRONG_FLASH_TIME).timeout
		if is_instance_valid(card):
			card.reset_outline()
		var letter_card := _letter_card_for(slot)
		if letter_card != null:
			letter_card.reset_outline()


func _tint_letter_below(slot: Panel, color: Color) -> void:
	var letter_card := _letter_card_for(slot)
	if letter_card != null:
		letter_card.set_outline(color)


func _letter_card_for(slot: Panel) -> Node:
	var index := _slots.find(slot)
	if index >= 0 and index < _letters_row.get_child_count():
		return _letters_row.get_child(index)
	return null


func _update_status() -> void:
	_status.text = "%s  •  %d / %d" % [
		Localization.t(LettersSettings.set_key), _matched, _total,
	]


func _on_win() -> void:
	_status.text = Localization.t("win")
	await get_tree().create_timer(0.4).timeout
	var splash := SplashOverlay.instantiate()
	splash.splash_texture = WIN_SPLASH
	splash.dismissed.connect(_on_win_dismissed.bind(splash))
	add_child(splash)


func _on_win_dismissed(splash: Control) -> void:
	splash.queue_free()
	_new_round()


## Size all cards to a square that fills the available play area across three
## rows (plus the gap between the picture row and the slots).
func _resize() -> void:
	if _total == 0:
		return
	var viewport := get_viewport_rect().size
	var avail_w := viewport.x - PLAY_AREA_SIDE * 2.0 - CARD_SEPARATION * (_total - 1)
	var avail_h := viewport.y - PLAY_AREA_TOP - PLAY_AREA_BOTTOM - CARD_SEPARATION * 2.0 - ROW_GAP
	var per_col := avail_w / _total
	var per_row := avail_h / 3.0
	_card_size = clampf(minf(per_col, per_row), 60.0, MAX_CARD_SIZE)

	var card_vec := Vector2(_card_size, _card_size)
	for row in [_images_row, _slots_row, _letters_row]:
		for cell in row.get_children():
			(cell as Control).custom_minimum_size = card_vec
			(cell as Control).size = card_vec

	_board.reset_size()
	_center_board()


func _center_board() -> void:
	# Hide until positioned: the board's final size is only known after the
	# container re-layouts next frame, so revealing early flashes it top-left.
	_board.visible = false
	await get_tree().process_frame
	var board_size := _board.size
	var viewport := get_viewport_rect().size
	_board.position = Vector2(
		(viewport.x - board_size.x) * 0.5,
		PLAY_AREA_TOP + (viewport.y - PLAY_AREA_TOP - PLAY_AREA_BOTTOM - board_size.y) * 0.5,
	)
	_board.visible = true


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/letters_setup.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()
