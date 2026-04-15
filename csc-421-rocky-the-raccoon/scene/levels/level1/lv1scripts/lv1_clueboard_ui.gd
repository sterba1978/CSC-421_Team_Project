extends Control

signal clue_selected(clue_id: String, clue_title: String, clue_text: String)

@onready var clue1UI = $"../clue_ui"
@onready var clue2UI = $"../clue_ui2"
@onready var clue3UI = $"../clue_ui3"
@onready var player = $"../InteriorPlayer"

@export var clue_1_title: String = "Client Intake"
@export_multiline var clue_1_text: String = "The first note from the client points to suspicious account activity and an unfamiliar login that happened after business hours."
@export var clue_2_title: String = "Workstation Snapshot"
@export_multiline var clue_2_text: String = "The office workstation shows new software and pop-up behavior that the client says they never approved or installed."
@export var clue_3_title: String = "Network Activity"
@export_multiline var clue_3_text: String = "Traffic logs show repeated outbound connections that line up with the client's report, suggesting the compromise is active and communicating outward."

signal clue_opened # dialog signal
signal clueboard_closed # dialog signal

@onready var checklist1 = $"../Checklist"
@onready var checklist2 = $"../Checklist2"
@onready var clbackground = $"../ChecklistBackground"
@onready var dialogue_manager = $"../DialogueManager"

var cluedesc = "This is a clue description."

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
	clue1UI.show()


func _on_clue_button_2_pressed() -> void:
	_open_clue("clue_2", clue_2_title, clue_2_text)
	clue2UI.show()


func _on_clue_button_3_pressed() -> void:
	_open_clue("clue_3", clue_3_title, clue_3_text)
	clue3UI.show()


func _open_clue(clue_id: String, clue_title: String, clue_text: String) -> void:
	clue_selected.emit(clue_id, clue_title, clue_text)
	clue_opened.emit() # dialog signal
