extends Control

signal clue_selected(clue_id: String, clue_title: String, clue_text: String)

@onready var clueUI = $"../Clue_UI"
@onready var player = $"../InteriorPlayer"

@export var clue_1_title: String = "Clue 1"
@export_multiline var clue_1_text: String = "Here is where important details of each clue will be displayed for you to analyze and determine if this clue is suspicious."
@export var clue_2_title: String = "Clue 2"
@export_multiline var clue_2_text: String = "Here is where important details of each clue will be displayed for you to analyze and determine if this clue is suspicious."
@export var clue_3_title: String = "Clue 3"
@export_multiline var clue_3_text: String = "Here is where important details of each clue will be displayed for you to analyze and determine if this clue is suspicious."

signal clue_opened # dialog signal
signal clueboard_closed # dialog signal

@onready var checklist1 = $"../Checklist"
@onready var checklist2 = $"../Checklist2"
@onready var clbackground = $"../ChecklistBackground"
@onready var dialogue_manager = $"../DialogueManager"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


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


func _on_clue_button_2_pressed() -> void:
	_open_clue("clue_2", clue_2_title, clue_2_text)


func _on_clue_button_3_pressed() -> void:
	_open_clue("clue_3", clue_3_title, clue_3_text)


func _open_clue(clue_id: String, clue_title: String, clue_text: String) -> void:
	clueUI.show()
	clue_selected.emit(clue_id, clue_title, clue_text)
	clue_opened.emit() # dialog signal
