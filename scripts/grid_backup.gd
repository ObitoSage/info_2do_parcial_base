extends Node2D

# state machine
enum {WAIT, MOVE}
var state

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

var rainbow_piece = preload("res://scenes/rainbow_piece.tscn")

var bomb_pieces = {
	"blue": preload("res://scenes/blue_bomb_piece.tscn"),
	"green": preload("res://scenes/green_bomb_piece.tscn"),
	"light_green": preload("res://scenes/light_green_bomb_piece.tscn"),
	"pink": preload("res://scenes/pink_bomb_piece.tscn"),
	"yellow": preload("res://scenes/yellow_bomb_piece.tscn"),
	"orange": preload("res://scenes/orange_bomb_piece.tscn"),
}
# current pieces in scene
var all_pieces = []

# swap back
var piece_one = null
var piece_two = null
var last_place = Vector2.ZERO
var last_direction = Vector2.ZERO
var move_checked = false

# touch variables
var first_touch = Vector2.ZERO
var final_touch = Vector2.ZERO
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


# Called when the node enters the scene tree for the first time.
func _ready():
	state = MOVE
	randomize()
	all_pieces = make_2d_array()
	spawn_pieces()
	
	# Setup game mode from GameManager
	setup_game_mode(GameManager.selected_game_mode, GameManager.selected_counter_value, GameManager.selected_score_goal)
	
	# Connect signals to UI
	update_score.connect(_on_score_updated)
	update_counter.connect(_on_counter_updated)

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
	if j> 1:
		if all_pieces[i][j - 1] != null and all_pieces[i][j - 2] != null:
			if all_pieces[i][j - 1].color == color and all_pieces[i][j - 2].color == color:
				return true

func touch_input():
	var mouse_pos = get_global_mouse_position()
	var grid_pos = pixel_to_grid(mouse_pos.x, mouse_pos.y)
	if Input.is_action_just_pressed("ui_touch") and in_grid(grid_pos.x, grid_pos.y):
		first_touch = grid_pos
		is_controlling = true
		
	# release button
	if Input.is_action_just_released("ui_touch") and in_grid(grid_pos.x, grid_pos.y) and is_controlling:
		is_controlling = false
		final_touch = grid_pos
		touch_difference(first_touch, final_touch)

func swap_pieces(column, row, direction: Vector2):
	var first_piece = all_pieces[column][row]
	var other_piece = all_pieces[column + direction.x][row + direction.y]
	if first_piece == null or other_piece == null:
		return
	# swap
	state = WAIT
	store_info(first_piece, other_piece, Vector2(column, row), direction)
	all_pieces[column][row] = other_piece
	all_pieces[column + direction.x][row + direction.y] = first_piece
	#first_piece.position = grid_to_pixel(column + direction.x, row + direction.y)
	#other_piece.position = grid_to_pixel(column, row)
	first_piece.move(grid_to_pixel(column + direction.x, row + direction.y))
	other_piece.move(grid_to_pixel(column, row))
	if not move_checked:
		find_matches()

func store_info(first_piece, other_piece, place, direction):
	piece_one = first_piece
	piece_two = other_piece
	last_place = place
	last_direction = direction

func swap_back():
	if piece_one != null and piece_two != null:
		swap_pieces(last_place.x, last_place.y, last_direction)
	state = MOVE
	move_checked = false

func touch_difference(grid_1, grid_2):
	var difference = grid_2 - grid_1
	# should move x or y?
	if abs(difference.x) > abs(difference.y):
		if difference.x > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(1, 0))
		elif difference.x < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(-1, 0))
	if abs(difference.y) > abs(difference.x):
		if difference.y > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, 1))
		elif difference.y < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, -1))

func _process(delta):
	if state == MOVE:
		touch_input()

