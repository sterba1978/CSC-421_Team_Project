extends Control

@onready var clueUI = $"../Clue_UI"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_return_button_pressed() -> void:
	self.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_clue_button_1_pressed() -> void:
	clueUI.show()


func _on_clue_button_2_pressed() -> void:
	clueUI.show()


func _on_clue_button_3_pressed() -> void:
	clueUI.show()
