extends Node

@export var dialogue_resource : DialogueResource
@export var dialogue_part2 : String = "tutorial2"
@export var dialogue_part3 : String = "tutorial3"

@onready var tab1 = $"../tab1"
@onready var tab2 = $"../tab2"
@onready var tab3 = $"../tab3"
@onready var folder = $"../folder"
var tabopen = 0

@onready var filingcabinet = $"../FilingCabinet"
var filingopencount = 0


func _ready() -> void:
	filingcabinet.filing_opened.connect(_on_filing_opened)
	print(tab1)
	print(tab2)
	print(tab3)
	print(folder)
	folder.tab_opened.connect(_on_filetab_opened)

func _on_filing_opened():
	filingopencount += 1
	if filingopencount == 1:
		DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_part2)

func _on_filetab_opened():
	tabopen += 1
	print(tabopen)
	if tabopen == 1:
		DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_part3)
