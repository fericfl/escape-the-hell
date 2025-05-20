extends Node2D

@export var tilemap: TileMapLayer
@export var player: CharacterBody2D
@export var SPAWN_DELAY_TILES = 5
@export var SPIKE_SPAWN_CHANCE = 30

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
	if x % 2 != 0:
		return
	
	var spike_range = SPIKE_Y_RANGES[randi() % SPIKE_Y_RANGES.size()]
	var group_width = randi_range(1, 3)
	var available_lanes = GROUND_Y_POSITIONS.duplicate()
	available_lanes.shuffle()
	
	if randi() % 100 < SPIKE_SPAWN_CHANCE:
		for dx in range(group_width):
			for dy in range(spike_range.x, spike_range.y + 1):
				var pos = Vector2i(x + dx, dy)
				tilemap.set_cell(pos, 0, SPIKE_TILE)
