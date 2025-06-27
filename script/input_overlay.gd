extends Control

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			_process_touch(event.position)
	elif event is InputEventScreenDrag:
		_process_touch(event.position)

func _process_touch(pos: Vector2) -> void:
	var screen_center = get_viewport().size.x / 2
	if pos.x < screen_center:
		Input.action_press("move_left")
		Input.action_release("move_right")
	else:
		Input.action_press("move_right")
		Input.action_release("move_left")
