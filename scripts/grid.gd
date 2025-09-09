extends Node2D

# state machine
enum {WAIT, MOVE}
var state
var current_state

# grid
@export var width: int
@export var height: int
@export var x_start: int
@export var y_start: int
@export var offset: int
@export var y_offset: int

# piece array
var possible_pieces = [
	preload("res://scenes/blue_piece.tscn"),
	preload("res://scenes/green_piece.tscn"),
	preload("res://scenes/light_green_piece.tscn"),
	preload("res://scenes/pink_piece.tscn"),
	preload("res://scenes/yellow_piece.tscn"),
	preload("res://scenes/orange_piece.tscn"),
]

# special pieces arrays
var column_pieces = {
	"blue": preload("res://scenes/blue_column_piece.tscn"),
	"green": preload("res://scenes/green_column_piece.tscn"),
	"light_green": preload("res://scenes/light_green_column_piece.tscn"),
	"pink": preload("res://scenes/pink_column_piece.tscn"),
	"yellow": preload("res://scenes/yellow_column_piece.tscn"),
	"orange": preload("res://scenes/orange_column_piece.tscn"),
}

var row_pieces = {
	"blue": preload("res://scenes/blue_row_piece.tscn"),
	"green": preload("res://scenes/green_row_piece.tscn"),
	"light_green": preload("res://scenes/light_green_row_piece.tscn"),
	"pink": preload("res://scenes/pink_row_piece.tscn"),
	"yellow": preload("res://scenes/yellow_row_piece.tscn"),
	"orange": preload("res://scenes/orange_row_piece.tscn"),
}

var bomb_pieces = {
	"blue": preload("res://scenes/blue_bomb_piece.tscn"),
	"green": preload("res://scenes/green_bomb_piece.tscn"),
	"light_green": preload("res://scenes/light_green_bomb_piece.tscn"),
	"pink": preload("res://scenes/pink_bomb_piece.tscn"),
	"yellow": preload("res://scenes/yellow_bomb_piece.tscn"),
	"orange": preload("res://scenes/orange_bomb_piece.tscn"),
}

var rainbow_piece = preload("res://scenes/rainbow_piece.tscn")

# current pieces in scene
var all_pieces = []

# swap back
var piece_one = null
var piece_two = null
var last_place = Vector2.ZERO
var last_place_two = Vector2.ZERO  # For free swap system
var last_direction = Vector2.ZERO
var move_checked = false

# touch variables
var first_touch = Vector2.ZERO
var final_touch = Vector2.ZERO
var first_touch_pos = Vector2.ZERO

# Free movement variables
var selected_piece_pos = Vector2(-1, -1)  # Position of currently selected piece
var is_piece_selected = false
var is_controlling = false

# scoring variables and signals
@export var current_score: int = 0
@export var score_goal: int = 1000
signal update_score

# counter variables and signals
@export var current_counter_value: int = 30
@export var game_mode: String = "moves" # "moves" or "time"
signal update_counter

# game state variables
var game_over_flag: bool = false
var game_timer: Timer

# special pieces creation system
var special_pieces_to_create = []
var pieces_to_destroy = []

# Ice/freeze system
var frozen_pieces = {}  # Dictionary to track frozen pieces
var ice_spawn_chance = 0.25  # 25% chance to spawn ice piece after each move
var ice_pieces_on_board = []  # Track actual ice pieces on the board

var x_offset: int

# Audio system
var audio_player: AudioStreamPlayer
var bg_music_player: AudioStreamPlayer
var special_effects_player: AudioStreamPlayer  # For special effects like ice break and bomb explosions
var fruit_select_sounds = []
var match_sounds = []
var special_match_sounds = []
var awesome_match_sounds = []
var game_win_sound: AudioStream
var ice_break_sound: AudioStream
var blast_time_sound: AudioStream
var girl_set_ball_sound: AudioStream

func _ready():
	state = MOVE
	randomize()
	
	# Initialize audio system
	setup_audio_system()
	
	# Initialize grid calculation variables
	x_offset = offset
	
	all_pieces = make_2d_array()
	spawn_pieces()
	
	await get_tree().create_timer(1.0).timeout
	spawn_random_ice_piece()
	
	setup_game_mode(GameManager.selected_game_mode, GameManager.selected_counter_value, GameManager.selected_score_goal)
	
	# Connect signals to UI
	update_score.connect(_on_score_updated)
	update_counter.connect(_on_counter_updated)

func setup_audio_system():
	# Create audio players
	audio_player = AudioStreamPlayer.new()
	bg_music_player = AudioStreamPlayer.new()
	special_effects_player = AudioStreamPlayer.new()
	add_child(audio_player)
	add_child(bg_music_player)
	add_child(special_effects_player)
	
	for i in range(12):
		var sound_path = "res://assets/audio/FruitSelect_" + str(i) + ".mp3"
		if ResourceLoader.exists(sound_path):
			var sound = ResourceLoader.load(sound_path, "AudioStreamMP3")
			if sound:
				fruit_select_sounds.append(sound)
				print("Loaded audio: ", sound_path)
		else:
			print("Warning: Audio file not found: ", sound_path)
	
	# Load sounds
	if ResourceLoader.exists("res://assets/audio/Match1.mp3"):
		var match1 = ResourceLoader.load("res://assets/audio/Match1.mp3", "AudioStreamMP3")
		if match1:
			match_sounds.append(match1)
	
	if ResourceLoader.exists("res://assets/audio/Match2.mp3"):
		var match2 = ResourceLoader.load("res://assets/audio/Match2.mp3", "AudioStreamMP3")
		if match2:
			match_sounds.append(match2)
	
	if ResourceLoader.exists("res://assets/audio/Grood.mp3"):
		var grood = ResourceLoader.load("res://assets/audio/Grood.mp3", "AudioStreamMP3")
		if grood:
			special_match_sounds.append(grood)
	
	if ResourceLoader.exists("res://assets/audio/Great.mp3"):
		var great = ResourceLoader.load("res://assets/audio/Great.mp3", "AudioStreamMP3")
		if great:
			special_match_sounds.append(great)
	
	if ResourceLoader.exists("res://assets/audio/WowAwesome.mp3"):
		var wow_awesome = ResourceLoader.load("res://assets/audio/WowAwesome.mp3", "AudioStreamMP3")
		if wow_awesome:
			awesome_match_sounds.append(wow_awesome)
	
	if ResourceLoader.exists("res://assets/audio/GameWin.mp3"):
		game_win_sound = ResourceLoader.load("res://assets/audio/GameWin.mp3", "AudioStreamMP3")
	
	if ResourceLoader.exists("res://assets/audio/IceBreak.mp3"):
		ice_break_sound = ResourceLoader.load("res://assets/audio/IceBreak.mp3", "AudioStreamMP3")
	
	if ResourceLoader.exists("res://assets/audio/BlastTime.mp3"):
		blast_time_sound = ResourceLoader.load("res://assets/audio/BlastTime.mp3", "AudioStreamMP3")
	
	if ResourceLoader.exists("res://assets/audio/GirlSetBall.mp3"):
		girl_set_ball_sound = ResourceLoader.load("res://assets/audio/GirlSetBall.mp3", "AudioStreamMP3")
	
	# Start background music
	if ResourceLoader.exists("res://assets/audio/GameBGM.mp3"):
		var game_bgm = ResourceLoader.load("res://assets/audio/GameBGM.mp3", "AudioStreamMP3")
		if game_bgm:
			bg_music_player.stream = game_bgm
			bg_music_player.volume_db = -10
			if bg_music_player.stream is AudioStreamMP3:
				bg_music_player.stream.loop = true
			bg_music_player.play()
	
	print("Audio system initialized - Fruit sounds: ", fruit_select_sounds.size(), 
		  " Match sounds: ", match_sounds.size(), 
		  " Special sounds: ", special_match_sounds.size(),
		  " BlastTime loaded: ", blast_time_sound != null,
		  " IceBreak loaded: ", ice_break_sound != null,
		  " GirlSetBall loaded: ", girl_set_ball_sound != null)

