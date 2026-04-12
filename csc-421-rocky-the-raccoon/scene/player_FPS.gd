extends CharacterBody3D

@export var mouse_sensitivity: float = 0.0025
@export var pitch_limit_deg: float = 80.0
@export var ray_length: float = 100.0
@export var eye_height: float = 1.65
@export var auto_capture_mouse_on_start: bool = true
@export var crosshair_size: float = 12.0
@export var crosshair_thickness: float = 2.0
@export var min_fov: float = 35.0
@export var max_fov: float = 90.0
@export var zoom_step: float = 5.0
@export var force_camera_local_pose: bool = false
@export var align_pitch_pivot_to_camera_on_start: bool = true
@export var use_camera_transform_as_spawn_on_start: bool = true

@onready var pitch_pivot: Node3D = $PitchPivot
@onready var cam: Camera3D = _resolve_camera()

var _pitch: float = 0.0
var _crosshair_layer: CanvasLayer
var _controls_enabled: bool = true
var _hovered_interactable: Node = null


func _ready() -> void:
	_ensure_collision_shape()
	if use_camera_transform_as_spawn_on_start:
		_apply_camera_spawn_pose()
	if align_pitch_pivot_to_camera_on_start:
		_align_pitch_pivot_to_camera_point()
	if force_camera_local_pose:
		_setup_camera_pose()
	_ensure_crosshair()

	if auto_capture_mouse_on_start:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_update_crosshair_visibility()


func _unhandled_input(event: InputEvent) -> void:
	if not _controls_enabled:
		return

	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and key_event.keycode == KEY_ESCAPE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			_update_crosshair_visibility()
			return

	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_button.pressed:
			cam.fov = clamp(cam.fov - zoom_step, min_fov, max_fov)
			return
		if mouse_button.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_button.pressed:
			cam.fov = clamp(cam.fov + zoom_step, min_fov, max_fov)
			return
		if mouse_button.button_index == MOUSE_BUTTON_LEFT and mouse_button.pressed:
			if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
				_update_crosshair_visibility()
				return
			_click_interact()
			return

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var mouse_motion := event as InputEventMouseMotion
		# 360 yaw around body (no clamp).
		rotate_y(-mouse_motion.relative.x * mouse_sensitivity)

		# Clamp vertical look.
		_pitch = clamp(
			_pitch - mouse_motion.relative.y * mouse_sensitivity,
			deg_to_rad(-pitch_limit_deg),
			deg_to_rad(pitch_limit_deg)
		)
		pitch_pivot.rotation.x = _pitch


func _process(_delta: float) -> void:
	if not _controls_enabled or Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		_set_hovered_interactable(null)
		return

	_set_hovered_interactable(_get_center_interactable())


func _click_interact() -> void:
	var interactable := _get_center_interactable()
	if interactable != null:
		interactable.interact()


func _setup_camera_pose() -> void:
	if cam == null:
		return

	# Normalize old scene offsets so the camera pivots in place from the player root.
	pitch_pivot.position = Vector3.ZERO
	cam.position = Vector3(0.0, eye_height, 0.0)
	cam.rotation = Vector3.ZERO


func _ensure_collision_shape() -> void:
	if has_node("CollisionShape3D"):
		return

	var shape_node := CollisionShape3D.new()
	shape_node.name = "CollisionShape3D"

	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.4
	shape_node.shape = capsule
	shape_node.position = Vector3(0.0, 1.0, 0.0)

	add_child(shape_node)


