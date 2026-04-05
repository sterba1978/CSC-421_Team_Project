extends Node3D

const MAGNIFYING_CURSOR := preload("res://assets/magnifying_cursor.png")
const CURSOR_HOTSPOT := Vector2(42, 48)
const EXTERIOR_BACKGROUND_MUSIC := preload("res://assets/audio/Speaking Out - Ambient Tension Vol 1 FINAL MIX.wav")
const OFFICE_BACKGROUND_MUSIC := preload("res://assets/audio/Race Against Fate - Ambient Tension Vol 1 FINAL MIX.wav")

@export var exterior_player_path: NodePath = ^"ExteriorPlayer"
@export var interior_player_path: NodePath = ^"InteriorPlayer"
@export var building_door_path: NodePath = ^"Building_door"
@export var interior_transition_delay_sec: float = 0.4
@export_file("*.tscn") var door_cinematic_scene_path: String = "res://scene/door_cinematic_scene.tscn"
@export var scene_transition_fade_duration: float = 0.4
@export var look_mouse_sensitivity: float = 0.0015
@export var journal_title: String = "Journal"
@export var journal_default_text: String = "No item selected yet."
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
@onready var _sign_light_spot: SpotLight3D = get_node_or_null(exterior_sign_light_path)
@onready var _door_light_spot: SpotLight3D = get_node_or_null(exterior_door_light_path)

var _transition_queued: bool = false
var _journal_entry_label: Label
var _time := 0.0
var _scene_fade_layer: CanvasLayer
var _scene_fade_rect: ColorRect

## Canvas UI's
@onready var clueboardUI = $ClueBoardUI
@onready var clueUI = $Clue_UI
@onready var tab1UI = $tab1
@onready var tab2UI = $tab2
@onready var tab3UI = $tab3
@onready var folder = $folder


#Dialogue
@export var dialogue_resource : DialogueResource
@export var dialogue_start : String = "start"

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

	if start_in_office:
		_set_active_player(_interior_player)
	else:
		_set_active_player(_exterior_player)

	_apply_mouse_sensitivity()
	_apply_sign_light_state()
	
	## Hiding UI's
	clueboardUI.hide()
	clueUI.hide()
	tab1UI.hide()
	tab2UI.hide()
	tab3UI.hide()
	folder.hide()

	_ensure_journal_ui()
	_set_journal_entry(journal_default_text)

	if clueboardUI != null and clueboardUI.has_signal("clue_selected"):
		clueboardUI.clue_selected.connect(_on_clue_selected)

	if not start_in_office:
		# DialogueStart
		DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_start)

	if fade_in_from_black:
		await get_tree().process_frame
		await _fade_from_black(scene_transition_fade_duration)


func _process(delta: float) -> void:
	_time += delta
	_apply_door_light_flicker()


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
	var layer := CanvasLayer.new()
	layer.name = "JournalHUD"
	add_child(layer)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	var panel := PanelContainer.new()
	panel.name = "JournalPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.anchor_left = 1.0
	panel.anchor_top = 0.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 0.0
	panel.offset_left = -260.0
	panel.offset_top = 16.0
	panel.offset_right = -16.0
	panel.offset_bottom = 112.0
	root.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(content)

	var title := Label.new()
	title.text = journal_title
	title.add_theme_font_size_override("font_size", 20)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(title)

	_journal_entry_label = Label.new()
	_journal_entry_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_journal_entry_label.add_theme_font_size_override("font_size", 14)
	_journal_entry_label.custom_minimum_size = Vector2(220.0, 0.0)
	_journal_entry_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(_journal_entry_label)


func _set_journal_entry(entry_text: String) -> void:
	if _journal_entry_label != null:
		_journal_entry_label.text = entry_text


func _on_clue_selected(clue_text: String) -> void:
	_set_journal_entry(clue_text)


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