func find_matches():
	var matches_found = false
	
	# Find basic 3-match patterns first
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				var current_color = all_pieces[i][j].color
				# detect horizontal matches
				if (
					i > 0 and i < width - 1 
					and 
					all_pieces[i - 1][j] != null and all_pieces[i + 1][j] != null
					and 
					all_pieces[i - 1][j].color == current_color and all_pieces[i + 1][j].color == current_color
				):
					all_pieces[i - 1][j].matched = true
					all_pieces[i - 1][j].dim()
					all_pieces[i][j].matched = true
					all_pieces[i][j].dim()
					all_pieces[i + 1][j].matched = true
					all_pieces[i + 1][j].dim()
					matches_found = true
				# detect vertical matches
				if (
					j > 0 and j < height - 1 
					and 
					all_pieces[i][j - 1] != null and all_pieces[i][j + 1] != null
					and 
					all_pieces[i][j - 1].color == current_color and all_pieces[i][j + 1].color == current_color
				):
					all_pieces[i][j - 1].matched = true
					all_pieces[i][j - 1].dim()
					all_pieces[i][j].matched = true
					all_pieces[i][j].dim()
					all_pieces[i][j + 1].matched = true
					all_pieces[i][j + 1].dim()
					matches_found = true
	
	if matches_found:
		get_parent().get_node("destroy_timer").start()
	else:
		if move_checked:
			swap_back()
	
func detect_all_matches():
	var matches = []
	
	# Check horizontal matches (including 4 and 5)
	for j in height:
		var i = 0
		while i < width:
			if all_pieces[i][j] != null:
				var current_color = all_pieces[i][j].color
				var match_length = 1
				var start_i = i
				
				# Count consecutive pieces
				while i + match_length < width and all_pieces[i + match_length][j] != null and all_pieces[i + match_length][j].color == current_color:
					match_length += 1
				
				if match_length >= 3:
					matches.append({
						"type": "horizontal",
						"color": current_color,
						"start": Vector2(start_i, j),
						"length": match_length
					})
				
				i += match_length
			else:
				i += 1
	
	# Check vertical matches (including 4 and 5)
	for i in width:
		var j = 0
		while j < height:
			if all_pieces[i][j] != null:
				var current_color = all_pieces[i][j].color
				var match_length = 1
				var start_j = j
				
				# Count consecutive pieces
				while j + match_length < height and all_pieces[i][j + match_length] != null and all_pieces[i][j + match_length].color == current_color:
					match_length += 1
				
				if match_length >= 3:
					matches.append({
						"type": "vertical",
						"color": current_color,
						"start": Vector2(i, start_j),
						"length": match_length
					})
				
				j += match_length
			else:
				j += 1
	
	# Check T-shaped matches
	var t_matches = detect_t_matches()
	matches.append_array(t_matches)
	
	return matches

func detect_t_matches():
	var t_matches = []
	
	for i in range(1, width - 1):
		for j in range(1, height - 1):
			if all_pieces[i][j] != null:
				var current_color = all_pieces[i][j].color
				
				# Check T-shape (horizontal line with vertical extension)
				if (all_pieces[i-1][j] != null and all_pieces[i+1][j] != null and
					all_pieces[i][j-1] != null and all_pieces[i][j+1] != null and
					all_pieces[i-1][j].color == current_color and
					all_pieces[i+1][j].color == current_color and
					all_pieces[i][j-1].color == current_color and
					all_pieces[i][j+1].color == current_color):
					
					t_matches.append({
						"type": "t_shape",
						"color": current_color,
						"center": Vector2(i, j),
						"length": 5
					})
	
	return t_matches

