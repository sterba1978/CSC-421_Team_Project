extends Node3D

const MAGNIFYING_CURSOR := preload("res://assets/magnifying_cursor.png")
const CURSOR_HOTSPOT := Vector2(42, 48)
const EXTERIOR_BACKGROUND_MUSIC := preload("res://assets/audio/Speaking Out - Ambient Tension Vol 1 FINAL MIX.wav")
const OFFICE_BACKGROUND_MUSIC := preload("res://assets/audio/Race Against Fate - Ambient Tension Vol 1 FINAL MIX.wav")
const JOURNAL_UI_SCENE := preload("res://scene/journal_ui.tscn")
const JOURNAL_CASE_TITLE := "Carla's Email Case"
const JOURNAL_CASE_SUMMARY := "Carla's bank account was emptied after she checked her email. Compare each message for phishing warning signs before you talk to Carla."
const JOURNAL_QUESTIONS := [
	"Which email caused Carla's bank problem?",
	"What phishing warning signs prove that email is unsafe?",
	"What should Carla do next time before trusting a money or bank message?"
]
const JOURNAL_PLACEHOLDERS := [
	"Example: Email 1: Rajah",
	"Example: strange sender, urgent money request, unsafe link...",
	"Example: verify the sender, do not share bank info, avoid suspicious links..."
]

@export var exterior_player_path: NodePath = ^"ExteriorPlayer"
@export var interior_player_path: NodePath = ^"InteriorPlayer"
@export var building_door_path: NodePath = ^"Building_door"
@export var office_door_path: NodePath = ^"Office_door"
@export var interior_transition_delay_sec: float = 0.4
@export_file("*.tscn") var door_cinematic_scene_path: String = "res://scene/levels/level1/lv1_door_cinematic_scene.tscn"
@export_file("*.tscn") var level_complete_cinematic_scene_path: String = "res://scene/levels/level1/lv1_complete_cinematic_scene.tscn"
@export var scene_transition_fade_duration: float = 0.4
@export var look_mouse_sensitivity: float = 0.0015
@export var exterior_sign_light_path: NodePath = ^"Environment/Exterior/StreetLamp/SignLight/SpotLight3D"
@export var exterior_door_light_path: NodePath = ^"Environment/Exterior/StreetLamp/MeshInstance3D/SpotLight3D"
@export var sign_light_on_energy: float = 15.0
@export var door_light_on_energy: float = 48.0
@export var door_light_dim_energy: float = 6.0
@export var door_light_flicker_speed: float = 4.0
@export var background_music_volume_db: float = -8.0
@export var background_music_start_position_sec: float = 0.0

@onready var _exterior_player: Node = get_node_or_null(exterior_player_path)
@onready var _interior_player: Node = get_node_or_null(interior_player_path)
@onready var _building_door: Node = get_node_or_null(building_door_path)
@onready var _office_door: Node = get_node_or_null(office_door_path)
@onready var _sign_light_spot: SpotLight3D = get_node_or_null(exterior_sign_light_path)
@onready var _door_light_spot: SpotLight3D = get_node_or_null(exterior_door_light_path)

var _transition_queued: bool = false
var _active_player: Node
var _journal_ui
var _time := 0.0
var _scene_fade_layer: CanvasLayer
var _scene_fade_rect: ColorRect

## Canvas UI's
@onready var clueboardUI = $ClueBoardUI
@onready var clueUI1 = $clue_ui
@onready var clueUI2 = $clue_ui2
@onready var clueUI3 = $clue_ui3
@onready var tab1UI = $tab1
@onready var tab2UI = $tab2
@onready var tab3UI = $tab3
@onready var folder = $folder


#Dialogue
@export var dialogue_resource : DialogueResource
@onready var dialogue_manager = $DialogueManager
var journalopened = 0

