extends Control

const MAGNIFYING_CURSOR := preload("res://assets/magnifying_cursor.png")
const CURSOR_HOTSPOT := Vector2(42, 48)
const FALLBACK_OFFICE_SCENE := preload("res://scene/levels/level1/mainlv1.tscn")
const CUTSCENE_AUDIO := preload("res://assets/audio/By The Paddy Wagon.mp3")

@export_file("*.tscn") var office_scene_path: String = "res://scene/levels/level1/lv1main.tscn"
@export var fade_in_duration: float = 0.55
@export var panel_reveal_duration: float = 0.6
@export var background_pan_duration: float = 2.6
@export var button_reveal_duration: float = 0.28
@export var fade_out_duration: float = 0.45
@export var cutscene_audio_volume_db: float = -8.0
@export var cutscene_audio_start_position_sec: float = 7.5

@onready var _background: TextureRect = $Background
@onready var _fade_rect: ColorRect = $FadeRect
@onready var _panel: PanelContainer = $Layout/Center/Panel
@onready var _rocky_card: TextureRect = $Layout/Center/Panel/Margin/HBox/RockyCard
@onready var _continue_button: Button = $Layout/Center/Panel/Margin/HBox/Content/ContinueButton

var _background_base_position := Vector2.ZERO
var _can_continue := false
var _is_transitioning := false


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

	_transition_to_office_now()


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
		_transition_to_office_now()


func _transition_to_office_now() -> void:
	if not _can_continue or _is_transitioning or _continue_button.disabled:
		return

	_is_transitioning = true
	_can_continue = false
	_continue_button.disabled = true
	_fade_rect.visible = true
	_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)

	if fade_out_duration > 0.0:
		var fade_tween := create_tween()
		fade_tween.tween_property(_fade_rect, "color", Color.BLACK, fade_out_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await fade_tween.finished
	else:
		_fade_rect.color = Color.BLACK

	SceneTransitionState.request_office_entry(true)
	var error := get_tree().change_scene_to_file(office_scene_path)
	if error != OK:
		error = get_tree().change_scene_to_packed(FALLBACK_OFFICE_SCENE)

	if error != OK:
		SceneTransitionState.reset()
		push_warning("door_cinematic_scene.gd: Failed to load office scene '%s' (error %d)." % [office_scene_path, error])
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
