extends TextureRect

@onready var score_label = $MarginContainer/HBoxContainer/score_label
@onready var counter_label = $MarginContainer/HBoxContainer/counter_label

var current_score = 0
var current_count = 0

func _ready():
	# Initialize display
	score_label.text = "000000"
	counter_label.text = "00"

func update_score_display(new_score: int):
	current_score = new_score
	score_label.text = str(current_score).pad_zeros(6)

func update_counter_display(new_count: int):
	current_count = new_count
	counter_label.text = str(current_count).pad_zeros(2)
