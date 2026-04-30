extends Control

const MAGNIFYING_CURSOR := preload("res://assets/magnifying_cursor.png")
const CURSOR_HOTSPOT := Vector2(42, 48)
const CUTSCENE_AUDIO := preload("res://assets/audio/By The Paddy Wagon.mp3")

@export_file("*.ogv") var snake_ending_video_path: String = "res://assets/video/snakeendingOGV.ogv"
@export_file("*.tscn") var ending_reflection_scene_path: String = "res://scene/levels/level3/ending_reflection_scene.tscn"
@export var fade_in_duration: float = 0.45
@export var fade_out_duration: float = 0.45
@export var cutscene_audio_volume_db: float = -8.0
@export var cutscene_audio_start_position_sec: float = 10.0

@onready var _video_player: VideoStreamPlayer = $VideoPlayer
@onready var _fade_rect: ColorRect = $FadeRect

var _video_stream: VideoStream
var _transitioning := false


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Input.set_custom_mouse_cursor(MAGNIFYING_CURSOR, Input.CURSOR_ARROW, CURSOR_HOTSPOT)
	MusicManager.clear_music_stack()
	MusicManager.play_music(CUTSCENE_AUDIO, cutscene_audio_volume_db, cutscene_audio_start_position_sec, true)

	_fade_rect.visible = true
	_fade_rect.color = Color.BLACK
	_video_player.stream = _get_snake_ending_video_stream()
	if _video_player.stream == null:
		await _transition_to_ending_reflection()
		return

	if not _video_player.finished.is_connected(_on_video_finished):
		_video_player.finished.connect(_on_video_finished)

	_video_player.play()
	await _fade_from_black()


func _unhandled_input(event: InputEvent) -> void:
	if _transitioning:
		return

	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		await _transition_to_ending_reflection()


func _on_video_finished() -> void:
	await _transition_to_ending_reflection()


func _transition_to_ending_reflection() -> void:
	if _transitioning:
		return

	_transitioning = true
	await _fade_to_black()

	var error := get_tree().change_scene_to_file(ending_reflection_scene_path)
	if error != OK:
		push_warning("lv3_snake_ending_cinematic_scene.gd: Failed to load ending reflection scene '%s' (error %d)." % [ending_reflection_scene_path, error])
		_transitioning = false
		await _fade_from_black()


func _get_snake_ending_video_stream() -> VideoStream:
	if _video_stream != null:
		return _video_stream

	if snake_ending_video_path.is_empty():
		return null

	if not ResourceLoader.exists(snake_ending_video_path):
		push_warning("lv3_snake_ending_cinematic_scene.gd: Snake ending video '%s' was not found." % snake_ending_video_path)
		return null

	_video_stream = load(snake_ending_video_path) as VideoStream
	if _video_stream == null:
		push_warning("lv3_snake_ending_cinematic_scene.gd: Snake ending video '%s' is not a valid VideoStream resource." % snake_ending_video_path)
		return null

	return _video_stream


func _fade_to_black() -> void:
	_fade_rect.visible = true
	if fade_out_duration <= 0.0:
		_fade_rect.color = Color.BLACK
		return

	var tween := create_tween()
	tween.tween_property(_fade_rect, "color", Color.BLACK, fade_out_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished


func _fade_from_black() -> void:
	_fade_rect.visible = true
	_fade_rect.color = Color.BLACK
	if fade_in_duration <= 0.0:
		_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
		_fade_rect.visible = false
		return

	var tween := create_tween()
	tween.tween_property(_fade_rect, "color", Color(0.0, 0.0, 0.0, 0.0), fade_in_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
	_fade_rect.visible = false
