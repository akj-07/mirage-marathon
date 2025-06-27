extends Node3D
class_name TerrainController

# Preload the scene here. This is the crucial step that ensures
# the scene is included in the Android export.
@export var terrain_scene: PackedScene = preload("res://scenes/Endless_Terrain.tscn")

var terrain_belt: Array[MeshInstance3D] = []
@export var terrain_velocity: float = 10.0
@export var num_terrain_blocks: int = 1  # Start with more blocks for smoother transitions
@export var generation_distance: float = 50.0  # Distance ahead of camera to generate new blocks
@export var cleanup_distance: float = 30.0     # Distance behind camera to remove old blocks

const wall_scene = preload("res://scenes/Wall.tscn")
@onready var player: CharacterBody3D = $"../Control/VBoxContainer/SubViewportContainer/SubViewport/Player"
@onready var camera: Camera3D = $"../Control/VBoxContainer/SubViewportContainer/SubViewport/Player/Neck/Camera3D"

# Track walls separately to prevent premature deletion
var active_walls: Array[Node3D] = []

func _ready() -> void:
	_init_blocks(num_terrain_blocks)

func _physics_process(delta: float) -> void:
	_progress_terrain(delta)
	_manage_terrain_based_on_camera()
	_cleanup_distant_walls()

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
		
		if block_index == 0:
			# Position first block so its front edge is at z=0
			block.position.z = -block.mesh.size.y / 2
		else:
			_append_to_far_edge(terrain_belt[block_index-1], block)
		
		add_child(block)
		terrain_belt.append(block)
		
		# Spawn walls on blocks after the first one (so player doesn't spawn inside a wall)
		if block_index > 0:
			_spawn_walls(block)

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
	
	# Check if we need to generate a new block ahead
	var last_block = terrain_belt[-1]
	var last_block_end = last_block.global_position.y + last_block.mesh.size.y / 2
	
	if last_block_end < camera_z + generation_distance:
		_generate_new_block()
	
	# Check if we need to remove old blocks behind the camera
	var first_block = terrain_belt[0]
	var first_block_end = first_block.global_position.y + first_block.mesh.size.y / 2
	
	if first_block_end < camera_z - cleanup_distance:
		_remove_old_block()

func _generate_new_block() -> void:
	if terrain_scene == null:
		return
	
	var block = terrain_scene.instantiate()
	
	if not block is MeshInstance3D or block.mesh == null:
		printerr("Invalid terrain block")
		block.queue_free()
		return
	
	var last_terrain = terrain_belt[-1]
	_append_to_far_edge(last_terrain, block)
	add_child(block)
	terrain_belt.append(block)
	_spawn_walls(block)

func _remove_old_block() -> void:
	if terrain_belt.is_empty():
		return
	
	var old_block = terrain_belt.pop_front()
	
	# Remove any walls that are children of this block
	_remove_walls_from_block(old_block)
	
	old_block.queue_free()

func _append_to_far_edge(target_block: MeshInstance3D, appending_block: MeshInstance3D) -> void:
	if target_block.mesh == null or appending_block.mesh == null:
		return
	
	# Position the new block at the far edge of the target block
	appending_block.position.z = target_block.position.y - target_block.mesh.size.y / 2 - appending_block.mesh.size.y / 2
	
	# Keep blocks at the same height
	appending_block.position.y = target_block.position.y

func _spawn_walls(block: MeshInstance3D) -> void:
	if wall_scene == null or block.mesh == null: 
		return
	
	# Spawn 0,1 walls randomly on this block
	var num_walls = randi_range(0,1)
	
	for i in range(num_walls):
		var wall = wall_scene.instantiate()
		
		# Set wall size
		var wall_width = 6.0
		var wall_height = 4.0
		var wall_depth = 1.0
		
		if wall.has_method("set_wall_size"):
			wall.set_wall_size(wall_width, wall_height, wall_depth)
		elif wall is MeshInstance3D and wall.mesh is BoxMesh:
			wall.mesh.size = Vector3(wall_width, wall_height, wall_depth)
		
		# Position wall randomly on the block (using local coordinates)
		var block_width = block.mesh.size.x
		var block_length = block.mesh.size.y  # Use z for length since that's our forward axis
		
		wall.position.x = randf_range(-block_width/2 + wall_width/2, block_width/2 - wall_width/2)
		wall.position.z = randf_range(-block_length/2 + wall_depth/2, block_length/2 - wall_depth/2)
		wall.position.y = wall_height / 2  # So it sits on the terrain surface
		
		# Add wall as child of the terrain block so it moves with it
		block.add_child(wall)
		
		# Track the wall for cleanup
		active_walls.append(wall)
		
		print("Spawning wall at local position: ", wall.position, " on block at: ", block.global_position)

func _remove_walls_from_block(block: MeshInstance3D) -> void:
	# Remove walls that belong to this block from our tracking array
	for i in range(active_walls.size() - 1, -1, -1):
		var wall = active_walls[i]
		if not is_instance_valid(wall) or wall.get_parent() == block:
			active_walls.remove_at(i)

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
		
		if wall.global_position.z > camera_z + cleanup_distance:
			wall.queue_free()
			active_walls.remove_at(i)
