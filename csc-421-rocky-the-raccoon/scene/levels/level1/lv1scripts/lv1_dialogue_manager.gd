extends Node

@export var dialogue_resource : DialogueResource
@export var dialogue_lv1a : String = "level1a"
@export var dialogue_lv1b : String = "level1b"

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

@onready var carla = $"../Carla"

func _ready() -> void:
	DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_lv1a)
	update_checklist("Investigate your clues and files")
	clue1.clue1_closed.connect(_on_clue1_closed)
	clue2.clue2_closed.connect(_on_clue2_closed)
	clue3.clue3_closed.connect(_on_clue3_closed)
	carla.carla_talk.connect(_on_carla_talk)

func _on_clue1_closed():
	clue1closed += 1
	if clue2closed >= 1 and clue3closed >= 1:
		carla.add_to_group("interactable")
		update_checklist("Talk to Carla when ready")

func _on_clue2_closed():
	clue2closed += 1
	if clue1closed >= 1 and clue3closed >= 1:
		carla.add_to_group("interactable")
		update_checklist("Talk to Carla when ready")

func _on_clue3_closed():
	clue3closed += 1
	if clue1closed >= 1 and clue2closed >= 1:
		carla.add_to_group("interactable")
		update_checklist("Talk to Carla when ready")

func _on_carla_talk():
	DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_lv1b)

func update_checklist(newtext):
	checklist.text = newtext
