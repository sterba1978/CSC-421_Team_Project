extends Control

signal clue_selected(clue_text: String)

@onready var clueUI = $"../Clue_UI"
@onready var player = $"../InteriorPlayer"

@export var clue_1_text: String = "Clue 1 selected"
@export var clue_2_text: String = "Clue 2 selected"
@export var clue_3_text: String = "Clue 3 selected"

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


func _on_clue_button_1_pressed() -> void:
	clueUI.show()
	clue_selected.emit(clue_1_text)


func _on_clue_button_2_pressed() -> void:
	clueUI.show()
	clue_selected.emit(clue_2_text)


func _on_clue_button_3_pressed() -> void:
	clueUI.show()
	clue_selected.emit(clue_3_text)
