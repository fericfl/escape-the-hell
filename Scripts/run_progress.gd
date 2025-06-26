extends Node

signal score_changed(new_score)
signal souls_changed(new_souls)

var HUD = preload("res://Scenes/hud.tscn")
var base_score_threshold := 1300
var base_boss_hits := 100
var souls_collected := 0
var rounds_completed := 0
var time_between_shots_boss: float = 1.5
var total_rounds_fired_boss := 1
var max_player_health := 3
var current_player_health = max_player_health
var player_damage := 25
var player_move_speed := 150
var player_shots := 1
var score = 0

func get_player_shots() -> int:
	return player_shots

func set_player_shots(no_of_shots: int):
	player_shots += no_of_shots

func get_player_move_speed() -> int:
	return player_move_speed

func set_player_move_speed(multiplier: float):
	player_move_speed *= multiplier

func get_player_damage() -> int:
	return player_damage

func set_player_damdage(new_damage: int):
	player_damage += new_damage

func set_score(new_score: int):
	score = new_score
	emit_signal("score_changed", score)

func add_score(add_score: int):
	score += add_score
	emit_signal("score_changed", score)
func get_score() -> int:
	return score


func get_current_total_rounds_fired_boss() -> int:
	return total_rounds_fired_boss + (rounds_completed * 2)

func get_current_tbsb() -> float:
	return time_between_shots_boss - (rounds_completed * 0.10)

func get_current_score_threshold() -> int:
	return base_score_threshold + (rounds_completed * 500)

func get_current_boss_hits() -> int:
	return base_boss_hits + (rounds_completed * 50)

func get_total_souls_collected() -> int:
	return souls_collected

func set_total_souls_collected(collected_souls: int) -> void:
	souls_collected += collected_souls
	emit_signal("souls_changed", souls_collected)

func add_current_player_health(current_health: int):
	if (current_health + current_player_health) > max_player_health:
		current_player_health = max_player_health
	else:
		current_player_health += current_health
	HUD.update_hearts()

func set_current_player_health(current_health: int):
	current_player_health = current_health
	HUD.update_hearts()

func get_current_player_health() -> int:
	return current_player_health

func get_max_player_health() -> int:
	return max_player_health

func set_player_health(new_health: int):
	max_player_health += new_health
	current_player_health += new_health

func reset_stats():
	base_score_threshold = 1000
	base_boss_hits = 100
	souls_collected = 0
	rounds_completed = 0
	time_between_shots_boss = 1.5
	total_rounds_fired_boss = 1
	max_player_health = 3
	current_player_health = max_player_health
	player_damage = 25
	player_move_speed = 150
	player_shots = 1
	score = 0
