extends Node2D

@export var tilemap: TileMapLayer
@export var player: CharacterBody2D
@export var SPAWN_DELAY_TILES = 5

const LAYER = 0
const SOURCE_ID = 0
const GROUND_TILE = Vector2i(0, 0)
const SPIKE_TILE = Vector2i(3, 3)

const GROUND_Y = 9
const GROUND_Y_POSITIONS = [3, 6, 9]
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
	
	if x < player_x_tile + SPAWN_DELAY_TILES:
		return
	for ground_y in GROUND_Y_POSITIONS:
		var ground_pos = Vector2i(x, ground_y)
		var spike1_pos = Vector2i(x, ground_y - 1)
		var spike2_pos = Vector2i(x, ground_y - 2)
		
		tilemap.set_cell(ground_pos, SOURCE_ID, GROUND_TILE)
		
		if randi() % 100 < 30:
			tilemap.set_cell(spike1_pos, SOURCE_ID, SPIKE_TILE)
			tilemap.set_cell(spike2_pos, SOURCE_ID, SPIKE_TILE)
