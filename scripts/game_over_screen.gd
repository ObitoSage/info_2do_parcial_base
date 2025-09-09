extends Control

@onready var result_label = $CenterContainer/VBoxContainer/ResultLabel
@onready var score_label = $CenterContainer/VBoxContainer/StatsContainer/ScoreLabel
@onready var goal_label = $CenterContainer/VBoxContainer/StatsContainer/GoalLabel
@onready var mode_label = $CenterContainer/VBoxContainer/StatsContainer/ModeLabel
@onready var remaining_label = $CenterContainer/VBoxContainer/StatsContainer/RemainingLabel
@onready var play_again_button = $CenterContainer/VBoxContainer/ButtonsContainer/PlayAgainButton
@onready var menu_button = $CenterContainer/VBoxContainer/ButtonsContainer/MenuButton

var game_won: bool = false

func _ready():
	play_again_button.pressed.connect(_on_play_again_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func setup_game_over_screen(won: bool, final_score: int, score_goal: int, game_mode: String, remaining_value: int):
	game_won = won
	
	# Ensure the control fills the screen and is centered
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Set result text and color with better formatting
	if won:
		result_label.text = "¡VICTORIA!"
		result_label.modulate = Color(0.2, 1.0, 0.2)  # Bright green
	else:
		result_label.text = "GAME OVER"  
		result_label.modulate = Color(1.0, 0.2, 0.2)  # Bright red
	
	# Set stats with better formatting
	score_label.text = "PUNTAJE FINAL: " + str(final_score)
	goal_label.text = "OBJETIVO: " + str(score_goal)
	
	if game_mode == "moves":
		mode_label.text = "MODO: MOVIMIENTOS"
		remaining_label.text = "MOVIMIENTOS RESTANTES: " + str(remaining_value)
	else:
		mode_label.text = "MODO: TIEMPO"
		remaining_label.text = "TIEMPO RESTANTE: " + str(remaining_value) + "s"
	
	# Color code the score based on achievement
	if final_score >= score_goal:
		score_label.modulate = Color(0.2, 1.0, 0.2)  # Bright green for success
		goal_label.modulate = Color(0.8, 0.8, 0.8)  # Light gray
	else:
		score_label.modulate = Color(1.0, 0.8, 0.2)  # Orange for partial success
		goal_label.modulate = Color(0.8, 0.8, 0.8)  # Light gray
	
	# Style other labels
	mode_label.modulate = Color(0.7, 0.7, 1.0)  # Light blue
	remaining_label.modulate = Color(1.0, 1.0, 0.8)  # Light yellow
	
	# Make sure the container is visible and properly sized
	show()
	
	print("Game Over screen setup complete - Won: ", won, " Final Score: ", final_score)

func _on_play_again_pressed():
	# Restart the game with the same mode
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_menu_pressed():
	# Go back to main menu
	get_tree().change_scene_to_file("res://scenes/game_mode_menu.tscn")
