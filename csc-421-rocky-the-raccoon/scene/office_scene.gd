extends Node

@onready var _main: Node = $Main


func _enter_tree() -> void:
	SceneTransitionState.ensure_office_entry(true)


func _ready() -> void:
	await get_tree().process_frame
	_force_interior_camera()


func _force_interior_camera() -> void:
	var exterior_player := _main.get_node_or_null("ExteriorPlayer")
	var interior_player := _main.get_node_or_null("InteriorPlayer")

	if exterior_player != null and exterior_player.has_method("set_player_enabled"):
		exterior_player.set_player_enabled(false)

	if interior_player != null and interior_player.has_method("set_player_enabled"):
		interior_player.set_player_enabled(true)

	var pivot := interior_player.get_node_or_null("PitchPivot") if interior_player != null else null
	if pivot == null:
		return

	for child in pivot.get_children():
		if child is Camera3D:
			(child as Camera3D).make_current()
			return
