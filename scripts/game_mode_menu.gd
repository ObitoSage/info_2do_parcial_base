extends Control

var bg_music_player: AudioStreamPlayer
var animation_timer: Timer

func _ready():
	# Setup background music
	setup_menu_audio()
	
	# Setup colorful animations
	setup_menu_animations()
	
	$VBoxContainer/MovesButton.pressed.connect(_on_moves_button_pressed)
	$VBoxContainer/TimeButton.pressed.connect(_on_time_button_pressed)

func setup_menu_animations():
	# Create gradient background animation
	var color_rect = $ColorRect
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(color_rect, "color", Color(0.9, 0.4, 0.7, 1), 2.0)
	tween.tween_property(color_rect, "color", Color(0.6, 0.8, 0.9, 1), 2.0)
	tween.tween_property(color_rect, "color", Color(0.8, 0.9, 0.4, 1), 2.0)
	tween.tween_property(color_rect, "color", Color(0.8, 0.3, 0.9, 1), 2.0)
	
	# Animate title
	var title_label = $VBoxContainer/TitleLabel
	var title_tween = create_tween()
	title_tween.set_loops()
	title_tween.tween_property(title_label, "scale", Vector2(1.05, 1.05), 1.0)
	title_tween.tween_property(title_label, "scale", Vector2(1.0, 1.0), 1.0)
	
	animate_buttons()

func animate_buttons():
	var moves_button = $VBoxContainer/MovesButton
	var time_button = $VBoxContainer/TimeButton
	
	# Create hover effects for buttons
	moves_button.mouse_entered.connect(func(): animate_button_hover(moves_button))
	time_button.mouse_entered.connect(func(): animate_button_hover(time_button))
	
	moves_button.mouse_exited.connect(func(): animate_button_normal(moves_button))
	time_button.mouse_exited.connect(func(): animate_button_normal(time_button))

func animate_button_hover(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.2)
	tween.parallel().tween_property(button, "modulate", Color(1.2, 1.2, 1.2, 1), 0.2)

func animate_button_normal(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.2)
	tween.parallel().tween_property(button, "modulate", Color(1, 1, 1, 1), 0.2)

func setup_menu_audio():
	bg_music_player = AudioStreamPlayer.new()
	add_child(bg_music_player)
	
	if ResourceLoader.exists("res://assets/audio/MainBGM.mp3"):
		var main_bgm = load("res://assets/audio/MainBGM.mp3")
		if main_bgm:
			bg_music_player.stream = main_bgm
			bg_music_player.volume_db = -10
			# Set the stream to loop
			if bg_music_player.stream is AudioStreamMP3:
				bg_music_player.stream.loop = true
			bg_music_player.play()
			print("Menu music loaded and playing")
		else:
			print("Warning: Could not load MainBGM.mp3")
	else:
		print("Warning: MainBGM.mp3 file not found")

func _on_moves_button_pressed():
	if bg_music_player:
		bg_music_player.stop()
	GameManager.set_game_mode("moves")
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_time_button_pressed():
	if bg_music_player:
		bg_music_player.stop()
	GameManager.set_game_mode("time")
	get_tree().change_scene_to_file("res://scenes/game.tscn")
