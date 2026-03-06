extends Node3D

@export var exterior_player_path: NodePath = ^"ExteriorPlayer"
@export var interior_player_path: NodePath = ^"InteriorPlayer"
@export var building_door_path: NodePath = ^"Building_door"
@export var interior_transition_delay_sec: float = 0.4

@onready var _exterior_player: Node = get_node_or_null(exterior_player_path)
@onready var _interior_player: Node = get_node_or_null(interior_player_path)
@onready var _building_door: Node = get_node_or_null(building_door_path)

var _transition_queued: bool = false


func _ready() -> void:
	if _building_door != null and _building_door.has_signal("door_opened"):
		_building_door.door_opened.connect(_on_building_door_opened)
	elif _building_door != null and _building_door.has_signal("door_state_changed"):
		# Fallback for older door scripts: switches immediately when state becomes open.
		_building_door.door_state_changed.connect(_on_building_door_state_changed)
	else:
		push_warning("main_flow.gd: Building_door missing or has no door_opened/door_state_changed signal.")

	_set_active_player(_exterior_player)


func _on_building_door_opened() -> void:
	if _transition_queued:
		return
	_transition_queued = true
	if interior_transition_delay_sec > 0.0:
		await get_tree().create_timer(interior_transition_delay_sec).timeout
	_set_active_player(_interior_player)
	_transition_queued = false


func _on_building_door_state_changed(is_open: bool) -> void:
	if is_open:
		_set_active_player(_interior_player)


func _set_active_player(active: Node) -> void:
	_set_player_enabled(_exterior_player, false)
	_set_player_enabled(_interior_player, false)
	_set_player_enabled(active, true)

	var active_camera := _get_player_camera(active)
	if active_camera != null:
		active_camera.make_current()


func _set_player_enabled(player: Node, enabled: bool) -> void:
	if player == null:
		return

	if player.has_method("set_player_enabled"):
		player.set_player_enabled(enabled)
	else:
		player.set_process_unhandled_input(enabled)


func _get_player_camera(player: Node) -> Camera3D:
	if player == null:
		return null

	if player.has_method("get_camera"):
		return player.get_camera() as Camera3D

	var pivot := player.get_node_or_null("PitchPivot")
	if pivot == null:
		return null

	for child in pivot.get_children():
		if child is Camera3D:
			return child as Camera3D

	return null
