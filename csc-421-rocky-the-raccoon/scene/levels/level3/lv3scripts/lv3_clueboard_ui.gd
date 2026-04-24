extends Control

signal clue_selected(clue_id: String, clue_title: String, clue_text: String)

const CLUE_SELECT_SFX := preload("res://assets/audio/Interact.mp3")

@onready var clue1UI = $"../clue_ui"
@onready var clue2UI = $"../clue_ui2"
@onready var clue3UI = $"../clue_ui3"
@onready var player = $"../InteriorPlayer"

@export var clue_1_title: String = "Bakery Webpage"
@export_multiline var clue_1_text: String = "Looks like Peter was checking out Julia's bakery yesterday. It doesn't seem suspicious at first glance. I should cross reference it with my files just to be sure."
@export var clue_2_title: String = "News Webpage"
@export_multiline var clue_2_text: String = "Looks like Peter was reading through a news reports yesterday. I don't like that ads scattered around the website. I should cross reference it with my files and see if its suspicious."
@export var clue_3_title: String = "Movie Webpage"
@export_multiline var clue_3_text: String = "Looks like Peter was trying to watch some movies on this website. The site s a retro vibe like back in the day. I don't like that it has a bunch of ads.I should cross reference it with my files and see if its suspicious."
@export var clue_select_sfx_volume_db: float = -4.0

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
