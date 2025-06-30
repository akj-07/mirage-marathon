extends Label

var current_score: int = 0

func _ready() -> void:
	# Initialize score display
	text = "Score: 0"
	
func add_score(points: int) -> void:
	current_score += points
	text = "Score: " + str(current_score)
	print("Score updated: ", current_score)

func get_score() -> int:
	return current_score

func reset_score() -> void:
	current_score = 0
	text = "Score: 0"
