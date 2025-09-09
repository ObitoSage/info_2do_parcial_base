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

# grid calculation variables
var x_offset: int

# Called when the node enters the scene tree for the first time.
func _ready():
	state = MOVE
	randomize()
	
	# Initialize grid calculation variables
	x_offset = offset
	
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
	
	# Check if either piece is special and activate its effect
	var special_activated = false
	if first_piece.piece_type != "normal":
		activate_special_piece(column, row, first_piece.piece_type)
		special_activated = true
	elif other_piece.piece_type != "normal":
		activate_special_piece(column + direction.x, row + direction.y, other_piece.piece_type)
		special_activated = true
	
	# If special piece was activated, handle the cascade
	if special_activated:
		current_state = WAIT
		destroy_matched()
		return
	
	# Normal swap logic
	current_state = WAIT
	store_info(first_piece, other_piece, Vector2(column, row), direction)
	all_pieces[column][row] = other_piece
	all_pieces[column + direction.x][row + direction.y] = first_piece
	first_piece.move(grid_to_pixel(column + direction.x, row + direction.y))
	other_piece.move(grid_to_pixel(column, row))
	if not move_checked:
		find_matches()

func store_info(first_piece, other_piece, place, direction_or_place2):
	piece_one = first_piece
	piece_two = other_piece
	last_place = place
	
	# Check if direction_or_place2 is a direction (Vector2 with small values) or a position
	if abs(direction_or_place2.x) <= 1 and abs(direction_or_place2.y) <= 1:
		# It's a direction
		last_direction = direction_or_place2
		last_place_two = place + direction_or_place2
	else:
		# It's a position (free swap)
		last_place_two = direction_or_place2
		last_direction = direction_or_place2 - place

func swap_back():
	print("swap_back called")
	if piece_one != null or piece_two != null:
		print("Swapping pieces back from position: ", last_place, " to position: ", last_place_two)
		
		# Swap the pieces back in the array
		all_pieces[last_place.x][last_place.y] = piece_one
		all_pieces[last_place_two.x][last_place_two.y] = piece_two
		
		# Move them visually back to original positions
		if piece_one != null:
			piece_one.move(grid_to_pixel(last_place.x, last_place.y))
		if piece_two != null:
			piece_two.move(grid_to_pixel(last_place_two.x, last_place_two.y))
	
	# Clear the stored info
	piece_one = null
	piece_two = null
	last_place = Vector2.ZERO
	last_direction = Vector2.ZERO
	
	print("Returning to MOVE state")
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
	elif abs(difference.y) > abs(difference.x):
		if difference.y > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, 1))
		elif difference.y < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, -1))

func _process(delta):
	if state == MOVE and not game_over_flag:
		touch_input()
	
	# Debug - print state occasionally
	if Engine.get_process_frames() % 60 == 0:  # Every second
		print("Game State: ", state, " | Game Over: ", game_over_flag, " | Mode: ", game_mode, " | Counter: ", current_counter_value)