func _ready() -> void:
	_apply_custom_cursor()
	_ensure_scene_fader()

	var start_in_office := SceneTransitionState.consume_start_in_office()
	var fade_in_from_black := SceneTransitionState.consume_fade_in_from_black()
	var background_music: AudioStream = OFFICE_BACKGROUND_MUSIC if start_in_office else EXTERIOR_BACKGROUND_MUSIC
	MusicManager.play_music(background_music, background_music_volume_db, background_music_start_position_sec)
	if fade_in_from_black:
		_set_scene_fade_alpha(1.0)

	if _building_door != null and _building_door.has_signal("door_opened"):
		_building_door.door_opened.connect(_on_building_door_opened)
	elif _building_door != null and _building_door.has_signal("door_state_changed"):
		# Fallback for older door scripts: switches immediately when state becomes open.
		_building_door.door_state_changed.connect(_on_building_door_state_changed)
	else:
		push_warning("main_flow.gd: Building_door missing or has no door_opened/door_state_changed signal.")
	_set_office_door_interaction_enabled(false)

	if not Autoload.level1_ended.is_connected(_on_level1_ended):
		Autoload.level1_ended.connect(_on_level1_ended)

	_set_active_player(_interior_player)
	#if start_in_office:
	#	_set_active_player(_interior_player)
	#else:
	#	_set_active_player(_exterior_player)

	_apply_mouse_sensitivity()
	_apply_sign_light_state()
	
	## Hiding UI's
	clueboardUI.hide()
	clueUI1.hide()
	clueUI2.hide()
	clueUI3.hide()
	tab1UI.hide()
	tab2UI.hide()
	tab3UI.hide()
	folder.hide()
	
	

	_ensure_journal_ui()
	_update_journal_shortcut_state()

	if clueboardUI != null and clueboardUI.has_signal("clue_selected"):
		clueboardUI.clue_selected.connect(_on_clue_selected)

	if fade_in_from_black:
		await get_tree().process_frame
		await _fade_from_black(scene_transition_fade_duration)


func _process(delta: float) -> void:
	_time += delta
	_apply_door_light_flicker()
	_update_journal_shortcut_state()


func _unhandled_input(event: InputEvent) -> void:
	if _journal_ui == null or _journal_ui.is_open():
		return

	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_SPACE and _can_open_journal():
			_journal_ui.open_journal()
			get_viewport().set_input_as_handled()


func _on_building_door_opened() -> void:
	if _transition_queued:
		return
	_transition_queued = true
	await _transition_to_cinematic_scene()
	_transition_queued = false


func _on_building_door_state_changed(is_open: bool) -> void:
	if not is_open or _transition_queued:
		return

	_transition_queued = true
	await _transition_to_cinematic_scene()
	_transition_queued = false


func _on_level1_ended() -> void:
	if _transition_queued:
		return

	_transition_queued = true
	_grade_journal_answers()
	await _transition_to_level_complete_cinematic_scene()
	_transition_queued = false


func _set_active_player(active: Node) -> void:
	_active_player = active
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


func _apply_mouse_sensitivity() -> void:
	for player in [_exterior_player, _interior_player]:
		if player == null:
			continue
		if _has_property(player, "mouse_sensitivity"):
			player.mouse_sensitivity = look_mouse_sensitivity


func _transition_to_cinematic_scene() -> void:
	if interior_transition_delay_sec > 0.0:
		await get_tree().create_timer(interior_transition_delay_sec).timeout

	_set_player_enabled(_exterior_player, false)
	_set_player_enabled(_interior_player, false)
	await _fade_to_black(scene_transition_fade_duration)

	var error := get_tree().change_scene_to_file(door_cinematic_scene_path)
	if error != OK:
		push_warning("main_flow.gd: Failed to load cinematic scene '%s' (error %d)." % [door_cinematic_scene_path, error])
		await _fade_from_black(scene_transition_fade_duration)
		_set_active_player(_exterior_player)


func _transition_to_level_complete_cinematic_scene() -> void:
	_set_player_enabled(_exterior_player, false)
	_set_player_enabled(_interior_player, false)
	if _journal_ui != null and _journal_ui.is_open():
		_journal_ui.close_journal()
	await _fade_to_black(scene_transition_fade_duration)

	var error := get_tree().change_scene_to_file(level_complete_cinematic_scene_path)
	if error != OK:
		push_warning("main_flow.gd: Failed to load level complete cinematic scene '%s' (error %d)." % [level_complete_cinematic_scene_path, error])
		await _fade_from_black(scene_transition_fade_duration)
		_set_active_player(_interior_player)


func _ensure_scene_fader() -> void:
	if _scene_fade_layer != null:
		return

	_scene_fade_layer = CanvasLayer.new()
	_scene_fade_layer.name = "SceneFadeLayer"
	_scene_fade_layer.layer = 200
	add_child(_scene_fade_layer)

	_scene_fade_rect = ColorRect.new()
	_scene_fade_rect.name = "SceneFadeRect"
	_scene_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scene_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scene_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	_scene_fade_layer.add_child(_scene_fade_rect)


func _set_scene_fade_alpha(alpha: float) -> void:
	if _scene_fade_rect == null:
		return

	_scene_fade_rect.color = Color(0.0, 0.0, 0.0, clamp(alpha, 0.0, 1.0))
	_scene_fade_rect.visible = alpha > 0.001


