extends Control

const GAME_SCENE_PATH := "res://scene/main.tscn"
const MAGNIFYING_CURSOR := preload("res://assets/magnifying_cursor.png")
const MENU_MUSIC := preload("res://assets/audio/Silent Regrets - Ambient Tension Vol 1 FINAL MIX.wav")
const GAME_MUSIC := preload("res://assets/audio/Speaking Out - Ambient Tension Vol 1 FINAL MIX.wav")
const CURSOR_HOTSPOT := Vector2.ZERO

@export var menu_music_volume_db: float = -8.0
@export var menu_music_start_position_sec: float = 0.0
@export var game_music_volume_db: float = -8.0
@export var game_music_start_position_sec: float = 0.0

@onready var _start_button: BaseButton = $Layout/Card/Content/VBox/Buttons/Start
@onready var _quit_button: BaseButton = $Layout/Card/Content/VBox/Buttons/Quit
@onready var _start_label: Label = $Layout/Card/Content/VBox/Buttons/Start/Label
@onready var _menu_viewport: SubViewport = $SubViewportContainer/SubViewport

var _load_requested := false
var _start_requested := false

func _ready() -> void:
	Input.set_custom_mouse_cursor(MAGNIFYING_CURSOR, Input.CURSOR_ARROW, CURSOR_HOTSPOT)
	SceneTransitionState.reset()
	MusicManager.play_music(MENU_MUSIC, menu_music_volume_db, menu_music_start_position_sec)

	if not _start_button.pressed.is_connected(_on_start_pressed):
		_start_button.pressed.connect(_on_start_pressed)
	if not _quit_button.pressed.is_connected(_on_quit_pressed):
		_quit_button.pressed.connect(_on_quit_pressed)

	if OS.has_feature("web"):
		_quit_button.hide()

	_request_game_scene_load()


func _process(_delta: float) -> void:
	if not _start_requested:
		return

	var load_status := ResourceLoader.load_threaded_get_status(GAME_SCENE_PATH)
	if load_status == ResourceLoader.THREAD_LOAD_LOADED:
		var packed_scene := ResourceLoader.load_threaded_get(GAME_SCENE_PATH) as PackedScene
		if packed_scene != null:
			_start_requested = false
			get_tree().change_scene_to_packed(packed_scene)
			return

		_finish_start_request(false)
	elif load_status == ResourceLoader.THREAD_LOAD_FAILED:
		_finish_start_request(false)


func _on_start_pressed() -> void:
	if _start_requested:
		return

	SceneTransitionState.reset()
	MusicManager.play_music(GAME_MUSIC, game_music_volume_db, game_music_start_position_sec)
	_request_game_scene_load()
	_start_requested = true
	_start_button.disabled = true
	_quit_button.disabled = true
	_start_label.text = "Loading..."
	if _menu_viewport != null:
		_menu_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED

func _on_quit_pressed() -> void:
	get_tree().quit()


func _request_game_scene_load() -> void:
	if _load_requested:
		return

	var error := ResourceLoader.load_threaded_request(GAME_SCENE_PATH)
	if error == OK:
		_load_requested = true


func _finish_start_request(keep_loading: bool) -> void:
	_start_requested = false
	_start_button.disabled = false
	_quit_button.disabled = false
	_start_label.text = "Start"
	if _menu_viewport != null:
		_menu_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	if not keep_loading:
		_load_requested = false
		MusicManager.play_music(MENU_MUSIC, menu_music_volume_db, menu_music_start_position_sec)