func find_matches():
	var matches_found = false
	
	# Clear any previous special pieces metadata
	special_pieces_to_create.clear()
	
	# Basic match detection (3+ in a row)
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				var current_piece = all_pieces[i][j]
				if current_piece.matched:
					continue
				
				# Check horizontal matches
				if i <= width - 3:
					if all_pieces[i + 1][j] != null and all_pieces[i + 2][j] != null:
						if current_piece.color == all_pieces[i + 1][j].color and current_piece.color == all_pieces[i + 2][j].color:
							# Count how many pieces match
							var match_length = 3
							var start_x = i
							
							# Count additional pieces to the right
							while i + match_length < width and all_pieces[i + match_length][j] != null and all_pieces[i + match_length][j].color == current_piece.color:
								match_length += 1
							
							# Mark all pieces in this match
							for k in range(match_length):
								if not all_pieces[i + k][j].matched:  # Don't double-mark
									all_pieces[i + k][j].matched = true
									all_pieces[i + k][j].dim()
							
							matches_found = true
							
							# Create special piece based on match length
							if match_length == 4:
								var special_data = {
									"x": i + 1,  # Place in middle of match
									"y": j,
									"piece_type": "row",  # Horizontal match creates ROW piece
									"color": current_piece.color
								}
								special_pieces_to_create.append(special_data)
								current_score += 50
								print("=== 4-MATCH HORIZONTAL DETECTED ===")
								print("Will create ROW piece at (", i + 1, ",", j, ") with color: ", current_piece.color)
								print("Special pieces queue size: ", special_pieces_to_create.size())
							elif match_length >= 5:
								special_pieces_to_create.append({
									"x": i + 2,  # Place in middle of match
									"y": j,
									"piece_type": "rainbow",
									"color": current_piece.color
								})
								current_score += 200
								print("5+ match horizontal detected - will create rainbow piece")
							else:
								current_score += match_length * 10
				
				# Check vertical matches
				if j <= height - 3:
					if all_pieces[i][j + 1] != null and all_pieces[i][j + 2] != null:
						if current_piece.color == all_pieces[i][j + 1].color and current_piece.color == all_pieces[i][j + 2].color:
							# Count how many pieces match
							var match_length = 3
							var start_y = j
							
							# Count additional pieces downward
							while j + match_length < height and all_pieces[i][j + match_length] != null and all_pieces[i][j + match_length].color == current_piece.color:
								match_length += 1
							
							# Mark all pieces in this match
							for k in range(match_length):
								if not all_pieces[i][j + k].matched:  # Don't double-mark
									all_pieces[i][j + k].matched = true
									all_pieces[i][j + k].dim()
							
							matches_found = true
							
							# Create special piece based on match length
							if match_length == 4:
								var special_data = {
									"x": i,
									"y": j + 1,  # Place in middle of match
									"piece_type": "column",  # Vertical match creates COLUMN piece
									"color": current_piece.color
								}
								special_pieces_to_create.append(special_data)
								current_score += 50
								print("=== 4-MATCH VERTICAL DETECTED ===")
								print("Will create COLUMN piece at (", i, ",", j + 1, ") with color: ", current_piece.color)
								print("Special pieces queue size: ", special_pieces_to_create.size())
							elif match_length >= 5:
								special_pieces_to_create.append({
									"x": i,
									"y": j + 2,  # Place in middle of match
									"piece_type": "rainbow",
									"color": current_piece.color
								})
								current_score += 200
								print("5+ match vertical detected - will create rainbow piece")
							else:
								current_score += match_length * 10
	
	# Check for T-shaped matches (simplified version)
	for i in range(1, width - 1):
		for j in range(1, height - 1):
			if all_pieces[i][j] != null and not all_pieces[i][j].matched:
				var center_piece = all_pieces[i][j]
				
				# Check for T-shape: horizontal line with vertical extension
				if (all_pieces[i-1][j] != null and all_pieces[i+1][j] != null and 
					all_pieces[i][j-1] != null and all_pieces[i][j+1] != null):
					
					if (center_piece.color == all_pieces[i-1][j].color and 
						center_piece.color == all_pieces[i+1][j].color and
						center_piece.color == all_pieces[i][j-1].color and
						center_piece.color == all_pieces[i][j+1].color):
						
						# Mark T-shaped pieces
						all_pieces[i][j].matched = true
						all_pieces[i][j].dim()
						all_pieces[i-1][j].matched = true
						all_pieces[i-1][j].dim()
						all_pieces[i+1][j].matched = true
						all_pieces[i+1][j].dim()
						all_pieces[i][j-1].matched = true
						all_pieces[i][j-1].dim()
						all_pieces[i][j+1].matched = true
						all_pieces[i][j+1].dim()
						
						matches_found = true
						
						# Create rainbow piece (Ficha 5 - destroys all of same color)
						special_pieces_to_create.append({
							"x": i,
							"y": j,
							"piece_type": "rainbow",
							"color": center_piece.color
						})
						current_score += 200
						print("T-match detected - will create rainbow piece (Ficha 5)")
	
	if matches_found:
		print("Matches found! Special pieces to create: ", special_pieces_to_create.size())
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
				
				# Count consecutive pieces of same color
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
				
				# Count consecutive pieces of same color
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
				
				# Check T-shape: center piece + 2 horizontal + 2 vertical
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
	var pieces_destroyed = 0
	
	print("destroy_matched called - move_checked: ", move_checked, " game_mode: ", game_mode)
	print("Special pieces to create before destruction: ", special_pieces_to_create.size())
	
	# FIRST: Create special pieces before destroying matched pieces
	if special_pieces_to_create.size() > 0:
		print("Creating special pieces BEFORE destroying matched pieces")
		create_special_pieces_immediately()
	
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and all_pieces[i][j].matched:
				was_matched = true
				pieces_destroyed += 1
				current_score += 10
				all_pieces[i][j].queue_free()
				all_pieces[i][j] = null
			elif all_pieces[i][j] != null:
				# Reset any piece that's not being destroyed
				all_pieces[i][j].matched = false
				all_pieces[i][j].modulate = Color(1, 1, 1, 1)  # Reset visibility
	
	# Update score display
	update_score.emit()
	
	# Only decrement moves in MOVES mode and if this was a player move
	if was_matched and game_mode == "moves" and move_checked:
		current_counter_value -= 1
		update_counter.emit()
		print("Moves decremented. Remaining: ", current_counter_value)
		
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
	print("=== CREATE SPECIAL PIECES IMMEDIATELY ===")
	print("Number of special pieces to create: ", special_pieces_to_create.size())
	
	for special_piece_data in special_pieces_to_create:
		var x = special_piece_data.x
		var y = special_piece_data.y
		var piece_type = special_piece_data.piece_type
		var color = special_piece_data.color
		
		print("Creating special piece at (", x, ",", y, ") type: ", piece_type, " color: ", color)
		
		# Check if this position will be destroyed - if so, don't mark the piece for destruction
		if all_pieces[x][y] != null and all_pieces[x][y].matched:
			print("Position (", x, ",", y, ") will be destroyed - clearing matched flag")
			all_pieces[x][y].matched = false  # Don't destroy this piece
			all_pieces[x][y].modulate = Color(1, 1, 1, 1)  # Reset visibility
		
		# If the position is empty or will be freed, create the special piece
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
	
	# Clear the queue
	special_pieces_to_create.clear()

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
		
		# Find the correct position for this special piece
		var target_y = y
		
		# First, try to use the original position if it's empty
		if all_pieces[x][y] == null:
			target_y = y
		else:
			# If original position is occupied, find the lowest empty position in this column
			target_y = -1
			for check_y in range(height - 1, -1, -1):  # Start from bottom
				if all_pieces[x][check_y] == null:
					target_y = check_y
					break
			
			# If no empty position found, skip this special piece
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
					# Fallback to basic piece
					piece_to_instantiate = possible_pieces[0]
			"row":
				if row_pieces.has(color):
					piece_to_instantiate = row_pieces[color]
					print("Found row piece for color: ", color)
				else:
					print("ERROR: No row piece found for color: ", color)
					# Fallback to basic piece
					piece_to_instantiate = possible_pieces[0]
			"bomb":
				if bomb_pieces.has(color):
					piece_to_instantiate = bomb_pieces[color]
					print("Found bomb piece for color: ", color)
				else:
					print("ERROR: No bomb piece found for color: ", color)
					# Fallback to basic piece
					piece_to_instantiate = possible_pieces[0]
			"rainbow":
				piece_to_instantiate = rainbow_piece
				print("Using rainbow piece")
		
		if piece_to_instantiate != null and all_pieces[x][target_y] == null:
			var piece = piece_to_instantiate.instantiate()
			add_child(piece)
			# Position it correctly using grid_to_pixel
			piece.position = grid_to_pixel(x, target_y)
			all_pieces[x][target_y] = piece
			piece.piece_type = piece_type
			piece.color = color  # Set the color explicitly
			piece.matched = false  # Ensure it's not marked as matched
			piece.modulate = Color(1, 1, 1, 1)  # Ensure full visibility
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
	
	# Clear the array after processing
	special_pieces_to_create.clear()
	
	# Ensure all pieces have proper visibility state
	reset_all_piece_states()
	
	print("=== CREATE SCHEDULED SPECIAL PIECES END ===")
	print("Grid state after creation:")
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and all_pieces[i][j].piece_type != "normal":
				print("Special piece found at (", i, ",", j, ") type: ", all_pieces[i][j].piece_type)