func play_fruit_select_sound():
	if fruit_select_sounds.size() > 0:
		var random_sound = fruit_select_sounds[randi() % fruit_select_sounds.size()]
		audio_player.stream = random_sound
		audio_player.volume_db = -5
		audio_player.play()

func play_match_sound():
	if match_sounds.size() > 0:
		var random_sound = match_sounds[randi() % match_sounds.size()]
		audio_player.stream = random_sound
		audio_player.volume_db = -3
		audio_player.play()

func play_special_match_sound():
	if special_match_sounds.size() > 0:
		var random_sound = special_match_sounds[randi() % special_match_sounds.size()]
		audio_player.stream = random_sound
		audio_player.volume_db = -2
		audio_player.play()

func play_awesome_match_sound():
	if awesome_match_sounds.size() > 0:
		var random_sound = awesome_match_sounds[randi() % awesome_match_sounds.size()]
		audio_player.stream = random_sound
		audio_player.volume_db = -1
		audio_player.play()

func play_ice_break_sound():
	print("Attempting to play IceBreak sound. ice_break_sound exists: ", ice_break_sound != null)
	if ice_break_sound:
		special_effects_player.stream = ice_break_sound
		special_effects_player.volume_db = -3
		special_effects_player.play()
		print("IceBreak sound played successfully on special_effects_player")
	else:
		print("ERROR: ice_break_sound is null!")

func play_blast_time_sound():
	if blast_time_sound:
		audio_player.stream = blast_time_sound
		audio_player.volume_db = -2
		audio_player.play()

func play_girl_set_ball_sound():
	if girl_set_ball_sound:
		special_effects_player.stream = girl_set_ball_sound
		special_effects_player.volume_db = -1
		special_effects_player.play()
		print("GirlSetBall sound played for bomb explosion")
	else:
		print("ERROR: girl_set_ball_sound is null!")

func freeze_piece(x: int, y: int):
	if all_pieces[x][y] != null and not is_piece_frozen(x, y):
		var piece = all_pieces[x][y]
		var freeze_key = str(x) + "," + str(y)
		frozen_pieces[freeze_key] = true
		ice_pieces_on_board.append(Vector2(x, y))
		
		var sprite = piece.get_node("Sprite2D")
		var ice_shader = null
		
		if ResourceLoader.exists("res://shaders/ice_freeze.gdshader"):
			ice_shader = ResourceLoader.load("res://shaders/ice_freeze.gdshader")
		
		if ice_shader != null:
			var ice_material = ShaderMaterial.new()
			ice_material.shader = ice_shader
			ice_material.set_shader_parameter("freeze_progress", 1.0)
			ice_material.set_shader_parameter("ice_color", Color(0.3, 0.7, 1.0, 1.0))
			ice_material.set_shader_parameter("ice_thickness", 0.9)
			
			sprite.material = ice_material
			
			var tween = create_tween()
			ice_material.set_shader_parameter("freeze_progress", 0.0)
			tween.tween_method(func(value): set_freeze_progress(ice_material, value), 0.0, 1.0, 0.8)
		else:
			print("Using fallback ice effect (no shader)")
			sprite.modulate = Color(0.2, 0.5, 1.0, 0.8)
			
			var border = ColorRect.new()
			border.color = Color(0.1, 0.4, 1.0, 1.0)
			border.size = sprite.texture.get_size() + Vector2(8, 8)
			border.position = Vector2(-4, -4)
			border.z_index = -1
			sprite.add_child(border)
		
		# Add visual glow effect
		var original_scale = sprite.scale
		var tween = create_tween()
		tween.tween_property(sprite, "scale", original_scale * 1.1, 0.2)
		tween.tween_property(sprite, "scale", original_scale, 0.2)
		
		print("Piece at (", x, ",", y, ") has been frozen with ice")

func set_freeze_progress(ice_material: ShaderMaterial, value: float):
	if ice_material != null:
		ice_material.set_shader_parameter("freeze_progress", value)

func unfreeze_piece(x: int, y: int):
	if all_pieces[x][y] != null and is_piece_frozen(x, y):
		print("UNFREEZING PIECE AT (", x, ",", y, ") - Playing IceBreak sound")
		var piece = all_pieces[x][y]
		var freeze_key = str(x) + "," + str(y)
		
		frozen_pieces.erase(freeze_key)
		
		# Remove from ice pieces list
		var pos = Vector2(x, y)
		if pos in ice_pieces_on_board:
			ice_pieces_on_board.erase(pos)
		
		# Play ice break sound
		play_ice_break_sound()
		
		var sprite = piece.get_node("Sprite2D")
		
		# Remove ice effect (either shader or fallback effect)
		if sprite.material != null:
			# Has shader material
			var ice_mat = sprite.material as ShaderMaterial
			var tween = create_tween()
			tween.tween_method(func(value): set_freeze_progress(ice_mat, value), 1.0, 0.0, 0.3)
			tween.tween_callback(func(): sprite.material = null)
		else:
			sprite.modulate = Color.WHITE
			for child in sprite.get_children():
				if child is ColorRect:
					child.queue_free()
		
		print("Piece at (", x, ",", y, ") has been unfrozen")

func is_piece_frozen(x: int, y: int) -> bool:
	var freeze_key = str(x) + "," + str(y)
	return freeze_key in frozen_pieces

