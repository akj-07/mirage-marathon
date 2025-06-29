extends Control

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			print("Right side pressed - releasing left first")
			# Ensure left is released when right is pressed
			Input.action_release("move_left")
			Input.action_press("move_right")
		else:
			print("Right side released")
			Input.action_release("move_right")
	elif event is InputEventScreenDrag:
		# Only press if not already pressed to avoid conflicts
		if not Input.is_action_pressed("move_right"):
			Input.action_release("move_left")  # Release opposite direction
			Input.action_press("move_right")

# Remove the _input method to avoid conflicts - only use _gui_input for GUI controls
