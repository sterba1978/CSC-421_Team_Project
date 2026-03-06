extends Node3D

signal door_state_changed(is_open: bool)
signal door_opened

enum HingeAxis {
	X,
	Y,
	Z,
}

@export var click_area_path: NodePath = ^"ClickArea"
@export var solid_collision_shape_path: NodePath = ^"Solid/CollisionShape3D"
@export var hinge_axis: HingeAxis = HingeAxis.Y
@export var open_angle_degrees: float = 90.0
@export var anim_time: float = 0.25
@export var disable_solid_collision_when_open: bool = true
@export var start_open: bool = false
@export var hover_highlight_enabled: bool = true
@export var hover_highlight_color: Color = Color(1.0, 0.92, 0.35, 0.35)

var _is_open := false
var _closed_angle := 0.0
var _highlight_targets: Array[MeshInstance3D] = []
var _highlight_material: StandardMaterial3D
var _is_highlighted: bool = false

@onready var _click_area: Area3D = get_node_or_null(click_area_path) as Area3D
@onready var _solid_shape: CollisionShape3D = get_node_or_null(solid_collision_shape_path) as CollisionShape3D


func _ready() -> void:
	_closed_angle = _get_axis_angle()
	add_to_group("interactable")
	if _click_area != null:
		_click_area.input_event.connect(_on_click_area_input_event)
	else:
		push_warning("door_open.gd: ClickArea not found at path '%s'." % click_area_path)

	_is_open = start_open
	if _is_open:
		_set_door_state(true, false)

	_cache_highlight_targets()
	_build_highlight_material()
	set_highlighted(false)


func _on_click_area_input_event(
	_camera: Camera3D,
	event: InputEvent,
	_event_position: Vector3,
	_normal: Vector3,
	_shape_idx: int
) -> void:
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		toggle()


func toggle() -> void:
	_set_door_state(not _is_open, true)


func open() -> void:
	_set_door_state(true, true)


func close() -> void:
	_set_door_state(false, true)


func interact() -> void:
	toggle()


func set_highlighted(enabled: bool) -> void:
	if not hover_highlight_enabled:
		return
	if _is_highlighted == enabled:
		return
	_is_highlighted = enabled

	for mesh in _highlight_targets:
		if mesh == null:
			continue
		mesh.material_overlay = _highlight_material if enabled else null


func _set_door_state(open_state: bool, animate: bool) -> void:
	_is_open = open_state

	if disable_solid_collision_when_open and _solid_shape != null:
		_solid_shape.disabled = _is_open

	var target_angle := _closed_angle
	if _is_open:
		target_angle += open_angle_degrees

	if not animate:
		_set_axis_angle(target_angle)
		door_state_changed.emit(_is_open)
		if _is_open:
			door_opened.emit()
		return

	var tween_property := "rotation_degrees:y"
	match hinge_axis:
		HingeAxis.X:
			tween_property = "rotation_degrees:x"
		HingeAxis.Y:
			tween_property = "rotation_degrees:y"
		HingeAxis.Z:
			tween_property = "rotation_degrees:z"

	var t := create_tween()
	t.tween_property(self, tween_property, target_angle, anim_time)
	t.finished.connect(_on_tween_finished.bind(_is_open))


func _get_axis_angle() -> float:
	match hinge_axis:
		HingeAxis.X:
			return rotation_degrees.x
		HingeAxis.Y:
			return rotation_degrees.y
		HingeAxis.Z:
			return rotation_degrees.z
	return rotation_degrees.y


func _set_axis_angle(value: float) -> void:
	var r := rotation_degrees
	match hinge_axis:
		HingeAxis.X:
			r.x = value
		HingeAxis.Y:
			r.y = value
		HingeAxis.Z:
			r.z = value
	rotation_degrees = r


func _on_tween_finished(open_state: bool) -> void:
	door_state_changed.emit(open_state)
	if open_state:
		door_opened.emit()


func _cache_highlight_targets() -> void:
	_highlight_targets.clear()
	_collect_mesh_instances(self)


func _collect_mesh_instances(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			_highlight_targets.append(child as MeshInstance3D)
		_collect_mesh_instances(child)


func _build_highlight_material() -> void:
	_highlight_material = StandardMaterial3D.new()
	_highlight_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_highlight_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_highlight_material.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	_highlight_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_highlight_material.albedo_color = hover_highlight_color
	_highlight_material.emission_enabled = true
	_highlight_material.emission = hover_highlight_color
