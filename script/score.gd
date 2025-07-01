extends Label

var time_delay = 0
var current_score: int = 0

func _ready() -> void:
	text = "Score: 0"

func _physics_process(delta: float) -> void:
	time_delay += 1
	if time_delay == 2:
		time_delay = 0
		current_score += 1
	add_score(current_score)
	
func add_score(points: int) -> void:
	text = "Score: " + str(current_score)

func reset_score() -> void:
	current_score = 0
	text = "Score: 0"