func spawn_random_ice_piece():
	if ice_pieces_on_board.size() >= 3:
		print("Max ice pieces reached (", ice_pieces_on_board.size(), "), not spawning more")
		return
	
	print("Attempting to spawn ice piece. Current ice pieces on board: ", ice_pieces_on_board.size())
		
	var attempts = 0
	var max_attempts = 20
	
	while attempts < max_attempts:
		var x = randi_range(0, width - 1)
		var y = randi_range(0, height - 1)
		
		if all_pieces[x][y] != null and not is_piece_frozen(x, y):
			freeze_piece(x, y)
			print("Ice piece spawned at (", x, ",", y, "). Total ice pieces: ", ice_pieces_on_board.size())
			return
		
		attempts += 1
	
	print("Could not spawn ice piece - no suitable location found")

func check_ice_pieces_in_matches():
	var pieces_to_unfreeze = []
	
	print("Checking ice pieces in matches. Ice pieces on board: ", ice_pieces_on_board.size())
	
	for ice_pos in ice_pieces_on_board:
		var x = int(ice_pos.x)
		var y = int(ice_pos.y)
		
		if all_pieces[x][y] != null and all_pieces[x][y].matched:
			print("Ice piece at (", x, ",", y, ") is part of a match - will unfreeze")
			pieces_to_unfreeze.append(ice_pos)
	
	# Unfreeze pieces that were part of matches
	for pos in pieces_to_unfreeze:
		print("Unfreezing ice piece at (", int(pos.x), ",", int(pos.y), ")")
		unfreeze_piece(int(pos.x), int(pos.y))

func play_game_win_sound():
	if game_win_sound:
		audio_player.stream = game_win_sound
		audio_player.volume_db = 0
		audio_player.play()
	


func make_2d_array():
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array
	
func grid_to_pixel(column, row):
	var new_x = x_start + offset * column
	var new_y = y_start - offset * row
	return Vector2(new_x, new_y)
	
func pixel_to_grid(pixel_x, pixel_y):
	var new_x = round((pixel_x - x_start) / offset)
	var new_y = round((pixel_y - y_start) / -offset)
	return Vector2(new_x, new_y)
	
func in_grid(column, row):
	return column >= 0 and column < width and row >= 0 and row < height
	
func spawn_pieces():
	for i in width:
		for j in height:
			# random number
			var rand = randi_range(0, possible_pieces.size() - 1)
			# instance 
			var piece = possible_pieces[rand].instantiate()
			# repeat until no matches
			var max_loops = 100
			var loops = 0
			while (match_at(i, j, piece.color) and loops < max_loops):
				rand = randi_range(0, possible_pieces.size() - 1)
				loops += 1
				piece = possible_pieces[rand].instantiate()
			add_child(piece)
			piece.position = grid_to_pixel(i, j)
			# fill array with pieces
			all_pieces[i][j] = piece

func match_at(i, j, color):
	# check left
	if i > 1:
		if all_pieces[i - 1][j] != null and all_pieces[i - 2][j] != null:
			if all_pieces[i - 1][j].color == color and all_pieces[i - 2][j].color == color:
				return true
	# check down
	if j > 1:
		if all_pieces[i][j - 1] != null and all_pieces[i][j - 2] != null:
			if all_pieces[i][j - 1].color == color and all_pieces[i][j - 2].color == color:
				return true
	return false

func touch_input():
	if Input.is_action_just_pressed("ui_touch"):
		var mouse_pos = get_global_mouse_position()
		var grid_1 = pixel_to_grid(mouse_pos.x, mouse_pos.y)
		if in_grid(grid_1.x, grid_1.y):
			# first_touch = true
			var difference = grid_1 - first_touch_pos
			if abs(difference.x) > abs(difference.y):
				if difference.x > 0:
					swap_pieces(grid_1.x, grid_1.y, Vector2(-1, 0))
				elif difference.x < 0:
					swap_pieces(grid_1.x, grid_1.y, Vector2(1, 0))
			elif abs(difference.y) > abs(difference.x):
				if difference.y > 0:
					swap_pieces(grid_1.x, grid_1.y, Vector2(0, -1))
				elif difference.y < 0:
					swap_pieces(grid_1.x, grid_1.y, Vector2(0, 1))
	
	if Input.is_action_just_released("ui_touch"):
		var mouse_pos = get_global_mouse_position()
		var grid_1 = pixel_to_grid(mouse_pos.x, mouse_pos.y)
		if in_grid(grid_1.x, grid_1.y):
			first_touch_pos = grid_1

func swap_pieces(column, row, direction: Vector2):
	var first_piece = all_pieces[column][row]
	var other_piece = all_pieces[column + direction.x][row + direction.y]
	if first_piece == null or other_piece == null:
		return
	
	# Check if either piece is frozen - if so, prevent swap
	if is_piece_frozen(column, row) or is_piece_frozen(column + direction.x, row + direction.y):
		print("Cannot swap: one or both pieces are frozen")
		# Visual feedback for blocked move
		if is_piece_frozen(column, row):
			first_piece.shake_effect()
		if is_piece_frozen(column + direction.x, row + direction.y):
			other_piece.shake_effect()
		return
	
	# For rainbow pieces, activate immediately on touch
	var special_activated = false
	if first_piece.piece_type == "rainbow":
		activate_special_piece(column, row, first_piece.piece_type)
		special_activated = true
	elif other_piece.piece_type == "rainbow":
		activate_special_piece(column + direction.x, row + direction.y, other_piece.piece_type)
		special_activated = true
	
	# If rainbow piece was activated, handle the cascade
	if special_activated:
		current_state = WAIT
		destroy_matched()
		return
	
	current_state = WAIT
	store_info(first_piece, other_piece, Vector2(column, row), direction)
	all_pieces[column][row] = other_piece
	all_pieces[column + direction.x][row + direction.y] = first_piece
	first_piece.move(grid_to_pixel(column + direction.x, row + direction.y))
	other_piece.move(grid_to_pixel(column, row))
	
	# Play fruit select sound for piece movement
	play_fruit_select_sound()
	
	if not move_checked:
		find_matches()

func store_info(first_piece, other_piece, place, direction_or_place2):
	piece_one = first_piece
	piece_two = other_piece
	last_place = place
	
	if abs(direction_or_place2.x) <= 1 and abs(direction_or_place2.y) <= 1:
		last_direction = direction_or_place2
		last_place_two = place + direction_or_place2
	else:
		last_place_two = direction_or_place2
		last_direction = direction_or_place2 - place

