extends Control

signal tab_selected(clue_text: String)


#THIS IS THE SPYWARE FILE
@onready var tab1UI = $"../tab1"
@onready var tab2UI = $"../tab2"
@onready var tab3UI = $"../tab3"
@onready var player = $"../InteriorPlayer"

@export var tab_1_text: String = "Tab 1 selected"
@export var tab_2_text: String = "Tab 2 selected"
@export var tab_3_text: String = "Tab 3 selected"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_return_button_pressed() -> void:
	self.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	player._update_crosshair_visibility()


func _on_tab_1_pressed() -> void:
	self.hide()
	tab1UI.show()
	tab_selected.emit(tab_1_text)

func _on_tab_2_pressed() -> void:
	self.hide()
	tab2UI.show()
	tab_selected.emit(tab_2_text)

func _on_tab_3_pressed() -> void:
	self.hide()
	tab3UI.show()
	tab_selected.emit(tab_3_text)
