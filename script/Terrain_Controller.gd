extends Node3D
class_name TerrainController

# Preload both terrain scenes
@export var terrain_scenes: Array[PackedScene] = [
	preload("res://scenes/Terrain_1.tscn"),
	preload("res://scenes/Terrain_2.tscn"),
	preload("res://scenes/Terrain_3.tscn")
]

var terrain_belt: Array[MeshInstance3D] = []
@export var terrain_velocity: float = 6.0
@export var num_terrain_blocks: int = 2  # Start with 2 blocks for smoother transitions
const wall_scene = preload("res://scenes/Wall.tscn")
@onready var player: CharacterBody3D = $"../Control/VBoxContainer/SubViewportContainer/SubViewport/Player"
@onready var camera: Camera3D = $"../Control/VBoxContainer/SubViewportContainer/SubViewport/Player/Neck/Camera3D"
@onready var score_controller = $"../ScoreController/Score"
var generate_block: = 0
var last_terrain = null

func _ready() -> void:
	_init_blocks(1)
	print("Initial terrain blocks created: ", terrain_belt.size())

func _physics_process(delta: float) -> void:
	_progress_terrain(delta)

func _init_blocks(number_of_blocks: int) -> void:
	if terrain_scenes.size() == 0:
		printerr("No terrain scenes loaded. Cannot initialize blocks.")
		return

	for block_index in number_of_blocks:
		var terrain_scene = _pick_terrain_scene()
		var block = terrain_scene.instantiate()
		
		if block.mesh == null:
			printerr("Terrain block has no mesh")
			block.queue_free()
			continue
		
		if block_index == 0 or block_index == 1:
			block.position.z = -block.mesh.size.y / 2
			print("First block positioned at: ", block.position)
		add_child(block)
		terrain_belt.append(block)

func _progress_terrain(delta):
	position.z += 5*delta
	generate_block += 1
	if generate_block >= 120:
		generate_block = 0
		var terrain_scene = _pick_terrain_scene()
		var block = terrain_scene.instantiate()
		if terrain_belt:
			last_terrain = terrain_belt[-1]
			block.position.z = last_terrain.position.z - last_terrain.mesh.size.y
		add_child(block)
		terrain_belt.append(block)
		
	if terrain_belt.size():
		var first_block = terrain_belt[0]
		
		if player.global_position.z > first_block.global_position.z+50:
			print("Freeing the last terrain")
			terrain_belt.pop_front()
			first_block.queue_free()
			print('Freed..')

# Helper function to pick a random terrain scene
func _pick_terrain_scene() -> PackedScene:
	return terrain_scenes[randi() % terrain_scenes.size()]