func activate_special_piece(x: int, y: int, piece_type: String):
	print("Activating special piece at (", x, ",", y, ") type: ", piece_type)
	var activated_piece = all_pieces[x][y]
	
	match piece_type:
		"column":
			destroy_column(x)
		"row":
			destroy_row(y)
		"bomb":
			destroy_bomb_area(x, y)
		"rainbow":
			destroy_all_of_color(activated_piece.color)
	
	# Mark the special piece itself for destruction
	if activated_piece:
		activated_piece.dim()
		pieces_to_destroy.append(activated_piece)

func destroy_column(column: int):
	print("Destroying column: ", column)
	for row in range(height):
		if all_pieces[column][row] != null:
			var piece = all_pieces[column][row]
			piece.dim()
			pieces_to_destroy.append(piece)
			current_score += 10

func destroy_row(row: int):
	print("Destroying row: ", row)
	for column in range(width):
		if all_pieces[column][row] != null:
			var piece = all_pieces[column][row]
			piece.dim()
			pieces_to_destroy.append(piece)
			current_score += 10

func destroy_bomb_area(center_x: int, center_y: int):
	print("Destroying bomb area at (", center_x, ",", center_y, ")")
	for x in range(max(0, center_x - 1), min(width, center_x + 2)):
		for y in range(max(0, center_y - 1), min(height, center_y + 2)):
			if all_pieces[x][y] != null:
				var piece = all_pieces[x][y]
				piece.dim()
				pieces_to_destroy.append(piece)
				current_score += 15