func process_matches(matches):
	var special_piece_created = false
	var pieces_to_mark = []
	
	for match in matches:
		var match_pieces = get_pieces_from_match(match)
		pieces_to_mark.append_array(match_pieces)
		
		# Determine if we should create special pieces
		if match.length == 4:
			if not special_piece_created:
				var center_pos = get_match_center(match)
				if match.type == "horizontal":
					create_special_piece(center_pos, match.color, "column")
				elif match.type == "vertical":
					create_special_piece(center_pos, match.color, "row")
				special_piece_created = true
		elif match.length >= 5 or match.type == "t_shape":
			if not special_piece_created:
				var center_pos = get_match_center(match)
				create_special_piece(center_pos, match.color, "rainbow")
				special_piece_created = true
	
	# Check for L-shaped or square matches to create bombs
	if not special_piece_created:
		var l_matches = detect_l_matches(pieces_to_mark)
		if l_matches.size() > 0:
			var l_match = l_matches[0]
			create_special_piece(l_match.center, l_match.color, "bomb")
			special_piece_created = true
	
	# Mark all pieces for destruction
	for piece_pos in pieces_to_mark:
		if all_pieces[piece_pos.x][piece_pos.y] != null:
			all_pieces[piece_pos.x][piece_pos.y].matched = true
			all_pieces[piece_pos.x][piece_pos.y].dim()

func get_pieces_from_match(match):
	var pieces = []
	
	if match.type == "horizontal":
		for i in range(match.start.x, match.start.x + match.length):
			pieces.append(Vector2(i, match.start.y))
	elif match.type == "vertical":
		for j in range(match.start.y, match.start.y + match.length):
			pieces.append(Vector2(match.start.x, j))
	elif match.type == "t_shape":
		var center = match.center
		pieces.append(center)
		pieces.append(Vector2(center.x - 1, center.y))
		pieces.append(Vector2(center.x + 1, center.y))
		pieces.append(Vector2(center.x, center.y - 1))
		pieces.append(Vector2(center.x, center.y + 1))
	
	return pieces

func get_match_center(match):
	if match.type == "horizontal":
		return Vector2(match.start.x + match.length / 2, match.start.y)
	elif match.type == "vertical":
		return Vector2(match.start.x, match.start.y + match.length / 2)
	elif match.type == "t_shape":
		return match.center
	return Vector2.ZERO

func create_special_piece(pos, color, piece_type):
	var special_piece
	
	if piece_type == "column":
		special_piece = column_pieces[color].instantiate()
	elif piece_type == "row":
		special_piece = row_pieces[color].instantiate()
	elif piece_type == "rainbow":
		special_piece = rainbow_piece.instantiate()
	elif piece_type == "bomb":
		special_piece = bomb_pieces[color].instantiate()
	
	if special_piece:
		add_child(special_piece)
		special_piece.position = grid_to_pixel(pos.x, pos.y)
		all_pieces[pos.x][pos.y] = special_piece

func mark_column_for_destruction(column):
	for j in height:
		if all_pieces[column][j] != null:
			all_pieces[column][j].matched = true
			all_pieces[column][j].dim()

func mark_row_for_destruction(row):
	for i in width:
		if all_pieces[i][row] != null:
			all_pieces[i][row].matched = true
			all_pieces[i][row].dim()

func mark_color_for_destruction(color):
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and all_pieces[i][j].color == color:
				all_pieces[i][j].matched = true
				all_pieces[i][j].dim()

func get_target_color_for_rainbow(rainbow_i, rainbow_j):
	# Find the color of the piece that was swapped with the rainbow
	if piece_two != null and piece_two.color != "rainbow":
		return piece_two.color
	if piece_one != null and piece_one.color != "rainbow":
		return piece_one.color
	
	# If no swap info, find a random color on the board
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and all_pieces[i][j].color != "rainbow":
				return all_pieces[i][j].color
	
	return "blue" # fallback

func detect_l_matches(marked_pieces):
	var l_matches = []
	var piece_positions = {}
	
	# Group pieces by color
	for piece_pos in marked_pieces:
		if all_pieces[piece_pos.x][piece_pos.y] != null:
			var color = all_pieces[piece_pos.x][piece_pos.y].color
			if not piece_positions.has(color):
				piece_positions[color] = []
			piece_positions[color].append(piece_pos)
	
	# Check for L-shaped patterns in each color group
	for color in piece_positions.keys():
		var positions = piece_positions[color]
		if positions.size() >= 5:  # Need at least 5 pieces for L-shape
			var center = find_l_center(positions)
			if center != Vector2(-1, -1):
				l_matches.append({
					"color": color,
					"center": center,
					"type": "l_shape"
				})
	
	return l_matches