func _ensure_crosshair() -> void:
	if _crosshair_layer != null:
		return

	_crosshair_layer = CanvasLayer.new()
	_crosshair_layer.name = "CrosshairLayer"
	add_child(_crosshair_layer)

	var root := Control.new()
	root.name = "CrosshairRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crosshair_layer.add_child(root)

	var h := ColorRect.new()
	h.name = "H"
	h.color = Color.WHITE
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.anchor_left = 0.5
	h.anchor_right = 0.5
	h.anchor_top = 0.5
	h.anchor_bottom = 0.5
	h.offset_left = -crosshair_size * 0.5
	h.offset_right = crosshair_size * 0.5
	h.offset_top = -crosshair_thickness * 0.5
	h.offset_bottom = crosshair_thickness * 0.5
	root.add_child(h)

	var v := ColorRect.new()
	v.name = "V"
	v.color = Color.WHITE
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.anchor_left = 0.5
	v.anchor_right = 0.5
	v.anchor_top = 0.5
	v.anchor_bottom = 0.5
	v.offset_left = -crosshair_thickness * 0.5
	v.offset_right = crosshair_thickness * 0.5
	v.offset_top = -crosshair_size * 0.5
	v.offset_bottom = crosshair_size * 0.5
	root.add_child(v)


func _update_crosshair_visibility() -> void:
	if _crosshair_layer != null:
		_crosshair_layer.visible = _controls_enabled and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED


func _find_interactable_ancestor(start: Node) -> Node:
	var current := start
	while current != null:
		if current.is_in_group("interactable") and current.has_method("interact"):
			return current
		current = current.get_parent()
	return null


func set_player_enabled(enabled: bool) -> void:
	_controls_enabled = enabled
	set_process_unhandled_input(enabled)
	set_process(enabled)
	if enabled:
		if auto_capture_mouse_on_start:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_set_hovered_interactable(null)
	_update_crosshair_visibility()


func get_camera() -> Camera3D:
	return cam


func _resolve_camera() -> Camera3D:
	if has_node("PitchPivot/Camera3D"):
		return $PitchPivot/Camera3D as Camera3D

	var children := pitch_pivot.get_children()
	for child in children:
		if child is Camera3D:
			return child as Camera3D

	push_warning("player_FPS.gd: No Camera3D found under PitchPivot.")
	return null


func _align_pitch_pivot_to_camera_point() -> void:
	if cam == null:
		return

	# Canonical FPS rig:
	# - Yaw rotates around player origin.
	# - Pitch rotates around a pivot at eye height.
	# - Camera sits at pivot local origin (no x/z offset => no orbiting).
	pitch_pivot.position = Vector3(0.0, eye_height, 0.0)
	cam.position = Vector3.ZERO


func _apply_camera_spawn_pose() -> void:
	if cam == null:
		return

	var cam_global_pos := cam.global_position
	var cam_global_rot := cam.global_rotation

	# Place the body so canonical eye-height pivot lands at the camera's authored world position.
	global_position = cam_global_pos - Vector3.UP * eye_height
	rotation.y = cam_global_rot.y
	_pitch = clamp(
		cam_global_rot.x,
		deg_to_rad(-pitch_limit_deg),
		deg_to_rad(pitch_limit_deg)
	)
	pitch_pivot.rotation.x = _pitch


func _get_center_interactable() -> Node:
	if cam == null:
		return null

	var vp := get_viewport()
	var center := vp.get_visible_rect().size * 0.5

	var from := cam.project_ray_origin(center)
	var dir := cam.project_ray_normal(center)
	var to := from + dir * ray_length

	var params := PhysicsRayQueryParameters3D.create(from, to)
	params.collide_with_areas = true
	params.collide_with_bodies = true
	params.exclude = [get_rid()]

	var hit := get_world_3d().direct_space_state.intersect_ray(params)
	if hit.is_empty():
		return null

	var obj: Node = hit.get("collider") as Node
	return _find_interactable_ancestor(obj)


func _set_hovered_interactable(next_interactable: Node) -> void:
	if _hovered_interactable == next_interactable:
		return

	if _hovered_interactable != null and _hovered_interactable.has_method("set_highlighted"):
		_hovered_interactable.set_highlighted(false)

	_hovered_interactable = next_interactable

	if _hovered_interactable != null and _hovered_interactable.has_method("set_highlighted"):
		_hovered_interactable.set_highlighted(true)
