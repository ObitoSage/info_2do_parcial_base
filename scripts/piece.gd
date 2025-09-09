extends Node2D

@export var color: String
@export var piece_type: String = "normal" # normal, column, row, rainbow

var matched = false

func _ready():
	# Aplicar shader de brillo si es ficha especial
	if piece_type != "normal":
		apply_special_glow()

func apply_special_glow():
	# Efecto visual mejorado para fichas especiales
	var glow_tween = create_tween()
	glow_tween.set_loops()
	glow_tween.tween_property(self, "modulate", Color(1.4, 1.4, 1.4, 1.0), 0.8)
	glow_tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.8)

func move(target):
	var move_tween = create_tween()
	move_tween.set_trans(Tween.TRANS_ELASTIC)
	move_tween.set_ease(Tween.EASE_OUT)
	move_tween.tween_property(self, "position", target, 0.4)

func dim():
	$Sprite2D.modulate = Color(1, 1, 1, 0.5)

func flash_match_effect():
	# Aplicar shader de flash para match
	if $Sprite2D.material == null:
		var flash_material = ShaderMaterial.new()
		flash_material.shader = preload("res://shaders/match_flash.gdshader")
		$Sprite2D.material = flash_material
	
	var material = $Sprite2D.material as ShaderMaterial
	if material != null:
		# Animación de flash
		var flash_tween = create_tween()
		flash_tween.tween_method(set_flash_progress, 0.0, 1.0, 0.3)
		flash_tween.tween_method(set_flash_progress, 1.0, 0.0, 0.2)

func set_flash_progress(value: float):
	if $Sprite2D.material != null:
		var material = $Sprite2D.material as ShaderMaterial
		material.set_shader_parameter("flash_progress", value)

func explode_effect():
	# Enhanced explosion effect for bomb pieces
	if piece_type == "bomb":
		print("Playing bomb explosion effect")
		
		# Create explosion visual
		var tween = create_tween()
		tween.set_parallel(true)
		
		# Scale up quickly then fade out
		tween.tween_property(self, "scale", Vector2(2.5, 2.5), 0.2)
		tween.tween_property(self, "modulate", Color(2, 2, 2, 1), 0.1)  # Bright flash
		tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.3)
		
		# Optional: Add rotation for more dynamic effect
		tween.tween_property(self, "rotation", PI, 0.3)
		
		# Clean up after effect
		tween.tween_callback(queue_free).set_delay(0.3)
	else:
		# Simple fade for other pieces
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.2)
		tween.tween_callback(queue_free).set_delay(0.2)

func pulse_effect():
	# Efecto de pulso para feedback
	var pulse_tween = create_tween()
	pulse_tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	pulse_tween.tween_property(self, "scale", Vector2.ONE, 0.1)

func shake_effect():
	# Efecto de sacudida para feedback negativo
	var original_pos = position
	var shake_tween = create_tween()
	
	for i in range(4):
		var offset = Vector2(randf_range(-5, 5), randf_range(-5, 5))
		shake_tween.tween_property(self, "position", original_pos + offset, 0.05)
	
	shake_tween.tween_property(self, "position", original_pos, 0.05)