func swap_back():
	print("swap_back called")
	if piece_one != null or piece_two != null:
		print("Swapping pieces back from position: ", last_place, " to position: ", last_place_two)
		
		all_pieces[last_place.x][last_place.y] = piece_one
		all_pieces[last_place_two.x][last_place_two.y] = piece_two
		
		if piece_one != null:
			piece_one.move(grid_to_pixel(last_place.x, last_place.y))
		if piece_two != null:
			piece_two.move(grid_to_pixel(last_place_two.x, last_place_two.y))
	
	piece_one = null
	piece_two = null
	last_place = Vector2.ZERO
	last_direction = Vector2.ZERO
	
	print("Returning to MOVE state")
	state = MOVE
	move_checked = false

func touch_difference(grid_1, grid_2):
	var difference = grid_2 - grid_1
	if abs(difference.x) > abs(difference.y):
		if difference.x > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(1, 0))
		elif difference.x < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(-1, 0))
	elif abs(difference.y) > abs(difference.x):
		if difference.y > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, 1))
		elif difference.y < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, -1))

func _process(_delta):
	if state == MOVE and not game_over_flag:
		touch_input()
	
	if Engine.get_process_frames() % 60 == 0:  
		print("Game State: ", state, " | Game Over: ", game_over_flag, " | Mode: ", game_mode, " | Counter: ", current_counter_value)

func find_matches():
	var matches_found = false
	var special_pieces_in_matches = []
	
	special_pieces_to_create.clear()
	
	# Basic match detection (3+ in a row)
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				var current_piece = all_pieces[i][j]
				if current_piece.matched:
					continue
				
				if i <= width - 3:
					if all_pieces[i + 1][j] != null and all_pieces[i + 2][j] != null:
						if current_piece.color == all_pieces[i + 1][j].color and current_piece.color == all_pieces[i + 2][j].color:
							# Count how many pieces match
							var match_length = 3
							var _start_x = i
							
							while i + match_length < width and all_pieces[i + match_length][j] != null and all_pieces[i + match_length][j].color == current_piece.color:
								match_length += 1
							
							for k in range(match_length):
								var piece = all_pieces[i + k][j]
								if not piece.matched:  # Don't double-mark
									piece.matched = true
									piece.flash_match_effect()  # Flash effect
									piece.dim()
									
									if piece.piece_type in ["bomb", "row", "column"]:
										special_pieces_in_matches.append({
											"x": i + k,
											"y": j,
											"type": piece.piece_type
										})
							
							matches_found = true
							
							if match_length == 4:
								var special_data = {
									"x": i + 1,  
									"y": j,
									"piece_type": "row", 
									"color": current_piece.color
								}
								special_pieces_to_create.append(special_data)
								current_score += 50
								print("=== 4-MATCH HORIZONTAL DETECTED ===")
								print("Will create ROW piece at (", i + 1, ",", j, ") with color: ", current_piece.color)
								print("Special pieces queue size: ", special_pieces_to_create.size())
								
								# Efecto especial para match de 4 
								create_special_match_effect(i + 1, j, "4_horizontal")
							elif match_length >= 5:
								special_pieces_to_create.append({
									"x": i + 2,  
									"y": j,
									"piece_type": "rainbow",
									"color": current_piece.color
								})
								current_score += 200
								print("5+ match horizontal detected - will create rainbow piece")
								create_special_match_effect(i + 2, j, "5_match")
							else:
								current_score += match_length * 10
				
				# Check vertical matches
				if j <= height - 3:
					if all_pieces[i][j + 1] != null and all_pieces[i][j + 2] != null:
						if current_piece.color == all_pieces[i][j + 1].color and current_piece.color == all_pieces[i][j + 2].color:
							var match_length = 3
							var _start_y = j
							
							while j + match_length < height and all_pieces[i][j + match_length] != null and all_pieces[i][j + match_length].color == current_piece.color:
								match_length += 1
							
							for k in range(match_length):
								var piece = all_pieces[i][j + k]
								if not piece.matched: 
									piece.matched = true
									piece.flash_match_effect()  # Flash effect
									piece.dim()
									
									if piece.piece_type in ["bomb", "row", "column"]:
										special_pieces_in_matches.append({
											"x": i,
											"y": j + k,
											"type": piece.piece_type
										})
							
							matches_found = true
							
						
							if match_length == 4:
								var special_data = {
									"x": i,
									"y": j + 1, 
									"piece_type": "column",
									"color": current_piece.color
								}
								special_pieces_to_create.append(special_data)
								current_score += 50
								print("=== 4-MATCH VERTICAL DETECTED ===")
								print("Will create COLUMN piece at (", i, ",", j + 1, ") with color: ", current_piece.color)
								print("Special pieces queue size: ", special_pieces_to_create.size())
								
								# Efecto especial para match de 4 
								create_special_match_effect(i, j + 1, "4_vertical")
							elif match_length >= 5:
								special_pieces_to_create.append({
									"x": i,
									"y": j + 2,  
									"piece_type": "rainbow",
									"color": current_piece.color
								})
								current_score += 200
								print("5+ match vertical detected - will create rainbow piece")
								create_special_match_effect(i, j + 2, "5_match")
							else:
								current_score += match_length * 10
	
	for i in range(1, width - 1):
		for j in range(1, height - 1):
			if all_pieces[i][j] != null and not all_pieces[i][j].matched:
				var center_piece = all_pieces[i][j]
				
				if (all_pieces[i-1][j] != null and all_pieces[i+1][j] != null and 
					all_pieces[i][j-1] != null and all_pieces[i][j+1] != null):
					
					if (center_piece.color == all_pieces[i-1][j].color and 
						center_piece.color == all_pieces[i+1][j].color and
						center_piece.color == all_pieces[i][j-1].color and
						center_piece.color == all_pieces[i][j+1].color):
						
						var t_pieces = [
							all_pieces[i][j],
							all_pieces[i-1][j],
							all_pieces[i+1][j],
							all_pieces[i][j-1],
							all_pieces[i][j+1]
						]
						
						for piece in t_pieces:
							piece.matched = true
							piece.dim()
							
							if piece.piece_type in ["bomb", "row", "column"]:
								var pos = pixel_to_grid(piece.position.x, piece.position.y)
								special_pieces_in_matches.append({
									"x": int(pos.x),
									"y": int(pos.y),
									"type": piece.piece_type
								})
						
						matches_found = true
						
						# Create rainbow piece 
						special_pieces_to_create.append({
							"x": i,
							"y": j,
							"piece_type": "rainbow",
							"color": center_piece.color
						})
						current_score += 200
						print("T-match detected - will create rainbow piece (Ficha 5)")
						create_special_match_effect(i, j, "t_match")
	
	if special_pieces_in_matches.size() > 0:
		print("Activating ", special_pieces_in_matches.size(), " special pieces that were in matches")
		for special_piece in special_pieces_in_matches:
			activate_special_piece(special_piece.x, special_piece.y, special_piece.type)
	
	check_ice_pieces_in_matches()
	
	if matches_found:
		print("Matches found! Special pieces to create: ", special_pieces_to_create.size())
		
		var has_5_match = false
		var has_4_match = false
		
		for special_data in special_pieces_to_create:
			if special_data.piece_type == "rainbow":
				has_5_match = true
			elif special_data.piece_type in ["row", "column"]:
				has_4_match = true
		
		play_match_sound()
		
		if has_5_match:
			await get_tree().create_timer(0.2).timeout
			play_blast_time_sound()
		elif has_4_match:
			await get_tree().create_timer(0.2).timeout
			play_blast_time_sound()
		
		if special_pieces_to_create.size() > 0:
			create_screen_flash_effect()
		
		get_parent().get_node("destroy_timer").start()
	else:
		swap_back()

