extends Node

signal score_changed(new_score)
signal souls_changed(new_souls)

var HUD = preload("res://Scenes/hud.tscn")
var base_score_threshold := 1000
var base_boss_hits := 100
var souls_collected := 0
var rounds_completed := 0
var time_between_shots_boss: float = 1.5
var total_rounds_fired_boss := 1
var max_player_health := 3
var current_player_health = max_player_health
var score = 0

func set_score(new_score: int):
	score = new_score
	emit_signal("score_changed", score)

func get_score() -> int:
	return score
	

func get_current_total_rounds_fired_boss() -> int:
	return total_rounds_fired_boss + (rounds_completed * 2)

func get_current_tbsb() -> float:
	return time_between_shots_boss - (rounds_completed * 0.10)

func get_current_score_threshold() -> int:
	return base_score_threshold + (rounds_completed * 300)

func get_current_boss_hits() -> int:
	return base_boss_hits + (rounds_completed * 50)

func get_total_souls_collected() -> int:
	return souls_collected

func set_total_souls_collected(collected_souls: int) -> void:
	souls_collected += collected_souls
	emit_signal("souls_changed", souls_collected)

func set_current_player_health(current_health: int):
	current_player_health = current_health
	HUD.update_hearts()
	print("Updating health: ", current_health, " / ", max_player_health)

func get_current_player_health() -> int:
	return current_player_health

func get_max_player_health() -> int:
	return max_player_health

func set_player_health(new_health: int):
	max_player_health += new_health
	current_player_health += new_health
