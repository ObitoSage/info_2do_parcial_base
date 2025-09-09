extends Control

func _ready():
	$VBoxContainer/MovesButton.pressed.connect(_on_moves_button_pressed)
	$VBoxContainer/TimeButton.pressed.connect(_on_time_button_pressed)

func _on_moves_button_pressed():
	GameManager.set_game_mode("moves")
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_time_button_pressed():
	GameManager.set_game_mode("time")
	get_tree().change_scene_to_file("res://scenes/game.tscn")