func detect_horizontal_matches():
	var matches = []
	
	for j in height:
		var i = 0
		while i < width:
			if all_pieces[i][j] != null and not all_pieces[i][j].matched:
				var current_color = all_pieces[i][j].color
				var match_length = 1
				var start_i = i
				
				while i + match_length < width and all_pieces[i + match_length][j] != null and all_pieces[i + match_length][j].color == current_color and not all_pieces[i + match_length][j].matched:
					match_length += 1
				
				if match_length >= 3:
					matches.append({
						"type": "horizontal",
						"color": current_color,
						"start_x": start_i,
						"y": j,
						"length": match_length
					})
				
				i = start_i + match_length
			else:
				i += 1
	
	return matches

func detect_vertical_matches():
	var matches = []
	
	for i in width:
		var j = 0
		while j < height:
			if all_pieces[i][j] != null and not all_pieces[i][j].matched:
				var current_color = all_pieces[i][j].color
				var match_length = 1
				var start_j = j
				
				while j + match_length < height and all_pieces[i][j + match_length] != null and all_pieces[i][j + match_length].color == current_color and not all_pieces[i][j + match_length].matched:
					match_length += 1
				
				if match_length >= 3:
					matches.append({
						"type": "vertical",
						"color": current_color,
						"x": i,
						"start_y": start_j,
						"length": match_length
					})
				
				j = start_j + match_length
			else:
				j += 1
	
	return matches

func detect_t_matches():
	var matches = []
	
	for i in range(1, width - 1):
		for j in range(1, height - 1):
			if all_pieces[i][j] != null and not all_pieces[i][j].matched:
				var current_color = all_pieces[i][j].color
				
				if (all_pieces[i-1][j] != null and all_pieces[i+1][j] != null and
					all_pieces[i][j-1] != null and all_pieces[i][j+1] != null and
					all_pieces[i-1][j].color == current_color and all_pieces[i+1][j].color == current_color and
					all_pieces[i][j-1].color == current_color and all_pieces[i][j+1].color == current_color and
					not all_pieces[i-1][j].matched and not all_pieces[i+1][j].matched and
					not all_pieces[i][j-1].matched and not all_pieces[i][j+1].matched):
					
					matches.append({
						"type": "t_shape",
						"color": current_color,
						"center": Vector2(i, j),
						"pieces": [
							Vector2(i, j),
							Vector2(i-1, j),
							Vector2(i+1, j),
							Vector2(i, j-1),
							Vector2(i, j+1)
						]
					})
	
	return matches

func mark_match_pieces(match):
	if match.type == "horizontal":
		for x in range(match.start_x, match.start_x + match.length):
			if all_pieces[x][match.y] != null:
				all_pieces[x][match.y].matched = true
				all_pieces[x][match.y].dim()
	elif match.type == "vertical":
		for y in range(match.start_y, match.start_y + match.length):
			if all_pieces[match.x][y] != null:
				all_pieces[match.x][y].matched = true
				all_pieces[match.x][y].dim()
	elif match.type == "t_shape":
		for piece_pos in match.pieces:
			if all_pieces[piece_pos.x][piece_pos.y] != null:
				all_pieces[piece_pos.x][piece_pos.y].matched = true
				all_pieces[piece_pos.x][piece_pos.y].dim()

func destroy_matched():
	var was_matched = false
	var _pieces_destroyed = 0
	
	print("destroy_matched called - move_checked: ", move_checked, " game_mode: ", game_mode)
	print("Special pieces to create before destruction: ", special_pieces_to_create.size())
	print("Additional pieces to destroy: ", pieces_to_destroy.size())
	
	if special_pieces_to_create.size() > 0:
		print("Creating special pieces BEFORE destroying matched pieces")
		create_special_pieces_immediately()
	
	for piece in pieces_to_destroy:
		if piece != null and is_instance_valid(piece):
			was_matched = true
			_pieces_destroyed += 1
			current_score += 10
			
			for i in width:
				for j in height:
					if all_pieces[i][j] == piece:
						all_pieces[i][j] = null
						break
			
			piece.queue_free()
	
	pieces_to_destroy.clear()
	
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and all_pieces[i][j].matched:
				was_matched = true
				_pieces_destroyed += 1
				current_score += 10
				all_pieces[i][j].queue_free()
				all_pieces[i][j] = null
			elif all_pieces[i][j] != null:
				all_pieces[i][j].matched = false
				all_pieces[i][j].modulate = Color(1, 1, 1, 1)
	
	update_score.emit()
	
	if was_matched and game_mode == "moves" and move_checked:
		current_counter_value -= 1
		update_counter.emit()
		print("Moves decremented. Remaining: ", current_counter_value)
		
		if randf() < ice_spawn_chance:
			spawn_random_ice_piece()
		
		if current_counter_value <= 0:
			check_game_over()
			return
	
	move_checked = true
	if was_matched:
		print("Starting collapse timer")
		get_parent().get_node("collapse_timer").start()
	else:
		print("No matches found, swapping back")
		swap_back()

func create_special_pieces_immediately():
	print("Creating special pieces immediately: ", special_pieces_to_create.size())
	
	for special_piece_data in special_pieces_to_create:
		var x = special_piece_data.x
		var y = special_piece_data.y
		var piece_type = special_piece_data.piece_type
		var color = special_piece_data.color
		
		print("Creating special piece at (", x, ",", y, ") type: ", piece_type, " color: ", color)
		
		if all_pieces[x][y] != null:
			print("Removing existing piece at (", x, ",", y, ") before creating special piece")
			all_pieces[x][y].queue_free()
			all_pieces[x][y] = null
		
		var piece_to_instantiate = get_special_piece_scene(piece_type, color)
		
		if piece_to_instantiate != null:
			var piece = piece_to_instantiate.instantiate()
			add_child(piece)
			piece.position = grid_to_pixel(x, y)
			all_pieces[x][y] = piece
			piece.piece_type = piece_type
			piece.color = color
			piece.matched = false
			piece.modulate = Color(1, 1, 1, 1)
			print("*** SPECIAL PIECE CREATED IMMEDIATELY at (", x, ",", y, ") ***")
	
	special_pieces_to_create.clear()

