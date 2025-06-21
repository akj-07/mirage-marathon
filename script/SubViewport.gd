extends SubViewport


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("forward"):
		$CameraForward.set_current(true)
	
	if Input.is_action_just_pressed("backward"):
		$CameraBackward.set_current(true)
	
	if Input.is_action_just_pressed("Left"):
		$CameraLeft.set_current(true)
		
	if Input.is_action_just_pressed("Right"):
		$CameraRight.set_current(true)
