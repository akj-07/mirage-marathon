extends Node3D
class_name TerrainController

# Preload the scene here. This is the crucial step that ensures
# the scene is included in the Android export.
@export var terrain_scene: PackedScene = preload("res://scenes/Endless_Terrain.tscn")

var terrain_belt: Array[MeshInstance3D] = []
@export var terrain_velocity: float = 6.0
@export var num_terrain_blocks: int = 2  # Start with 2 blocks for smoother transitions
@export var generation_distance: float = 100.0  # Distance ahead of camera to generate new blocks
@export var cleanup_distance: float = 50.0     # Distance behind camera to remove old blocks

const wall_scene = preload("res://scenes/Wall.tscn")
@onready var player: CharacterBody3D = $"../Control/VBoxContainer/SubViewportContainer/SubViewport/Player"
@onready var camera: Camera3D = $"../Control/VBoxContainer/SubViewportContainer/SubViewport/Player/Neck/Camera3D"
@onready var score_controller = $"../ScoreController/Score"
var last_terrain = null

# Track walls separately to prevent premature deletion
var active_walls: Array[Node3D] = []
# Track wall generation parameters
@export var wall_generation_distance: float = 15.0  # Distance ahead of camera to generate walls
@export var wall_spacing: float = 8.0  # Fixed distance between walls
@export var wall_generation_ahead: float = 100.0   # Maximum distance ahead to maintain walls

# Score tracking
var passed_walls: Array[Node3D] = []  # Track walls that have been passed to avoid double scoring
@export var points_per_wall: int = 10  # Points awarded for passing each wall

func _ready() -> void:
	# Force initialization of exactly 2 blocks
	_init_blocks(2)
	print("Initial terrain blocks created: ", terrain_belt.size())
	
	# Verify score controller connection
	if score_controller == null:
		print("Warning: Score controller not found at path: ../ScoreController/Score")
	else:
		print("Score controller connected successfully")

func _physics_process(delta: float) -> void:
	_progress_terrain(delta)
	_manage_terrain_based_on_camera()
	_manage_wall_generation()
	_cleanup_distant_walls()
	_check_wall_passes()  # New function to check for wall passes

func _init_blocks(number_of_blocks: int) -> void:
	# A safety check to make sure the scene was loaded
	if terrain_scene == null:
		printerr("Terrain scene is not loaded. Cannot initialize blocks.")
		return

	for block_index in number_of_blocks:
		var block = terrain_scene.instantiate()
		
		if not block is MeshInstance3D:
			printerr("Terrain scene must be a MeshInstance3D")
			block.queue_free()
			continue
			
		if block.mesh == null:
			printerr("Terrain block has no mesh")
			block.queue_free()
			continue
		
		if block_index == 0 or block_index == 1:
			# Position first block so its front edge is at z=0
			block.position.z = -block.mesh.size.y / 2
			print("First block positioned at: ", block.position)
		else:
			_append_to_far_edge(terrain_belt[block_index-1], block)
			print("Block ", block_index, " positioned at: ", block.position)
		
		add_child(block)
		terrain_belt.append(block)

func _progress_terrain(delta: float) -> void:
	# A safety check to prevent errors if the belt is empty
	if terrain_belt.is_empty():
		return

	# Move all terrain blocks forward
	for block in terrain_belt:
		block.position.z += terrain_velocity * delta
	
	# Move walls with terrain (they should move automatically as children, but just in case)
	for wall in active_walls:
		if is_instance_valid(wall):
			wall.global_position.z += terrain_velocity * delta