func create_destruction_particles(x: int, y: int, piece_color: String):
	var particles = GPUParticles2D.new()
	add_child(particles)
	
	particles.position = grid_to_pixel(x, y)
	
	var particle_material = ParticleProcessMaterial.new()
	particles.process_material = particle_material
	
	# Configuración básica
	particle_material.direction = Vector3(0, -1, 0)
	particle_material.initial_velocity_min = 50.0
	particle_material.initial_velocity_max = 150.0
	particle_material.angular_velocity_min = -180.0
	particle_material.angular_velocity_max = 180.0
	particle_material.gravity = Vector3(0, 98, 0)
	particle_material.scale_min = 0.3
	particle_material.scale_max = 0.8
	
	var particle_color = get_piece_color(piece_color)
	particle_material.color = particle_color
	
	particles.amount = 15
	particles.lifetime = 1.5
	particles.emitting = true
	
	await get_tree().create_timer(2.0).timeout
	particles.queue_free()

func create_match_effect(x: int, y: int, match_length: int, direction: String):
	# Crear efecto visual para matches especiales
	var effect_particles = GPUParticles2D.new()
	add_child(effect_particles)
	effect_particles.position = grid_to_pixel(x, y)
	
	var effect_material = ParticleProcessMaterial.new()
	effect_particles.process_material = effect_material
	
	# Configurar según el tipo de match
	match match_length:
		4:
			effect_material.color = Color.GOLD
			effect_particles.amount = 25
			effect_material.scale_min = 0.5
			effect_material.scale_max = 1.2
		5:
			effect_material.color = Color.MAGENTA
			effect_particles.amount = 40
			effect_material.scale_min = 0.8
			effect_material.scale_max = 2.0
		_:
			effect_material.color = Color.CYAN
			effect_particles.amount = 30
	
	if direction == "horizontal":
		effect_material.direction = Vector3(-1, 0, 0)
		effect_material.spread = 30.0
	else: 
		effect_material.direction = Vector3(0, -1, 0)
		effect_material.spread = 30.0
	
	effect_material.initial_velocity_min = 100.0
	effect_material.initial_velocity_max = 200.0
	effect_material.gravity = Vector3(0, 50, 0)
	
	effect_particles.lifetime = 1.0
	effect_particles.emitting = true
	
	await get_tree().create_timer(1.5).timeout
	effect_particles.queue_free()

func get_piece_color(color_name: String) -> Color:
	match color_name:
		"blue": return Color.BLUE
		"green": return Color.GREEN
		"light_green": return Color.LIGHT_GREEN
		"pink": return Color.PINK
		"yellow": return Color.YELLOW
		"orange": return Color.ORANGE
		_: return Color.WHITE

func create_special_match_effect(x: int, y: int, effect_type: String):
	var effect_node = Node2D.new()
	add_child(effect_node)
	effect_node.position = grid_to_pixel(x, y)
	
	var effect_sprite = Sprite2D.new()
	effect_node.add_child(effect_sprite)
	
	match effect_type:
		"4_horizontal":
			effect_sprite.modulate = Color.GOLD
			create_line_effect(effect_node, "horizontal")
		"4_vertical":
			effect_sprite.modulate = Color.GOLD  
			create_line_effect(effect_node, "vertical")
		"5_match":
			effect_sprite.modulate = Color.MAGENTA
			create_explosion_effect(effect_node)
		"t_match":
			effect_sprite.modulate = Color.CYAN
			create_cross_effect(effect_node)
	
	await get_tree().create_timer(1.0).timeout
	if effect_node and is_instance_valid(effect_node):
		effect_node.queue_free()

func create_line_effect(effect_node: Node2D, direction: String):
	var tween = create_tween()
	tween.set_parallel(true)
	
	if direction == "horizontal":
		tween.tween_property(effect_node, "scale", Vector2(3.0, 0.5), 0.3)
	else:
		tween.tween_property(effect_node, "scale", Vector2(0.5, 3.0), 0.3)
	
	tween.tween_property(effect_node, "modulate", Color(1, 1, 1, 0), 0.5)

func create_explosion_effect(effect_node: Node2D):
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(effect_node, "scale", Vector2(4.0, 4.0), 0.4)
	tween.tween_property(effect_node, "rotation", PI * 2, 0.4)
	tween.tween_property(effect_node, "modulate", Color(1, 1, 1, 0), 0.6)

func create_cross_effect(effect_node: Node2D):
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(effect_node, "scale", Vector2(2.5, 2.5), 0.4)
	tween.tween_property(effect_node, "rotation", PI, 0.4)
	tween.tween_property(effect_node, "modulate", Color(1, 1, 1, 0), 0.5)

func create_screen_flash_effect():
	var flash_overlay = ColorRect.new()
	get_tree().current_scene.add_child(flash_overlay)
	
	flash_overlay.color = Color(1, 1, 1, 0)
	flash_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash_overlay.z_index = 100
	
	var flash_tween = create_tween()
	flash_tween.tween_property(flash_overlay, "color", Color(1, 1, 1, 0.3), 0.1)
	flash_tween.tween_property(flash_overlay, "color", Color(1, 1, 1, 0), 0.2)
	
	await flash_tween.finished
	if flash_overlay and is_instance_valid(flash_overlay):
		flash_overlay.queue_free()

func get_special_piece_scene(piece_type: String, color: String):
	match piece_type:
		"column":
			return column_pieces.get(color, possible_pieces[0])
		"row":
			return row_pieces.get(color, possible_pieces[0])
		"bomb":
			return bomb_pieces.get(color, possible_pieces[0])
		"rainbow":
			return rainbow_piece
		_:
			return possible_pieces[0]

