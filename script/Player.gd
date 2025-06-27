extends CharacterBody3D

const SPEED = 10.0

@export var side_speed: float = 8.0
#@export var move_limit_x: float = 20.0

func _physics_process(delta: float) -> void:
	# Reset lateral velocity each frame
	velocity.x = 0

	# Apply lateral input
	if Input.is_action_pressed("move_left"):
		velocity.x = -side_speed
	elif Input.is_action_pressed("move_right"):
		velocity.x = side_speed

	move_and_slide()

	# Clamp X position to prevent moving out of bounds
	#position.x = clamp(position.x, -move_limit_x, move_limit_x)

	var collision = get_last_slide_collision()
	if collision:
		print("Collided with: ", collision.get_collider())
		get_tree().quit()
		
