extends Control

signal clue_closed # dialog signal

@onready var return_button: Button = get_node_or_null("ReturnButton")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_apply_return_button_frame()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_return_button_pressed() -> void:
	self.hide()
	clue_closed.emit() # dialog signal


func _apply_return_button_frame() -> void:
	if return_button == null:
		return

	var normal := _make_button_style(Color(0.02, 0.018, 0.012, 0.82), Color(0.78, 0.72, 0.56, 0.95))
	var hover := _make_button_style(Color(0.08, 0.06, 0.035, 0.92), Color(1.0, 0.88, 0.42, 1.0))
	var pressed := _make_button_style(Color(0.01, 0.01, 0.008, 1.0), Color(1.0, 0.78, 0.25, 1.0))
	return_button.add_theme_stylebox_override("normal", normal)
	return_button.add_theme_stylebox_override("hover", hover)
	return_button.add_theme_stylebox_override("pressed", pressed)
	return_button.add_theme_stylebox_override("disabled", normal)


func _make_button_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(3)
	style.set_corner_radius_all(4)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style
