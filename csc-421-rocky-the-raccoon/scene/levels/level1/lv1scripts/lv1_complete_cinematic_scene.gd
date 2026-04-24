extends Control

const MAGNIFYING_CURSOR := preload("res://assets/magnifying_cursor.png")
const CURSOR_HOTSPOT := Vector2(42, 48)
const FALLBACK_LEVEL_2_SCENE := preload("res://scene/levels/level2/mainlv2.tscn")
const CUTSCENE_AUDIO := preload("res://assets/audio/By The Paddy Wagon.mp3")
const KNOCK_SFX := preload("res://assets/audio/freesound_community-knocking-on-door-6022.mp3")

@export_file("*.tscn") var next_level_scene_path: String = "res://scene/levels/level2/mainlv2.tscn"
@export_file("*.ogv") var next_client_video_path: String = "res://assets/video/patty.ogv"
@export var fade_in_duration: float = 0.55
@export var panel_reveal_duration: float = 0.6
@export var background_pan_duration: float = 2.6
@export var button_reveal_duration: float = 0.28
@export var fade_out_duration: float = 0.45
@export var cutscene_audio_volume_db: float = -8.0
@export var cutscene_audio_start_position_sec: float = 7.5
@export var knock_sfx_volume_db: float = -4.0
@export var knock_start_delay_sec: float = 1.4

@onready var _background: TextureRect = $Background
@onready var _fade_rect: ColorRect = $FadeRect
@onready var _panel: PanelContainer = $Layout/Center/Panel
@onready var _rocky_card: TextureRect = $Layout/Center/Panel/Margin/HBox/RockyCard
@onready var _continue_button: Button = $Layout/Center/Panel/Margin/HBox/Content/ContinueButton

var _background_base_position := Vector2.ZERO
var _can_continue := false
var _is_transitioning := false
var _client_video_backdrop: ColorRect
var _client_video_player: VideoStreamPlayer
var _client_video_stream: VideoStream
var _knock_player: AudioStreamPlayer
var _knock_cancelled := false


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Input.set_custom_mouse_cursor(MAGNIFYING_CURSOR, Input.CURSOR_ARROW, CURSOR_HOTSPOT)
	MusicManager.clear_music_stack()
	MusicManager.play_music(CUTSCENE_AUDIO, cutscene_audio_volume_db, cutscene_audio_start_position_sec, true)

	_background_base_position = _background.position

	_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_rocky_card.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_background.scale = Vector2(1.08, 1.08)
	_background.position = _background_base_position - Vector2(34.0, 18.0)
	_fade_rect.color = Color.BLACK
	_fade_rect.visible = true
	_continue_button.visible = false
	_continue_button.disabled = true
	_continue_button.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_apply_framed_button_style(_continue_button)

	if not _continue_button.pressed.is_connected(_on_continue_button_pressed):
		_continue_button.pressed.connect(_on_continue_button_pressed)

	_ensure_knock_player()
	_ensure_client_video_overlay()
	_schedule_knock_sfx()
	await _play_cinematic_intro()