func find_l_center(positions):
	# Look for intersection points that could be L-shape centers
	for pos in positions:
		var horizontal_count = 0
		var vertical_count = 0
		
		# Count horizontal neighbors
		for other_pos in positions:
			if other_pos.y == pos.y and abs(other_pos.x - pos.x) <= 2:
				horizontal_count += 1
		
		# Count vertical neighbors
		for other_pos in positions:
			if other_pos.x == pos.x and abs(other_pos.y - pos.y) <= 2:
				vertical_count += 1
		
		# If we have at least 3 in each direction, this could be an L center
		if horizontal_count >= 3 and vertical_count >= 3:
			return pos
	
	return Vector2(-1, -1)

func mark_area_for_destruction(center_x, center_y, size):
	var radius = size / 2
	
	# Show explosion effect on the bomb piece first
	if all_pieces[center_x][center_y] != null and all_pieces[center_x][center_y].piece_type == "bomb":
		all_pieces[center_x][center_y].explode_effect()
	
	# Mark surrounding area for destruction
	for i in range(center_x - radius, center_x + radius + 1):
		for j in range(center_y - radius, center_y + radius + 1):
			if in_grid(i, j) and all_pieces[i][j] != null:
				all_pieces[i][j].matched = true
				all_pieces[i][j].dim()

func destroy_matched():
	var was_matched = false
	var pieces_destroyed = 0
	
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and all_pieces[i][j].matched:
				was_matched = true
				pieces_destroyed += 1
				
				# Calculate score based on piece type
				var piece_value = 10
				if all_pieces[i][j].piece_type == "column" or all_pieces[i][j].piece_type == "row":
					piece_value = 50
				elif all_pieces[i][j].piece_type == "rainbow":
					piece_value = 100
				elif all_pieces[i][j].piece_type == "bomb":
					piece_value = 75
				
				current_score += piece_value
				
				all_pieces[i][j].queue_free()
				all_pieces[i][j] = null
	
	# Update score display
	update_score.emit()
	
	# Check if moves should be decremented
	if was_matched and game_mode == "moves" and move_checked:
		current_counter_value -= 1
		update_counter.emit()
		
		if current_counter_value <= 0:
			check_game_over()
	
	move_checked = true
	if was_matched:
		get_parent().get_node("collapse_timer").start()
	else:
		swap_back()

func collapse_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				print(i, j)
				# look above
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
				piece.position = grid_to_pixel(i, j - y_offset)
				piece.move(grid_to_pixel(i, j))
				# fill array with pieces
				all_pieces[i][j] = piece
				
	check_after_refill()

func check_after_refill():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and match_at(i, j, all_pieces[i][j].color):
				find_matches()
				get_parent().get_node("destroy_timer").start()
				return
	state = MOVE
	
	move_checked = false

func start_timer():
	var game_timer = Timer.new()
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

func _on_score_updated():
	get_parent().get_node("top_ui").update_score_display(current_score)

func _on_counter_updated():
	get_parent().get_node("top_ui").update_counter_display(current_counter_value)

func _on_destroy_timer_timeout():
	print("destroy")
	destroy_matched()

func _on_collapse_timer_timeout():
	print("collapse")
	collapse_columns()

func _on_refill_timer_timeout():
	refill_columns()
	
func check_game_over():
	if game_mode == "moves" and current_counter_value <= 0:
		if current_score >= score_goal:
			game_win()
		else:
			game_over()
	elif game_mode == "time" and current_counter_value <= 0:
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
	show_game_over_screen(true)

func show_game_over_screen(won: bool):
	# Load the game over screen
	var game_over_scene = preload("res://scenes/game_over_screen.tscn")
	var game_over_instance = game_over_scene.instantiate()
	
	# Add it to the scene
	get_parent().add_child(game_over_instance)
	
	# Setup the screen with current game data
	game_over_instance.setup_game_over_screen(
		won,
		current_score,
		score_goal,
		game_mode,
		current_counter_value
	)

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
