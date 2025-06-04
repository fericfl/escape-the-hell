extends Node2D

@export var tilemap: TileMapLayer
@export var player: CharacterBody2D
@export var SPAWN_DELAY_TILES = 5
@export var SPIKE_SPAWN_CHANCE = 30

var soul_scene = preload("res://Scenes/soul.tscn")

const LAYER = 0
const GROUND_TILE = Vector2i(0, 0)
const SPIKE_TILE = Vector2i(3, 3)
const VOID_TILE = Vector2i(9, 2)
const WALL_TILE = Vector2i(9, 3)

const MAP_HEIGHT = 18
const GROUND_WIDTH = 2
const GROUND_Y_POSITIONS = [7, 10, 13]

const GENERATE_DISTANCE = 40
var last_generated_x = 0

func _process(_delta):
	var player_local_pos = tilemap.to_local(player.global_position)
	var player_x_tile = tilemap.local_to_map(player_local_pos).x
	
	while last_generated_x < player_x_tile + GENERATE_DISTANCE:
		generate_column(last_generated_x)
		last_generated_x += 1

func generate_column(x: int) -> void:
	var player_local_pos = tilemap.to_local(player.global_position)
	var player_x_tile = tilemap.local_to_map(player_local_pos).x
	const SPIKE_Y_RANGES = [Vector2i(5,6), Vector2i(8,9), Vector2i(11,12)]
	
	if x < player_x_tile + SPAWN_DELAY_TILES:
		return
	for y in MAP_HEIGHT :
		var tile: Vector2i
		match y:
			0,1,2,3,14,15,16,17: 
				tile = VOID_TILE
				tilemap.set_cell(Vector2i(x, y), 1, tile)
			4,13: 
				tile = WALL_TILE
				tilemap.set_cell(Vector2i(x, y), 1, tile)
			5,6,7,8,9,10,11,12:
				tile = GROUND_TILE
				tilemap.set_cell(Vector2i(x, y), 0, tile)
			_:
				pass
	
	var spike_range = SPIKE_Y_RANGES[randi() % SPIKE_Y_RANGES.size()]
	var group_width = randi_range(1, 3)
	var available_lanes = GROUND_Y_POSITIONS.duplicate()
	available_lanes.shuffle()
	
	if randi() % 100 < SPIKE_SPAWN_CHANCE:
		for dx in range(group_width):
			for dy in range(spike_range.x, spike_range.y + 1):
				var pos = Vector2i(x + dx, dy)
				tilemap.set_cell(pos, 0, SPIKE_TILE)
	else:
		if randi() % 100 < 60:
			var safe_lanes := []
			
			for ground_y in GROUND_Y_POSITIONS:
				var spike_y_range = Vector2i(ground_y - 2, ground_y - 1)
				var has_spike = false
				
				for y in range(spike_y_range.x, spike_y_range.y + 1):
					if tilemap.get_cell_source_id(Vector2i(x, y)) == 0 and tilemap.get_cell_atlas_coords(Vector2i(x,y)) == SPIKE_TILE:
						has_spike = true
						break
					
				if not has_spike:
					safe_lanes.append(ground_y)
			
			if safe_lanes.size() > 0:
				var chosen_y = safe_lanes[randi() % safe_lanes.size()]
				var soul_tile_coords = Vector2i(x, chosen_y)
				var soul_pixel_pos = tilemap.map_to_local(soul_tile_coords) - Vector2(24,24)
				
				var soul = soul_scene.instantiate()
				soul.global_position = soul_pixel_pos
				soul.connect("collected", Callable(player, "_on_soul_collected"))
				soul.connect("area_entered", Callable(soul, "_on_area_entered"))
				add_child(soul)

func _on_score_threshold_reached():
	player.set_player_health()
	get_tree().change_scene_to_file("res://Scenes/light_maze.tscn")
