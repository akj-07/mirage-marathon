extends Camera3D

# Store the default (front) and top view transforms
var front_view_transform: Transform3D
var top_view_transform: Transform3D

func _ready():
	# Save the default transform as the front view
	front_view_transform = transform
	# Define the top view transform (adjust as needed for your scene)
	top_view_transform = Transform3D(Basis().rotated(Vector3(1,0,0), -PI/2), Vector3(0, 10, 0))

func set_front_view():
	transform = front_view_transform

func set_top_view():
	transform = top_view_transform