func _manage_terrain_based_on_camera() -> void:
	if terrain_belt.is_empty() or camera == null:
		return
	
	var camera_z = camera.global_position.z
	
	# Check if we need to generate a new block
	if terrain_belt.size() >= 1:
		var first_block = terrain_belt[0]
		var first_block_end = first_block.global_position.z + first_block.mesh.size.y / 2
		
		# Generate new block when player is close to the end of first block
		if camera_z >= (first_block_end - generation_distance):
			_generate_new_block()
			print("Generated new block. Total blocks: ", terrain_belt.size())
	
	# Only remove old blocks if we have more than 2 blocks AND the first block is far behind
	if terrain_belt.size() > 2:
		var first_block = terrain_belt[0]
		var first_block_end = first_block.global_position.z + first_block.mesh.size.y / 2
		
		# More conservative cleanup - only remove when block is much further behind
		if first_block_end < (camera_z - cleanup_distance * 2):  # Double the cleanup distance
			_remove_old_block()
			print("Removed old block. Remaining blocks: ", terrain_belt.size())

func _append_to_far_edge(target_block: MeshInstance3D, appending_block: MeshInstance3D) -> void:
	if target_block.mesh == null or appending_block.mesh == null:
		return
	
	# FIXED: Use Z axis consistently for positioning
	appending_block.position.z = target_block.position.z - target_block.mesh.size.y / 2 - appending_block.mesh.size.y / 2
	
	# Keep blocks at the same height
	appending_block.position.y = target_block.position.y

func _generate_new_block() -> void:
	if terrain_scene == null:
		return
	
	var block = terrain_scene.instantiate()
	
	if not block is MeshInstance3D or block.mesh == null:
		printerr("Invalid terrain block")
		block.queue_free()
		return
	
	# Position new block at the end of the last block
	if not terrain_belt.is_empty():
		last_terrain = terrain_belt[-1]
	_append_to_far_edge(last_terrain, block)
	
	add_child(block)
	terrain_belt.append(block)
	
	print("New block generated at position: ", block.position)

func _remove_old_block() -> void:
	if terrain_belt.is_empty():
		return
	
	var old_block = terrain_belt.pop_front()
	
	# Remove any walls that are children of this block
	_remove_walls_from_block(old_block)
	
	old_block.queue_free()
	print("Old block removed")

func _manage_wall_generation() -> void:
	if camera == null or terrain_belt.is_empty():
		return
	
	var camera_z = camera.global_position.z
	
	# Check if we have any active walls
	if active_walls.is_empty():
		# No walls exist - generate walls up to 100m ahead
		_generate_initial_wall_segment(camera_z)
	else:
		# Find the furthest wall ahead
		var furthest_wall_z = _get_furthest_wall_z()
		
		# If the furthest wall is less than 100m ahead, generate more walls
		var distance_to_furthest = camera_z - furthest_wall_z
		if distance_to_furthest > -(wall_generation_ahead):
			_generate_walls_to_distance(furthest_wall_z, camera_z - wall_generation_ahead)

func _generate_initial_wall_segment(camera_z: float) -> void:
	"""Generate walls from current position up to 100m ahead"""
	print("Generating initial wall segment")
	
	var current_z = camera_z - wall_spacing  # Start first wall 8 units ahead
	var target_z = camera_z - wall_generation_ahead  # Generate up to 100m ahead
	
	while current_z >= target_z:
		_generate_wall_at_position(current_z)
		current_z -= wall_spacing  # Move to next wall position (8 units further)

func _generate_walls_to_distance(start_z: float, target_z: float) -> void:
	"""Generate walls from start_z to target_z with proper spacing"""
	print("Generating walls from ", start_z, " to ", target_z)
	
	var current_z = start_z - wall_spacing  # Start next wall at proper spacing
	
	while current_z >= target_z:
		_generate_wall_at_position(current_z)
		current_z -= wall_spacing  # Move to next wall position

func _get_furthest_wall_z() -> float:
	"""Get the Z position of the furthest wall ahead (lowest Z value)"""
	var furthest_z = INF
	
	for wall in active_walls:
		if is_instance_valid(wall):
			if wall.global_position.z < furthest_z:
				furthest_z = wall.global_position.z
	
	return furthest_z if furthest_z != INF else 0.0

