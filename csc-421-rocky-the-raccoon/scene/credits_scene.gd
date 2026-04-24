extends Control

const MAGNIFYING_CURSOR := preload("res://assets/magnifying_cursor.png")
const CURSOR_HOTSPOT := Vector2(42, 48)

@export_file("*.tscn") var menu_scene_path: String = "res://scene/StartMenu.tscn"
@export var fade_in_duration: float = 0.55
@export var fade_out_duration: float = 0.45

var _fade_rect: ColorRect
var _continue_button: Button
var _can_continue := false
var _is_transitioning := false


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Input.set_custom_mouse_cursor(MAGNIFYING_CURSOR, Input.CURSOR_ARROW, CURSOR_HOTSPOT)
	_build_scene()
	await _fade_from_black()
	_can_continue = true
	_continue_button.disabled = false
	_continue_button.grab_focus()


func _build_scene() -> void:
	var background := ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_PASS
	background.color = Color(0.025, 0.03, 0.045)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 72)
	margin.add_theme_constant_override("margin_top", 56)
	margin.add_theme_constant_override("margin_right", 72)
	margin.add_theme_constant_override("margin_bottom", 56)
	add_child(margin)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 18)
	margin.add_child(content)

	var title := Label.new()
	title.text = "Credits"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", Color(0.98, 0.96, 0.9))
	content.add_child(title)

	var body := Label.new()
	body.text = "Asset acknowledgements\n\nKayKit assets by Kay Lousberg - www.kaylousberg.com\nKenney asset packs - www.kenney.nl\nDialogue Manager addon\nGodot Engine\n\nAudio and sound effects\n\nBy The Paddy Wagon\nAmbient Tension music tracks\nfreesound community knocking-on-door sound effect\nsoundreality opening door sound effect\nfletchpike door closing sound effect\nfreesound community page flip sound effect\n\nThank you to everyone whose art, tools, music, and sound effects helped bring Rocky's office and cases to life."
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 22)
	body.add_theme_color_override("font_color", Color(0.88, 0.91, 0.96))
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(body)

	_continue_button = Button.new()
	_continue_button.text = "Exit To Title Screen"
	_continue_button.custom_minimum_size = Vector2(260, 52)
	_continue_button.disabled = true
	_apply_framed_button_style(_continue_button)
	_continue_button.pressed.connect(_on_continue_button_pressed)
	content.add_child(_continue_button)

	_fade_rect = ColorRect.new()
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.color = Color.BLACK
	add_child(_fade_rect)


func _on_continue_button_pressed() -> void:
	if not _can_continue or _is_transitioning:
		return
	await _return_to_menu()


func _input(event: InputEvent) -> void:
	if not _can_continue or _is_transitioning:
		return
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		get_viewport().set_input_as_handled()
		await _return_to_menu()


func _return_to_menu() -> void:
	_is_transitioning = true
	_can_continue = false
	_continue_button.disabled = true
	await _fade_to_black()
	SceneTransitionState.reset()
	var error := get_tree().change_scene_to_file(menu_scene_path)
	if error != OK:
		push_warning("credits_scene.gd: Failed to load menu scene '%s' (error %d)." % [menu_scene_path, error])


func _apply_framed_button_style(button: Button) -> void:
	var normal := _make_button_style(Color(0.043, 0.075, 0.133, 0.92), Color(0.624, 0.773, 0.941, 0.95))
	var hover := _make_button_style(Color(0.08, 0.12, 0.2, 0.96), Color(0.82, 0.9, 1.0, 1.0))
	var pressed := _make_button_style(Color(0.025, 0.045, 0.085, 0.98), Color(0.98, 0.96, 0.9, 1.0))
	var disabled := _make_button_style(Color(0.03, 0.04, 0.06, 0.72), Color(0.35, 0.42, 0.5, 0.8))

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_color_override("font_color", Color(0.98, 0.96, 0.9))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_font_size_override("font_size", 20)


func _make_button_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 8
	return style


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
