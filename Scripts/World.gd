extends Node2D

@onready var tile_map : TileMap = $TileMap

var day : int = 1
var money : int = 0
var seeds_available : int = 4
var tools : Array = ["Hoe", "Seed bag", "Watering pot", "Sickle"]

enum farming_modes {DIRT, SEEDS, WATER, HARVEST}
var farming_mode_state : farming_modes = farming_modes.DIRT

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	manage_ui()
	manage_tools()
	
	if Input.is_action_just_pressed("ui_accept"):
		next_day()
	
	if Input.is_action_just_pressed("interact"):
		var mouse_pos : Vector2 = get_global_mouse_position()
		var tile_map_pos : Vector2i = tile_map.local_to_map(mouse_pos)
		
		if farming_mode_state == farming_modes.DIRT:
			use_dirt(tile_map_pos)
		if farming_mode_state == farming_modes.SEEDS:
			use_seeds(tile_map_pos)
		if farming_mode_state == farming_modes.WATER:
			use_water(tile_map_pos)
		if farming_mode_state == farming_modes.HARVEST:
			use_harvest(tile_map_pos)

func manage_ui() -> void:
	$CanvasLayer/Control/Day.text = "Day: " + str(day)
	$CanvasLayer/Control/Tool.text = "Tool: " + tools[farming_mode_state]
	$CanvasLayer/Control/Money.text = "Money: $" + str(money)
	$CanvasLayer/Control/Seeds.text = "Seeds: " + str(seeds_available)

func use_seeds(tile_map_pos : Vector2i) -> void:
	if retreive_custom_data(tile_map_pos, "can_place_seeds", 0) and seeds_available > 0:
		if !retreive_custom_data(tile_map_pos, "has_seeds", 1):
			tile_map.set_cell(1, tile_map_pos, 1, Vector2i(0, 0))
			seeds_available -= 1

func use_dirt(tile_map_pos):
	tile_map.set_cell(0, tile_map_pos, 0, Vector2i(1, 0))

func use_water(tile_map_pos):
	if retreive_custom_data(tile_map_pos, "can_water", 0):
		tile_map.set_cell(0, tile_map_pos, 0, Vector2i(2, 0))
		
func use_harvest(tile_map_pos) -> void:
	if retreive_custom_data(tile_map_pos, "can_harvest", 1):
		tile_map.set_cell(0, tile_map_pos, 0, Vector2i(1, 0))
		tile_map.set_cell(1, tile_map_pos, -1, Vector2i(0, 0))
		money += 20

func manage_tools() -> void:
	if Input.is_action_just_pressed("dirt"):
		farming_mode_state = farming_modes.DIRT
	if Input.is_action_just_pressed("seeds"):
		farming_mode_state = farming_modes.SEEDS
	if Input.is_action_just_pressed("water"):
		farming_mode_state = farming_modes.WATER
	if Input.is_action_just_pressed("harvest"):
		farming_mode_state = farming_modes.HARVEST

func retreive_custom_data(tile_map_pos : Vector2i, custom_data_layer : String, layer : int):
	var tile_data : TileData = tile_map.get_cell_tile_data(layer, tile_map_pos)

	if tile_data:
		return tile_data.get_custom_data(custom_data_layer)
	else:
		return false

func next_day() -> void:
	$DayTimer.start()
	day += 1
	for cell in tile_map.get_used_cells(1):
		var cell_pos : Vector2i = Vector2i(cell.x, cell.y)
		var cell_level = retreive_custom_data(cell_pos, "seed_level", 1)
		
		if cell_level != 3:
			if retreive_custom_data(cell_pos, "has_been_watered", 0):
				tile_map.set_cell(1, cell_pos, 1, Vector2i(cell_level + 1, 0))
	
	for cell in tile_map.get_used_cells(0):
		var cell_pos : Vector2i = Vector2i(cell.x, cell.y)
		if retreive_custom_data(cell_pos, "has_been_watered", 0):
			tile_map.set_cell(0, cell_pos, 0, Vector2i(1, 0))

func _on_buy_seeds_pressed():
	if money >= 10:
		money -= 10
		seeds_available += 1

func _on_next_day_pressed():
	next_day()

func _on_day_timer_timeout():
	next_day()
