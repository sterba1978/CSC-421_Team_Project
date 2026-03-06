extends Node3D

@export var edge_margin_px: float = 90.0        # how close to the edge before turning
@export var max_turn_speed: float = 1.6         # radians/sec
@export var pitch_limit_deg: float = 75.0
@export var ray_length: float = 100.0

@onready var pitch_pivot: Node3D = $PitchPivot
@onready var cam: Camera3D = $PitchPivot/Camera3D

var _pitch := 0.0

func _ready() -> void:
	# Keep cursor visible but inside the window (good for point-and-click).
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)

func _process(delta: float) -> void:
	_edge_pan(delta)

func _edge_pan(delta: float) -> void:
	var vp := get_viewport()
	var size := vp.get_visible_rect().size
	var mpos := vp.get_mouse_position()

	var turn_x := _edge_axis(mpos.x, size.x)   # yaw
	var turn_y := _edge_axis(mpos.y, size.y)   # pitch

	# Yaw (left/right)
	rotate_y(turn_x * max_turn_speed * delta)

	# Pitch (up/down)
	_pitch = clamp(_pitch - turn_y * max_turn_speed * delta,
		deg_to_rad(-pitch_limit_deg), deg_to_rad(pitch_limit_deg))
	pitch_pivot.rotation.x = _pitch

func _edge_axis(p: float, max_p: float) -> float:
	# Returns -1..1 depending on how deep into the edge zone the cursor is.
	if p < edge_margin_px:
		return -((edge_margin_px - p) / edge_margin_px)
	if p > max_p - edge_margin_px:
		return ((p - (max_p - edge_margin_px)) / edge_margin_px)
	return 0.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_click_interact()

func _click_interact() -> void:
	var vp := get_viewport()
	var mpos := vp.get_mouse_position()

	var from := cam.project_ray_origin(mpos)
	var dir := cam.project_ray_normal(mpos)
	var to := from + dir * ray_length

	var params := PhysicsRayQueryParameters3D.create(from, to)
	params.collide_with_areas = true
	params.collide_with_bodies = true

	var hit := get_world_3d().direct_space_state.intersect_ray(params)
	if hit.is_empty():
		return

	var obj: Node = hit.get("collider") as Node
	# Easiest pattern: put interactables in a group and give them an interact() method.
	if obj != null and obj.is_in_group("interactable") and obj.has_method("interact"):
		obj.interact()
