extends Button

func _ready() -> void:
	# Allow button to work when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Connect the button press signal
	pressed.connect(_on_pressed)
	# Set initial text
	text = "⏸"

func _on_pressed() -> void:
	# Toggle pause state
	get_tree().paused = not get_tree().paused
	
	# Update button text based on pause state
	if get_tree().paused:
		text = "▶"  # Play symbol when paused
	else:
		text = "⏸"  # Pause symbol when playing
