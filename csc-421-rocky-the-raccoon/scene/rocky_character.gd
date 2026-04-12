@tool
extends Node3D

const ALBEDO_TEXTURE := preload("res://assets/models/textures/tripo_image_fcdea367_0.jpg")
const NORMAL_TEXTURE := preload("res://assets/models/textures/tripo_image_fcdea367_2.jpg")
const ROUGHNESS_TEXTURE := preload("res://assets/models/textures/tripo_image_fcdea367-1096-46b7-9c2b-22299aade409_Roughness.jpg")
const METALLIC_TEXTURE := preload("res://assets/models/textures/tripo_image_fcdea367-1096-46b7-9c2b-22299aade409_Metallic.jpg")

var _apply_textures_enabled := true
var _apply_sitting_pose_enabled := false

@export var apply_textures: bool:
	get:
		return _apply_textures_enabled
	set(value):
		_apply_textures_enabled = value
		_queue_refresh()

@export var apply_sitting_pose: bool:
	get:
		return _apply_sitting_pose_enabled
	set(value):
		_apply_sitting_pose_enabled = value
		_queue_refresh()

var _refresh_queued := false


func _ready() -> void:
	_queue_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_ENTER_TREE:
		_queue_refresh()


func _queue_refresh() -> void:
	if not is_inside_tree() or _refresh_queued:
		return
	_refresh_queued = true
	call_deferred("_refresh_model")


func _refresh_model() -> void:
	_refresh_queued = false
	var model_root := get_node_or_null("RockyModel")
	if model_root == null:
		return

	if _apply_textures_enabled:
		var material := _build_material()
		_apply_material_recursive(model_root, material)

	if _apply_sitting_pose_enabled:
		_stop_animation_players(model_root)
		var skeleton: Skeleton3D = _find_first_skeleton(model_root)
		if skeleton != null:
			_apply_sitting_pose_to_skeleton(skeleton)


func _build_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.resource_local_to_scene = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_texture = ALBEDO_TEXTURE
	material.normal_enabled = true
	material.normal_texture = NORMAL_TEXTURE
	material.roughness = 1.0
	material.roughness_texture = ROUGHNESS_TEXTURE
	material.metallic = 1.0
	material.metallic_texture = METALLIC_TEXTURE
	return material


func _apply_material_recursive(node: Node, material: StandardMaterial3D) -> void:
	if node is MeshInstance3D:
		node.material_override = material

	for child in node.get_children():
		_apply_material_recursive(child, material)


func _stop_animation_players(node: Node) -> void:
	if node is AnimationPlayer:
		node.stop()

	for child in node.get_children():
		_stop_animation_players(child)


func _find_first_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D

	for child in node.get_children():
		var skeleton: Skeleton3D = _find_first_skeleton(child)
		if skeleton != null:
			return skeleton

	return null


func _apply_sitting_pose_to_skeleton(skeleton: Skeleton3D) -> void:
	# This gives Rocky a usable office-chair starting pose that can still be tweaked by hand.
	_set_bone_rotation_degrees(skeleton, "hips", Vector3(12.0, 0.0, 0.0))
	_set_bone_rotation_degrees(skeleton, "spine", Vector3(-10.0, 0.0, 0.0))
	_set_bone_rotation_degrees(skeleton, "spine1", Vector3(-8.0, 0.0, 0.0))
	_set_bone_rotation_degrees(skeleton, "spine2", Vector3(-4.0, 0.0, 0.0))
	_set_bone_rotation_degrees(skeleton, "neck", Vector3(8.0, 0.0, 0.0))
	_set_bone_rotation_degrees(skeleton, "head", Vector3(-6.0, 0.0, 0.0))

	_set_bone_rotation_degrees(skeleton, "left_up_leg", Vector3(-88.0, 0.0, -6.0))
	_set_bone_rotation_degrees(skeleton, "right_up_leg", Vector3(-88.0, 0.0, 6.0))
	_set_bone_rotation_degrees(skeleton, "left_leg", Vector3(110.0, 0.0, 0.0))
	_set_bone_rotation_degrees(skeleton, "right_leg", Vector3(110.0, 0.0, 0.0))
	_set_bone_rotation_degrees(skeleton, "left_foot", Vector3(-18.0, 0.0, 0.0))
	_set_bone_rotation_degrees(skeleton, "right_foot", Vector3(-18.0, 0.0, 0.0))

	_set_bone_rotation_degrees(skeleton, "left_shoulder", Vector3(0.0, 0.0, -12.0))
	_set_bone_rotation_degrees(skeleton, "right_shoulder", Vector3(0.0, 0.0, 12.0))
	_set_bone_rotation_degrees(skeleton, "left_arm", Vector3(16.0, 0.0, -28.0))
	_set_bone_rotation_degrees(skeleton, "right_arm", Vector3(16.0, 0.0, 28.0))
	_set_bone_rotation_degrees(skeleton, "left_forearm", Vector3(24.0, 0.0, -12.0))
	_set_bone_rotation_degrees(skeleton, "right_forearm", Vector3(24.0, 0.0, 12.0))
	_set_bone_rotation_degrees(skeleton, "left_hand", Vector3(8.0, 0.0, 0.0))
	_set_bone_rotation_degrees(skeleton, "right_hand", Vector3(8.0, 0.0, 0.0))


