extends Node

@export var dialogue_resource : DialogueResource
@export var dialogue_part2 : String = "tutorial2"

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


func _ready() -> void:
	update_checklist("Enter the office")

func update_checklist(newtext):
	checklist.text = newtext
