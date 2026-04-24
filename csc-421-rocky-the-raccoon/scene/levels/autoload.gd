extends Node

signal dialogue_show_mouse
signal dialogue_hide_mouse
signal level1_ended
signal level2_ended
signal level3_ended

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _show_mouse():
	dialogue_show_mouse.emit()

func _hide_mouse():
	dialogue_hide_mouse.emit()

func _level1_ended():
	level1_ended.emit()

func _level2_ended():
	level2_ended.emit()

func _level3_ended():
	level3_ended.emit()