func destroy_all_of_color(target_color: String):
	print("Destroying all pieces of color: ", target_color)
	for x in range(width):
		for y in range(height):
			if all_pieces[x][y] != null and all_pieces[x][y].color == target_color:
				var piece = all_pieces[x][y]
				piece.dim()
				pieces_to_destroy.append(piece)
				current_score += 20

func collapse_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
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



func reset_all_piece_states():
	print("Resetting all piece states for visibility")
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				all_pieces[i][j].matched = false
				all_pieces[i][j].modulate = Color(1, 1, 1, 1)  # Full visibility
				# Ensure piece is at correct position
				all_pieces[i][j].position = grid_to_pixel(i, j)

func check_after_refill():
	print("check_after_refill called")
	
	# Wait for grid to fully stabilize
	await get_tree().create_timer(0.2).timeout
	
	# Special pieces are now created immediately in destroy_matched()
	# No need to create them here anymore
	
	# Check for new matches
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
			# Restart the timer for next second
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
	show_game_over_screen(true)

func show_game_over_screen(won: bool):
	# Create full screen overlay with gradient background like main menu
	var overlay = ColorRect.new()
	overlay.color = Color(0.25, 0.25, 0.4, 1.0)  # Dark blue-gray background like menu
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 1000
	
	# Create main container perfectly centered
	var center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Create vertical layout for the whole screen
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 50)
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# Load pixel font if available
	var pixel_font = load("res://assets/fonts/Kenney Blocks.ttf")
	
	# Main title - same style as "MATCH 3 GAME"
	var title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 56)
	if pixel_font:
		title_label.add_theme_font_override("font", pixel_font)
	
	if won:
		title_label.text = "¡VICTORIA!"
		title_label.modulate = Color(0.3, 1.0, 0.3)  # Bright green
	else:
		title_label.text = "GAME OVER"
		title_label.modulate = Color(1.0, 0.3, 0.3)  # Bright red
	
	# Stats container - rectangular panel like menu buttons
	var stats_panel = Panel.new()
	stats_panel.custom_minimum_size = Vector2(500, 200)
	
	# Style the stats panel to look like menu buttons
	var stats_style = StyleBoxFlat.new()
	stats_style.bg_color = Color(0.15, 0.15, 0.25, 0.9)  # Dark background
	stats_style.border_width_left = 3
	stats_style.border_width_right = 3
	stats_style.border_width_top = 3
	stats_style.border_width_bottom = 3
	stats_style.border_color = Color(0.6, 0.6, 0.6)  # Light gray border
	stats_panel.add_theme_stylebox_override("panel", stats_style)
	
	# Stats container inside panel
	var stats_vbox = VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 15)
	stats_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stats_vbox.add_theme_constant_override("margin_left", 30)
	stats_vbox.add_theme_constant_override("margin_right", 30)
	stats_vbox.add_theme_constant_override("margin_top", 20)
	stats_vbox.add_theme_constant_override("margin_bottom", 20)
	
	# Score labels with pixel font
	var score_label = Label.new()
	score_label.text = "PUNTAJE FINAL: " + str(current_score)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 24)
	if pixel_font:
		score_label.add_theme_font_override("font", pixel_font)
	score_label.modulate = Color.WHITE
	
	var goal_label = Label.new()
	goal_label.text = "OBJETIVO: " + str(score_goal)
	goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	goal_label.add_theme_font_size_override("font_size", 22)
	if pixel_font:
		goal_label.add_theme_font_override("font", pixel_font)
	goal_label.modulate = Color.WHITE
	
	var mode_label = Label.new()
	mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mode_label.add_theme_font_size_override("font_size", 20)
	if pixel_font:
		mode_label.add_theme_font_override("font", pixel_font)
	mode_label.modulate = Color.WHITE
	
	if game_mode == "moves":
		mode_label.text = "MODO MOVIMIENTOS\n(" + str(current_counter_value) + " RESTANTES)"
	else:
		mode_label.text = "MODO TIEMPO\n(" + str(current_counter_value) + "S RESTANTES)"
	
	# Add stats to panel
	stats_vbox.add_child(score_label)
	stats_vbox.add_child(goal_label)
	stats_vbox.add_child(mode_label)
	stats_panel.add_child(stats_vbox)
	
	# Buttons styled like menu buttons
	var play_button = Button.new()
	play_button.text = "JUGAR DE NUEVO"
	play_button.custom_minimum_size = Vector2(400, 70)
	play_button.add_theme_font_size_override("font_size", 22)
	if pixel_font:
		play_button.add_theme_font_override("font", pixel_font)
	
	var menu_button = Button.new()
	menu_button.text = "MENU PRINCIPAL"
	menu_button.custom_minimum_size = Vector2(400, 70)
	menu_button.add_theme_font_size_override("font_size", 22)
	if pixel_font:
		menu_button.add_theme_font_override("font", pixel_font)
	
	# Style buttons to match menu style
	var button_normal = StyleBoxFlat.new()
	button_normal.bg_color = Color(0.15, 0.15, 0.25, 0.9)  # Same as stats panel
	button_normal.border_width_left = 3
	button_normal.border_width_right = 3
	button_normal.border_width_top = 3
	button_normal.border_width_bottom = 3
	button_normal.border_color = Color(0.6, 0.6, 0.6)
	
	var button_hover = StyleBoxFlat.new()
	button_hover.bg_color = Color(0.2, 0.2, 0.35, 0.9)  # Slightly lighter on hover
	button_hover.border_width_left = 3
	button_hover.border_width_right = 3
	button_hover.border_width_top = 3
	button_hover.border_width_bottom = 3
	button_hover.border_color = Color(0.8, 0.8, 0.8)  # Brighter border on hover
	
	play_button.add_theme_stylebox_override("normal", button_normal)
	play_button.add_theme_stylebox_override("hover", button_hover)
	play_button.add_theme_color_override("font_color", Color.WHITE)
	
	menu_button.add_theme_stylebox_override("normal", button_normal)
	menu_button.add_theme_stylebox_override("hover", button_hover)
	menu_button.add_theme_color_override("font_color", Color.WHITE)
	
	# Connect button signals
	play_button.pressed.connect(_on_play_again_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	
	# Build the main layout
	main_vbox.add_child(title_label)
	main_vbox.add_child(stats_panel)
	main_vbox.add_child(play_button)
	main_vbox.add_child(menu_button)
	
	center_container.add_child(main_vbox)
	overlay.add_child(center_container)
	
	# Add to scene
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
	# Restart the game with the same mode
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_menu_pressed():
	# Go back to game mode menu
	get_tree().change_scene_to_file("res://scenes/game_mode_menu.tscn")

func _on_refill_timer_timeout():
	refill_columns()
