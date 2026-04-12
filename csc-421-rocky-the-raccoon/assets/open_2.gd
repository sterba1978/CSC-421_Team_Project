extends Node3D

@export var hover_highlight_enabled: bool = true
@export var hover_highlight_color: Color = Color(1.0, 0.92, 0.35, 0.35)
@export var click_area_path: NodePath = ^"StaticBody3D"

var _highlight_targets: Array[MeshInstance3D] = []
var _highlight_material: StandardMaterial3D
var _is_highlighted := false

@onready var _click_target: CollisionObject3D = _resolve_click_target()

@onready var cabinetui = $"../File2"


func _ready() -> void:
	add_to_group("interactable")

	if _click_target:
		_click_target.input_event.connect(_on_click_area_input_event)
	else:
		push_warning("Interactable: Click target not found at path '%s'." % click_area_path)

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
		interact()


func interact() -> void:
	cabinetui.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func set_highlighted(enabled: bool) -> void:
	if not hover_highlight_enabled:
		return
	if _is_highlighted == enabled:
		return

	_is_highlighted = enabled

	for mesh in _highlight_targets:
		if mesh == null or mesh.mesh == null:
			continue
		if enabled:
			mesh.material_overlay = _highlight_material
		elif mesh.material_overlay == _highlight_material:
			mesh.material_overlay = null


func _cache_highlight_targets() -> void:
	_highlight_targets.clear()
	_collect_mesh_instances(self)


func _collect_mesh_instances(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D and child.mesh != null:
			_highlight_targets.append(child)
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


func _resolve_click_target() -> CollisionObject3D:
	var node := get_node_or_null(click_area_path)
	if node is CollisionObject3D:
		return node as CollisionObject3D
	if node is CollisionShape3D and node.get_parent() is CollisionObject3D:
		return node.get_parent() as CollisionObject3D

	var fallback_click_area := find_child("ClickArea", true, false)
	if fallback_click_area is CollisionObject3D:
		return fallback_click_area as CollisionObject3D

	var all_nodes := find_children("*", "CollisionObject3D", true, false)
	if not all_nodes.is_empty():
		return all_nodes[0] as CollisionObject3D

	return null
