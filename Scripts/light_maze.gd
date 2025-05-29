extends Node2D

@onready var player = $Player
@onready var wall_tilemap = $Walls
@onready var floor_tilemap = $Floor

const MAZE_SIZE = Vector2i(50,50)
const FLOOR_TILE = Vector2i(1,0)
const TERRAIN_SET = 0
const WALL_TERRAIN_ID = 0

var maze = []
var visited = []
var directions = [Vector2i(0, -2), Vector2i(0, 2), Vector2i(-2, 0), Vector2i(2,0)]

func _ready():
	randomize()
	generate_maze()
	spawn_player()

func generate_maze():
	maze.clear()
	visited.clear()
	for y in range(MAZE_SIZE.y):
		maze.append([])
		for x in range(MAZE_SIZE.x):
				maze[y].append(false)

	var start = Vector2i(1,1)
	visited.append(start)
	carve(start)
	
	wall_tilemap.clear()
	var wall_positions = []
	var floor_positions = []
	for y in range(MAZE_SIZE.y):
		for x in range(MAZE_SIZE.x):
			var pos = Vector2i(x,y)
			if maze[y][x]:
				floor_tilemap.set_cell(pos, 0, FLOOR_TILE)
			else:
				wall_positions.append(pos)
				floor_tilemap.set_cell(pos, 0, FLOOR_TILE)
	wall_tilemap.set_cells_terrain_connect(wall_positions, 0, 0)
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
	var start_tile = visited[0]
	var start_pos = wall_tilemap.map_to_local(start_tile)
	player.global_position = wall_tilemap.to_global(start_pos)