func create_scheduled_special_pieces():
	print("=== CREATE SCHEDULED SPECIAL PIECES START ===")
	print("Number of special pieces to create: ", special_pieces_to_create.size())
	
	if special_pieces_to_create.size() == 0:
		print("No special pieces scheduled - returning early")
		return
	
	for special_piece_data in special_pieces_to_create:
		var x = special_piece_data.x
		var y = special_piece_data.y
		var piece_type = special_piece_data.piece_type
		var color = special_piece_data.color
		
		print("Creating special piece at (", x, ",", y, ") type: ", piece_type, " color: ", color)
		
		var target_y = y
		
		if all_pieces[x][y] == null:
			target_y = y
		else:
			target_y = -1
			for check_y in range(height - 1, -1, -1): 
				if all_pieces[x][check_y] == null:
					target_y = check_y
					break
			
			if target_y == -1:
				print("ERROR: No empty position found in column ", x, " for special piece")
				continue
		
		var piece_to_instantiate
		match piece_type:
			"column":
				if column_pieces.has(color):
					piece_to_instantiate = column_pieces[color]
					print("Found column piece for color: ", color)
				else:
					print("ERROR: No column piece found for color: ", color)
					piece_to_instantiate = possible_pieces[0]
			"row":
				if row_pieces.has(color):
					piece_to_instantiate = row_pieces[color]
					print("Found row piece for color: ", color)
				else:
					print("ERROR: No row piece found for color: ", color)
					piece_to_instantiate = possible_pieces[0]
			"bomb":
				if bomb_pieces.has(color):
					piece_to_instantiate = bomb_pieces[color]
					print("Found bomb piece for color: ", color)
				else:
					print("ERROR: No bomb piece found for color: ", color)
					piece_to_instantiate = possible_pieces[0]
			"rainbow":
				piece_to_instantiate = rainbow_piece
				print("Using rainbow piece")
		
		if piece_to_instantiate != null and all_pieces[x][target_y] == null:
			var piece = piece_to_instantiate.instantiate()
			add_child(piece)
			piece.position = grid_to_pixel(x, target_y)
			all_pieces[x][target_y] = piece
			piece.piece_type = piece_type
			piece.color = color 
			piece.matched = false 
			piece.modulate = Color(1, 1, 1, 1)  
			print("*** SPECIAL PIECE CREATED SUCCESSFULLY ***")
			print("Position: (", x, ",", target_y, ")")
			print("Type: ", piece_type)
			print("Color: ", color)
			print("Piece instance: ", piece)
			print("Piece type property: ", piece.piece_type)
		else:
			print("ERROR: Could not create special piece")
			print("piece_to_instantiate null: ", piece_to_instantiate == null)
			print("position occupied: ", all_pieces[x][target_y] != null)
			if all_pieces[x][target_y] != null:
				print("Position (", x, ",", target_y, ") contains: ", all_pieces[x][target_y])
	
	special_pieces_to_create.clear()
	
	reset_all_piece_states()
	
	print("Grid state after creation:")
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and all_pieces[i][j].piece_type != "normal":
				print("Special piece found at (", i, ",", j, ") type: ", all_pieces[i][j].piece_type)

func activate_special_piece(x: int, y: int, piece_type: String):
	print("Activating special piece at (", x, ",", y, ") type: ", piece_type)
	var activated_piece = all_pieces[x][y]
	
	if activated_piece and piece_type == "bomb":
		activated_piece.explode_effect()
		play_girl_set_ball_sound()
	
	match piece_type:
		"column":
			destroy_column(x)
		"row":
			destroy_row(y)
		"bomb":
			destroy_bomb_area(x, y)
		"rainbow":
			destroy_all_of_color(activated_piece.color)
			play_awesome_match_sound()
	
	if activated_piece:
		activated_piece.dim()
		pieces_to_destroy.append(activated_piece)

func destroy_column(column: int):
	print("Destroying column: ", column)
	for row in range(height):
		if all_pieces[column][row] != null:
			var piece = all_pieces[column][row]
			piece.dim()
			if not pieces_to_destroy.has(piece):
				pieces_to_destroy.append(piece)
			current_score += 10

func destroy_row(row: int):
	print("Destroying row: ", row)
	for column in range(width):
		if all_pieces[column][row] != null:
			var piece = all_pieces[column][row]
			piece.dim()
			if not pieces_to_destroy.has(piece):
				pieces_to_destroy.append(piece)
			current_score += 10

func destroy_bomb_area(center_x: int, center_y: int):
	print("Destroying bomb area in cross pattern at (", center_x, ",", center_y, ")")
	
	for y in range(height):
		if all_pieces[center_x][y] != null:
			var piece = all_pieces[center_x][y]
			piece.dim()
			if not pieces_to_destroy.has(piece):
				pieces_to_destroy.append(piece)
			current_score += 15
	
	for x in range(width):
		if all_pieces[x][center_y] != null:
			var piece = all_pieces[x][center_y]
			piece.dim()
			if not pieces_to_destroy.has(piece):
				pieces_to_destroy.append(piece)
			current_score += 15

func destroy_all_of_color(target_color: String):
	print("Destroying all pieces of color: ", target_color)
	for x in range(width):
		for y in range(height):
			if all_pieces[x][y] != null and all_pieces[x][y].color == target_color:
				var piece = all_pieces[x][y]
				piece.dim()
				if not pieces_to_destroy.has(piece):
					pieces_to_destroy.append(piece)
				current_score += 20

func collapse_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				for k in range(j + 1, height):
					if all_pieces[i][k] != null:
						all_pieces[i][k].move(grid_to_pixel(i, j))
						all_pieces[i][j] = all_pieces[i][k]
						all_pieces[i][k] = null
						break
	get_parent().get_node("refill_timer").start()

func refill_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				var rand = randi_range(0, possible_pieces.size() - 1)
				var piece = possible_pieces[rand].instantiate()
				var max_loops = 100
				var loops = 0
				while (match_at(i, j, piece.color) and loops < max_loops):
					rand = randi_range(0, possible_pieces.size() - 1)
					loops += 1
					piece = possible_pieces[rand].instantiate()
				add_child(piece)
				piece.position = grid_to_pixel(i, j - y_offset)
				piece.move(grid_to_pixel(i, j))
				all_pieces[i][j] = piece
				
	check_after_refill()



func reset_all_piece_states():
	print("Resetting all piece states for visibility")
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				all_pieces[i][j].matched = false
				all_pieces[i][j].modulate = Color(1, 1, 1, 1)  
				all_pieces[i][j].position = grid_to_pixel(i, j)

func check_after_refill():
	print("check_after_refill called")
	
	await get_tree().create_timer(0.2).timeout
	
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and match_at(i, j, all_pieces[i][j].color):
				print("Found new matches after refill, starting destroy timer")
				find_matches()
				get_parent().get_node("destroy_timer").start()
				return
	print("No new matches after refill, returning to MOVE state")
	state = MOVE
	move_checked = false

func setup_game_mode(mode: String, counter_value: int, score_target: int):
	game_mode = mode
	current_counter_value = counter_value
	score_goal = score_target
	current_score = 0
	game_over_flag = false
	
	update_score.emit()
	update_counter.emit()
	
	if game_mode == "time":
		start_timer()

