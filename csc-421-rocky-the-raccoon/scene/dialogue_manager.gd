extends Node

@export var dialogue_resource : DialogueResource
@export var dialogue_part2 : String = "tutorial2"
@export var dialogue_part3 : String = "tutorial3"
@export var dialogue_part4 : String = "tutorial4"

@onready var tab1 = $"../tab1"
@onready var tab2 = $"../tab2"
@onready var tab3 = $"../tab3"
@onready var folder = $"../folder"
var tabopen = 0
var folderclosed = 0

@onready var filingcabinet = $"../FilingCabinet"
var filingopencount = 0


func _ready() -> void:
	filingcabinet.filing_opened.connect(_on_filing_opened)
	folder.tab_opened.connect(_on_filetab_opened)
	folder.folder_closed.connect(_on_folder_closed)

func _on_filing_opened():
	filingopencount += 1
	if filingopencount == 1:
		DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_part2)

func _on_filetab_opened():
	tabopen += 1
	if tabopen == 1:
		DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_part3)

func _on_folder_closed():
	folderclosed += 1
	if folderclosed == 1:
		DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_part4)
