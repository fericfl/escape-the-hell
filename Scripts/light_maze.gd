extends Node2D

@onready var player = $Player
@onready var wall_tilemap = $Walls
@onready var floor_tilemap = $Floor

var next_room = "res://Scenes/boss_room.tscn"
var enemy_scene = preload("res://Scenes/hidden_enemy.tscn")
const MAZE_SIZE = Vector2i(80,25)
const FLOOR_TILES = [Vector2i(1,0), Vector2i(0,0), Vector2i(2,0), Vector2i(1,1)]
const TERRAIN_SET = 0
const WALL_TERRAIN_ID = 0

var maze = []
var visited = []
var directions = [Vector2i(0, -2), Vector2i(0, 2), Vector2i(-2, 0), Vector2i(2,0)]

var START_POS := Vector2i(1, MAZE_SIZE.y / 2)
var END_POS := Vector2i(MAZE_SIZE.x - 2, MAZE_SIZE.y / 2)

func _physics_process(_delta: float) -> void:
	check_player_on_end_tile()

func _ready():
	randomize()
	generate_maze()
	spawn_player()
	spawn_enemies()

func generate_maze():
	maze.clear()
	visited.clear()
	for y in range(MAZE_SIZE.y):
		maze.append([])
		for x in range(MAZE_SIZE.x):
				maze[y].append(false)

	visited.append(START_POS)
	carve(START_POS)
	
	maze[END_POS.y][END_POS.x] = true
	var bridge = (START_POS + END_POS) / 2
	maze[bridge.y][bridge.x] = true
	
	wall_tilemap.clear()
	var wall_positions = []
	for y in range(MAZE_SIZE.y):
		for x in range(MAZE_SIZE.x):
			var pos = Vector2i(x,y)
			if maze[y][x]:
				floor_tilemap.set_cell(pos, 0, FLOOR_TILES.pick_random())
			else:
				wall_positions.append(pos)
				floor_tilemap.set_cell(pos, 0, FLOOR_TILES.pick_random())
	wall_tilemap.set_cells_terrain_connect(wall_positions, 0, 0)
	floor_tilemap.set_cell(END_POS, 0, Vector2i(0,5))

func carve(pos: Vector2i):
	maze[pos.y][pos.x] = true
	directions.shuffle()
	for dir in directions:
		var next = pos + dir
		if is_inside_maze(next) and not maze[next.y][next.x]:
			var between = pos + dir / 2
			maze[between.y][between.x] = true
			visited.append(next)
			carve(next)

func is_inside_maze(pos: Vector2i) -> bool:
	return pos.x > 0 and pos.x < MAZE_SIZE.x - 1 and pos.y > 0 and pos.y < MAZE_SIZE.y - 1

func spawn_player():
	var start_pos = wall_tilemap.map_to_local(START_POS)
	player.global_position = wall_tilemap.to_global(start_pos)

func spawn_enemies(count: int = 3):
	var spawned = 0
	while spawned < count:
		var x = randi_range(1, MAZE_SIZE.x - 2)
		var y = randi_range(1, MAZE_SIZE.y - 2)
		if maze[y][x]:
			print("Spawning Enemy")
			var enemy = enemy_scene.instantiate()
			enemy.player = player
			enemy.global_position = floor_tilemap.map_to_local(Vector2i(x, y))
			add_child(enemy)
			print("Spanwned Enemy")
			spawned += 1

func check_player_on_end_tile():
	var player_local_pos = floor_tilemap.to_local(player.global_position)
	var player_tile_pos = floor_tilemap.local_to_map(player_local_pos)
	
	if player_tile_pos == END_POS:
		get_tree().change_scene_to_file(next_room)
