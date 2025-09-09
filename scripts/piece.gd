extends Node2D

@export var color: String
@export var piece_type: String = "normal" # normal, column, row, rainbow

var matched = false

func move(target):
	var move_tween = create_tween()
	move_tween.set_trans(Tween.TRANS_ELASTIC)
	move_tween.set_ease(Tween.EASE_OUT)
	move_tween.tween_property(self, "position", target, 0.4)

func dim():
	$Sprite2D.modulate = Color(1, 1, 1, 0.5)

func explode_effect():
	# Simple explosion effect for bomb pieces
	if piece_type == "bomb":
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "scale", Vector2(2.0, 2.0), 0.3)
		tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.3)
		tween.tween_callback(queue_free).set_delay(0.3)