func start_timer():
	if game_timer != null:
		game_timer.queue_free()
	
	game_timer = Timer.new()
	add_child(game_timer)
	game_timer.wait_time = 1.0
	game_timer.timeout.connect(_on_game_timer_timeout)
	game_timer.start()

func _on_game_timer_timeout():
	if game_mode == "time" and not game_over_flag:
		current_counter_value -= 1
		update_counter.emit()
		
		if current_counter_value <= 0:
			check_game_over()
		else:
			game_timer.start()

func check_game_over():
	if current_counter_value <= 0:
		if current_score >= score_goal:
			game_win()
		else:
			game_over()

func game_over():
	state = WAIT
	game_over_flag = true
	show_game_over_screen(false)

func game_win():
	state = WAIT
	game_over_flag = true
	
	bg_music_player.stop()
	play_game_win_sound()
	
	show_game_over_screen(true)

func show_game_over_screen(won: bool):
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.8)  
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 1000
	
	var center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var main_panel = Panel.new()
	main_panel.custom_minimum_size = Vector2(600, 500)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.15, 0.15, 0.25, 0.95) 
	panel_style.border_width_left = 4
	panel_style.border_width_right = 4
	panel_style.border_width_top = 4
	panel_style.border_width_bottom = 4
	panel_style.border_color = Color(0.7, 0.7, 0.7)  
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	main_panel.add_theme_stylebox_override("panel", panel_style)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 30)
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("margin_left", 40)
	main_vbox.add_theme_constant_override("margin_right", 40)
	main_vbox.add_theme_constant_override("margin_top", 30)
	main_vbox.add_theme_constant_override("margin_bottom", 30)
	
	var pixel_font = load("res://assets/fonts/Kenney Blocks.ttf")
	
	var title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 48)
	if pixel_font:
		title_label.add_theme_font_override("font", pixel_font)
	
	if won:
		title_label.text = "¡VICTORIA!"
		title_label.modulate = Color(0.3, 1.0, 0.3)  
	else:
		title_label.text = "GAME OVER"
		title_label.modulate = Color(1.0, 0.3, 0.3)  
	
	var stats_vbox = VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 15)
	
	var score_label = Label.new()
	score_label.text = "PUNTAJE FINAL: " + str(current_score)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 22)
	if pixel_font:
		score_label.add_theme_font_override("font", pixel_font)
	score_label.modulate = Color.WHITE
	
	var goal_label = Label.new()
	goal_label.text = "OBJETIVO: " + str(score_goal)
	goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	goal_label.add_theme_font_size_override("font_size", 20)
	if pixel_font:
		goal_label.add_theme_font_override("font", pixel_font)
	goal_label.modulate = Color.WHITE
	
	var mode_label = Label.new()
	mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mode_label.add_theme_font_size_override("font_size", 18)
	if pixel_font:
		mode_label.add_theme_font_override("font", pixel_font)
	mode_label.modulate = Color.WHITE
	
	if game_mode == "moves":
		mode_label.text = "MODO MOVIMIENTOS\n(" + str(current_counter_value) + " RESTANTES)"
	else:
		mode_label.text = "MODO TIEMPO\n(" + str(current_counter_value) + "S RESTANTES)"
	
	stats_vbox.add_child(score_label)
	stats_vbox.add_child(goal_label)
	stats_vbox.add_child(mode_label)
	
	var buttons_hbox = HBoxContainer.new()
	buttons_hbox.add_theme_constant_override("separation", 20)
	buttons_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var play_button = Button.new()
	play_button.text = "JUGAR DE NUEVO"
	play_button.custom_minimum_size = Vector2(200, 60)
	play_button.add_theme_font_size_override("font_size", 16)
	if pixel_font:
		play_button.add_theme_font_override("font", pixel_font)
	
	var menu_button = Button.new()
	menu_button.text = "MENU PRINCIPAL"
	menu_button.custom_minimum_size = Vector2(200, 60)
	menu_button.add_theme_font_size_override("font_size", 16)
	if pixel_font:
		menu_button.add_theme_font_override("font", pixel_font)
	
	var button_normal = StyleBoxFlat.new()
	button_normal.bg_color = Color(0.2, 0.2, 0.35, 0.9)
	button_normal.border_width_left = 2
	button_normal.border_width_right = 2
	button_normal.border_width_top = 2
	button_normal.border_width_bottom = 2
	button_normal.border_color = Color(0.6, 0.6, 0.6)
	button_normal.corner_radius_top_left = 5
	button_normal.corner_radius_top_right = 5
	button_normal.corner_radius_bottom_left = 5
	button_normal.corner_radius_bottom_right = 5
	
	var button_hover = StyleBoxFlat.new()
	button_hover.bg_color = Color(0.3, 0.3, 0.45, 0.9)
	button_hover.border_width_left = 2
	button_hover.border_width_right = 2
	button_hover.border_width_top = 2
	button_hover.border_width_bottom = 2
	button_hover.border_color = Color(0.8, 0.8, 0.8)
	button_hover.corner_radius_top_left = 5
	button_hover.corner_radius_top_right = 5
	button_hover.corner_radius_bottom_left = 5
	button_hover.corner_radius_bottom_right = 5
	
	play_button.add_theme_stylebox_override("normal", button_normal)
	play_button.add_theme_stylebox_override("hover", button_hover)
	play_button.add_theme_color_override("font_color", Color.WHITE)
	
	menu_button.add_theme_stylebox_override("normal", button_normal)
	menu_button.add_theme_stylebox_override("hover", button_hover)
	menu_button.add_theme_color_override("font_color", Color.WHITE)
	
	play_button.pressed.connect(_on_play_again_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	
	buttons_hbox.add_child(play_button)
	buttons_hbox.add_child(menu_button)
	
	main_vbox.add_child(title_label)
	main_vbox.add_child(stats_vbox)
	main_vbox.add_child(buttons_hbox)
	
	main_panel.add_child(main_vbox)
	center_container.add_child(main_panel)
	overlay.add_child(center_container)
	
	get_tree().current_scene.add_child(overlay)
	
	print("Game Over screen displayed - Won: ", won, " Score: ", current_score)

func _on_score_updated():
	get_parent().get_node("top_ui").update_score_display(current_score)

func _on_counter_updated():
	get_parent().get_node("top_ui").update_counter_display(current_counter_value)

func _on_destroy_timer_timeout():
	destroy_matched()

func _on_collapse_timer_timeout():
	collapse_columns()

func _on_play_again_pressed():
	if bg_music_player:
		bg_music_player.stop()
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_menu_pressed():
	if bg_music_player:
		bg_music_player.stop()
	get_tree().change_scene_to_file("res://scenes/game_mode_menu.tscn")

func _on_refill_timer_timeout():
	refill_columns()
