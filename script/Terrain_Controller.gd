extends Node3D
class_name TerrainController

# Preload the scene here. This is the crucial step that ensures
# the scene is included in the Android export.
@export var terrain_scene: PackedScene = preload("res://Terrain_blocks/Terrain_0.tscn")

var terrain_belt: Array[MeshInstance3D] = []
@export var terrain_velocity: float = 6.0
@export var num_terrain_blocks: int = 2  # Start with 2 blocks for smoother transitions
@export var generation_distance: float = 100.0  # Distance ahead of camera to generate new blocks
@export var cleanup_distance: float = 50.0     # Distance behind camera to remove old blocks

const wall_scene = preload("res://scenes/Wall.tscn")
@onready var player: CharacterBody3D = $"../Control/VBoxContainer/SubViewportContainer/SubViewport/Player"
@onready var camera: Camera3D = $"../Control/VBoxContainer/SubViewportContainer/SubViewport/Player/Neck/Camera3D"
@onready var score_controller = $"../ScoreController/Score"
var generate_block: = 0
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

func _physics_process(delta: float) -> void:
	_progress_terrain(delta)
#
func _init_blocks(number_of_blocks: int) -> void:
	# A safety check to make sure the scene was loaded
	if terrain_scene == null:
		printerr("Terrain scene is not loaded. Cannot initialize blocks.")
		return

	for block_index in number_of_blocks:
		var block = terrain_scene.instantiate()
		
		if block.mesh == null:
			printerr("Terrain block has no mesh")
			block.queue_free()
			continue
		
		if block_index == 0 or block_index == 1:
			# Position first block so its front edge is at z=0
			block.position.z = -block.mesh.size.y / 2
			print("First block positioned at: ", block.position)
		add_child(block)
		terrain_belt.append(block)

func _progress_terrain(delta):
	position.z += 5*delta
	generate_block += 1
	if generate_block >= 60:
		generate_block = 0
		var block: = terrain_scene.instantiate()
		var last_terrain = terrain_belt[-1]
		block.position.z = last_terrain.position.z - last_terrain.mesh.size.y
		add_child(block)
		terrain_belt.append(block)
		
	if player.position.z > terrain_belt[-1].mesh.size.y:
		print("Freeing the last terrain")
		terrain_belt[-1].queue_free()
