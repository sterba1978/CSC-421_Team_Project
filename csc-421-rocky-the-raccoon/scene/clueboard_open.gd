extends Node3D

@export var hover_highlight_enabled: bool = true
@export var hover_highlight_color: Color = Color(1.0, 0.92, 0.35, 0.35)
@export var click_area_path: NodePath = ^"ClickArea"

var _highlight_targets: Array[MeshInstance3D] = []
var _highlight_material: StandardMaterial3D
var _is_highlighted := false

@onready var _click_area: Area3D = get_node_or_null(click_area_path) as Area3D

@onready var clueboardui = $"../ClueBoardUI"


func _ready() -> void:
	add_to_group("interactable")

	if _click_area:
		_click_area.input_event.connect(_on_click_area_input_event)
	else:
		push_warning("Interactable: ClickArea not found at path '%s'." % click_area_path)

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
	clueboardui.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func set_highlighted(enabled: bool) -> void:
	if not hover_highlight_enabled:
		return
	if _is_highlighted == enabled:
		return

	_is_highlighted = enabled

	for mesh in _highlight_targets:
		if mesh:
			mesh.material_overlay = _highlight_material if enabled else null


func _cache_highlight_targets() -> void:
	_highlight_targets.clear()
	_collect_mesh_instances(self)


func _collect_mesh_instances(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
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
