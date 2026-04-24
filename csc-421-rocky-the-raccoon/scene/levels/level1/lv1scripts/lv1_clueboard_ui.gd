extends Control

signal clue_selected(clue_id: String, clue_title: String, clue_text: String)

const CLUE_SELECT_SFX := preload("res://assets/audio/Interact.mp3")

@onready var clue1UI = $"../clue_ui"
@onready var clue2UI = $"../clue_ui2"
@onready var clue3UI = $"../clue_ui3"
@onready var player = $"../InteriorPlayer"

@export var clue_1_title: String = "Email 1: Rajah"
@export_multiline var clue_1_text: String = "This email is a bit weird. The senders email address doesn't make sense. It seems like the prince is in urgent need of help. I should cross reference my files and make sure im not missing anything."
@export var clue_2_title: String = "Email 2: Alice"
@export_multiline var clue_2_text: String = "I don't notice anything odd about this email right off the bat. Seems like Alice are Carla are friends. I should cross reference my files just to be sure and make sure im not missing anything."
@export var clue_3_title: String = "Email 3: Tony"
@export_multiline var clue_3_text: String = "Looks like Tony's Pizza is offering a discount tomorrow. Guess he's urgently trying to get as many customers as possible. I should cross reference my files and make sure im not missing anything."
@export var clue_select_sfx_volume_db: float = -4.0

signal clue_opened # dialog signal
signal clueboard_closed # dialog signal

@onready var checklist1 = $"../Checklist"
@onready var checklist2 = $"../Checklist2"
@onready var clbackground = $"../ChecklistBackground"
@onready var dialogue_manager = $"../DialogueManager"
@onready var return_button: Button = get_node_or_null("ReturnButton")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_apply_return_button_frame()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_return_button_pressed() -> void:
	self.hide()
	MusicManager.pop_music()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	player._update_crosshair_visibility()
	clueboard_closed.emit() # dialog signal
	checklist1.show()
	checklist2.show()
	clbackground.show()


func _on_clue_button_1_pressed() -> void:
	_open_clue("clue_1", clue_1_title, clue_1_text)
	clue1UI.show()


func _on_clue_button_2_pressed() -> void:
	_open_clue("clue_2", clue_2_title, clue_2_text)
	clue2UI.show()


func _on_clue_button_3_pressed() -> void:
	_open_clue("clue_3", clue_3_title, clue_3_text)
	clue3UI.show()


func _open_clue(clue_id: String, clue_title: String, clue_text: String) -> void:
	MusicManager.play_sfx(CLUE_SELECT_SFX, clue_select_sfx_volume_db)
	clue_selected.emit(clue_id, clue_title, clue_text)
	clue_opened.emit() # dialog signal


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