func _fade_to_black(duration: float) -> void:
	if _scene_fade_rect == null:
		return

	_scene_fade_rect.visible = true
	if duration <= 0.0:
		_set_scene_fade_alpha(1.0)
		return

	var tween := create_tween()
	tween.tween_property(_scene_fade_rect, "color", Color.BLACK, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished


func _fade_from_black(duration: float) -> void:
	if _scene_fade_rect == null:
		return

	_scene_fade_rect.visible = true
	_scene_fade_rect.color = Color.BLACK
	if duration <= 0.0:
		_set_scene_fade_alpha(0.0)
		return

	var tween := create_tween()
	tween.tween_property(_scene_fade_rect, "color", Color(0.0, 0.0, 0.0, 0.0), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
	_scene_fade_rect.visible = false


func _ensure_journal_ui() -> void:
	if _journal_ui != null:
		return

	_journal_ui = JOURNAL_UI_SCENE.instantiate()
	_journal_ui.configure_case(JOURNAL_CASE_TITLE, JOURNAL_CASE_SUMMARY, PackedStringArray(JOURNAL_QUESTIONS), PackedStringArray(JOURNAL_PLACEHOLDERS))
	add_child(_journal_ui)
	_journal_ui.journal_opened.connect(_on_journal_opened)
	_journal_ui.journal_closed.connect(_on_journal_closed)


func _on_clue_selected(clue_id: String, clue_title: String, clue_text: String) -> void:
	if _journal_ui != null:
		_journal_ui.add_clue(clue_id, clue_title, clue_text)


func _on_journal_opened() -> void:
	if _active_player != null:
		_set_player_enabled(_active_player, false)
	
	journalopened += 1
	if dialogue_manager != null and dialogue_manager.has_method("on_journal_opened_for_case"):
		dialogue_manager.on_journal_opened_for_case()


func _on_journal_closed() -> void:
	if _active_player != null:
		_set_player_enabled(_active_player, true)


func _grade_journal_answers() -> void:
	if _journal_ui != null and _journal_ui.has_method("get_question_answers"):
		Autoload.grade_case_journal(1, _journal_ui.get_question_answers())


func _can_open_journal() -> bool:
	if _transition_queued or _journal_ui == null:
		return false

	return not _has_blocking_ui_open()


func _has_blocking_ui_open() -> bool:
	for ui in [clueboardUI, clueUI1, clueUI2, clueUI3, tab1UI, tab2UI, tab3UI, folder]:
		if ui != null and ui.visible:
			return true
	return false


func _update_journal_shortcut_state() -> void:
	if _journal_ui != null:
		_journal_ui.set_shortcut_enabled(not _has_blocking_ui_open())


func _has_property(node: Object, property_name: String) -> bool:
	for prop in node.get_property_list():
		if prop.get("name", "") == property_name:
			return true
	return false


func _apply_custom_cursor() -> void:
	Input.set_custom_mouse_cursor(MAGNIFYING_CURSOR, Input.CURSOR_ARROW, CURSOR_HOTSPOT)


func _apply_sign_light_state() -> void:
	if _sign_light_spot != null:
		_sign_light_spot.light_energy = sign_light_on_energy


func _apply_door_light_flicker() -> void:
	var flicker_pattern := 0.92
	flicker_pattern += sin(_time * door_light_flicker_speed) * 0.06
	flicker_pattern += sin((_time * door_light_flicker_speed * 1.73) + 0.8) * 0.04

	var short_dip := pow(max(0.0, sin((_time * door_light_flicker_speed * 2.2) + 0.35)), 18.0) * 0.75
	var deep_dip := pow(max(0.0, sin((_time * door_light_flicker_speed * 0.9) + 1.4)), 30.0) * 0.9
	flicker_pattern -= short_dip
	flicker_pattern -= deep_dip
	flicker_pattern = clamp(flicker_pattern, 0.0, 1.0)

	if _door_light_spot != null:
		_door_light_spot.light_energy = lerp(door_light_dim_energy, door_light_on_energy, flicker_pattern)


func _set_office_door_interaction_enabled(enabled: bool) -> void:
	if _office_door == null:
		return
	if _office_door.has_method("set_interaction_enabled"):
		_office_door.set_interaction_enabled(enabled)
	else:
		if enabled:
			_office_door.add_to_group("interactable")
		else:
			_office_door.remove_from_group("interactable")
