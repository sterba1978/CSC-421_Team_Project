extends Control

const GAME_SCENE_PATH := "res://scene/main.tscn"
const MAGNIFYING_CURSOR := preload("res://assets/magnifying_cursor.png")
const CURSOR_HOTSPOT := Vector2(42, 48)

@onready var _start_button: BaseButton = $Layout/Card/Content/VBox/Buttons/Start
@onready var _quit_button: BaseButton = $Layout/Card/Content/VBox/Buttons/Quit

func _ready() -> void:
	_apply_custom_cursor()

	if not _start_button.pressed.is_connected(_on_start_pressed):
		_start_button.pressed.connect(_on_start_pressed)
	if not _quit_button.pressed.is_connected(_on_quit_pressed):
		_quit_button.pressed.connect(_on_quit_pressed)

	if OS.has_feature("web"):
		_quit_button.hide()

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_quit_pressed() -> void:
	get_tree().quit()

func _apply_custom_cursor() -> void:
	Input.set_custom_mouse_cursor(MAGNIFYING_CURSOR, Input.CURSOR_ARROW, CURSOR_HOTSPOT)
