extends Node3D

signal closed

@export var player_path: NodePath = ^"../../../../InteriorPlayer"
@export var default_texture: Texture2D
@export var tab_1_texture: Texture2D
@export var tab_2_texture: Texture2D
@export var tab_3_texture: Texture2D

@onready var _player: Node = get_node_or_null(player_path)
@onready var _folder_mesh: MeshInstance3D = $FolderMesh
@onready var _return_layer: CanvasLayer = $ReturnLayer

var _folder_material: StandardMaterial3D

func _ready() -> void:
	var base_material := _folder_mesh.material_override as StandardMaterial3D
	if base_material != null:
		_folder_material = base_material.duplicate() as StandardMaterial3D
	else:
		_folder_material = StandardMaterial3D.new()
	_folder_mesh.material_override = _folder_material
	_show_texture(default_texture)
	hide()
	_return_layer.visible = false


func open_folder() -> void:
	_show_texture(default_texture)
	show()
	_return_layer.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if _player != null and _player.has_method("set_player_enabled"):
		_player.set_player_enabled(false)


func close_folder() -> void:
	hide()
	_return_layer.visible = false
	if _player != null and _player.has_method("set_player_enabled"):
		_player.set_player_enabled(true)
	if _player != null and _player.has_method("_update_crosshair_visibility"):
		_player._update_crosshair_visibility()
	closed.emit()


func _show_texture(next_texture: Texture2D) -> void:
	if _folder_material != null and next_texture != null:
		_folder_material.albedo_texture = next_texture


func _activate_tab(texture: Texture2D) -> void:
	if texture != null:
		_show_texture(texture)


func _is_left_click(event: InputEvent) -> bool:
	return event is InputEventMouseButton \
		and event.button_index == MOUSE_BUTTON_LEFT \
		and event.pressed


func _on_tab_1_area_input_event(
	_camera: Camera3D,
	event: InputEvent,
	_event_position: Vector3,
	_normal: Vector3,
	_shape_idx: int
) -> void:
	if _is_left_click(event):
		_activate_tab(tab_1_texture)


func _on_tab_2_area_input_event(
	_camera: Camera3D,
	event: InputEvent,
	_event_position: Vector3,
	_normal: Vector3,
	_shape_idx: int
) -> void:
	if _is_left_click(event):
		_activate_tab(tab_2_texture)


func _on_tab_3_area_input_event(
	_camera: Camera3D,
	event: InputEvent,
	_event_position: Vector3,
	_normal: Vector3,
	_shape_idx: int
) -> void:
	if _is_left_click(event):
		_activate_tab(tab_3_texture)


func _on_return_button_pressed() -> void:
	close_folder()
