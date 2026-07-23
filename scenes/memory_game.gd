extends Control
## The Memory game. Builds a grid of card pairs from the chosen image set and
## difficulty, then handles flipping, matching, and win detection.

const MemoryCard := preload("res://scenes/memory_card.tscn")
const SplashOverlay := preload("res://scenes/splash_overlay.tscn")
const WIN_SPLASH := preload("res://assets/win-splash.png")

## Column counts chosen to keep the board roughly rectangular per difficulty.
const COLUMNS_FOR_PAIRS := {
	3: 3,   # 6 cards  -> 3x2
	4: 4,   # 8 cards  -> 4x2
	6: 4,   # 12 cards -> 4x3
	8: 4,   # 16 cards -> 4x4
}

## Spacing between cards, matching the grid's h/v separation.
const CARD_SEPARATION := 16.0
## Top margin reserved for the status label; bottom for the back button.
const PLAY_AREA_TOP := 90.0
const PLAY_AREA_BOTTOM := 80.0
const PLAY_AREA_SIDE := 40.0
## Cards never grow beyond this, so easy boards don't get comically large.
const MAX_CARD_SIZE := 220.0

@onready var _grid: GridContainer = %Grid
@onready var _status: Label = %Status

var _first_card: Control = null
var _busy: bool = false
var _matched_pairs: int = 0
var _total_pairs: int = 0


func _ready() -> void:
	_build_board()


func _build_board() -> void:
	# Reset per-round state and clear any cards from a previous round.
	_first_card = null
	_busy = false
	_matched_pairs = 0
	# Free immediately (not queue_free) so the old cards don't get counted by
	# the resize/centering that runs later in this same rebuild.
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.free()

	var textures := _load_textures(MemorySettings.image_dir)
	var pair_count: int = mini(MemorySettings.pair_count(), textures.size())
	_total_pairs = pair_count

	# Pick the images for this round and make a pair of cards for each.
	textures.shuffle()
	var deck: Array[Dictionary] = []
	for i in pair_count:
		deck.append({"id": i, "texture": textures[i]})
		deck.append({"id": i, "texture": textures[i]})
	deck.shuffle()

	var columns: int = COLUMNS_FOR_PAIRS.get(pair_count, 4)
	_grid.columns = columns
	for entry in deck:
		var card := MemoryCard.instantiate()
		_grid.add_child(card)
		card.setup(entry["id"], entry["texture"])
		card.flip_requested.connect(_on_card_flip_requested)

	var rows: int = ceili(float(deck.size()) / columns)
	_resize_cards(columns, rows)
	_update_status()

	# Re-fit if the window size changes.
	if not get_viewport().size_changed.is_connected(_on_viewport_resized):
		get_viewport().size_changed.connect(_on_viewport_resized.bind(columns, rows))


func _on_viewport_resized(columns: int, rows: int) -> void:
	_resize_cards(columns, rows)


## Size the cards so the whole board fills the available play area, keeping
## square cards and respecting a max size on easy difficulties.
func _resize_cards(columns: int, rows: int) -> void:
	var viewport := get_viewport_rect().size
	var avail_w := viewport.x - PLAY_AREA_SIDE * 2.0 - CARD_SEPARATION * (columns - 1)
	var avail_h := viewport.y - PLAY_AREA_TOP - PLAY_AREA_BOTTOM - CARD_SEPARATION * (rows - 1)
	var card_size := minf(avail_w / columns, avail_h / rows)
	card_size = clampf(card_size, 60.0, MAX_CARD_SIZE)

	var card_vec := Vector2(card_size, card_size)
	for card in _grid.get_children():
		card.custom_minimum_size = card_vec
		# The Control-based card has no fixed size otherwise; pin it.
		(card as Control).size = card_vec

	# Let the grid shrink-wrap its content, then re-center it.
	_grid.reset_size()
	_center_grid()


func _center_grid() -> void:
	# Hide until positioned: the grid's final size is only known after the
	# container re-layouts next frame, so revealing early flashes it top-left.
	_grid.visible = false
	await get_tree().process_frame
	var grid_size := _grid.size
	var viewport := get_viewport_rect().size
	_grid.position = Vector2(
		(viewport.x - grid_size.x) * 0.5,
		PLAY_AREA_TOP + (viewport.y - PLAY_AREA_TOP - PLAY_AREA_BOTTOM - grid_size.y) * 0.5,
	)
	_grid.visible = true


## Load every PNG in `dir` as a Texture2D.
func _load_textures(dir_path: String) -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_error("Memory: could not open image dir %s" % dir_path)
		return textures
	for file_name in dir.get_files():
		# Imported textures are referenced by their source path minus .import.
		var name := file_name.trim_suffix(".import")
		if name.get_extension().to_lower() != "png":
			continue
		var path := dir_path.path_join(name)
		var tex := load(path)
		if tex is Texture2D and not textures.has(tex):
			textures.append(tex)
	return textures


func _on_card_flip_requested(card: Control) -> void:
	if _busy or card.is_face_up() or card.is_matched():
		return

	if _first_card == null:
		_first_card = card
		card.reveal()
		return

	# Second card flipped: block further input until this pair resolves.
	_busy = true
	await card.reveal()

	# Second card flipped: check for a match.
	if _first_card.pair_id == card.pair_id:
		_first_card.set_matched()
		card.set_matched()
		_first_card = null
		_matched_pairs += 1
		_update_status()
		_busy = false
		if _matched_pairs == _total_pairs:
			_on_win()
	else:
		var first_card := _first_card
		var second_card := card
		_first_card = null
		await get_tree().create_timer(0.8).timeout
		first_card.hide_face()
		second_card.hide_face()
		_busy = false


func _update_status() -> void:
	_status.text = "%s  •  Matches: %d / %d" % [
		MemorySettings.set_name, _matched_pairs, _total_pairs,
	]


func _on_win() -> void:
	_status.text = "You matched them all!"
	# Let the last pair's fade finish before the splash appears.
	await get_tree().create_timer(0.5).timeout
	var splash := SplashOverlay.instantiate()
	splash.splash_texture = WIN_SPLASH
	splash.dismissed.connect(_on_win_dismissed.bind(splash))
	add_child(splash)


## Dismissing the win splash starts a fresh round with new random cards.
func _on_win_dismissed(splash: Control) -> void:
	splash.queue_free()
	_build_board()


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/memory_setup.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()