func _generate_wall_at_position(target_z: float) -> void:
	if wall_scene == null or terrain_belt.is_empty():
		return
	
	# Find the terrain block that should contain this wall
	var target_block: MeshInstance3D = null
	for block in terrain_belt:
		var block_start = block.global_position.z - block.mesh.size.y / 2
		var block_end = block.global_position.z + block.mesh.size.y / 2
		if target_z >= block_start and target_z <= block_end:
			target_block = block
			break
	
	if target_block == null:
		# If no block found, use the last block as fallback
		target_block = terrain_belt[-1]
	
	# Randomly decide if we should spawn a wall (50% chance)
	if randi_range(0, 1) == 0:
		print("Skipping wall generation at ", target_z, " (random)")
		return
	
	var wall = wall_scene.instantiate()
	
	# Set wall size
	var wall_width = 6.0
	var wall_height = 4.0
	var wall_depth = 1.0
	
	if wall.mesh is BoxMesh:
		wall.mesh.size = Vector3(wall_width, wall_height, wall_depth)
		
	var static_body = wall.get_node("StaticBody3D")
	if static_body:
		var collision_shape = static_body.get_node("CollisionShape3D")
		if collision_shape and collision_shape.shape is BoxShape3D:
			collision_shape.shape.size = Vector3(wall_width, wall_height, wall_depth)
			
	# Position wall
	var block_width = target_block.mesh.size.x
	var x = randf_range(-block_width/2 + wall_width/2, block_width/2 - wall_width/2)
	var final_global_pos = Vector3(x, wall_height/2, target_z)
	
	# Add wall as child of the terrain block so it moves with it
	target_block.add_child(wall)
	wall.global_position = final_global_pos
	active_walls.append(wall)
	
	# Add custom metadata to track if this wall has been passed
	wall.set_meta("passed", false)
	wall.set_meta("original_z", target_z)  # Store original Z position for scoring
	
	print("Generated wall at position: ", wall.global_position, " on block at: ", target_block.global_position)

func _check_wall_passes() -> void:
	"""Check if player has passed any walls and award points"""
	if camera == null:
		return
	
	var player_z = camera.global_position.z
	
	for wall in active_walls:
		if not is_instance_valid(wall):
			continue
		
		# Check if this wall hasn't been passed yet
		if not wall.get_meta("passed", false):
			# Check if player has passed this wall (player Z is greater than wall Z)
			if player_z > wall.global_position.z:
				# Mark wall as passed
				wall.set_meta("passed", true)
				
				# Award points
				_update_score(points_per_wall)
				print("Player passed wall! Awarded ", points_per_wall, " points. Wall was at Z: ", wall.global_position.z)

func _remove_walls_from_block(block: MeshInstance3D) -> void:
	# Remove walls that belong to this block from our tracking array
	for i in range(active_walls.size() - 1, -1, -1):
		var wall = active_walls[i]
		if not is_instance_valid(wall) or wall.get_parent() == block:
			active_walls.remove_at(i)
			print("Wall removed from tracking")

func _cleanup_distant_walls() -> void:
	if camera == null:
		return
	
	var camera_z = camera.global_position.z
	
	# Remove walls that are too far behind the camera
	for i in range(active_walls.size() - 1, -1, -1):
		var wall = active_walls[i]
		if not is_instance_valid(wall):
			active_walls.remove_at(i)
			continue
		
		# Remove walls that are too far behind the camera
		if wall.global_position.z > camera_z + cleanup_distance:
			print("Cleaning up distant wall at: ", wall.global_position)
			wall.queue_free()
			active_walls.remove_at(i)

func _update_score(points: int) -> void:
	"""Update the score by adding points"""
	if score_controller != null:
		if score_controller.has_method("add_score"):
			score_controller.add_score(points)
			print("Score updated: +", points, " points")
		elif score_controller.has_method("update_score"):
			score_controller.update_score(points)
			print("Score updated: +", points, " points")
		else:
			print("Warning: Score controller doesn't have add_score() or update_score() method")
			# Try to access score property directly if it exists
			if "score" in score_controller:
				score_controller.score += points
				print("Score updated directly: +", points, " points")
	else:
		print("Warning: Score controller not found - cannot update score")

# Optional: Public method to manually add score (can be called from other scripts)
func add_score(points: int) -> void:
	_update_score(points)
