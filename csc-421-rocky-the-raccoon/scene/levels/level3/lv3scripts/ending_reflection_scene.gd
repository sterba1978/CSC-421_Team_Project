extends Control

const MAGNIFYING_CURSOR := preload("res://assets/magnifying_cursor.png")
const CURSOR_HOTSPOT := Vector2(42, 48)
const CUTSCENE_AUDIO := preload("res://assets/audio/By The Paddy Wagon.mp3")

@export_file("*.tscn") var credits_scene_path: String = "res://scene/credits_scene.tscn"
@export var fade_in_duration: float = 0.55
@export var fade_out_duration: float = 0.45
@export var cutscene_audio_volume_db: float = -8.0
@export var cutscene_audio_start_position_sec: float = 7.5

var _fade_rect: ColorRect
var _continue_button: Button
var _can_continue := false
var _is_transitioning := false


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Input.set_custom_mouse_cursor(MAGNIFYING_CURSOR, Input.CURSOR_ARROW, CURSOR_HOTSPOT)
	MusicManager.clear_music_stack()
	MusicManager.play_music(CUTSCENE_AUDIO, cutscene_audio_volume_db, cutscene_audio_start_position_sec, true)
	_build_scene()
	await _fade_from_black()
	_can_continue = true
	_continue_button.disabled = false
	_continue_button.grab_focus()


func _build_scene() -> void:
	var background := TextureRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.texture = load("res://officeSceneRender.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(background)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.02, 0.03, 0.07, 0.68)
	add_child(shade)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 72)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_right", 72)
	margin.add_theme_constant_override("margin_bottom", 36)
	add_child(margin)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 14)
	margin.add_child(content)

	var kicker := Label.new()
	kicker.text = "Case Results"
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kicker.add_theme_font_size_override("font_size", 18)
	kicker.add_theme_color_override("font_color", Color(0.7, 0.82, 0.97))
	content.add_child(kicker)

	var title := Label.new()
	title.text = "Detective Grade"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(0.98, 0.96, 0.9))
	content.add_child(title)

	var results_scroll := ScrollContainer.new()
	results_scroll.custom_minimum_size = Vector2(0, 320)
	results_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	results_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	results_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(results_scroll)

	var body := Label.new()
	body.text = _build_results_text()
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 20)
	body.add_theme_color_override("font_color", Color(0.88, 0.91, 0.96))
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	results_scroll.add_child(body)

	_continue_button = Button.new()
	_continue_button.text = "Continue"
	_continue_button.custom_minimum_size = Vector2(260, 52)
	_continue_button.disabled = true
	_apply_framed_button_style(_continue_button)
	_continue_button.pressed.connect(_on_continue_button_pressed)
	content.add_child(_continue_button)

	_fade_rect = ColorRect.new()
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.color = Color.BLACK
	add_child(_fade_rect)


func _build_results_text() -> String:
	var results := Autoload.get_case_results()
	var overall_score := Autoload.get_overall_score()
	var lines: Array[String] = [
		"Overall Score: %d%%  Grade: %s" % [overall_score, Autoload.get_letter_grade(overall_score)],
		"",
	]

	for result in results:
		var mistakes := int(result.get("mistakes", 0))
		var penalty_text := "No solve penalties" if mistakes == 0 else "%d wrong solve guess%s (-%d)" % [mistakes, "" if mistakes == 1 else "es", mistakes * 10]
		lines.append("%s: %d%%  Grade: %s" % [
			result.get("title", "Case"),
			int(result.get("total_score", 0)),
			result.get("grade", "Incomplete"),
		])
		lines.append("Solve choices: %d/50 | Journal: %d/50 | %s" % [
			int(result.get("choice_score", 0)),
			int(result.get("journal_score", 0)),
			penalty_text,
		])
		var solve_feedback: Array = result.get("solve_feedback", [])
		if not solve_feedback.is_empty():
			var solve_feedback_text := PackedStringArray()
			for feedback in solve_feedback:
				solve_feedback_text.append(str(feedback))
			lines.append("Solve review: %s" % [" ".join(solve_feedback_text)])
		lines.append(str(result.get("journal_feedback", "")))
		lines.append("")

	lines.append("Journal answers are graded by whether they identify the suspicious clue and mention case-relevant warning signs or safety advice.")
	return "\n".join(lines)


func _on_continue_button_pressed() -> void:
	if not _can_continue or _is_transitioning:
		return
	await _transition_to_credits()


func _unhandled_input(event: InputEvent) -> void:
	if not _can_continue or _is_transitioning:
		return
	if event.is_action_pressed("ui_accept"):
		await _transition_to_credits()


func _transition_to_credits() -> void:
	_is_transitioning = true
	_can_continue = false
	_continue_button.disabled = true
	await _fade_to_black()

	var error := get_tree().change_scene_to_file(credits_scene_path)
	if error != OK:
		push_warning("ending_reflection_scene.gd: Failed to load credits scene '%s' (error %d)." % [credits_scene_path, error])
		_is_transitioning = false
		_can_continue = true
		_continue_button.disabled = false
		await _fade_from_black()


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
