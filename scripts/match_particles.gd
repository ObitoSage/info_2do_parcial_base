extends GPUParticles2D

func _ready():
	# Configuración básica de partículas para match
	emitting = false
	
func play_match_effect(match_length: int):
	var material = process_material as ParticleProcessMaterial
	
	# Configurar según el tipo de match
	match match_length:
		3:
			material.emission.amount_ratio = 20.0
			material.scale_min = 0.5
			material.scale_max = 1.0
			modulate = Color.YELLOW
		4:
			material.emission.amount_ratio = 30.0
			material.scale_min = 0.8
			material.scale_max = 1.5
			modulate = Color.ORANGE
		_: # 5+
			material.emission.amount_ratio = 50.0
			material.scale_min = 1.0
			material.scale_max = 2.0
			modulate = Color.MAGENTA
	
	emitting = true
	
	# Auto-apagar después de 1 segundo
	await get_tree().create_timer(1.0).timeout
	emitting = false
