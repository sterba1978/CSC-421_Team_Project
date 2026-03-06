extends Node3D
@onready var outside_cam: Camera3D = $OutsideCamera

func _ready() -> void:
	outside_cam.make_current()
