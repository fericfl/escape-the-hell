extends Node

signal update_enemy_awareness(enemy: Node2D, nearby_allies: int)
signal group_attack_position(position: Vector2)
signal send_hide_positions(positions: Array)

var enemies := []
var player: CharacterBody2D = null
var attack_positions := []
var hide_positions := []

func register(enemy: Node2D):
	if enemy not in enemies:
		enemies.append(enemy)

func unregister(enemy: Node2D):
	enemies.erase(enemy)

func set_player(player_node: CharacterBody2D) -> void:
	player = player_node
	for enemy in enemies:
		enemy.player = player_node

func get_player_position() -> Vector2:
	return player.global_position if player else Vector2.ZERO

func update_enemy_positions() -> void:
	if not player:
		return
	var groups = _identify_groups()
	_calculate_attack_positions(groups)
	_calculate_hide_positions()

	for enemy in enemies:
		var nearby_allies = _count_nearby_allies(enemy)
		emit_signal("update_enemy_awareness", enemy, nearby_allies)

func _identify_groups() -> Array:
	var groups := []
	var processed := []

	for enemy in enemies:
		if enemy in processed:
			continue
		
		var group := [enemy]
		processed.append(enemy)

		for other in enemies:
			if other == enemy or other in processed:
				continue
			if enemy.global_position.distance_to(other.global_position) <= enemy.ally_radius * 16 * 5:
				group.append(other)
				processed.append(other)
		
		if group.size() > 0:
			groups.append(group)
		
	return groups

func _calculate_attack_positions(groups: Array) -> void:
	attack_positions.clear()

	for group in groups:
		if group.size() < 2:
			continue

		var center = player.global_position
		var rect_shape = player.collision_shape.shape as RectangleShape2D
		var radius = max(rect_shape.size.x, rect_shape.size.y) * 1.5
		var angle_step = TAU / group.size()

		var positions := []
		for i in range(group.size()):
			var angle = angle_step * i
			var pos = center + Vector2(cos(angle), sin(angle)) * radius
			positions.append(pos)
		
		attack_positions.append(positions)
		emit_signal("group_attack_position", positions)

func _calculate_hide_positions() -> void:
	if not player or enemies.size() == 0:
		return
	
	hide_positions.clear()
	var potential_hides := []
	
	var maze_width = AstarManager.maze[0].size() if AstarManager.maze.size() > 0 else 0
	var maze_height = AstarManager.maze.size()
	
	for enemy in enemies:
		var dir_to_player = (player.global_position - enemy.global_position).normalized()
		var hide_dir = -dir_to_player

		for i in range(1,4):
			var check_pos = enemy.global_position + hide_dir * (i * 16)
			var tile_pos = AstarManager.floor_tilemap.local_to_map(check_pos)
			
			if tile_pos.x >= 0 and tile_pos.y >= 0 and tile_pos.x < maze_width and tile_pos.y < maze_height:
				if AstarManager.maze[tile_pos.y][tile_pos.x]:
					potential_hides.append(check_pos)
					break
			
	
	hide_positions = potential_hides
	emit_signal("send_hide_positions", potential_hides)

func _count_nearby_allies(enemy: Node2D) -> int:
	var count := 0
	var enemy_pos = enemy.global_position
	var ally_radius = enemy.get_ally_radius if enemy.has_method("get_ally_radius") else 2
	for other in enemies:
		if other == enemy:
			continue
		if enemy_pos.distance_to(other.global_position) <= ally_radius * 16:
			count += 1
	return count