func _play_cinematic_intro() -> void:
	var background_tween := create_tween()
	background_tween.set_parallel(true)
	background_tween.tween_property(_fade_rect, "color", Color(0.0, 0.0, 0.0, 0.0), fade_in_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	background_tween.tween_property(_background, "scale", Vector2.ONE, background_pan_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	background_tween.tween_property(_background, "position", _background_base_position, background_pan_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(0.18).timeout

	var panel_tween := create_tween()
	panel_tween.set_parallel(true)
	panel_tween.tween_property(_panel, "modulate", Color.WHITE, panel_reveal_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	panel_tween.tween_property(_rocky_card, "modulate", Color.WHITE, panel_reveal_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await panel_tween.finished

	_continue_button.visible = true
	var button_tween := create_tween()
	button_tween.tween_property(_continue_button, "modulate", Color.WHITE, button_reveal_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await button_tween.finished

	_can_continue = true
	_continue_button.disabled = false
	_continue_button.grab_focus()
	_fade_rect.visible = false


func _on_continue_button_pressed() -> void:
	if not _can_continue or _is_transitioning:
		return

	_transition_to_next_level_now()


func _apply_framed_button_style(button: Button) -> void:
	var normal := _make_button_style(Color(0.05, 0.045, 0.035, 0.9), Color(0.78, 0.72, 0.56, 0.95))
	var hover := _make_button_style(Color(0.1, 0.085, 0.045, 0.95), Color(1.0, 0.88, 0.42, 1.0))
	var pressed := _make_button_style(Color(0.02, 0.018, 0.012, 1.0), Color(1.0, 0.78, 0.25, 1.0))
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", normal)


func _make_button_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(3)
	style.set_corner_radius_all(4)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style


func _unhandled_input(event: InputEvent) -> void:
	if not _can_continue or _is_transitioning:
		return

	if event.is_action_pressed("ui_accept"):
		_transition_to_next_level_now()


func _transition_to_next_level_now() -> void:
	if not _can_continue or _is_transitioning or _continue_button.disabled:
		return

	_is_transitioning = true
	_can_continue = false
	_continue_button.disabled = true
	_stop_knock_sfx()
	_fade_rect.visible = true
	_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)

	if fade_out_duration > 0.0:
		var fade_tween := create_tween()
		fade_tween.tween_property(_fade_rect, "color", Color.BLACK, fade_out_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await fade_tween.finished
	else:
		_fade_rect.color = Color.BLACK

	await _play_next_client_intro()
	await _fade_to_black()
	await _load_next_level()


func _ensure_knock_player() -> void:
	if _knock_player != null:
		return

	_knock_player = AudioStreamPlayer.new()
	_knock_player.name = "KnockPlayer"
	_knock_player.bus = &"Master"
	_knock_player.stream = KNOCK_SFX
	_knock_player.volume_db = knock_sfx_volume_db
	add_child(_knock_player)


func _schedule_knock_sfx() -> void:
	if knock_start_delay_sec <= 0.0:
		_play_knock_sfx()
		return

	get_tree().create_timer(knock_start_delay_sec).timeout.connect(_play_knock_sfx, CONNECT_ONE_SHOT)


func _play_knock_sfx() -> void:
	if _knock_cancelled or _is_transitioning or _knock_player == null:
		return

	_knock_player.volume_db = knock_sfx_volume_db
	_knock_player.play()


func _stop_knock_sfx() -> void:
	_knock_cancelled = true
	if _knock_player != null:
		_knock_player.stop()


func _ensure_client_video_overlay() -> void:
	if _client_video_player != null:
		return

	_client_video_backdrop = ColorRect.new()
	_client_video_backdrop.name = "ClientVideoBackdrop"
	_client_video_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_client_video_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_client_video_backdrop.color = Color.BLACK
	_client_video_backdrop.visible = false
	add_child(_client_video_backdrop)

	_client_video_player = VideoStreamPlayer.new()
	_client_video_player.name = "ClientVideoPlayer"
	_client_video_player.set_anchors_preset(Control.PRESET_FULL_RECT)
	_client_video_player.mouse_filter = Control.MOUSE_FILTER_STOP
	_client_video_player.expand = true
	_client_video_player.visible = false
	add_child(_client_video_player)
	move_child(_fade_rect, get_child_count() - 1)


func _play_next_client_intro() -> void:
	var stream := _get_next_client_video_stream()
	if stream == null or _client_video_player == null or _client_video_backdrop == null:
		return

	MusicManager.stop_music()
	_client_video_backdrop.visible = true
	_client_video_player.stream = stream
	_client_video_player.visible = true
	_client_video_player.play()
	await _fade_from_black()
	await _client_video_player.finished


func _get_next_client_video_stream() -> VideoStream:
	if _client_video_stream != null:
		return _client_video_stream

	if next_client_video_path.is_empty():
		return null

	if not ResourceLoader.exists(next_client_video_path):
		push_warning("lv1_complete_cinematic_scene.gd: Next client video '%s' was not found." % next_client_video_path)
		return null

	_client_video_stream = load(next_client_video_path) as VideoStream
	if _client_video_stream == null:
		push_warning("lv1_complete_cinematic_scene.gd: Next client video '%s' is not a valid VideoStream resource." % next_client_video_path)
		return null

	return _client_video_stream


func _fade_to_black() -> void:
	_fade_rect.visible = true
	if fade_out_duration <= 0.0:
		_fade_rect.color = Color.BLACK
		return

	var fade_tween := create_tween()
	fade_tween.tween_property(_fade_rect, "color", Color.BLACK, fade_out_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await fade_tween.finished


func _fade_from_black() -> void:
	_fade_rect.visible = true
	_fade_rect.color = Color.BLACK
	if fade_in_duration <= 0.0:
		_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
		_fade_rect.visible = false
		return

	var fade_tween := create_tween()
	fade_tween.tween_property(_fade_rect, "color", Color(0.0, 0.0, 0.0, 0.0), fade_in_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await fade_tween.finished
	_fade_rect.visible = false


func _load_next_level() -> void:
	SceneTransitionState.request_office_entry(true)
	var error := get_tree().change_scene_to_file(next_level_scene_path)
	if error != OK:
		error = get_tree().change_scene_to_packed(FALLBACK_LEVEL_2_SCENE)

	if error != OK:
		SceneTransitionState.reset()
		push_warning("lv1_complete_cinematic_scene.gd: Failed to load next level scene '%s' (error %d)." % [next_level_scene_path, error])
		if fade_out_duration > 0.0:
			var recover_tween := create_tween()
			recover_tween.tween_property(_fade_rect, "color", Color(0.0, 0.0, 0.0, 0.0), fade_out_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			await recover_tween.finished
		else:
			_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
		_fade_rect.visible = false
		_can_continue = true
		_is_transitioning = false
		_continue_button.disabled = false
		_continue_button.grab_focus()
