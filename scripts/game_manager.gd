extends Node

var selected_game_mode: String = "moves"
var selected_counter_value: int = 30
var selected_score_goal: int = 1000

func set_game_mode(mode: String):
	selected_game_mode = mode
	if mode == "moves":
		selected_counter_value = 30
		selected_score_goal = 1000
	elif mode == "time":
		selected_counter_value = 60
		selected_score_goal = 1500

func set_custom_game_mode(mode: String, counter: int, goal: int):
	selected_game_mode = mode
	selected_counter_value = counter
	selected_score_goal = goal
