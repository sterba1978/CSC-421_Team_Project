extends Node

@export var dialogue_resource : DialogueResource
@export var dialogue_lv3a : String = "level3a"
@export var dialogue_lv3b : String = "level3b"

@onready var tab1 = $"../tab1"
@onready var tab2 = $"../tab2"
@onready var tab3 = $"../tab3"
@onready var folder = $"../folder"
var tabopen = 0
var folderclosed = 0

@onready var filingcabinet = $"../FilingCabinet"
var filingopencount = 0
@onready var clueboardobj = $"../ClueBoard1"
var clueboardopened = 0
@onready var clueboard = $"../ClueBoardUI"
var clueopened = 0
var clueboardclosed = 0
@onready var clue1 = $"../clue_ui"
var clue1closed = 0
@onready var clue2 = $"../clue_ui2"
var clue2closed = 0
@onready var clue3 = $"../clue_ui3"
var clue3closed = 0

@onready var checklist = $"../Checklist2"

@onready var bear = $"../Peter"

var autoload = Autoload

func _ready() -> void:
	DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_lv3a)
	update_checklist("Investigate your clues and journal")
	clue1.clue1_closed.connect(_on_clue1_closed)
	clue2.clue2_closed.connect(_on_clue2_closed)
	clue3.clue3_closed.connect(_on_clue3_closed)
	bear.bear_talk.connect(_on_bear_talk)
	autoload.dialogue_show_mouse.connect(_showmouse)
	autoload.dialogue_hide_mouse.connect(_hidemouse)

func _on_clue1_closed():
	clue1closed += 1
	if clue2closed >= 1 and clue3closed >= 1:
		bear.add_to_group("interactable")
		update_checklist("Talk to Peter when ready")

func _on_clue2_closed():
	clue2closed += 1
	if clue1closed >= 1 and clue3closed >= 1:
		bear.add_to_group("interactable")
		update_checklist("Talk to Peter when ready")

func _on_clue3_closed():
	clue3closed += 1
	if clue1closed >= 1 and clue2closed >= 1:
		bear.add_to_group("interactable")
		update_checklist("Talk to Peter when ready")

func _on_bear_talk():
	DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_lv3b)

func update_checklist(newtext):
	checklist.text = newtext

func _showmouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _hidemouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
