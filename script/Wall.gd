extends CSGBox3D

class_name Wall

## Provides the movement direction along x-axis or y-axis
## based on your selection.
@export_flags("x-axis","y-axis",)
var direction = 0

## Stores the minimum of random value of the distance wall 
## can move along x-axis.
@export var x_offset_min = 0

## Stores the maximum of random value of the distance wall 
## can move along x-axis.
@export var x_offset_max = 0 

## Stores the minimum of random value of the distance wall 
## can move along y-axis.
@export var y_offset_min = 0

## Stores the maximum of random value of the distance wall 
## can move along y-axis.
@export var y_offset_max = 0 

## Whether the 
@export_enum("Yes","No")
var Holes = 1

@export var hole_offset_min: float = 0.0
@export var hole_offset_max: float = 0.0

@export_flags("Width","Height","Depth")
var Scale=0

@export var x_scale_min = 0
@export var x_scale_max = 0
@export var y_scale_min = 0
@export var y_scale_max = 0
@export var z_scale_min = 0
@export var z_scale_max = 0

func _ready():
	apply_offset_positioning()

func apply_offset_positioning():
	if direction & 1: 
		var x_offset = randf_range(x_offset_min, x_offset_max)
		position.x += x_offset

	if direction & 2: 
		var y_offset = randf_range(y_offset_min, y_offset_max)
		position.y += y_offset

func apply_offset_holes():
	if Holes & 0:
		var holes_offset = randf_range(hole_offset_min,hole_offset_max)
		position.x += holes_offset

func apply_offset_scale():
	if Scale & 1: # Width (x)
		var x_scale = randf_range(x_scale_min, x_scale_max)
		scale.x = x_scale
	if Scale & 2: # Height (y)
		var y_scale = randf_range(y_scale_min, y_scale_max)
		scale.y = y_scale
	if Scale & 4: # Depth (z)
		var z_scale = randf_range(z_scale_min, z_scale_max)
		scale.z = z_scale
