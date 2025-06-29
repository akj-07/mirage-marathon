extends CharacterBody3D

const SPEED = 10.0

@export var side_speed: float = 8.0
#@export var move_limit_x: float = 20.0

func _physics_process(delta: float) -> void:
	# Reset lateral velocity each frame
	velocity.x = 0

	# Debug prints to see what inputs are active
	var left_pressed = Input.is_action_pressed("move_left")
	var right_pressed = Input.is_action_pressed("move_right")
	
	# Apply lateral input with priority system
	if left_pressed and not right_pressed:
		velocity.x = -side_speed
		print("Moving left")
	elif right_pressed and not left_pressed:
		velocity.x = side_speed
		print("Moving right")
	elif left_pressed and right_pressed:
		# Both pressed - cancel out (or you could give priority to one)
		velocity.x = 0
		print("Both directions pressed - canceling")

	move_and_slide()

	# Clamp X position to prevent moving out of bounds
	#position.x = clamp(position.x, -move_limit_x, move_limit_x)

	var collision = get_last_slide_collision()
	if collision:
		print("Collided with: ", collision.get_collider())
		get_tree().quit()

# Add this method to handle input cleanup
func _ready():
	# Ensure all actions are released at start
	Input.action_release("move_left")
	Input.action_release("move_right")
