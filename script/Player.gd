extends CharacterBody3D

const SPEED = 10.0
const GRAVITY = 10.0
const FALL_SPEED = 15.0

@export var side_speed: float = 8.0
@export var terrain_width: float = 15.0
@export var fall_height: float = -10.0
var is_falling: bool = false
var has_fallen: bool = false

func _physics_process(delta: float) -> void:
	# If player is falling, handle falling logic
	if is_falling:
		handle_falling(delta)
		return
	
	# Reset lateral velocity each frame
	velocity.x = 0

	# Debug prints to see what inputs are active
	var left_pressed = Input.is_action_pressed("move_left")
	var right_pressed = Input.is_action_pressed("move_right")
	
	# Apply lateral input with priority system
	if left_pressed and not right_pressed:
		velocity.x = -side_speed

	elif right_pressed and not left_pressed:
		velocity.x = side_speed

	elif left_pressed and right_pressed:
		# Both pressed - cancel out (or you could give priority to one)
		velocity.x = 0
		print("Both directions pressed - canceling")
	
	# Check boundaries before moving
	check_terrain_boundaries()

	move_and_slide()

	# Check for collisions with obstacles
	var collision = get_last_slide_collision()
	if collision:
		print("Collided with: ", collision.get_collider())
		get_tree().quit()

func _ready():
	# Ensure all actions are released at start
	Input.action_release("move_left")
	Input.action_release("move_right")
	
func check_terrain_boundaries() -> void:
	# Check if player is outside the terrain width
	if abs(position.x) > terrain_width:
		start_falling()
		return
	
	# Check if player has fallen below the fall height
	if position.y < fall_height:
		start_falling()
		return

func start_falling() -> void:
	if not is_falling:
		is_falling = true
		has_fallen = true
		print("Player fell off the terrain!")
		# Stop horizontal movement when falling
		velocity.x = 0
		
func handle_falling(delta: float) -> void:
	# Apply gravity when falling
	velocity.y -= GRAVITY * delta
	
	# Keep horizontal velocity at 0 during fall
	velocity.x = 0
	
	# Use move_and_slide to handle the falling movement
	move_and_slide()
	
	# Check if player has fallen far enough to trigger game over
	if position.y < fall_height - 5.0:  # 5 units below fall height
		game_over()

func game_over() -> void:
	print("Game Over - Player fell!")
	get_tree().quit()
