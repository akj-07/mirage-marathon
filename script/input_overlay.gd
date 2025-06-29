extends Control

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			print("Left side pressed - releasing right first")
			# Ensure right is released when left is pressed
			Input.action_release("move_right")
			Input.action_press("move_left")
		else:
			print("Left side released")
			Input.action_release("move_left")
	elif event is InputEventScreenDrag:
		# Only press if not already pressed to avoid conflicts
		if not Input.is_action_pressed("move_left"):
			Input.action_release("move_right")  # Release opposite direction
			Input.action_press("move_left")

# Remove the _input method to avoid conflicts - only use _gui_input for GUI controls