func _set_bone_rotation_degrees(skeleton: Skeleton3D, bone_key: String, degrees: Vector3) -> void:
	var bone_idx := _find_bone_index(skeleton, bone_key)
	if bone_idx == -1:
		return

	var radians := Vector3(
		deg_to_rad(degrees.x),
		deg_to_rad(degrees.y),
		deg_to_rad(degrees.z)
	)
	var rotation := Basis.from_euler(radians).get_rotation_quaternion()
	skeleton.set_bone_pose_rotation(bone_idx, rotation)


func _bone_aliases_for(bone_key: String) -> Array[String]:
	match bone_key:
		"hips":
			return ["mixamorig_Hips", "mixamorig:Hips", "Hips"]
		"spine":
			return ["mixamorig_Spine", "mixamorig:Spine", "Spine"]
		"spine1":
			return ["mixamorig_Spine1", "mixamorig:Spine1", "Spine1"]
		"spine2":
			return ["mixamorig_Spine2", "mixamorig:Spine2", "Spine2"]
		"neck":
			return ["mixamorig_Neck", "mixamorig:Neck", "Neck"]
		"head":
			return ["mixamorig_Head", "mixamorig:Head", "Head"]
		"left_shoulder":
			return ["mixamorig_LeftShoulder", "mixamorig:LeftShoulder", "LeftShoulder"]
		"right_shoulder":
			return ["mixamorig_RightShoulder", "mixamorig:RightShoulder", "RightShoulder"]
		"left_arm":
			return ["mixamorig_LeftArm", "mixamorig:LeftArm", "LeftArm"]
		"right_arm":
			return ["mixamorig_RightArm", "mixamorig:RightArm", "RightArm"]
		"left_forearm":
			return ["mixamorig_LeftForeArm", "mixamorig:LeftForeArm", "LeftForeArm"]
		"right_forearm":
			return ["mixamorig_RightForeArm", "mixamorig:RightForeArm", "RightForeArm"]
		"left_hand":
			return ["mixamorig_LeftHand", "mixamorig:LeftHand", "LeftHand"]
		"right_hand":
			return ["mixamorig_RightHand", "mixamorig:RightHand", "RightHand"]
		"left_up_leg":
			return ["mixamorig_LeftUpLeg", "mixamorig:LeftUpLeg", "LeftUpLeg"]
		"right_up_leg":
			return ["mixamorig_RightUpLeg", "mixamorig:RightUpLeg", "RightUpLeg"]
		"left_leg":
			return ["mixamorig_LeftLeg", "mixamorig:LeftLeg", "LeftLeg"]
		"right_leg":
			return ["mixamorig_RightLeg", "mixamorig:RightLeg", "RightLeg"]
		"left_foot":
			return ["mixamorig_LeftFoot", "mixamorig:LeftFoot", "LeftFoot"]
		"right_foot":
			return ["mixamorig_RightFoot", "mixamorig:RightFoot", "RightFoot"]
		_:
			return []


func _find_bone_index(skeleton: Skeleton3D, bone_key: String) -> int:
	var aliases: Array[String] = _bone_aliases_for(bone_key)
	if aliases.is_empty():
		return -1

	for bone_name in aliases:
		var idx := skeleton.find_bone(bone_name)
		if idx != -1:
			return idx

	return -1
