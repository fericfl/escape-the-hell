extends Node

class_name AStarManager

var astar := AStar2D.new()
var cell_size := Vector2(16,16)
var pos_to_id : Dictionary = {}

func build_from_maze(maze: Array, tilemap: TileMapLayer):
	astar.clear()
	pos_to_id.clear()
	var point_id := 0
	
	for y in range(maze.size()):
		for x in range(maze[y].size()):
			if maze[y][x]:
				var cell = Vector2i(x,y)
				var world_pos = tilemap.map_to_local(cell) + Vector2(16,16) / 2
				astar.add_point(point_id, world_pos)
				pos_to_id[cell] = point_id
				point_id += 1
	
	for cell in pos_to_id.keys():
		var id = pos_to_id[cell]
		for offset in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
			var neighbor = cell + offset
			if pos_to_id.has(neighbor):
				var neighbor_id = pos_to_id[neighbor]
				astar.connect_points(id, neighbor_id)
